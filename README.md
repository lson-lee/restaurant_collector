# 餐厅收藏助手 (Restaurant Collector)

基于Flutter开发的餐厅收藏和用餐体验记录应用，通过原生WebView抓取餐厅信息，结合Kimi AI智能整理用户体验。

## 📋 项目概述

本项目专注于提供便捷的餐厅信息收藏和用餐体验记录功能，通过真实浏览器环境的WebView加载目标网站，用户可以直接操作处理人机验证等情况，然后提取页面内容交由AI进行智能解析和整理。

## 🎯 核心功能

### 1. 餐厅收藏模块
- **链接输入**：支持各种餐厅网站链接粘贴
- **WebView加载**：使用原生WebView，完全模拟真实浏览器环境
- **智能提取**：AI自动解析HTML内容，提取餐厅信息
- **用户备注**：添加个人标签和想去理由
- **收藏管理**：分类、搜索、筛选功能

### 2. 体验记录模块  
- **体验输入**：评分、文字描述、照片上传
- **AI整理**：Kimi AI自动生成体验总结和标签
- **多风格文案**：生成小红书、大众点评、抖音等不同风格的分享文案
- **历史管理**：体验记录的查看和编辑

### 3. 数据管理
- **本地存储**：SQLite存储所有数据
- **数据分析**：用餐偏好、消费统计
- **导出功能**：数据备份和导出

## 🏗 技术架构

### 开发栈
- **框架**：Flutter 3.27.1
- **状态管理**：Provider
- **本地数据库**：sqflite
- **网络请求**：dio
- **WebView**：webview_flutter (原生实现)
- **图片处理**：image_picker
- **AI集成**：Kimi API

### 技术要点

#### WebView实现方案
```
核心原则：
- 使用原生WebView而非iframe（避免第三方站点限制）
- 完全模拟真实浏览器环境
- 支持用户直接交互（处理人机验证）
- 页面加载完成后提取完整HTML内容
```

**关键优势：**
- ✅ 绕过iframe限制，支持所有第三方网站
- ✅ 用户可直接操作，处理登录、验证码等
- ✅ 获得完整页面内容，包括动态加载的数据
- ✅ 真实User-Agent，避免反爬虫检测

#### AI解析策略
```
MVP阶段处理流程：
1. WebView加载完成 → 提取页面HTML
2. 文本预处理 → 提取文字内容 + JSON数据
3. 整体发送Kimi → AI解析结构化数据
4. 结果验证 → 本地存储
```

**处理机制：**
- 📝 提取页面所有文本内容
- 🔍 识别并提取JSON数据块
- 🤖 全量数据发送给Kimi进行智能解析
- 🎨 AI生成多种风格的分享文案

#### 数据存储方案
```
Flutter客户端本地存储：
- SQLite：餐厅信息、体验记录、用户设置
- 文件系统：图片、缓存数据
- SharedPreferences：应用配置
```

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── restaurant.dart       # 餐厅模型
│   ├── experience.dart       # 体验记录模型
│   └── user_preference.dart  # 用户偏好模型
├── services/                 # 服务层
│   ├── database_service.dart # 数据库服务
│   ├── kimi_service.dart     # Kimi AI服务
│   ├── webview_service.dart  # WebView服务
│   └── storage_service.dart  # 本地存储服务
├── providers/                # 状态管理
│   ├── restaurant_provider.dart
│   ├── experience_provider.dart
│   └── app_provider.dart
├── screens/                  # 页面
│   ├── home/                 # 首页
│   ├── collection/           # 收藏页面
│   ├── webview/             # WebView页面
│   ├── experience/          # 体验记录页面
│   └── settings/            # 设置页面
├── widgets/                  # 通用组件
│   ├── webview_widget.dart
│   ├── restaurant_card.dart
│   └── experience_form.dart
└── utils/                    # 工具类
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

## 🚀 开发计划

### MVP版本 (v1.0.0)
- [x] 项目初始化和依赖配置
- [ ] 基础WebView功能实现
- [ ] HTML内容提取机制
- [ ] Kimi AI集成和数据解析
- [ ] 基础数据库结构
- [ ] 简单的收藏和查看功能

### 增强版本 (v1.1.0)
- [ ] 多风格文案生成
- [ ] 图片上传和管理
- [ ] 体验记录功能
- [ ] 数据导出功能
- [ ] UI/UX优化

### 扩展版本 (v1.2.0)
- [ ] 数据分析功能
- [ ] 社交分享
- [ ] 同步功能
- [ ] 高级筛选和搜索

## 🔧 开发环境设置

### 环境变量配置

1. **复制环境变量模板**
   ```bash
   cp .env.example .env
   ```

2. **配置API密钥**
   编辑 `.env` 文件，添加你的 API 密钥：
   ```
   KIMI_API_KEY=your_actual_kimi_api_key_here
   ```

3. **确保 .env 文件已添加到 .gitignore**
   项目已自动配置 `.gitignore` 排除 `.env` 文件，确保不会意外提交敏感信息。

### 依赖安装
```bash
flutter pub get
```

### 运行项目
```bash
# Web版本
flutter run -d chrome

# Android版本  
flutter run -d android

# iOS版本
flutter run -d ios
```

### 构建发布版本
```bash
# Web
flutter build web

# Android
flutter build apk

# iOS
flutter build ios
```

## 📝 开发注意事项

### WebView相关
- **页面兼容性**：确保WebView设置支持所有现代Web特性
- **用户交互**：保留完整的用户操作能力
- **内容提取**：等待页面完全加载后再提取内容
- **错误处理**：网络超时、页面加载失败等异常情况

### AI集成要点
- **数据量控制**：虽然MVP阶段发送全量数据，但要监控Token使用量
- **响应处理**：建立标准化的AI返回格式处理机制
- **备用方案**：AI服务不可用时的降级处理
- **成本控制**：合理使用AI服务，避免不必要的API调用

### 性能优化
- **异步处理**：所有网络和AI调用都要异步执行
- **内存管理**：及时释放WebView和图片资源
- **数据库优化**：合理设计索引和查询语句
- **缓存策略**：适当缓存常用数据

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🏷 版本历史

- **v1.0.0** - 初始版本，基础WebView和AI解析功能
- **v0.1.0** - 项目初始化和架构搭建

---

**注意**：本项目处于活跃开发阶段，API和功能可能会发生变化。
