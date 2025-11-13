# ArtMe API 文档

## 基础信息

- **Base URL**: `http://localhost:8000` (开发环境)
- **API Version**: `v1`
- **Content-Type**: `application/json`

## 认证

大部分 API 需要用户认证。使用 JWT Token 进行认证：

```
Authorization: Bearer <token>
```

## API 端点

### 健康检查

#### GET /health

检查服务健康状态

**响应示例：**
```json
{
  "status": "healthy"
}
```

### 图像生成

#### POST /api/v1/generate

生成卡通头像

**请求体：**
```json
{
  "prompt": "a cute cat",
  "style_id": "style_001",
  "user_id": "user_123",
  "width": 512,
  "height": 512,
  "model": "dall-e-3"
}
```

**响应示例：**
```json
{
  "image_url": "/uploads/generated/image.jpg",
  "task_id": "task_123",
  "status": "completed",
  "prompt": "anime style, kawaii, a cute cat, high quality"
}
```

### 风格管理

#### GET /api/v1/styles/list

获取风格列表

**查询参数：**
- `category` (可选): 风格类别
- `limit` (可选, 默认20): 返回数量
- `offset` (可选, 默认0): 偏移量

**响应示例：**
```json
{
  "styles": [
    {
      "id": "style_001",
      "name": "日系卡通",
      "description": "日系风格的卡通头像",
      "category": "anime",
      "example_image_url": "/style_images/anime_example.jpg",
      "prompt_template": "anime style, kawaii, {user_prompt}, high quality",
      "tags": ["anime", "kawaii", "cute"]
    }
  ],
  "total": 10
}
```

#### GET /api/v1/styles/search

搜索风格

**查询参数：**
- `q` (必需): 搜索关键词
- `limit` (可选, 默认20): 返回数量

#### GET /api/v1/styles/{style_id}

获取单个风格详情

### 模型管理

#### GET /api/v1/models

获取可用的大模型列表

**响应示例：**
```json
{
  "models": [
    {
      "id": "dall-e-3",
      "name": "DALL-E 3",
      "status": "available"
    }
  ]
}
```

### 账户管理

#### POST /api/v1/account/register

用户注册

**请求体：**
```json
{
  "username": "user123",
  "email": "user@example.com",
  "password": "password123"
}
```

#### POST /api/v1/account/login

用户登录

**请求体：**
```json
{
  "username": "user123",
  "password": "password123"
}
```

**响应示例：**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": "user_123",
    "username": "user123",
    "email": "user@example.com",
    "balance": 0.0,
    "subscription_type": "none"
  }
}
```

#### GET /api/v1/account/balance

查询账户余额

**查询参数：**
- `user_id` (必需): 用户ID

**响应示例：**
```json
{
  "balance": 100.0
}
```

#### POST /api/v1/account/recharge

账户充值

**查询参数：**
- `user_id` (必需): 用户ID

**请求体：**
```json
{
  "amount": 50.0,
  "payment_method": "apple"
}
```

#### GET /api/v1/account/transactions

获取交易记录

**查询参数：**
- `user_id` (必需): 用户ID
- `limit` (可选, 默认20): 返回数量
- `offset` (可选, 默认0): 偏移量

### 订阅管理

#### POST /api/v1/subscription

创建订阅

**查询参数：**
- `user_id` (必需): 用户ID

**请求体：**
```json
{
  "subscription_type": "monthly",
  "payment_method": "apple"
}
```

#### GET /api/v1/subscription

获取当前订阅信息

**查询参数：**
- `user_id` (必需): 用户ID

#### POST /api/v1/subscription/cancel

取消订阅

**查询参数：**
- `user_id` (必需): 用户ID

## 错误响应

所有错误响应遵循以下格式：

```json
{
  "error": "Error Type",
  "message": "错误描述",
  "detail": "详细错误信息"
}
```

### 常见错误码

- `400`: 请求参数错误
- `401`: 未授权
- `403`: 禁止访问
- `404`: 资源不存在
- `422`: 验证错误
- `500`: 服务器内部错误

## 速率限制

- 图像生成：每个用户每分钟最多 10 次请求
- API 调用：每个 IP 每分钟最多 100 次请求

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 支持图像生成
- 支持风格管理
- 支持用户账户和支付

