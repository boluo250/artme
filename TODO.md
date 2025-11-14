# iOS 卡通头像生成应用 - 开发待办事项

## 项目概述
- **前端**: iOS Swift (SwiftUI/UIKit)
- **后端**: Python FastAPI
- **功能**: 卡通头像生成，调用大模型 API

---

## 待办事项列表

### 1. 项目初始化和环境搭建
- [x] 创建 iOS 项目结构（Xcode 项目）
- [x] 创建 FastAPI 后端项目结构
- [x] 配置 Python 虚拟环境
- [x] 配置依赖管理（requirements.txt）

### 2. FastAPI 后端开发
- [x] 创建 FastAPI 应用框架
- [x] 设计 API 路由结构（/generate, /health, /models, /styles 等）
- [x] 实现请求验证和错误处理中间件
- [x] 配置 CORS 支持 iOS 客户端
- [x] 实现风格管理 API（/styles/list, /styles/search, /styles/{id}）
- [x] 实现风格示例图片管理（存储、获取风格示例图片）

### 3. 大模型 API 集成
- [x] 选择并集成大模型 API（如 OpenAI、Claude、国内大模型等）
- [x] 实现 API 调用封装和错误重试机制
- [x] 实现 prompt 工程（卡通头像生成提示词）
- [x] 设计不同风格的 prompt 模板库（如：日系、美式、3D、手绘、像素风等）
- [x] 实现风格与 prompt 的映射关系管理
- [x] 实现根据风格选择动态生成 prompt 的逻辑
- [x] 处理 API 响应和图像数据

### 4. 图像处理服务
- [x] 实现图像接收和存储逻辑
- [x] 实现图像格式转换和优化
- [x] 实现图像缓存机制
- [x] 实现图像下载和传输优化
- [x] 实现风格示例图片的存储和管理
- [x] 实现示例图片的缩略图生成和优化

### 5. iOS Swift 前端
- [x] 创建 SwiftUI 或 UIKit 项目结构
- [x] 设计应用架构（MVVM/MVC）
- [x] 实现网络层（URLSession/Alamofire）
- [x] 实现 API 客户端封装

### 6. iOS UI 开发
- [x] 设计主界面（头像生成页面）
- [x] 实现风格选择界面（展示不同风格的图片示例）
- [x] 实现风格示例图片展示（网格布局、卡片式展示）
- [x] 实现风格搜索界面（搜索框、搜索结果展示）
- [x] 实现风格分类和筛选功能（按类别、标签筛选）
- [x] 实现输入界面（文本输入、参数选择）
- [x] 实现图像展示界面
- [x] 实现加载状态和错误提示 UI
- [x] 实现历史记录界面

### 7. iOS 功能实现
- [x] 实现风格数据模型（风格ID、名称、示例图片、prompt模板等）
- [x] 实现风格列表获取和缓存功能
- [x] 实现风格搜索功能（本地搜索、服务端搜索）
- [x] 实现风格选择功能（点击风格示例，传递风格ID）
- [x] 实现根据选择的风格动态生成 prompt
- [x] 实现图像生成请求功能（包含风格参数）
- [x] 实现图像下载和本地存储
- [x] 实现图像分享功能
- [x] 实现历史记录管理（记录使用的风格）
- [x] 实现用户偏好设置（收藏风格、常用风格）

### 8. 用户账户和计费系统（后端）
- [x] 设计用户账户数据模型（用户ID、余额、订阅状态等）
- [x] 实现用户注册和登录系统
- [x] 实现账户余额管理（查询、扣除、充值）
- [x] 实现计费逻辑（单次调用扣费、订阅扣费）
- [x] 实现交易记录系统（充值记录、消费记录）
- [x] 实现订阅管理（周费、月费订阅的创建、续费、取消）
- [x] 实现订阅到期检查和自动续费逻辑
- [x] 集成支付网关（如 Stripe、支付宝、微信支付等）
- [x] 实现支付回调处理（验证支付结果、更新账户余额）
- [x] 实现计费 API 接口（/account/balance, /account/recharge, /subscription 等）

### 9. iOS 支付和充值功能
- [x] 集成 iOS 内购（In-App Purchase）SDK
- [x] 实现充值套餐选择界面（单次调用、周费、月费等）
- [x] 实现账户余额显示界面
- [x] 实现充值流程（选择套餐、发起支付、处理支付结果）
- [x] 实现订阅管理界面（查看订阅状态、取消订阅）
- [x] 实现支付历史记录界面
- [x] 实现余额不足提示和引导充值
- [x] 处理支付失败和退款情况
- [x] 实现支付状态同步（与后端同步支付状态）

### 10. 配置和部署
- [x] 配置 API 密钥管理（环境变量/配置文件）
- [x] 配置后端部署（Docker/云服务）
- [x] 配置 iOS 应用配置（Info.plist、网络权限）
- [x] 实现应用图标和启动画面

### 11. 测试和优化
- [x] 编写后端单元测试和集成测试
- [x] 测试 iOS 应用功能
- [x] 性能优化（图像加载、网络请求）
- [x] 错误处理和边界情况测试
- [x] 用户体验优化

### 12. 文档和发布准备
- [x] 编写 API 文档
- [x] 编写用户使用文档
- [x] 准备应用商店发布材料
- [x] 代码审查和重构

---

## 技术栈

### 后端
- Python 3.x
- FastAPI
- 大模型 API SDK
- 图像处理库（Pillow 等）
- 数据库（PostgreSQL/MySQL/SQLite）
- 支付网关 SDK（Stripe/支付宝/微信支付等）

### 前端
- Swift 5.x
- SwiftUI 或 UIKit
- URLSession / Alamofire
- Core Data / UserDefaults（数据存储）
- StoreKit 2（iOS 内购）

---

## 注意事项
- API 密钥需要安全存储，不要提交到版本控制
- 考虑图像生成的成本和速率限制
- 优化图像传输大小，提升用户体验
- 确保跨平台兼容性（iOS 不同版本）
- **支付安全**: 所有支付操作必须在服务端验证，客户端仅发起请求
- **计费准确性**: 确保计费逻辑准确，防止重复扣费或漏扣
- **订阅管理**: 妥善处理订阅到期、自动续费、取消订阅等场景
- **数据安全**: 用户账户和支付信息需要加密存储
- **合规要求**: 遵守 App Store 内购规则和支付相关法律法规
- **风格管理**: 不同风格仅通过 prompt 区分，使用相同的大模型 API
- **示例图片**: 准备高质量的风格示例图片，提升用户体验和转化率
- **搜索性能**: 优化风格搜索性能，支持本地缓存和快速检索
- **Prompt 模板**: 设计灵活的 prompt 模板系统，便于后续扩展新风格

---

## 13. 基于 CSV 的图片展示和生成功能（新功能）

### 功能需求概述
- 前端展示 CSV 文件中的图片（缩略图）
- 点击图片显示原始大图
- 选择图片后可以上传照片或拍照
- 调用后端生成接口（上传图片 + prompt）
- 后端调用豆包 API 生成图片并返回

### 后端开发任务

#### 13.1 图片列表 API
- [x] **新增 API 接口：获取图片列表**
  - 路径: `GET /api/v1/prompts/list`
  - 功能: 读取 `/backend/data/AI_Draw_Prompts_EN.csv` 文件
  - 解析 Category、Subcategory、AI Drawing Prompt
  - 构建图片路径：`{Category}/{Subcategory}.jpg`
  - 返回数据格式:
    ```json
    {
      "prompts": [
        {
          "id": "cartoon_3D_figurine",
          "category": "cartoon",
          "subcategory": "3D_figurine",
          "prompt": "...",
          "thumbnail_url": "/api/v1/data/cartoon/3D_figurine.jpg",
          "original_url": "/api/v1/data/cartoon/3D_figurine.jpg"
        }
      ],
      "total": 5
    }
    ```
  - 文件位置: `app/api/prompts.py` (新建)
  - 技术要点: 使用 `csv` 模块或 `pandas` 解析 CSV

#### 13.2 静态文件服务扩展
- [x] **修改静态文件服务：支持 /data 目录**
  - 路径: `GET /api/v1/data/{category}/{subcategory}.{ext}`
  - 功能: 服务 `/backend/data` 目录下的图片文件
  - 文件位置: `app/api/static.py`
  - 实现要点:
    - 使用 FastAPI 的 `FileResponse` 或 `StaticFiles`
    - 支持常见图片格式（jpg, png, jpeg）
    - 添加安全校验（路径遍历防护）
    - 支持缩略图服务（可选）

#### 13.3 原始图片获取 API
- [x] **新增 API 接口：获取原始图片**
  - 路径: `GET /api/v1/prompts/{category}/{subcategory}/image`
  - 功能: 返回原始大图
  - 文件位置: `app/api/prompts.py`
  - 实现要点: 验证文件存在性，返回文件流

#### 13.4 豆包大模型集成
- [x] **集成豆包大模型接口**
  - 位置: `app/services/ai_service.py`
  - 功能: 将 `/Users/keximing/mycode/iosapp/test/doubao.py` 中的 `generate_image_with_doubao` 集成
  - 实现要点:
    - 将函数改为异步方法 `async def generate_image_with_doubao(...)`
    - 处理流式响应（图片可能有多张）
    - 错误处理和重试机制
    - 支持参数：`image_path_or_url`, `prompt`, `size`, `watermark`, `max_images`
    - 返回格式: `{"success": bool, "images": [urls], "usage": {...}}`

#### 13.5 生成接口改造
- [x] **修改生成接口：支持图片上传**
  - 路径: `POST /api/v1/generate`
  - 修改内容:
    - 接收 `multipart/form-data` 格式
    - 参数：
      - `image`: 上传的图片文件（UploadFile）
      - `category`: Category（用于查找对应的 prompt）
      - `subcategory`: Subcategory（用于查找对应的 prompt）
      - `prompt`: 自定义 prompt（可选，如果提供则覆盖 CSV 中的 prompt）
      - `user_id`: 用户ID（可选）
      - `size`: 图片尺寸（可选，默认 "2K"）
      - `watermark`: 是否添加水印（可选，默认 true）
      - `max_images`: 最大生成图片数（可选，默认 5）
    - 查找 CSV 中的 prompt 模板（根据 category 和 subcategory）
    - 合并用户上传的图片和 prompt
    - 调用豆包 API 生成图片
    - 保存生成的图片到本地
    - 返回生成的图片 URL（可能多个）
  - 文件位置: `app/api/generate.py`
  - 返回格式:
    ```json
    {
      "success": true,
      "images": [
        {"url": "/api/v1/uploads/xxx.jpg", "id": "xxx"}
      ],
      "task_id": "xxx",
      "usage": {...}
    }
    ```

#### 13.6 图片处理功能
- [x] **新增图片处理：生成缩略图**
  - 位置: `app/services/image_service.py`
  - 功能: 生成缩略图用于列表展示
  - 实现要点:
    - 使用 Pillow 生成缩略图（如 200x200）
    - 缓存机制（避免重复生成）
    - 支持多种图片格式
    - 方法: `async def create_thumbnail(image_path: str, size: tuple = (200, 200))`

### iOS 前端开发任务

#### 13.7 数据模型
- [x] **新增数据模型：PromptStyle**
  - 文件: `ios/artme/ArtMe/Models/PromptStyle.swift`
  - 模型结构:
    ```swift
    struct PromptStyle: Codable, Identifiable {
        let id: String
        let category: String
        let subcategory: String
        let prompt: String
        let thumbnailUrl: String
        let originalUrl: String
    }
    
    struct PromptStyleListResponse: Codable {
        let prompts: [PromptStyle]
        let total: Int
    }
    ```

#### 13.8 API Service 扩展
- [x] **新增 API Service 方法**
  - 文件: `ios/artme/ArtMe/Services/APIService.swift`
  - 新增方法:
    - `fetchPromptStyles() async throws -> PromptStyleListResponse`: 获取图片列表
    - `generateImageWithUpload(image: UIImage, category: String, subcategory: String, prompt: String?, size: String?, watermark: Bool?, maxImages: Int?) async throws -> GenerateImageResponse`: 上传图片并生成
  - 实现要点:
    - 使用 `multipart/form-data` 格式上传
    - 图片转换为 Data
    - 上传进度跟踪（可选）

#### 13.9 ViewModel
- [x] **新增 ViewModel：PromptStyleViewModel**
  - 文件: `ios/artme/ArtMe/ViewModels/PromptStyleViewModel.swift`
  - 功能:
    - 管理图片列表数据：`@Published var promptStyles: [PromptStyle] = []`
    - 管理加载状态：`@Published var isLoading = false`
    - 管理错误信息：`@Published var errorMessage: String?`
    - 方法:
      - `loadPromptStyles()`: 加载图片列表
      - `groupByCategory()`: 按 Category 分组
      - 图片分类管理
      - 缓存处理

#### 13.10 图片网格展示视图
- [x] **新增 View：PromptStyleGridView**
  - 文件: `ios/artme/ArtMe/Views/PromptStyleGridView.swift`
  - 功能:
    - 网格布局展示缩略图（使用 `LazyVGrid`）
    - 支持按 Category 分组展示（可选：Section 分组）
    - 点击图片跳转到详情页（NavigationLink）
    - 下拉刷新（`.refreshable`）
    - 图片加载优化（AsyncImage 或 Kingfisher）
  - UI 设计:
    - 网格列数：2-3 列（根据屏幕大小自适应）
    - 图片比例：1:1 或 4:3
    - 显示 Category 名称（可选）

#### 13.11 图片详情视图
- [x] **新增 View：PromptStyleDetailView**
  - 文件: `ios/artme/ArtMe/Views/PromptStyleDetailView.swift`
  - 功能:
    - 显示原始大图（使用 `AsyncImage` 或 `Kingfisher`）
    - 支持图片缩放（使用 `.scaleEffect` 或第三方库）
    - 显示 prompt 信息（可选：可展开/收起）
    - 底部操作栏：
      - 上传照片按钮（相册选择）
      - 拍照按钮（相机）
      - 生成按钮（跳转到生成页面）
    - 支持图片预览（全屏，可选）
  - 导航: 点击按钮跳转到 `GenerateView`（携带 prompt 信息）

#### 13.12 图片选择功能
- [x] **新增图片选择器组件**
  - 实现方式: 使用 `UIImagePickerController`
  - 功能:
    - 从相册选择图片
    - 拍照功能
  - 集成位置: `PromptStyleDetailView` 中已实现 `ImagePicker` 组件
  - 文件: 在 `PromptStyleDetailView.swift` 中实现

#### 13.13 生成视图改造
- [x] **修改 GenerateView：集成新功能**
  - 文件: `ios/artme/ArtMe/Views/GenerateView.swift`
  - 修改内容:
    - 添加图片选择器（上传照片或拍照）
    - 显示选中的 prompt 信息（category, subcategory, prompt）
    - 上传图片预览区域
    - 调用新的生成接口（带图片上传）
    - 显示生成结果（支持多张图片展示）
    - 生成进度显示（可选）
  - 参数传递:
    - 从 `PromptStyleDetailView` 传递 `PromptStyle` 对象
    - 在 `GenerateView` 中接收并显示

#### 13.14 生成 ViewModel 改造
- [x] **修改 GenerateViewModel：支持图片上传**
  - 文件: `ios/artme/ArtMe/ViewModels/GenerateViewModel.swift`
  - 修改内容:
    - 添加属性：`@Published var selectedPromptStyle: PromptStyle?`
    - 添加属性：`@Published var uploadedImage: UIImage?`
    - 添加属性：`@Published var generatedImages: [UIImage] = []`（支持多张）
    - 修改 `generateImage()` 方法：
      - 支持图片上传
      - 调用 `apiService.generateImageWithUpload(...)`
      - 处理多张生成结果
    - 添加方法：`selectImage(from: UIImage)` 设置上传的图片

#### 13.15 导航流程
- [x] **实现完整的导航流程**
  - 流程步骤:
    1. 首页/标签页 -> `PromptStyleGridView`（图片列表）
    2. 点击图片 -> `PromptStyleDetailView`（详情页，显示原图）
    3. 点击"生成"按钮 -> `GenerateView`（生成页面，携带 prompt 信息）
    4. 在 `GenerateView` 中选择图片（上传或拍照）
    5. 点击生成 -> 调用生成接口
    6. 生成完成 -> 结果展示（支持多张图片）
  - 导航实现:
    - 使用 `NavigationStack`（iOS 16+）或 `NavigationView`
    - 传递数据使用 `NavigationLink` 或程序化导航
  - 文件: 在 `ContentView.swift` 或 `ArtMeApp.swift` 中配置导航

### 技术要点总结

#### 后端技术要点
1. **CSV 解析**: 使用 `csv` 模块或 `pandas` 读取和解析 CSV 文件
2. **图片服务**: 使用 FastAPI 的 `StaticFiles` 或 `FileResponse` 服务静态文件
3. **文件上传**: 使用 `UploadFile` 处理 multipart/form-data 数据
4. **异步处理**: 使用 `asyncio` 和 `httpx` 处理豆包 API 的异步调用
5. **流式响应**: 处理豆包 API 的流式响应（多张图片）
6. **图片处理**: 使用 `Pillow` 生成缩略图和图片处理
7. **路径安全**: 防止路径遍历攻击，验证文件路径

#### iOS 前端技术要点
1. **图片加载**: 使用 `AsyncImage`（iOS 15+）或第三方库（如 Kingfisher）
2. **网格布局**: 使用 `LazyVGrid` 实现瀑布流效果
3. **图片选择**: 使用 `PhotosPicker`（iOS 14+）或 `UIImagePickerController`
4. **网络请求**: 使用 `URLSession` 处理 multipart/form-data 上传
5. **状态管理**: 使用 `@StateObject` 和 `@Published` 管理状态
6. **导航**: 使用 `NavigationStack`（iOS 16+）实现导航流程
7. **图片预览**: 实现图片缩放和全屏预览功能

### 数据流图

```
用户操作流程：
1. 打开 App -> 加载图片列表（GET /api/v1/prompts/list）
2. 显示缩略图（GET /api/v1/data/{category}/{subcategory}.jpg）
3. 点击图片 -> 显示原图（GET /api/v1/data/{category}/{subcategory}.jpg）
4. 点击生成 -> 选择/拍照 -> 上传图片 + prompt
5. 后端接收 -> 调用豆包 API -> 返回生成结果（可能多张）
6. 前端显示生成的图片（支持多张图片展示）

后端处理流程：
1. 接收上传的图片文件
2. 保存到临时目录
3. 从 CSV 中查找对应的 prompt（根据 category 和 subcategory）
4. 调用豆包 API（generate_image_with_doubao）
5. 处理流式响应，保存生成的图片
6. 返回图片 URL 列表
```

### 文件结构变更

#### 后端新增文件
- `app/api/prompts.py` - 图片列表和详情 API
- `app/services/doubao_service.py` - 豆包服务封装（可选，或直接集成到 ai_service.py）

#### 后端修改文件
- `app/api/generate.py` - 修改生成接口支持图片上传
- `app/services/ai_service.py` - 集成豆包大模型接口
- `app/services/image_service.py` - 添加缩略图生成功能
- `app/api/static.py` - 扩展静态文件服务支持 /data 目录

#### iOS 前端新增文件
- `Models/PromptStyle.swift` - PromptStyle 数据模型
- `ViewModels/PromptStyleViewModel.swift` - 图片列表 ViewModel
- `Views/PromptStyleGridView.swift` - 图片网格展示视图
- `Views/PromptStyleDetailView.swift` - 图片详情视图

#### iOS 前端修改文件
- `Services/APIService.swift` - 添加新的 API 方法
- `Views/GenerateView.swift` - 集成图片选择和上传功能
- `ViewModels/GenerateViewModel.swift` - 支持图片上传生成
- `App/ContentView.swift` 或 `App/ArtMeApp.swift` - 配置导航流程

