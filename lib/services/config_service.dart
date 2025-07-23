import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// 配置服务 - 集中管理所有配置和环境变量
class ConfigService {
  static final Logger _logger = Logger();
  
  /// 初始化配置
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _logger.i('Configuration loaded successfully');
    } catch (e) {
      _logger.e('Failed to load configuration: $e');
      rethrow;
    }
  }
  
  /// 获取Kimi API密钥
  static String get kimiApiKey {
    final apiKey = dotenv.env['KIMI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('KIMI_API_KEY not found in environment variables');
    }
    return apiKey;
  }
  
  /// 获取配置值（带默认值）
  static String get(String key, {String? defaultValue}) {
    return dotenv.env[key] ?? defaultValue ?? '';
  }
  
  /// 检查配置是否存在
  static bool has(String key) {
    return dotenv.env[key] != null && dotenv.env[key]!.isNotEmpty;
  }
  
  /// 获取所有配置（调试用）
  static Map<String, String> get allConfig {
    return Map.from(dotenv.env);
  }
}