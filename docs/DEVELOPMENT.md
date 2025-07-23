# 餐厅收藏助手 - 开发文档

## 🚀 快速开始

### 环境要求
- Flutter 3.27.1 或更高版本
- Dart 3.6.0 或更高版本
- 支持的平台：Web、Android、iOS

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd restaurant_collector
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **生成代码**
   ```bash
   dart run build_runner build
   ```

4. **配置API密钥**
   
   在 `lib/main.dart` 中找到以下行：
   ```dart
   const apiKey = 'YOUR_KIMI_API_KEY'; // TODO: 替换为实际的API密钥
   ```
   
   将 `YOUR_KIMI_API_KEY` 替换为你的Kimi API密钥。
   
   **获取Kimi API密钥：**
   - 访问 [Moonshot AI官网](https://platform.moonshot.cn/)
   - 注册账号并创建API密钥
   - 复制密钥到上述配置中

5. **运行项目**
   ```bash
   # Web版本（推荐用于开发）
   flutter run -d chrome
   
   # Android版本
   flutter run -d android
   
   # iOS版本（需要macOS）
   flutter run -d ios
   ```

## 📝 开发指南

### 项目结构
```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   └── restaurant.dart       # 餐厅模型
├── services/                 # 服务层
│   ├── database_service.dart # 数据库服务
│   ├── kimi_service.dart     # Kimi AI服务
│   └── webview_service.dart  # WebView服务
├── providers/                # 状态管理
│   └── restaurant_provider.dart
├── screens/                  # 页面
│   ├── home/
│   └── webview/
└── widgets/                  # 通用组件
    └── restaurant_card.dart
```

### 核心功能流程

1. **添加餐厅**
   ```
   用户输入URL → WebView加载 → 用户交互完成 → 确认内容 → AI解析 → 保存数据库
   ```

2. **WebView处理**
   - 使用原生WebView，支持完整的浏览器功能
   - 用户可以进行登录、搜索等交互
   - 等待页面完全加载后提取HTML内容

3. **AI解析**
   - 发送完整HTML内容到Kimi API
   - AI返回结构化的餐厅信息
   - 自动填充餐厅模型数据

### 数据库设计

使用SQLite进行本地存储：

- **restaurants** - 餐厅信息表
- **experience_records** - 体验记录表
- **share_contents** - 分享内容表
- **images** - 图片表

### API集成

项目集成了Kimi AI API：
- **模型**: moonshot-v1-32k
- **功能**: 餐厅信息解析、分享文案生成
- **安全**: API密钥需要妥善保管

## 🔧 配置选项

### WebView配置
在 `lib/services/webview_service.dart` 中可以调整：
- User-Agent设置
- JavaScript执行权限
- 页面加载超时时间

### AI解析配置
在 `lib/services/kimi_service.dart` 中可以调整：
- Prompt模板
- Token限制
- 响应超时时间

### 数据库配置
在 `lib/services/database_service.dart` 中可以调整：
- 表结构
- 索引设计
- 数据库版本

## 🛠 开发技巧

### 1. 调试WebView
```dart
// 在WebView中注入调试代码
await controller.runJavaScript('''
  console.log('Page loaded:', document.title);
  console.log('Content length:', document.body.innerHTML.length);
''');
```

### 2. 测试AI解析
```dart
// 使用模拟数据测试AI解析
final mockContent = ExtractedContent(
  htmlContent: '<html>...</html>',
  textContent: '餐厅名称：测试餐厅...',
  jsonData: [],
  metadata: {'title': '测试'},
  images: [],
);
```

### 3. 数据库调试
```dart
// 直接查询数据库
final db = await DatabaseService.database;
final result = await db.rawQuery('SELECT * FROM restaurants');
print(result);
```

## 📱 平台特定配置

### Web平台
- WebView在Web平台使用iframe实现
- 某些网站可能有跨域限制
- 建议使用Chrome进行开发测试

### Android平台
- 需要网络权限配置
- WebView需要硬件加速支持
- 建议API级别21以上

### iOS平台
- 需要WKWebView权限
- 可能需要网络安全配置
- 支持iOS 12.0以上

## 🔄 代码生成

当修改了模型类后，需要重新生成代码：
```bash
# 重新生成
dart run build_runner build

# 强制重新生成
dart run build_runner build --delete-conflicting-outputs
```

## 🧪 测试

### 单元测试
```bash
flutter test
```

### 集成测试
```bash
flutter test integration_test/
```

### Web测试
```bash
flutter test --platform chrome
```

## 📦 构建发布

### Web构建
```bash
flutter build web
```

### Android构建
```bash
flutter build apk --release
```

### iOS构建
```bash
flutter build ios --release
```

## ⚠️ 注意事项

1. **API密钥安全**
   - 不要将API密钥提交到版本控制
   - 生产环境使用环境变量
   - 定期轮换API密钥

2. **WebView限制**
   - 某些网站禁止嵌入
   - 可能需要处理验证码
   - 注意内存泄漏

3. **数据隐私**
   - 本地数据库未加密
   - 用户数据不会上传
   - 遵循数据保护法规

4. **性能优化**
   - WebView内存管理
   - 数据库查询优化
   - AI请求频率控制

## 🐛 常见问题

### Q: WebView无法加载页面
A: 检查网络连接，确认URL格式正确，尝试使用不同的User-Agent

### Q: AI解析失败
A: 检查API密钥配置，确认网络连接，检查Prompt格式

### Q: 数据库错误
A: 清除应用数据重新安装，检查数据库版本兼容性

### Q: 构建失败
A: 清理项目缓存：`flutter clean && flutter pub get`

## 📚 相关文档

- [Flutter官方文档](https://docs.flutter.dev/)
- [WebView Flutter插件](https://pub.dev/packages/webview_flutter)
- [Kimi API文档](https://platform.moonshot.cn/docs)
- [SQLite文档](https://www.sqlite.org/docs.html)

---

如果有任何问题，请查看项目的Issue或创建新的Issue。 