import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

/// 调试工具：检查数据库中的实际数据
void debugDatabase() async {
  print('🔍 开始检查数据库...');
  
  try {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'restaurant_collector.db');
    
    print('📁 数据库路径: $path');
    
    // 检查数据库文件是否存在
    final dbFile = File(path);
    if (!await dbFile.exists()) {
      print('❌ 数据库文件不存在');
      return;
    }
    
    print('✅ 数据库文件存在');
    
    // 打开数据库
    final db = await openDatabase(path);
    
    // 检查餐厅总数
    final restaurantCount = await db.rawQuery('SELECT COUNT(*) as count FROM restaurants');
    print('📊 餐厅总数: ${restaurantCount.first['count']}');
    
    // 检查所有餐厅数据
    final restaurants = await db.query('restaurants');
    print('📋 餐厅详细信息:');
    
    for (var restaurant in restaurants) {
      print('  🏪 ID: ${restaurant['id']}');
      print('     名称: ${restaurant['name']}');
      print('     地址: ${restaurant['address']}');
      print('     菜系: ${restaurant['cuisine']}');
      print('     创建时间: ${DateTime.fromMillisecondsSinceEpoch(restaurant['created_at'] as int)}');
      print('');
    }
    
    // 检查表结构
    final tableInfo = await db.rawQuery("PRAGMA table_info(restaurants)");
    print('🗂️ 表结构:');
    for (var column in tableInfo) {
      print('  ${column['name']}: ${column['type']}');
    }
    
    await db.close();
    
  } catch (e) {
    print('❌ 检查数据库时出错: $e');
  }
}

void main() async {
  await debugDatabase();
}