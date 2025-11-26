# 真机连接配置指南

## 问题
当 iOS 应用在真机上运行时，无法连接到运行在 Mac 上的后端服务（localhost）。

## 原因
- 真机的 `localhost` 指向设备本身，不是 Mac
- 需要使用 Mac 的局域网 IP 地址

## 解决步骤

### 1. 获取 Mac 的 IP 地址

在终端运行：
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

或者更简单的方式：
```bash
ipconfig getifaddr en0
```

当前 Mac IP: `192.168.31.128`

### 2. 确认后端服务配置

后端服务已经配置为监听所有网络接口（`0.0.0.0`），这是正确的。

检查 `app/config.py`：
```python
HOST: str = "0.0.0.0"  # ✅ 正确，允许来自任何 IP 的连接
PORT: int = 8000
```

### 3. 确认 iOS 应用配置

#### 3.1 检查 Constants.swift

文件位置：`artme/ios/artme/ArtMe/Utils/Constants.swift`

真机配置应该使用 Mac IP：
```swift
#if targetEnvironment(simulator)
    static let apiBaseURL = "http://localhost:8000"
#else
    static let apiBaseURL = "http://172.18.20.225:8000"  // 使用 Mac IP
#endif
```

#### 3.2 检查 Info.plist

文件位置：`artme/ios/artme/Info.plist`

确保包含 Mac IP 的 ATS 例外：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>172.18.20.225</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 4. 启动后端服务

确保后端服务正在运行：
```bash
cd artme/backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

或者使用：
```bash
python -m app.main
```

### 5. 测试连接

#### 5.1 在 Mac 上测试
```bash
curl http://localhost:8000/api/v1/prompts/list
```

#### 5.2 在 iPhone 上测试

1. 确保 iPhone 和 Mac 连接到**同一个 Wi-Fi 网络**
2. 在 iPhone 的 Safari 浏览器中访问：
   ```
   http://172.18.20.225:8000/api/v1/prompts/list
   ```
3. 如果能看到 JSON 数据，说明连接正常

### 6. 检查防火墙

确保 Mac 防火墙允许端口 8000 的入站连接：

1. 打开"系统设置" > "网络" > "防火墙"
2. 如果防火墙已开启，确保允许 Python 或 uvicorn 的连接
3. 或者临时关闭防火墙进行测试

### 7. 常见问题排查

#### 问题 1: 连接超时
- ✅ 检查 Mac 和 iPhone 是否在同一 Wi-Fi 网络
- ✅ 检查后端服务是否运行：`curl http://localhost:8000/health`
- ✅ 检查防火墙设置

#### 问题 2: 无法解析主机
- ✅ 确认 Constants.swift 中的 IP 地址正确
- ✅ 确认 Info.plist 中配置了 ATS 例外

#### 问题 3: 连接被拒绝
- ✅ 确认后端服务绑定到 `0.0.0.0` 而不是 `127.0.0.1`
- ✅ 确认端口 8000 没有被其他程序占用

### 8. 快速验证清单

- [ ] Mac IP 地址已获取：`192.168.31.128`
- [ ] Constants.swift 中真机配置使用 Mac IP
- [ ] Info.plist 中包含 Mac IP 的 ATS 例外
- [ ] 后端服务正在运行（端口 8000）
- [ ] 后端服务绑定到 `0.0.0.0`
- [ ] Mac 和 iPhone 在同一 Wi-Fi 网络
- [ ] 防火墙允许端口 8000 的连接
- [ ] 在 iPhone Safari 中可以访问 API

### 9. 如果 IP 地址改变

如果 Mac 的 IP 地址改变了，需要更新：

1. **获取新 IP**：
   ```bash
   ipconfig getifaddr en0
   ```

2. **更新 Constants.swift**：
   修改真机配置中的 IP 地址

3. **更新 Info.plist**：
   在 NSExceptionDomains 中添加新的 IP 地址

4. **重新编译运行**：
   在 Xcode 中重新编译并运行应用

## 当前配置状态

- ✅ 后端服务: 监听 `0.0.0.0:8000`
- ✅ CORS: 开发环境允许所有来源
- ✅ Mac IP: `172.18.20.225`
- ✅ iOS 配置: 已配置真机使用 Mac IP
- ✅ Info.plist: 已配置 ATS 例外

## 下一步

1. 重启后端服务（如果正在运行）
2. 在 Xcode 中重新编译并运行应用到真机
3. 测试应用是否能正常加载数据




