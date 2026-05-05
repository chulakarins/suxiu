"""
设计 API 路由
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.db.database import get_db, async_session_maker
from app.db.crud_design import (
    create_design,
    get_design_by_id,
    update_design,
    delete_design,
    get_user_designs,
)
from app.schemas.design import (
    DesignGenerateRequest,
    DesignInfo,
    DesignSpecs,
    TaskStatusResponse,
)
from app.schemas.response import success_response, error_response, ErrorCode
from app.utils.auth import get_current_user
from app.services.ai_service import ai_service

router = APIRouter()


async def on_progress_update(progress_data: dict):
    """进度更新回调"""
    # 这里可以记录日志或推送给前端
    print(f"[Progress] {progress_data}")


@router.post("/generate")
async def generate_design(
    request: DesignGenerateRequest,
    background_tasks: BackgroundTasks,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    生成 AI 设计

    提交任务后立即返回，前端通过 task_id 轮询结果
    """
    # 创建设计记录
    design = await create_design(
        db=db,
        user_id=current_user_id,
        prompt=request.prompt,
        style=request.style,
        size=request.size,
        reference_image_urls=request.reference_image_urls,
        color_preferences=request.color_preferences,
    )

    # 后台任务：执行 AI 生成
    background_tasks.add_task(run_ai_task, design.id, request.prompt, request.size)

    return success_response(
        data={
            "task_id": design.id,
            "design_id": design.id,
            "status": "pending",
            "estimated_time": 30
        }
    )


async def run_ai_task(design_id: str, prompt: str, size: str):
    """后台执行 AI 生成任务"""
    async with async_session_maker() as session:
        try:
            # 获取设计记录
            from app.db.crud_design import get_design_by_id
            design = await get_design_by_id(session, design_id)
            if not design:
                print(f"[AI Task] Design {design_id} not found")
                return

            # 更新状态为运行中
            await update_design(session, design, status="running", progress=10)

            # 进度回调：轮询时更新进度到 DB
            async def on_progress(data: dict):
                status_map = {
                    "PENDING": "running",
                    "RUNNING": "running",
                    "SUCCEEDED": "succeeded",
                    "FAILED": "failed",
                    "SUCCESS": "succeeded",
                }
                current_status = status_map.get(data.get("status", ""), "running")
                progress = data.get("progress", 10)
                await update_design(session, design, status=current_status, progress=progress)

            # 调用 AI 服务
            image_url = await ai_service.generate_image(
                prompt=prompt,
                size=size,
                poll_callback=on_progress,
            )

            # 生成制作规格
            specs = {
                "dimensions": {"width": 30, "height": 30, "unit": "cm"},
                "stitch_types": ["平针绣", "打籽绣"],
                "thread_colors": [{"code": "C001", "name": "中国红"}],
                "estimated_time": 8,
                "difficulty": "medium",
            }

            await update_design(
                session, design,
                status="succeeded",
                progress=100,
                image_url=image_url,
                specs=specs,
            )
            await session.commit()
            print(f"[AI Task] Design {design_id} completed successfully")
        except Exception as e:
            async with async_session_maker() as err_session:
                try:
                    design = await get_design_by_id(err_session, design_id)
                    if design:
                        await update_design(err_session, design, status="failed", progress=0)
                        await err_session.commit()
                except:
                    pass
            print(f"[AI Task Error] {e}")


@router.get("/task/{task_id}")
async def get_task_status(
    task_id: str,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    查询任务状态
    """
    design = await get_design_by_id(db, task_id, user_id=current_user_id)
    if not design:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设计不存在"
        )

    result = None
    if design.status == "succeeded" and design.image_url:
        result = {
            "image_url": design.image_url,
            "thumbnail_url": design.thumbnail_url,
            "design_id": design.id
        }

    return success_response(
        data={
            "task_id": task_id,
            "status": design.status,
            "progress": design.progress,
            "result": result,
            "message": None
        }
    )


@router.get("/{design_id}")
async def get_design(
    design_id: str,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    获取设计详情
    """
    design = await get_design_by_id(db, design_id, user_id=current_user_id)
    if not design:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设计不存在"
        )

    return success_response(
        data={
            "design_id": design.id,
            "user_id": design.user_id,
            "prompt": design.prompt,
            "style": design.style,
            "size": design.size,
            "image_url": design.image_url,
            "thumbnail_url": design.thumbnail_url,
            "specs": design.specs,
            "status": design.status,
            "progress": design.progress,
            "created_at": design.created_at.isoformat() if design.created_at else None,
            "updated_at": design.updated_at.isoformat() if design.updated_at else None,
        }
    )


@router.get("/s")
async def list_designs(
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=50),
    status: Optional[str] = Query(None),
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    获取设计列表
    """
    designs, total = await get_user_designs(
        db=db,
        user_id=current_user_id,
        offset=offset,
        limit=limit,
        status=status,
    )

    design_list = []
    for d in designs:
        design_list.append({
            "design_id": d.id,
            "thumbnail_url": d.thumbnail_url or d.image_url,
            "prompt": d.prompt,
            "style": d.style,
            "status": d.status,
            "progress": d.progress,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        })

    return success_response(
        data={
            "total": total,
            "designs": design_list
        }
    )


@router.delete("/{design_id}")
async def delete_design_endpoint(
    design_id: str,
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    删除设计
    """
    design = await get_design_by_id(db, design_id, user_id=current_user_id)
    if not design:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设计不存在"
        )

    await delete_design(db, design)

    return success_response(message="删除成功")
