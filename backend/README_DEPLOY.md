# ArtMe Backend 部署指南

## 环境变量配置

复制 `.env.example` 为 `.env` 并配置以下变量：

```bash
cp .env.example .env
```

### 必需配置

- `SECRET_KEY`: 用于 JWT 令牌签名的密钥（生产环境必须更改）
- `OPENAI_API_KEY`: OpenAI API 密钥
- `DATABASE_URL`: 数据库连接字符串

### 可选配置

- `DEBUG`: 调试模式（生产环境设为 False）
- `CORS_ORIGINS`: 允许的跨域来源
- `UPLOAD_DIR`: 上传文件目录
- `STYLE_IMAGES_DIR`: 风格图片目录

## Docker 部署

### 使用 Docker Compose（推荐）

```bash
# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 使用 Docker

```bash
# 构建镜像
docker build -t artme-backend .

# 运行容器
docker run -d \
  -p 8000:8000 \
  -e OPENAI_API_KEY=your-key \
  -e SECRET_KEY=your-secret \
  -v $(pwd)/uploads:/app/uploads \
  artme-backend
```

## 云服务部署

### Heroku

```bash
# 安装 Heroku CLI
heroku create artme-backend

# 设置环境变量
heroku config:set OPENAI_API_KEY=your-key
heroku config:set SECRET_KEY=your-secret

# 部署
git push heroku main
```

### AWS EC2

1. 在 EC2 实例上安装 Docker
2. 克隆代码仓库
3. 配置环境变量
4. 使用 docker-compose 启动服务

### 数据库迁移

```bash
# 初始化数据库
python scripts/init_db.py

# 或使用 Alembic（如果配置了）
alembic upgrade head
```

## 生产环境注意事项

1. **安全性**
   - 使用强密码和密钥
   - 启用 HTTPS
   - 配置防火墙规则
   - 定期更新依赖

2. **性能**
   - 使用 PostgreSQL 替代 SQLite
   - 配置 Redis（RQ 队列/缓存）
   - 使用 CDN 提供静态文件
   - 配置负载均衡

3. **监控**
   - 配置日志收集
   - 设置健康检查
   - 监控 API 响应时间
   - 设置告警

## RQ Worker（并发后台生图）

说明：`/api/v1/generate` 与 `/api/v1/generate/with-image` 会把任务投递到 Redis/RQ，
需要独立启动 worker 才会真正执行生图。

### 1) 启动 Redis

- 本地可直接使用 `redis-server`
- 或使用 Docker：

```bash
docker run -d --name artme-redis -p 6379:6379 redis:7
```

### 2) 启动 Worker

推荐使用脚本（支持一次拉起多个 worker 进程）：

```bash
python scripts/run_rq_workers.py
```

也可以手动启动单个 worker（示例）：

```bash
rq worker artme_generate
```

