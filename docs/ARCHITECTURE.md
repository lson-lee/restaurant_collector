# 餐厅收藏助手 - 技术架构文档

## 1. 架构概览

### 1.1 整体架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │  Service Layer  │    │  Data Layer     │
│                 │    │                 │    │                 │
│ - Screens       │◄──►│ - WebView       │◄──►│ - SQLite DB     │
│ - Widgets       │    │ - Kimi AI       │    │ - File Storage  │
│ - Providers     │    │ - Network       │    │ - SharedPrefs   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1.2 核心流程
```
用户输入URL → WebView加载 → 用户交互 → 内容提取 → AI解析 → 数据存储 → 展示结果
```

## 2. WebView实现方案

### 2.1 技术选型
- **包**: `webview_flutter` (Flutter官方包)
- **原理**: 原生WebView封装，非iframe
- **平台**: 支持Android、iOS、Web

### 2.2 WebView配置
```dart
class WebViewConfig {
  static WebViewController createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) => _handleProgress(progress),
        onPageStarted: (String url) => _handlePageStart(url),
        onPageFinished: (String url) => _handlePageFinished(url),
        onWebResourceError: (WebResourceError error) => _handleError(error),
      ))
      ..setUserAgent(_getBrowserUserAgent())
      ..loadRequest(Uri.parse(url));
  }
}
```

### 2.3 内容提取机制
```dart
class ContentExtractor {
  // MVP阶段：提取完整HTML内容
  static Future<String> extractFullContent(WebViewController controller) async {
    final html = await controller.runJavaScriptReturningResult(
      'document.documentElement.outerHTML'
    );
    return html.toString();
  }
  
  // 提取文本内容
  static Future<String> extractTextContent(WebViewController controller) async {
    final text = await controller.runJavaScriptReturningResult(
      'document.body.innerText'
    );
    return text.toString();
  }
  
  // 提取JSON数据
  static Future<List<String>> extractJsonData(String html) async {
    final RegExp jsonPattern = RegExp(r'\{[^{}]*\}|\[[^\[\]]*\]');
    return jsonPattern.allMatches(html).map((m) => m.group(0)!).toList();
  }
}
```

### 2.4 用户交互保持
- 完全保留原生WebView的所有交互能力
- 支持登录、验证码、人机验证
- 支持JavaScript执行和DOM操作
- 支持文件上传、下载

## 3. AI集成方案

### 3.1 Kimi API集成
```dart
class KimiService {
  static const String baseUrl = 'https://api.moonshot.cn/v1';
  
  Future<RestaurantInfo> parseRestaurantContent({
    required String htmlContent,
    required String textContent,
    required List<String> jsonData,
  }) async {
    final prompt = _buildRestaurantParsePrompt(
      htmlContent: htmlContent,
      textContent: textContent,
      jsonData: jsonData,
    );
    
    final response = await _callKimiAPI(prompt);
    return RestaurantInfo.fromJson(response);
  }
  
  Future<List<String>> generateShareContent({
    required RestaurantInfo restaurant,
    required ExperienceRecord experience,
    required List<ShareStyle> styles,
  }) async {
    final prompt = _buildShareContentPrompt(
      restaurant: restaurant,
      experience: experience,
      styles: styles,
    );
    
    final response = await _callKimiAPI(prompt);
    return _parseShareContent(response);
  }
}
```

### 3.2 数据处理策略
```dart
// MVP阶段：全量数据发送
class DataProcessor {
  static ProcessedData processForAI(String htmlContent) {
    return ProcessedData(
      fullHtml: htmlContent,
      textContent: _extractText(htmlContent),
      jsonBlocks: _extractJsonBlocks(htmlContent),
      metadata: _extractMetadata(htmlContent),
    );
  }
  
  // 未来优化：智能过滤
  static ProcessedData processForAIOptimized(String htmlContent) {
    return ProcessedData(
      relevantSections: _extractRelevantSections(htmlContent),
      structuredData: _extractStructuredData(htmlContent),
      keywords: _extractKeywords(htmlContent),
    );
  }
}
```

### 3.3 Prompt设计
```dart
class PromptTemplates {
  static String restaurantParsePrompt(ProcessedData data) => '''
请解析以下餐厅页面内容，提取结构化信息：

HTML内容：${data.fullHtml}
文本内容：${data.textContent}
JSON数据：${data.jsonBlocks}

请返回JSON格式，包含：
{
  "name": "餐厅名称",
  "address": "地址",
  "phone": "电话",
  "cuisine": "菜系",
  "priceRange": "价格区间",
  "rating": "评分",
  "recommendedDishes": ["推荐菜品"],
  "businessHours": "营业时间",
  "description": "描述",
  "images": ["图片URL"]
}
''';

  static String shareContentPrompt({
    required RestaurantInfo restaurant,
    required ExperienceRecord experience,
    required List<ShareStyle> styles,
  }) => '''
基于以下餐厅信息和用餐体验，生成${styles.join('、')}风格的分享文案：

餐厅信息：${restaurant.toJson()}
用餐体验：${experience.toJson()}

请为每种风格生成一段文案，要求：
- 小红书：轻松活泼，适合年轻人，多用emoji
- 大众点评：客观详细，重点突出性价比和体验
- 抖音：简短有趣，适合视频配文
''';
}
```

## 4. 数据库设计

### 4.1 表结构设计
```sql
-- 餐厅信息表
CREATE TABLE restaurants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  cuisine TEXT,
  price_range TEXT,
  rating REAL,
  description TEXT,
  source_url TEXT,
  created_at INTEGER,
  updated_at INTEGER
);

-- 推荐菜品表
CREATE TABLE recommended_dishes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  restaurant_id INTEGER,
  dish_name TEXT NOT NULL,
  price TEXT,
  description TEXT,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants (id)
);

-- 体验记录表
CREATE TABLE experience_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  restaurant_id INTEGER,
  rating INTEGER,
  content TEXT,
  visit_date INTEGER,
  spend_amount REAL,
  companion_count INTEGER,
  tags TEXT, -- JSON数组
  ai_summary TEXT,
  created_at INTEGER,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants (id)
);

-- 分享内容表
CREATE TABLE share_contents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  experience_id INTEGER,
  style TEXT, -- xiaohongshu, dianping, douyin
  content TEXT,
  created_at INTEGER,
  FOREIGN KEY (experience_id) REFERENCES experience_records (id)
);

-- 图片表
CREATE TABLE images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT, -- restaurant, experience
  entity_id INTEGER,
  file_path TEXT,
  url TEXT,
  created_at INTEGER
);
```

### 4.2 数据访问层
```dart
class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  // 餐厅操作
  Future<int> insertRestaurant(Restaurant restaurant) async {
    final db = await database;
    return await db.insert('restaurants', restaurant.toMap());
  }
  
  Future<Restaurant?> getRestaurant(int id) async {
    final db = await database;
    final result = await db.query(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Restaurant.fromMap(result.first) : null;
  }
  
  Future<List<Restaurant>> getAllRestaurants() async {
    final db = await database;
    final result = await db.query('restaurants');
    return result.map((map) => Restaurant.fromMap(map)).toList();
  }
}
```

## 5. 状态管理

### 5.1 Provider架构
```dart
// 应用状态管理
class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
}

// 餐厅状态管理
class RestaurantProvider extends ChangeNotifier {
  List<Restaurant> _restaurants = [];
  Restaurant? _currentRestaurant;
  
  List<Restaurant> get restaurants => _restaurants;
  Restaurant? get currentRestaurant => _currentRestaurant;
  
  Future<void> loadRestaurants() async {
    final restaurants = await DatabaseService().getAllRestaurants();
    _restaurants = restaurants;
    notifyListeners();
  }
  
  Future<void> addRestaurant(String url) async {
    // WebView加载 → AI解析 → 保存
    final content = await WebViewService().extractContent(url);
    final restaurant = await KimiService().parseRestaurantContent(content);
    await DatabaseService().insertRestaurant(restaurant);
    await loadRestaurants();
  }
}
```

## 6. 性能优化策略

### 6.1 WebView优化
```dart
class WebViewOptimizer {
  // 预加载常用WebView
  static final Map<String, WebViewController> _cachedControllers = {};
  
  // 内存管理
  static void disposeController(String key) {
    _cachedControllers.remove(key);
  }
  
  // 缓存策略
  static void setCachePolicy(WebViewController controller) {
    controller.setUserAgent(_getCachedUserAgent());
  }
}
```

### 6.2 数据库优化
```sql
-- 添加索引
CREATE INDEX idx_restaurants_name ON restaurants(name);
CREATE INDEX idx_restaurants_cuisine ON restaurants(cuisine);
CREATE INDEX idx_experience_restaurant_id ON experience_records(restaurant_id);
CREATE INDEX idx_experience_visit_date ON experience_records(visit_date);
```

### 6.3 AI调用优化
```dart
class AIOptimizer {
  // 请求缓存
  static final Map<String, dynamic> _responseCache = {};
  
  // 请求合并
  static final Map<String, Future<dynamic>> _pendingRequests = {};
  
  // Token使用监控
  static void trackTokenUsage(int tokens) {
    // 记录Token使用情况
  }
}
```

## 7. 错误处理

### 7.1 错误类型定义
```dart
enum AppErrorType {
  networkError,
  webviewError,
  aiError,
  databaseError,
  validationError,
}

class AppError {
  final AppErrorType type;
  final String message;
  final dynamic original;
  
  AppError(this.type, this.message, [this.original]);
}
```

### 7.2 错误处理策略
```dart
class ErrorHandler {
  static void handleError(AppError error) {
    switch (error.type) {
      case AppErrorType.networkError:
        _handleNetworkError(error);
        break;
      case AppErrorType.aiError:
        _handleAIError(error);
        break;
      // ... 其他错误处理
    }
  }
  
  static void _handleAIError(AppError error) {
    // AI服务降级处理
    // 1. 重试机制
    // 2. 使用缓存数据
    // 3. 手动填写选项
  }
}
```

## 8. 安全考虑

### 8.1 数据安全
- 本地数据库加密
- API密钥安全存储
- 用户隐私保护

### 8.2 网络安全
- HTTPS强制
- 证书验证
- 请求签名

### 8.3 WebView安全
```dart
class WebViewSecurity {
  static void configureSecureWebView(WebViewController controller) {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_getSecureUserAgent())
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _handleSecureMessage,
      );
  }
}
```

## 9. 测试策略

### 9.1 单元测试
- Service层测试
- Provider测试
- 工具类测试

### 9.2 集成测试
- WebView功能测试
- AI集成测试
- 数据库操作测试

### 9.3 UI测试
- Widget测试
- 页面流程测试
- 用户交互测试

---

**文档版本**: v1.0.0  
**最后更新**: 2024-07-22  
**维护者**: 开发团队 