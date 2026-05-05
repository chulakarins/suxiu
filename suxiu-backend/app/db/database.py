"""
数据库配置和会话管理
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.config import settings

# 判断是否使用 SQLite
_is_sqlite = "sqlite" in settings.DATABASE_URL

# 创建异步引擎
if _is_sqlite:
    # SQLite 不支持连接池
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=settings.DEBUG,
    )
else:
    # PostgreSQL 使用连接池
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=settings.DEBUG,
        pool_size=settings.DATABASE_POOL_SIZE,
        max_overflow=settings.DATABASE_MAX_OVERFLOW,
    )

# 会话工厂
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Base 类 - 所有模型继承
Base = declarative_base()


async def init_db():
    """初始化数据库 - 创建所有表"""
    async with engine.begin() as conn:
        # 导入所有模型以注册到 Base
        from app.models import user, design, order
        await conn.run_sync(Base.metadata.create_all)


async def get_db() -> AsyncSession:
    """获取数据库会话 (依赖注入)"""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
