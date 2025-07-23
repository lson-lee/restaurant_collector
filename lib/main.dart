import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'services/config_service.dart';
import 'services/kimi_service.dart';
import 'services/hive_service.dart';
import 'providers/restaurant_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志
  Logger.level = Level.debug;
  final logger = Logger();
  
  try {
    // 初始化配置
    logger.i('正在加载配置...');
    await ConfigService.initialize();
    
    // 初始化Hive数据库
    logger.i('正在初始化Hive数据库...');
    await HiveService.init();
    
    // 初始化Kimi AI服务
    final apiKey = ConfigService.kimiApiKey;
    KimiService.initialize(apiKey: apiKey);
    
    logger.i('App initialization completed');
  } catch (e) {
    logger.e('App initialization failed: $e');
  }
  
  runApp(const RestaurantCollectorApp());
}

class RestaurantCollectorApp extends StatelessWidget {
  const RestaurantCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '餐厅收藏助手',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => RestaurantProvider(context: context)..initialize(),
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
