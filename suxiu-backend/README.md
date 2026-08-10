# 锦绣智造后端：用户指南

## 项目结构

```
suxiu-backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI 入口
│   ├── config.py            # 配置管理
│   ├── api/
│   │   ├── v1/
│   │   │   ├── auth.py      # 认证 API
│   │   │   ├── design.py    # 设计 API
│   │   │   ├── order.py     # 订单 API
│   │   │   ├── factory.py   # 工厂 API
│   │   │   └── upload.py    # 上传 API
│   ├── db/
│   │   ├── database.py      # 数据库连接
│   │   ├── crud_user.py     # 用户 CRUD
│   │   ├── crud_design.py   # 设计 CRUD
│   │   └── crud_order.py    # 订单 CRUD
│   ├── models/
│   │   ├── user.py          # 用户模型
│   │   ├── design.py        # 设计模型
│   │   └── order.py         # 订单模型
│   ├── schemas/
│   │   ├── user.py          # 用户 Schema
│   │   ├── design.py        # 设计 Schema
│   │   ├── order.py         # 订单 Schema
│   │   └── response.py      # 统一响应
│   ├── services/
│   │   └── ai_service.py    # AI 服务
│   └── utils/
│       └── auth.py          # 认证工具
├── config.yaml              # 配置文件
├── requirements.txt         # Python 依赖
├── .env.example             # 环境变量示例
└── README.md                # 本文件
```

## 快速开始

### 1. 安装依赖

```bash
cd suxiu-backend
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入实际配置
```

### 3. 启动数据库

使用 PostgreSQL（或 Docker）：

```bash
docker run -d \
  --name suxiu-postgres \
  -e POSTGRES_USER=suxiu \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=suxiu_ai \
  -p 5432:5432 \
  postgres:15
```

### 4. 启动服务

```bash
# 开发模式
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 生产模式
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 5. 访问 API 文档

打开浏览器访问：http://localhost:8000/docs

## API 接口

### 认证接口
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/refresh` - 刷新 Token
- `GET /api/v1/auth/me` - 获取当前用户信息

### 设计接口
- `POST /api/v1/design/generate` - 生成 AI 设计
- `GET /api/v1/design/task/{id}` - 查询任务状态
- `GET /api/v1/design/{id}` - 获取设计详情
- `GET /api/v1/designs` - 获取设计列表
- `DELETE /api/v1/design/{id}` - 删除设计

### 订单接口
- `POST /api/v1/order/create` - 创建订单
- `GET /api/v1/order/{id}` - 获取订单详情
- `GET /api/v1/orders` - 获取订单列表
- `POST /api/v1/order/{id}/cancel` - 取消订单
- `GET /api/v1/order/{id}/track` - 跟踪订单

### 工厂接口
- `GET /api/v1/factory/list` - 获取工厂列表
- `GET /api/v1/factory/{id}` - 获取工厂详情

### 上传接口
- `GET /api/v1/upload/oss-token` - 获取 OSS 上传凭证

## 部署到阿里云函数计算

### 1. 安装部署工具

```bash
pip install funtool
```

### 2. 配置阿里云凭证

```bash
aliyun configure
```

### 3. 部署

```bash
fun deploy
```

## 测试

```bash
pytest tests/
```

## 注意事项

1. **API Key 安全**: 不要将 `.env` 文件提交到 Git
2. **生产环境**: 必须修改 `JWT_SECRET_KEY`
3. **数据库**: 生产环境建议使用阿里云 RDS PostgreSQL
4. **日志**: 生产环境建议接入阿里云日志服务
