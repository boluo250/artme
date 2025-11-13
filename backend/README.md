# ArtMe Backend API

卡通头像生成应用的后端 API 服务，基于 FastAPI 构建。

## 项目结构

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI 应用入口
│   ├── config.py            # 配置管理
│   ├── database.py          # 数据库连接
│   ├── models/              # 数据模型
│   ├── schemas/             # Pydantic 模型
│   ├── api/                 # API 路由
│   │   ├── __init__.py
│   │   ├── generate.py      # 图像生成 API
│   │   ├── styles.py        # 风格管理 API
│   │   ├── account.py       # 账户管理 API
│   │   └── subscription.py  # 订阅管理 API
│   ├── services/            # 业务逻辑
│   │   ├── __init__.py
│   │   ├── ai_service.py    # 大模型 API 服务
│   │   ├── image_service.py # 图像处理服务
│   │   └── payment_service.py # 支付服务
│   └── utils/               # 工具函数
│       ├── __init__.py
│       └── prompts.py       # Prompt 模板管理
├── requirements.txt
├── .env.example
└── README.md
```

## 安装和运行

### 1. 创建虚拟环境

```bash
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# 或
venv\Scripts\activate  # Windows
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入实际的配置值
```

### 4. 运行服务

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

服务将在 http://localhost:8000 启动

API 文档访问：http://localhost:8000/docs

## 开发说明

- 使用 FastAPI 作为 Web 框架
- 使用 SQLAlchemy 进行数据库操作
- 使用 Pydantic 进行数据验证
- 支持异步处理

