"""
AI 服务 - 调用阿里云通义万相 API
"""
import asyncio
from typing import Optional
import httpx
from app.config import settings


class AIService:
    """AI 图像生成服务"""

    def __init__(self):
        self.api_key = settings.DASHSCOPE_API_KEY
        self.endpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis"
        self.base_url = "https://dashscope.aliyuncs.com/api/v1"

        # 苏绣风格提示词后缀
        self.suxiu_style_prompt = (
            ", ultra realistic macro photography of traditional suzhou embroidery (苏绣), "
            "hand stitched silk threads, visible thread fibers, delicate needlework details, "
            "natural fabric folds, subtle thread tension variations, silk texture with soft light scattering, "
            "100mm macro lens, shallow depth of field, realistic bokeh, soft studio lighting, "
            "gentle shadows, slight natural imperfections, documentary style textile photography, "
            "extremely detailed craftsmanship"
        )

        # 负向提示词
        self.negative_prompt = (
            "CGI, 3D render, plastic texture, artificial smooth surfaces, "
            "over-sharpening, glossy AI effect, cartoon, anime, digital illustration, "
            "oil painting, watercolor, brush strokes, low quality"
        )

    async def submit_task(
        self,
        prompt: str,
        size: str = "1280*1280",
        style: str = "traditional"
    ) -> str:
        """
        提交图像生成任务
        :return: 任务 ID
        """
        # 构建完整提示词
        full_prompt = prompt + self.suxiu_style_prompt

        body = {
            "model": "wan2.5-t2i-preview",
            "input": {
                "prompt": full_prompt,
                "negative_prompt": self.negative_prompt
            },
            "parameters": {
                "size": size,
                "n": 1,
                "prompt_extend": True,
                "watermark": False
            }
        }

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "X-DashScope-Async": "enable"
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                self.endpoint,
                json=body,
                headers=headers
            )

            if response.status_code != 200:
                raise Exception(f"提交任务失败：{response.status_code} - {response.text}")

            data = response.json()

            if data.get("code"):
                raise Exception(f"API 错误：{data.get('message')} (code: {data.get('code')})")

            task_id = data.get("output", {}).get("task_id")
            if not task_id:
                raise Exception("无法获取任务 ID")

            return task_id

    async def query_task(self, task_id: str) -> dict:
        """
        查询任务状态
        :return: 任务状态信息
        """
        url = f"{self.base_url}/tasks/{task_id}"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, headers=headers)

            if response.status_code != 200:
                raise Exception(f"查询任务失败：{response.status_code}")

            data = response.json()
            output = data.get("output", {})

            return {
                "task_id": task_id,
                "status": output.get("task_status", "UNKNOWN"),
                "message": output.get("message"),
                "code": output.get("code"),
                "results": output.get("results", []),
            }

    async def generate_image(
        self,
        prompt: str,
        size: str = "1280*1280",
        poll_callback: callable = None
    ) -> str:
        """
        生成图片（包含轮询）
        :param prompt: 提示词
        :param size: 尺寸
        :param poll_callback: 轮询回调函数 (用于更新进度)
        :return: 图片 URL
        """
        # 提交任务
        task_id = await self.submit_task(prompt, size)

        if poll_callback:
            await poll_callback({"task_id": task_id, "status": "pending", "progress": 10})

        # 轮询结果
        max_attempts = settings.AI_MAX_POLL_ATTEMPTS
        poll_interval = settings.AI_POLL_INTERVAL

        for attempt in range(1, max_attempts + 1):
            await asyncio.sleep(poll_interval)

            task_info = await self.query_task(task_id)
            status = task_info["status"]

            if poll_callback:
                progress = min(10 + (attempt * 80 // max_attempts), 90)
                await poll_callback({
                    "task_id": task_id,
                    "status": status,
                    "progress": progress
                })

            if status == "SUCCEEDED":
                # 提取图片 URL
                results = task_info.get("results", [])
                if results and len(results) > 0:
                    image_url = results[0].get("url")
                    if image_url:
                        if poll_callback:
                            await poll_callback({
                                "task_id": task_id,
                                "status": "succeeded",
                                "progress": 100,
                                "image_url": image_url
                            })
                        return image_url
                raise Exception("无法从结果中提取图片 URL")

            elif status == "FAILED":
                raise Exception(f"生成失败：{task_info.get('message', '未知错误')}")

            # 其他状态继续轮询 (PENDING/RUNNING)

        raise Exception("任务超时，请稍后重试")


# 全局 AI 服务实例
ai_service = AIService()
