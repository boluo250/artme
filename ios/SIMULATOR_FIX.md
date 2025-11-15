# iOS 模拟器连接修复指南

## 快速修复步骤

### 1. 确保后端服务运行

在终端运行：
```bash
cd artme/backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

确认服务运行后，测试 API：
```bash
curl http://localhost:8000/api/v1/prompts/list
```

应该返回 JSON 数据。

### 2. 检查 Xcode 控制台日志

我已经添加了详细的调试日志。运行应用后，在 Xcode 控制台（Console）中查看以下日志：

```
🔄 开始加载图片列表...
📡 API Base URL: http://localhost:8000
📡 Full URL: http://localhost:8000/api/v1/prompts/list
🌐 API Request: GET http://localhost:8000/api/v1/prompts/list
```

如果看到错误，会显示：
```
❌ 错误信息...
```

### 3. 常见问题和解决方案

#### 问题 1: 无法连接到服务器
**错误信息**: `无法连接到服务器` 或 `cannotConnectToHost`

**解决方案**:
1. 确认后端服务正在运行
2. 检查端口 8000 是否被占用
3. 尝试在模拟器的 Safari 中访问 `http://localhost:8000/api/v1/prompts/list`

#### 问题 2: URL 无效
**错误信息**: `无效的 URL 地址`

**解决方案**:
检查 `Constants.swift` 中的配置：
```swift
#if targetEnvironment(simulator)
static let apiBaseURL = "http://localhost:8000"
#endif
```

#### 问题 3: 数据解析失败
**错误信息**: `数据解析失败`

**解决方案**:
1. 查看控制台输出的响应内容
2. 确认后端返回的数据格式正确
3. 检查 JSON 字段名称是否匹配

#### 问题 4: 请求超时
**错误信息**: `请求超时`

**解决方案**:
1. 检查网络连接
2. 确认后端服务响应速度
3. 超时时间已设置为 60 秒

### 4. 测试步骤

1. **启动后端服务**
   ```bash
   cd artme/backend
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

2. **在 Xcode 中运行应用**
   - 选择 iOS 模拟器（不是真机）
   - 按 ⌘ + R 运行
   - 打开应用后，下拉刷新列表

3. **查看日志**
   - 在 Xcode 底部打开控制台（Console）
   - 查看是否有错误信息
   - 如果有错误，根据上面的解决方案修复

### 5. 当前配置状态

✅ **Constants.swift**: 
   - 模拟器使用 `http://localhost:8000`
   - 已配置正确的 API 端点

✅ **Info.plist**: 
   - 已允许 localhost 的 HTTP 访问

✅ **错误处理**: 
   - 已添加详细的错误信息
   - 已添加调试日志

✅ **API Service**: 
   - 已添加请求日志
   - 已添加响应日志
   - 已添加错误日志

### 6. 下一步

1. 运行应用
2. 查看 Xcode 控制台的日志输出
3. 根据日志信息找到具体问题
4. 按照上面的解决方案修复

### 7. 如果还是不行

请提供以下信息：
1. Xcode 控制台的完整日志
2. 具体的错误信息
3. 后端服务的运行状态

我可以根据这些信息进一步诊断问题。

