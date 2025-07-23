import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/restaurant.dart';
import 'webview_service.dart';
import 'dart:convert';

/// Kimi AI服务类 - 处理AI解析和内容生成
class KimiService {
  static const String baseUrl = 'https://api.moonshot.cn/v1';
  static const String model = 'kimi-k2-0711-preview';
  
  static final Logger _logger = Logger();
  static late Dio _dio;
  static String? _apiKey;

  /// 初始化服务
  static void initialize({required String apiKey}) {
    _apiKey = apiKey;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    
    _logger.i('Kimi AI Service initialized');
  }

  /// 解析餐厅页面内容
  static Future<Restaurant> parseRestaurantContent(ExtractedContent content) async {
    try {
      _logger.d('Starting AI parsing for restaurant content');
      
      final prompt = _buildRestaurantParsePrompt(content);
      final response = await _callKimiAPI(prompt);
      
      // 提取坐标信息
      final coordinates = _extractCoordinatesFromHtml(content.htmlContent);
      _logger.d('Extracted coordinates: $coordinates');

      try {
        // 解析AI返回的餐厅信息
        final restaurant = _parseRestaurantFromJson(response);
        _logger.i('Successfully parsed restaurant: ${restaurant.name}');
        _logger.d('Images found: ${restaurant.images?.length ?? 0}');
        
        // 显示AI返回的坐标信息
        if (restaurant.latitude != null && restaurant.longitude != null) {
          _logger.d('AI returned coordinates: ${restaurant.latitude}, ${restaurant.longitude}');
        } else {
          _logger.d('AI did not return coordinates');
        }
        
        // 显示HTML提取的坐标信息
        if (coordinates['latitude'] != null && coordinates['longitude'] != null) {
          _logger.d('HTML extracted coordinates: ${coordinates['latitude']}, ${coordinates['longitude']}');
        } else {
          _logger.d('No coordinates found in HTML');
        }

        // 合并坐标信息：优先使用AI返回的坐标，如果AI没有返回则使用HTML提取的坐标
        String? finalLatitude = restaurant.latitude ?? coordinates['latitude'];
        String? finalLongitude = restaurant.longitude ?? coordinates['longitude'];
        
        // 创建最终的Restaurant对象，确保包含坐标信息
        final finalRestaurant = restaurant.copyWith(
          latitude: finalLatitude,
          longitude: finalLongitude,
        );
        
        _logger.i('Final coordinates: ${finalRestaurant.latitude}, ${finalRestaurant.longitude}');
        
        return finalRestaurant;
      } catch (e) {
        _logger.e('Failed to parse restaurant JSON: $e');
        _logger.e('Response content: $response');
        throw Exception('AI返回格式错误: $e');
      }
    } catch (e) {
      _logger.e('Failed to parse restaurant content: $e');
      // 返回基础餐厅信息作为降级处理
      return _createFallbackRestaurant(content);
    }
  }

  /// 生成分享文案
  static Future<Map<String, String>> generateShareContent({
    required Restaurant restaurant,
    required String experienceText,
    required int rating,
    List<ShareStyle> styles = const [ShareStyle.xiaohongshu, ShareStyle.dianping, ShareStyle.douyin],
  }) async {
    try {
      _logger.d('Generating share content for restaurant: ${restaurant.name}');
      
      final prompt = _buildShareContentPrompt(
        restaurant: restaurant,
        experienceText: experienceText,
        rating: rating,
        styles: styles,
      );
      
      final response = await _callKimiAPI(prompt);
      final shareContent = _parseShareContentResponse(response, styles);
      
      _logger.i('Successfully generated share content');
      return shareContent;
    } catch (e) {
      _logger.e('Failed to generate share content: $e');
      return _createFallbackShareContent(restaurant, experienceText, rating, styles);
    }
  }

  /// 调用Kimi API
  static Future<String> _callKimiAPI(String prompt) async {
    try {
      final requestData = {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 4000,
      };

      // 详细打印发送给AI的prompt
      print('\n' + '🚀' * 40);
      print('📨 发送给 Kimi AI 的完整请求:');
      print('🚀' * 40);
      print('🤖 模型: $model');
      print('🌡️ Temperature: 0.7');
      print('📏 Max Tokens: 4000');
      print('📝 Prompt 长度: ${prompt.length} 字符');
      print('⏰ 请求时间: ${DateTime.now().toIso8601String()}');
      print('\n' + '-' * 80);
      print('📄 完整 Prompt 内容:');
      print('-' * 80);
      print(prompt);
      print('\n' + '🚀' * 40);
      print('⏳ 正在等待 Kimi AI 响应...');
      print('🚀' * 40 + '\n');

      _logger.d('Calling Kimi API with prompt length: ${prompt.length}');
      
      final stopwatch = Stopwatch()..start();
      
      final response = await _dio.post(
        '/chat/completions',
        data: requestData,
      );
      
      stopwatch.stop();

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final usage = response.data['usage'];
        
        // 打印AI的响应
        print('\n' + '✅' * 40);
        print('📨 Kimi AI 响应结果:');
        print('✅' * 40);
        print('⏰ 响应时间: ${DateTime.now().toIso8601String()}');
        print('🕐 耗时: ${stopwatch.elapsedMilliseconds}ms');
        print('📏 响应长度: ${content.length} 字符');
        if (usage != null) {
          print('🔢 Token使用: ${usage['prompt_tokens']} + ${usage['completion_tokens']} = ${usage['total_tokens']}');
        }
        print('\n' + '-' * 80);
        print('📄 AI 响应内容:');
        print('-' * 80);
        print(content);
        print('\n' + '✅' * 40);
        print('🎯 AI解析完成！');
        print('✅' * 40 + '\n');
        
        _logger.d('Kimi API response received, length: ${content.length}, time: ${stopwatch.elapsedMilliseconds}ms');
        return content;
      } else {
        print('\n❌ Kimi API 请求失败: HTTP ${response.statusCode}');
        print('❌ 响应内容: ${response.data}');
        throw Exception('Kimi API returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('\n❌ Kimi AI 调用出错: $e');
      if (e is DioException) {
        print('❌ 错误类型: ${e.type}');
        print('❌ 错误消息: ${e.message}');
        print('❌ 响应数据: ${e.response?.data}');
      }
      _logger.e('Kimi API call failed: $e');
      rethrow;
    }
  }

  /// 构建餐厅解析Prompt
  static String _buildRestaurantParsePrompt(ExtractedContent content) {
    String htmlContent = content.htmlContent;
    const maxHtmlLength = 20000; // 增加限制
    if (htmlContent.length > maxHtmlLength) {
      htmlContent = htmlContent.substring(0, maxHtmlLength) + '...[截断]';
    }

    return '''
请解析以下已经清理过的餐厅页面HTML内容，提取结构化信息并以JSON格式返回。

HTML内容：
$htmlContent

请仔细分析HTML结构，从标签名、保留的class名称、文本内容等提取餐厅信息，返回以下JSON格式：

{
  "name": "餐厅名称",
  "address": "详细地址（尽量获取完整地址，不要星号遮挡）",
  "fullAddress": "完整地址（包含省市区）",
  "phone": "电话号码（尽量获取完整号码，不要星号遮挡）",
  "cuisine": "菜系类型",
  "priceRange": "价格区间（如：50-100元/人）",
  "rating": 4.5,
  "description": "餐厅描述和特色介绍",
  "recommendedDishes": ["推荐菜品1", "推荐菜品2"],
  "businessHours": "营业时间",
  "images": ["图片URL1", "图片URL2"],
  "latitude": "纬度（数字字符串格式，如'31.123456'）",
  "longitude": "经度（数字字符串格式，如'121.123456'）",
  "features": ["特色标签1", "特色标签2"],
  "environment": "环境描述",
  "serviceHighlights": ["服务亮点1", "服务亮点2"],
  "userReviewKeywords": ["用户评价关键词1", "关键词2"],
  "marketingPoints": ["营销亮点1", "亮点2"],
  "parkingInfo": "停车信息",
  "specialOffers": "特惠信息"
}

关键提取指南：
1. 仔细观察HTML标签的语义和结构
2. 关注保留的有意义class名和id
3. 寻找结构化数据，特别是script标签中的JSON，从中提取坐标、完整地址、电话等信息
4. 地址和电话经常被星号遮挡，请从JSON数据中寻找完整信息
5. 坐标信息通常在JSON数据中，格式如："lat":31.123456,"lng":121.403571
6. 图片URL必须完整且有效（http/https开头）
7. 基础字段如果无法确定，设置为null
8. 拓展字段请尽量从HTML中挖掘更多信息：
   - features: 提取餐厅特色标签（如"网红餐厅"、"情侣约会"、"亲子友好"等）
   - environment: 描述餐厅环境氛围
   - serviceHighlights: 服务特色（如"免费WiFi"、"可预订"、"外卖配送"等）
   - userReviewKeywords: 从用户评价中提取的关键词
   - marketingPoints: 营销卖点（如"必吃榜"、"新店优惠"等）
   - parkingInfo: 停车相关信息
   - specialOffers: 特惠活动信息
9. 只返回JSON，不要额外的说明文字
10. 确保餐厅名称尽可能准确和完整
11. 推荐菜品提取最多5个最有代表性的
12. 坐标信息非常重要，请仔细从HTML中寻找lat/latitude和lng/longitude相关信息
''';
  }

  /// 从HTML内容中提取坐标信息
  static Map<String, String?> _extractCoordinatesFromHtml(String html) {
    final coordinates = <String, String?>{
      'latitude': null,
      'longitude': null,
    };

    try {
      // 1. 查找地图相关的坐标
      final mapPatterns = [
        RegExp(r'maps\.google\.com.*q=(-?\d+\.\d+),(-?\d+\.\d+)'),
        RegExp(r'google\.com/maps.*@(-?\d+\.\d+),(-?\d+\.\d+)'),
        RegExp(r'latitude["\s]*[:=]["\s]*(-?\d+\.\d+)'),
        RegExp(r'longitude["\s]*[:=]["\s]*(-?\d+\.\d+)'),
        RegExp(r'lat["\s]*[:=]["\s]*(-?\d+\.\d+)'),
        RegExp(r'lng["\s]*[:=]["\s]*(-?\d+\.\d+)'),
        RegExp(r'"lat"\s*:\s*(-?\d+\.\d+)'),
        RegExp(r'"lng"\s*:\s*(-?\d+\.\d+)'),
      ];

      // 2. 查找坐标对
      final coordPatterns = [
        RegExp(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)'),
        RegExp(r'(-?\d+\.\d+)[^\d]*(-?\d+\.\d+)'),
      ];

      for (final pattern in mapPatterns) {
        final match = pattern.firstMatch(html);
        if (match != null && match.groupCount >= 2) {
          try {
            final lat = double.tryParse(match.group(1) ?? '');
            final lng = double.tryParse(match.group(2) ?? '');
            
            if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
              coordinates['latitude'] = lat.toStringAsFixed(6);
              coordinates['longitude'] = lng.toStringAsFixed(6);
              _logger.d('Found coordinates from pattern: lat=$lat, lng=$lng');
              break;
            }
          } catch (e) {
            _logger.w('Error parsing coordinates from match: $e');
            continue;
          }
        }
      }

      // 如果上面没有找到，尝试坐标对模式
      if (coordinates['latitude'] == null && coordinates['longitude'] == null) {
        for (final pattern in coordPatterns) {
          final matches = pattern.allMatches(html);
          for (final match in matches) {
            if (match.groupCount >= 2) {
              try {
                final lat = double.tryParse(match.group(1) ?? '');
                final lng = double.tryParse(match.group(2) ?? '');
                
                if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                  coordinates['latitude'] = lat.toStringAsFixed(6);
                  coordinates['longitude'] = lng.toStringAsFixed(6);
                  _logger.d('Found coordinates from coord pattern: lat=$lat, lng=$lng');
                  break;
                }
              } catch (e) {
                _logger.w('Error parsing coordinate pair: $e');
                continue;
              }
            }
          }
          if (coordinates['latitude'] != null) break;
        }
      }

      _logger.d('Final extracted coordinates: $coordinates');
    } catch (e) {
      _logger.e('Failed to extract coordinates: $e');
    }

    return coordinates;
  }
  static String _buildShareContentPrompt({
    required Restaurant restaurant,
    required String experienceText,
    required int rating,
    required List<ShareStyle> styles,
  }) {
    final styleNames = styles.map((s) => s.displayName).join('、');
    
    return '''
基于以下餐厅信息和用餐体验，生成${styleNames}风格的分享文案：

餐厅信息：
- 名称：${restaurant.name}
- 地址：${restaurant.address ?? ''}
- 菜系：${restaurant.cuisine ?? ''}
- 价格区间：${restaurant.priceRange ?? ''}
- 推荐菜品：${restaurant.recommendedDishes?.join('、') ?? ''}

用餐体验：
- 评分：$rating分（满分5分）
- 体验描述：$experienceText

请为每种风格生成一段文案，要求：

小红书风格：
- 轻松活泼，适合年轻人
- 多用emoji表情
- 突出颜值和体验感
- 150字左右

大众点评风格：
- 客观详细，重点突出性价比和体验
- 条理清晰，信息全面
- 适合实用性参考
- 200字左右

抖音风格：
- 简短有趣，适合视频配文
- 有话题性和互动性
- 节奏感强
- 100字左右

请严格按照以下JSON格式返回：

{
  "xiaohongshu": "小红书文案内容",
  "dianping": "大众点评文案内容", 
  "douyin": "抖音文案内容"
}

注意：只返回JSON格式，不要包含其他说明文字。
''';
  }

  /// 从JSON字符串解析餐厅信息，返回Restaurant对象
  static Restaurant _parseRestaurantFromJson(String response) {
    try {
      // 提取JSON部分
      final jsonStr = _extractJsonFromResponse(response);
      if (jsonStr.isEmpty) {
        throw Exception('No JSON found in response');
      }
      
      // 解析JSON
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      // 创建Restaurant对象
      return Restaurant(
        name: data['name'] ?? '未知餐厅',
        address: data['address'],
        fullAddress: data['fullAddress'] ?? data['address'],
        phone: data['phone'],
        cuisine: data['cuisine'],
        priceRange: data['priceRange'],
        rating: data['rating']?.toDouble(),
        description: data['description'],
        recommendedDishes: data['recommendedDishes']?.cast<String>(),
        businessHours: data['businessHours'],
        images: data['images']?.cast<String>(),
        latitude: data['latitude']?.toString(),
        longitude: data['longitude']?.toString(),
        features: data['features']?.cast<String>(),
        environment: data['environment'],
        serviceHighlights: data['serviceHighlights']?.cast<String>(),
        userReviewKeywords: data['userReviewKeywords']?.cast<String>(),
        marketingPoints: data['marketingPoints']?.cast<String>(),
        parkingInfo: data['parkingInfo'],
        specialOffers: data['specialOffers'],
        sourceUrl: null, // 稍后会被设置
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to parse JSON: $e');
      _logger.e('JSON content: $response');
      rethrow;
    }
  }

  /// 解析餐厅信息响应
  static Map<String, dynamic> _parseRestaurantResponse(String response) {
    try {
      // 提取JSON部分
      final jsonStr = _extractJsonFromResponse(response);
      if (jsonStr.isEmpty) {
        throw Exception('No JSON found in response');
      }
      
      // 这里简化处理，实际项目中应该使用json.decode
      final Map<String, dynamic> data = {};
      
      // 基于响应内容提取关键信息（简化实现）
      data['name'] = _extractField(response, 'name') ?? _extractField(response, '餐厅名称');
      data['address'] = _extractField(response, 'address') ?? _extractField(response, '地址');
      data['fullAddress'] = _extractField(response, 'fullAddress') ?? _extractField(response, 'full_address') ?? data['address'];
      data['phone'] = _extractField(response, 'phone') ?? _extractField(response, '电话');
      data['cuisine'] = _extractField(response, 'cuisine') ?? _extractField(response, '菜系');
      data['priceRange'] = _extractField(response, 'priceRange') ?? _extractField(response, 'price_range') ?? _extractField(response, '价格区间');
      data['description'] = _extractField(response, 'description') ?? _extractField(response, '描述');
      data['businessHours'] = _extractField(response, 'businessHours') ?? _extractField(response, 'business_hours') ?? _extractField(response, '营业时间');
      
      // 解析评分
      final ratingStr = _extractField(response, 'rating');
      if (ratingStr != null) {
        data['rating'] = double.tryParse(ratingStr);
      }
      
      // 解析推荐菜品
      final dishesStr = _extractField(response, 'recommendedDishes');
      if (dishesStr != null) {
        data['recommendedDishes'] = dishesStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      
      // 解析图片
      final imagesStr = _extractField(response, 'images');
      if (imagesStr != null) {
        data['images'] = imagesStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      
      return data;
    } catch (e) {
      _logger.e('Failed to parse restaurant response: $e');
      return {};
    }
  }

  /// 解析分享文案响应
  static Map<String, String> _parseShareContentResponse(String response, List<ShareStyle> styles) {
    try {
      final result = <String, String>{};
      
      for (final style in styles) {
        final content = _extractField(response, style.name);
        if (content != null) {
          result[style.name] = content;
        }
      }
      
      return result;
    } catch (e) {
      _logger.e('Failed to parse share content response: $e');
      return {};
    }
  }

  /// 从响应中提取JSON
  static String _extractJsonFromResponse(String response) {
    final jsonPattern = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}');
    final match = jsonPattern.firstMatch(response);
    return match?.group(0) ?? '';
  }

  /// 从响应中提取字段值
  static String? _extractField(String response, String field) {
    final patterns = [
      RegExp('"$field"\\s*:\\s*"([^"]*)"'),
      RegExp('"$field"\\s*:\\s*([^,}\\n]+)'),
      RegExp('$field[:：]\\s*([^\\n,}]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(response);
      if (match != null) {
        return match.group(1)?.trim().replaceAll('"', '');
      }
    }
    
    return null;
  }

  /// 创建降级餐厅信息
  static Restaurant _createFallbackRestaurant(ExtractedContent content) {
    return Restaurant(
      name: content.metadata['title'] ?? '未知餐厅',
      description: content.metadata['description'],
      sourceUrl: content.metadata['url'],
      images: content.images,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 创建降级分享文案
  static Map<String, String> _createFallbackShareContent(
    Restaurant restaurant,
    String experienceText,
    int rating,
    List<ShareStyle> styles,
  ) {
    final result = <String, String>{};
    
    for (final style in styles) {
      switch (style) {
        case ShareStyle.xiaohongshu:
          result[style.name] = '今天去了${restaurant.name}！$experienceText 给${rating}分！👍✨';
          break;
        case ShareStyle.dianping:
          result[style.name] = '${restaurant.name}\n评分：${rating}分\n体验：$experienceText\n推荐指数：${rating >= 4 ? '推荐' : '一般'}';
          break;
        case ShareStyle.douyin:
          result[style.name] = '${restaurant.name}探店！$experienceText #美食推荐 #探店';
          break;
      }
    }
    
    return result;
  }
}

/// 分享文案风格枚举
enum ShareStyle {
  xiaohongshu('xiaohongshu', '小红书'),
  dianping('dianping', '大众点评'),
  douyin('douyin', '抖音');

  const ShareStyle(this.name, this.displayName);
  
  final String name;
  final String displayName;
} 