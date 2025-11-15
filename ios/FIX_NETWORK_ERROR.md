# 修复 iOS 应用网络连接错误指南

## 问题描述
应用在下拉刷新时显示"加载图片列表失败"错误。

## 诊断步骤

### 1. 检查后端服务是否运行
在终端运行：
```bash
curl http://localhost:8000/api/v1/prompts/list
```
如果返回 JSON 数据，说明后端正常。

### 2. 检查运行环境

#### 情况 A：在 iOS 模拟器上运行
- ✅ 可以使用 `http://localhost:8000`
- 确保后端服务在 Mac 上运行
- 检查防火墙设置

#### 情况 B：在真机上运行
- ❌ **不能使用 `localhost`**，因为真机的 localhost 指向设备本身，不是 Mac
- 需要使用 Mac 的局域网 IP 地址

## 修复方法

### 方法 1：在模拟器上运行（推荐开发时使用）

1. **确认后端服务运行**
   ```bash
   cd artme/backend
   # 启动后端服务（如果未运行）
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

2. **确认 Constants.swift 配置**
   ```swift
   #if DEBUG
   static let apiBaseURL = "http://localhost:8000"
   #else
   static let apiBaseURL = "https://api.artme.com"
   #endif
   ```

3. **在 Xcode 中运行应用**
   - 选择 iOS 模拟器（不是真机）
   - 按 ⌘ + R 运行

### 方法 2：在真机上运行

1. **获取 Mac 的 IP 地址**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   当前 Mac IP: `172.18.20.225`

2. **修改 Constants.swift**
   打开 `artme/ios/artme/ArtMe/Utils/Constants.swift`，修改为：
   ```swift
   #if DEBUG
   static let apiBaseURL = "http://172.18.20.225:8000"  // 使用 Mac 的 IP
   #else
   static let apiBaseURL = "https://api.artme.com"
   #endif
   ```

3. **确保后端服务监听所有接口**
   后端服务需要绑定到 `0.0.0.0` 而不是 `127.0.0.1`：
   ```bash
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

4. **检查防火墙**
   - 确保 Mac 防火墙允许端口 8000 的入站连接
   - 系统设置 > 网络 > 防火墙

5. **确保 Mac 和 iPhone 在同一网络**
   - 两者必须连接到同一个 Wi-Fi 网络

6. **更新 Info.plist（如果需要）**
   如果使用 IP 地址而不是 localhost，需要添加 IP 地址到 App Transport Security 例外：
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSExceptionDomains</key>
       <dict>
           <key>localhost</key>
           <dict>
               <key>NSExceptionAllowsInsecureHTTPLoads</key>
               <true/>
           </dict>
           <key>172.18.20.225</key>
           <dict>
               <key>NSExceptionAllowsInsecureHTTPLoads</key>
               <true/>
           </dict>
       </dict>
   </dict>
   ```

### 方法 3：使用环境变量（更灵活的方案）

可以创建一个更智能的配置，自动检测运行环境：

```swift
struct Constants {
    // API 配置
    #if DEBUG
    #if targetEnvironment(simulator)
    // 模拟器使用 localhost
    static let apiBaseURL = "http://localhost:8000"
    #else
    // 真机使用 Mac IP（需要手动配置）
    static let apiBaseURL = "http://172.18.20.225:8000"
    #endif
    #else
    static let apiBaseURL = "https://api.artme.com"
    #endif
}
```

## 测试连接

### 在 Mac 上测试
```bash
curl http://localhost:8000/api/v1/prompts/list
```

### 在 iPhone 上测试
1. 打开 Safari
2. 访问 `http://172.18.20.225:8000/api/v1/prompts/list`
3. 如果能看到 JSON 数据，说明网络连接正常

## 常见问题

### Q1: 错误信息显示 "无法连接到服务器"
**原因**: 
- 真机上使用了 localhost
- 后端服务未运行
- Mac 和 iPhone 不在同一网络

**解决**: 
- 使用 Mac IP 地址替代 localhost
- 确保后端服务运行
- 确保在同一 Wi-Fi 网络

### Q2: 错误信息显示 "请求超时"
**原因**: 
- 网络速度慢
- 后端服务响应慢

**解决**: 
- 检查网络连接
- 检查后端服务日志
- 增加超时时间（已设置为 60 秒）

### Q3: 错误信息显示 "服务器错误 (HTTP 500)"
**原因**: 
- 后端服务内部错误
- 数据库连接问题

**解决**: 
- 查看后端服务日志
- 检查后端服务状态

## 快速修复步骤总结

1. ✅ **确认后端服务运行**: `curl http://localhost:8000/api/v1/prompts/list`
2. ✅ **确定运行环境**: 模拟器还是真机？
3. ✅ **配置 API 地址**: 
   - 模拟器: `http://localhost:8000`
   - 真机: `http://[Mac IP]:8000`
4. ✅ **更新 Info.plist**: 添加 IP 地址到 ATS 例外（如果使用 IP）
5. ✅ **重新编译运行**: 在 Xcode 中重新运行应用

## 当前配置状态

- ✅ 后端服务: 运行中（端口 8000）
- ✅ API 端点: 正常（返回 200）
- ✅ Mac IP 地址: `172.18.20.225`
- ⚠️  iOS 应用配置: 需要根据运行环境调整

## 下一步

根据你的运行环境（模拟器或真机），按照上面的步骤进行配置即可。

