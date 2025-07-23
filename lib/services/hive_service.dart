import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/restaurant.dart';

/// Hive数据库服务类
class HiveService {
  static const String _restaurantBoxName = 'restaurants';
  static const String _experienceBoxName = 'experiences';
  static const String _shareContentsBoxName = 'share_contents';
  static const String _imagesBoxName = 'images';
  
  static final Logger _logger = Logger();
  
  static Box<Restaurant>? _restaurantBox;
  static Box? _experienceBox;
  static Box? _shareContentsBox;
  static Box? _imagesBox;

  /// 初始化Hive数据库
  static Future<void> init() async {
    try {
      _logger.i('正在初始化Hive数据库...');
      
      // 初始化Hive
      await Hive.initFlutter();
      
      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(RestaurantAdapter());
      }
      
      // 打开boxes
      _restaurantBox = await Hive.openBox<Restaurant>(_restaurantBoxName);
      _experienceBox = await Hive.openBox(_experienceBoxName);
      _shareContentsBox = await Hive.openBox(_shareContentsBoxName);
      _imagesBox = await Hive.openBox(_imagesBoxName);
      
      _logger.i('Hive数据库初始化成功');
      _logger.d('餐厅数量: ${_restaurantBox?.length ?? 0}');
      
    } catch (e, stackTrace) {
      _logger.e('Hive数据库初始化失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 关闭数据库
  static Future<void> close() async {
    try {
      await _restaurantBox?.close();
      await _experienceBox?.close();
      await _shareContentsBox?.close();
      await _imagesBox?.close();
      await Hive.close();
      _logger.i('Hive数据库已关闭');
    } catch (e) {
      _logger.e('关闭Hive数据库时出错: $e');
    }
  }

  /// 确保boxes已初始化
  static void _ensureInitialized() {
    if (_restaurantBox == null) {
      throw Exception('HiveService未初始化，请先调用init()');
    }
  }

  // ==================== 餐厅相关操作 ====================

  /// 插入餐厅
  static Future<int> insertRestaurant(Restaurant restaurant) async {
    try {
      _ensureInitialized();
      
      // 生成一个简单的递增ID
      final id = _getNextId();
      final restaurantWithId = restaurant.copyWith(
        id: id,
        createdAt: restaurant.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 保存到Hive
      await _restaurantBox!.put(id, restaurantWithId);
      
      _logger.d('成功插入餐厅: ${restaurant.name} (ID: $id)');
      return id;
      
    } catch (e, stackTrace) {
      _logger.e('插入餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取下一个可用的ID
  static int _getNextId() {
    _ensureInitialized();
    
    if (_restaurantBox!.isEmpty) {
      return 1;
    }
    
    // 找到当前最大的ID并加1
    final keys = _restaurantBox!.keys.cast<int>();
    final maxId = keys.reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  /// 更新餐厅
  static Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      _ensureInitialized();
      
      if (restaurant.id == null) {
        throw Exception('更新餐厅时ID不能为空');
      }
      
      final updatedRestaurant = restaurant.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _restaurantBox!.put(restaurant.id!, updatedRestaurant);
      
      _logger.d('成功更新餐厅: ${restaurant.name} (ID: ${restaurant.id})');
      
    } catch (e, stackTrace) {
      _logger.e('更新餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 删除餐厅
  static Future<void> deleteRestaurant(int id) async {
    try {
      _ensureInitialized();
      
      await _restaurantBox!.delete(id);
      
      _logger.d('成功删除餐厅 (ID: $id)');
      
    } catch (e, stackTrace) {
      _logger.e('删除餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取所有餐厅
  static Future<List<Restaurant>> getAllRestaurants() async {
    try {
      _ensureInitialized();
      
      final restaurants = _restaurantBox!.values.toList();
      
      // 按创建时间倒序排列（最新的在前）
      restaurants.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      
      _logger.d('获取到 ${restaurants.length} 个餐厅');
      return restaurants;
      
    } catch (e, stackTrace) {
      _logger.e('获取餐厅列表失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 根据ID获取餐厅
  static Future<Restaurant?> getRestaurantById(int id) async {
    try {
      _ensureInitialized();
      
      final restaurant = _restaurantBox!.get(id);
      
      if (restaurant != null) {
        _logger.d('找到餐厅: ${restaurant.name} (ID: $id)');
      } else {
        _logger.d('未找到餐厅 (ID: $id)');
      }
      
      return restaurant;
      
    } catch (e, stackTrace) {
      _logger.e('根据ID获取餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 搜索餐厅（按名称、地址、菜系）
  static Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      _ensureInitialized();
      
      if (query.isEmpty) {
        return await getAllRestaurants();
      }
      
      final allRestaurants = _restaurantBox!.values.toList();
      final lowerQuery = query.toLowerCase();
      
      final filteredRestaurants = allRestaurants.where((restaurant) {
        return restaurant.name.toLowerCase().contains(lowerQuery) ||
            (restaurant.address?.toLowerCase().contains(lowerQuery) ?? false) ||
            (restaurant.cuisine?.toLowerCase().contains(lowerQuery) ?? false) ||
            (restaurant.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
      
      // 按创建时间倒序排列
      filteredRestaurants.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      
      _logger.d('搜索"$query"找到 ${filteredRestaurants.length} 个餐厅');
      return filteredRestaurants;
      
    } catch (e, stackTrace) {
      _logger.e('搜索餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 按菜系筛选餐厅
  static Future<List<Restaurant>> getRestaurantsByCuisine(String? cuisine) async {
    try {
      _ensureInitialized();
      
      if (cuisine == null || cuisine.isEmpty) {
        return await getAllRestaurants();
      }
      
      final allRestaurants = _restaurantBox!.values.toList();
      
      final filteredRestaurants = allRestaurants.where((restaurant) {
        return restaurant.cuisine == cuisine;
      }).toList();
      
      // 按创建时间倒序排列
      filteredRestaurants.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      
      _logger.d('菜系"$cuisine"找到 ${filteredRestaurants.length} 个餐厅');
      return filteredRestaurants;
      
    } catch (e, stackTrace) {
      _logger.e('按菜系筛选餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取所有菜系类型
  static Future<List<String>> getAllCuisines() async {
    try {
      _ensureInitialized();
      
      final allRestaurants = _restaurantBox!.values.toList();
      
      final cuisines = allRestaurants
          .where((restaurant) => restaurant.cuisine != null && restaurant.cuisine!.isNotEmpty)
          .map((restaurant) => restaurant.cuisine!)
          .toSet()
          .toList();
      
      cuisines.sort();
      
      _logger.d('找到 ${cuisines.length} 种菜系');
      return cuisines;
      
    } catch (e, stackTrace) {
      _logger.e('获取菜系列表失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 检查是否存在重复餐厅
  static Future<Restaurant?> findDuplicateRestaurant(
    String name, 
    String? address, 
    String? phone
  ) async {
    try {
      _ensureInitialized();
      
      final allRestaurants = _restaurantBox!.values.toList();
      
      for (final restaurant in allRestaurants) {
        // 检查名称相似度
        if (_isSimilarName(restaurant.name, name)) {
          _logger.d('找到相似名称的餐厅: ${restaurant.name} vs $name');
          return restaurant;
        }
        
        // 检查地址相似度（如果都有地址）
        if (address != null && 
            restaurant.address != null && 
            _isSimilarAddress(restaurant.address!, address)) {
          _logger.d('找到相似地址的餐厅: ${restaurant.address} vs $address');
          return restaurant;
        }
        
        // 检查电话号码（如果都有电话）
        if (phone != null && 
            restaurant.phone != null && 
            _isSimilarPhone(restaurant.phone!, phone)) {
          _logger.d('找到相同电话的餐厅: ${restaurant.phone} vs $phone');
          return restaurant;
        }
      }
      
      _logger.d('未找到重复餐厅');
      return null;
      
    } catch (e, stackTrace) {
      _logger.e('检查重复餐厅失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== 辅助方法 ====================

  /// 检查名称相似度
  static bool _isSimilarName(String name1, String name2) {
    final cleaned1 = name1.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '').toLowerCase();
    final cleaned2 = name2.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '').toLowerCase();
    
    return cleaned1 == cleaned2 || 
           cleaned1.contains(cleaned2) || 
           cleaned2.contains(cleaned1);
  }

  /// 检查地址相似度
  static bool _isSimilarAddress(String address1, String address2) {
    final cleaned1 = address1.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '').toLowerCase();
    final cleaned2 = address2.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '').toLowerCase();
    
    // 提取主要地址部分进行比较
    return cleaned1.contains(cleaned2) || cleaned2.contains(cleaned1);
  }

  /// 检查电话号码相似度
  static bool _isSimilarPhone(String phone1, String phone2) {
    final cleaned1 = phone1.replaceAll(RegExp(r'[^\d]'), '');
    final cleaned2 = phone2.replaceAll(RegExp(r'[^\d]'), '');
    
    return cleaned1 == cleaned2;
  }

  // ==================== 数据迁移和维护 ====================

  /// 清空所有数据
  static Future<void> clearAllData() async {
    try {
      _ensureInitialized();
      
      await _restaurantBox!.clear();
      await _experienceBox?.clear();
      await _shareContentsBox?.clear();
      await _imagesBox?.clear();
      
      _logger.i('已清空所有数据');
      
    } catch (e, stackTrace) {
      _logger.e('清空数据失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取数据统计信息
  static Future<Map<String, int>> getDataStats() async {
    try {
      _ensureInitialized();
      
      return {
        'restaurants': _restaurantBox?.length ?? 0,
        'experiences': _experienceBox?.length ?? 0,
        'shareContents': _shareContentsBox?.length ?? 0,
        'images': _imagesBox?.length ?? 0,
      };
      
    } catch (e, stackTrace) {
      _logger.e('获取数据统计失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
} 