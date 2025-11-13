# ArtMe iOS App

卡通头像生成应用的 iOS 客户端，使用 Swift 和 SwiftUI 开发。

## 项目结构

```
ios/
├── ArtMe/
│   ├── ArtMe.xcodeproj      # Xcode 项目文件（需在 Xcode 中创建）
│   ├── ArtMe/
│   │   ├── App/
│   │   │   ├── ArtMeApp.swift        # 应用入口
│   │   │   └── ContentView.swift     # 主视图
│   │   ├── Models/                   # 数据模型
│   │   │   ├── Style.swift           # 风格模型
│   │   │   ├── GeneratedImage.swift  # 生成的图像模型
│   │   │   └── UserAccount.swift     # 用户账户模型
│   │   ├── Views/                    # 视图
│   │   │   ├── StyleSelectionView.swift    # 风格选择视图
│   │   │   ├── GenerateView.swift          # 生成视图
│   │   │   ├── HistoryView.swift           # 历史记录视图
│   │   │   └── AccountView.swift           # 账户视图
│   │   ├── ViewModels/               # 视图模型（MVVM）
│   │   │   ├── StyleViewModel.swift
│   │   │   ├── GenerateViewModel.swift
│   │   │   └── AccountViewModel.swift
│   │   ├── Services/                 # 服务层
│   │   │   ├── APIService.swift      # API 客户端
│   │   │   ├── ImageService.swift    # 图像服务
│   │   │   └── PaymentService.swift  # 支付服务
│   │   ├── Utils/                    # 工具类
│   │   │   └── Constants.swift       # 常量定义
│   │   └── Resources/                # 资源文件
│   │       ├── Assets.xcassets       # 图片资源
│   │       └── Info.plist            # 应用配置
│   └── ArtMeTests/                   # 测试文件
└── README.md
```

## 创建 Xcode 项目

### 方法 1: 使用 Xcode 创建

1. 打开 Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "iOS" -> "App"
4. 填写项目信息：
   - Product Name: ArtMe
   - Interface: SwiftUI
   - Language: Swift
5. 选择保存位置为 `ios/ArtMe/` 目录

### 方法 2: 使用命令行

```bash
cd ios
xcodegen  # 如果安装了 xcodegen
# 或手动在 Xcode 中创建项目
```

## 配置要求

### Info.plist 配置

需要添加以下权限：

- 网络访问权限
- 相册访问权限（用于保存生成的图像）
- 相机权限（如果需要）

### 依赖管理

推荐使用 Swift Package Manager (SPM) 或 CocoaPods：

#### Swift Package Manager

在 Xcode 中添加以下依赖：
- Alamofire (可选，用于网络请求)
- Kingfisher (可选，用于图像加载和缓存)

#### CocoaPods

创建 `Podfile`：

```ruby
platform :ios, '15.0'
use_frameworks!

target 'ArtMe' do
  pod 'Alamofire', '~> 5.8'
  pod 'Kingfisher', '~> 7.0'
end
```

## 开发说明

- 最低支持 iOS 15.0
- 使用 SwiftUI 构建界面
- 采用 MVVM 架构模式
- 使用 URLSession 或 Alamofire 进行网络请求
- 使用 StoreKit 2 实现内购功能

## 环境配置

在 `Utils/Constants.swift` 中配置 API 基础 URL：

```swift
struct Constants {
    static let apiBaseURL = "http://localhost:8000"  // 开发环境
    // static let apiBaseURL = "https://api.artme.com"  // 生产环境
}
```

## 在 iOS 模拟器中运行应用

### 前提条件

1. **安装 Xcode**：从 App Store 安装最新版本的 Xcode
2. **安装 Command Line Tools**：
   ```bash
   xcode-select --install
   ```
3. **确保后端服务已启动**（如果应用需要连接后端）

### 步骤 1: 创建 Xcode 项目（如果还没有创建）

如果还没有创建 `.xcodeproj` 文件，请按照以下步骤：

1. 打开 **Xcode**
2. 选择菜单：`File` > `New` > `Project...`
3. 选择 **iOS** > **App**，点击 `Next`
4. 填写项目信息：
   - **Product Name**: `ArtMe`
   - **Team**: 选择你的开发团队（如果没有，可以稍后添加）
   - **Organization Identifier**: 例如 `com.yourcompany`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: Core Data（可选，根据需求）
5. 点击 `Next`
6. **重要**：保存位置选择为 `ios/ArtMe/` 目录（确保覆盖已存在的文件结构）
7. 点击 `Create`

### 步骤 2: 添加现有文件到项目

如果创建新项目，需要将现有代码文件添加到项目中：

1. 在 Xcode 左侧项目导航器中，右键点击 `ArtMe` 文件夹
2. 选择 `Add Files to "ArtMe"...`
3. 选择 `ios/ArtMe/ArtMe/` 目录下的所有文件夹：
   - `App/`
   - `Models/`
   - `Views/`
   - `ViewModels/`
   - `Services/`
   - `Utils/`
   - `Resources/`
4. 确保勾选：
   - ✅ **Copy items if needed**（如果文件在其他位置）
   - ✅ **Create groups**（推荐）
   - ✅ **Add to targets: ArtMe**
5. 点击 `Add`

### 步骤 3: 配置项目设置

1. 在 Xcode 项目导航器中，点击项目名称（最上面的蓝色图标）
2. 选择 **ArtMe** target
3. 在 **General** 标签页中：
   - **Minimum Deployments**: iOS 15.0 或更高
   - **Bundle Identifier**: 确保是唯一的（例如 `com.yourcompany.ArtMe`）
4. 在 **Info** 标签页中，检查 `Info.plist` 配置：
   - 确保已添加网络访问权限（如果需要）
   - 添加相册访问权限说明（如果应用需要保存图片）

### 步骤 4: 配置模拟器

1. 在 Xcode 顶部工具栏，点击设备选择器（显示 "Any iOS Device" 的地方）
2. 选择要使用的模拟器：
   - **iPhone 15 Pro**（推荐，最新设备）
   - **iPhone 14 Pro**
   - **iPad Pro**（如果需要测试平板）
3. 如果没有可用的模拟器，选择 `Add Additional Simulators...` 进行添加

### 步骤 5: 配置 API 地址（用于连接后端）

如果应用需要连接本地后端服务器：

1. 打开 `Utils/Constants.swift`
2. 修改 `apiBaseURL`：
   ```swift
   static let apiBaseURL = "http://localhost:8000"  // 模拟器使用
   ```
   
   **注意**：iOS 模拟器使用 `localhost` 或 `127.0.0.1` 可以访问 Mac 上的本地服务。
   
   如果需要从真实设备访问，需要使用 Mac 的局域网 IP 地址，例如：
   ```swift
   static let apiBaseURL = "http://192.168.1.100:8000"  // 替换为你的 Mac IP
   ```

### 步骤 6: 运行应用

1. 在 Xcode 中，按 **`⌘ + R`**（或点击左上角的播放按钮 ▶️）
2. Xcode 会：
   - 编译项目
   - 启动选定的模拟器（如果还没有运行）
   - 安装并启动应用

### 步骤 7: 查看应用界面

应用启动后，你会在 iOS 模拟器中看到界面。可以：
- **滚动**：在模拟器中用鼠标拖动
- **点击**：用鼠标点击界面元素
- **旋转**：`⌘ + ←/→` 旋转设备
- **缩放**：`⌘ + 1/2/3` 调整模拟器大小
- **截屏**：`⌘ + S` 保存模拟器截图
- **重启应用**：`⌘ + R` 重新运行

### 常用快捷键

- **⌘ + R**: 运行应用
- **⌘ + .**: 停止运行
- **⌘ + B**: 仅编译
- **⌘ + K**: 清理构建
- **⌘ + Shift + K**: 清理构建文件夹
- **⌘ + Control + Z**: 模拟器菜单（摇动、旋转等）

### 故障排除

#### 问题 1: 编译错误
- 检查所有 Swift 文件是否都添加到 target
- 确保最低 iOS 版本设置正确
- 查看 Xcode 底部的 Issue Navigator（左侧边栏的三角形图标）

#### 问题 2: 模拟器无法启动
- 检查 Xcode 是否已完全安装
- 尝试：`Xcode` > `Settings` > `Platforms`，确保已下载 iOS 模拟器

#### 问题 3: 网络请求失败
- 确保后端服务正在运行
- 检查防火墙设置
- 在模拟器中访问 Safari，测试能否打开 `http://localhost:8000`

#### 问题 4: 应用崩溃
- 查看 Xcode 底部的控制台输出
- 检查是否有缺失的资源文件
- 验证所有必需的视图文件是否存在

### 使用 SwiftUI 预览（快速查看）

SwiftUI 支持实时预览功能，无需运行完整模拟器：

1. 在 Xcode 中打开任意 SwiftUI 视图文件（如 `ContentView.swift`）
2. 在代码编辑器的右上角，点击 **Resume** 按钮（或按 `⌘ + Option + P`）
3. 预览会在右侧显示，可以实时看到 UI 变化
4. 点击预览底部的 **Live Preview** 按钮进行交互测试

### 下一步

- 修改代码后，应用会自动重新编译并运行（如果启用了自动运行）
- 使用 Xcode 的调试工具进行断点调试
- 查看应用日志输出

