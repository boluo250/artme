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

