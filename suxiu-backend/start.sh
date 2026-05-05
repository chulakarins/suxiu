#!/bin/bash
# 苏绣 AI 后端 - 启动脚本

echo "================================"
echo "     苏绣 AI 后端服务"
echo "================================"
echo ""

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "错误：未找到 Python3"
    exit 1
fi

echo "[1/4] 检查 Python 版本..."
python3 --version

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "[2/4] 创建虚拟环境..."
    python3 -m venv venv
else
    echo "[2/4] 虚拟环境已存在"
fi

# 激活虚拟环境
echo "[3/4] 激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "[4/4] 安装依赖..."
pip install -r requirements.txt -q

# 检查.env 文件
if [ ! -f ".env" ]; then
    echo ""
    echo "警告：未找到.env 文件"
    echo "请复制.env.example 为.env 并配置："
    echo "  cp .env.example .env"
    echo ""
fi

echo ""
echo "================================"
echo "启动服务..."
echo "API 文档：http://localhost:8000/docs"
echo "按 Ctrl+C 停止服务"
echo "================================"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
