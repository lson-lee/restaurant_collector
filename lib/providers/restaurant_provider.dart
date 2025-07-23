import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/restaurant.dart';
import '../services/hive_service.dart';
import '../services/webview_service.dart';
import '../services/kimi_service.dart';
import '../screens/webview/webview_screen.dart';

/// 餐厅状态管理Provider
class RestaurantProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  final BuildContext context;
  
  // 状态变量
  List<Restaurant> _restaurants = [];
  Restaurant? _currentRestaurant;
  bool _isLoading = false;
  String? _error;
  
  // 搜索和筛选
  String _searchKeyword = '';
  String? _selectedCuisine;

  RestaurantProvider({required this.context});

  // Getters
  List<Restaurant> get restaurants => _restaurants;
  Restaurant? get currentRestaurant => _currentRestaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchKeyword => _searchKeyword;
  String? get selectedCuisine => _selectedCuisine;

  /// 初始化Provider
  Future<void> initialize() async {
    try {
      _logger.d('Initializing RestaurantProvider');
      await loadRestaurants();
    } catch (e) {
      _logger.e('Failed to initialize RestaurantProvider: $e');
      _setError('初始化失败：$e');
    }
  }

  /// 获取筛选后的餐厅列表
  List<Restaurant> get filteredRestaurants {
    List<Restaurant> filtered = List.from(_restaurants); // 创建新列表避免修改原数据
    
    // 按关键词搜索
    if (_searchKeyword.isNotEmpty) {
      filtered = filtered.where((restaurant) {
        return restaurant.name.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
               (restaurant.address?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false) ||
               (restaurant.cuisine?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false);
      }).toList();
    }
    
    // 按菜系筛选
    if (_selectedCuisine != null && _selectedCuisine!.isNotEmpty) {
      filtered = filtered.where((restaurant) => restaurant.cuisine == _selectedCuisine).toList();
    }
    
    return filtered;
  }

  /// 获取所有可用的菜系
  List<String> get availableCuisines {
    final cuisineSet = <String>{};
    for (final restaurant in _restaurants) {
      if (restaurant.cuisine != null && restaurant.cuisine!.isNotEmpty) {
        cuisineSet.add(restaurant.cuisine!);
      }
    }
    return cuisineSet.toList()..sort();
  }

  /// 加载所有餐厅
  Future<void> loadRestaurants() async {
    try {
      _setLoading(true);
      _clearError();
      
      final restaurants = await HiveService.getAllRestaurants();
      _restaurants = restaurants;
      
      _logger.d('Loaded ${restaurants.length} restaurants from database');
      if (restaurants.isNotEmpty) {
        _logger.d('First restaurant: ${restaurants.first.name}');
      }
      
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to load restaurants: $e');
      _setError('加载餐厅列表失败：$e');
      _restaurants = []; // 确保空列表避免显示错误
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// 从URL添加餐厅（新流程：WebView中完成AI处理和查重）
  Future<void> addRestaurantFromUrl(String url) async {
    try {
      _logger.d('Adding restaurant from URL: $url');
      
      // 打开WebView页面，用户手动操作并完成AI处理（包含查重）
      final restaurant = await Navigator.of(context).push<Restaurant>(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: url),
        ),
      );
      
      // 检查是否获取到餐厅信息
      if (restaurant == null) {
        _logger.w('User cancelled or no restaurant data returned');
        return;
      }
      
      _logger.d('Received restaurant data: ${restaurant.name}');
      
      // 显示保存进度对话框
      _showSaveProgressDialog();
      
      try {
        // 准备保存数据
        _updateSaveProgress('准备保存', '正在准备餐厅数据...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 确保必要的元数据
        final restaurantWithMetadata = restaurant.copyWith(
          sourceUrl: restaurant.sourceUrl ?? url,
          createdAt: restaurant.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // 保存到数据库
        _updateSaveProgress('保存数据', '正在保存餐厅信息到数据库...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        final id = await HiveService.insertRestaurant(restaurantWithMetadata);
        final savedRestaurant = restaurantWithMetadata.copyWith(id: id);
        
        // 刷新数据
        _updateSaveProgress('更新列表', '正在刷新餐厅列表...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 清除筛选条件，确保新餐厅可见
        clearFilters();
        
        // 刷新数据，确保新餐厅在列表顶部
        await loadRestaurants();
        
        _logger.i('Successfully added restaurant: ${savedRestaurant.name}');
        _logger.i('Now have ${_restaurants.length} restaurants in list');
        
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '成功添加餐厅：${savedRestaurant.name ?? '未知餐厅'}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 跳转回主页面，新餐厅会显示在列表顶部
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
        }
        rethrow;
      }
      
    } catch (e) {
      _logger.e('Failed to add restaurant from URL: $e');
      
      if (context.mounted) {
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('添加餐厅失败：$e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      rethrow;
    }
  }

  /// 更新餐厅信息
  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updatedRestaurant = restaurant.copyWith(updatedAt: DateTime.now());
      await HiveService.updateRestaurant(updatedRestaurant);
      
      // 更新本地列表
      final index = _restaurants.indexWhere((r) => r.id == restaurant.id);
      if (index != -1) {
        _restaurants[index] = updatedRestaurant;
        
        // 如果当前选中的餐厅被更新了，也要更新它
        if (_currentRestaurant?.id == restaurant.id) {
          _currentRestaurant = restaurant;
        }
        
        notifyListeners();
      }
      
      _logger.d('Updated restaurant: ${restaurant.name}');
    } catch (e) {
      _logger.e('Failed to update restaurant: $e');
      _setError('更新餐厅失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  /// 删除餐厅
  Future<void> deleteRestaurant(int restaurantId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await HiveService.deleteRestaurant(restaurantId);
      
      // 从本地列表中移除
      _restaurants.removeWhere((restaurant) => restaurant.id == restaurantId);
      
      // 如果删除的是当前选中的餐厅，清空选中状态
      if (_currentRestaurant?.id == restaurantId) {
        _currentRestaurant = null;
      }
      
      notifyListeners();
      _logger.d('Deleted restaurant with id: $restaurantId');
    } catch (e) {
      _logger.e('Failed to delete restaurant: $e');
      _setError('删除餐厅失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置当前选中的餐厅
  void setCurrentRestaurant(Restaurant restaurant) {
    _currentRestaurant = restaurant;
    notifyListeners();
  }

  /// 设置搜索关键词
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  /// 设置选中的菜系
  void setSelectedCuisine(String? cuisine) {
    _selectedCuisine = cuisine;
    notifyListeners();
  }

  /// 清除筛选条件
  void clearFilters() {
    _searchKeyword = '';
    _selectedCuisine = null;
    notifyListeners();
  }

  /// 刷新数据
  Future<void> refresh() async {
    _logger.d('Refreshing restaurant data');
    await loadRestaurants();
  }

  /// 获取餐厅统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allRestaurants = await HiveService.getAllRestaurants();
      final totalCount = allRestaurants.length;
      
      // 暂时设置为0，后续实现体验记录功能时再更新
      final experienceCount = 0;
      
      // 计算菜系统计
      final cuisineCount = <String, int>{};
      for (final restaurant in allRestaurants) {
        if (restaurant.cuisine != null && restaurant.cuisine!.isNotEmpty) {
          cuisineCount[restaurant.cuisine!] = (cuisineCount[restaurant.cuisine!] ?? 0) + 1;
        }
      }
      final cuisineStats = cuisineCount;
      
      return {
        'totalRestaurants': totalCount,
        'totalExperiences': experienceCount,
        'cuisineStats': cuisineStats,
      };
    } catch (e) {
      _logger.e('Failed to get statistics: $e');
      return {};
    }
  }

  // 私有辅助方法
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// 查找重复餐厅（更智能的匹配）
  Future<Restaurant?> findDuplicateRestaurant(String restaurantName, String? address, String? phone) async {
    try {
      final existingRestaurants = await HiveService.getAllRestaurants();
      
      // 标准化输入
      final normalizedName = restaurantName.toLowerCase().trim();
      final normalizedAddress = address?.toLowerCase().trim();
      final normalizedPhone = phone?.replaceAll(RegExp(r'[^0-9]'), '');
      
      for (final existing in existingRestaurants) {
        // 名称完全匹配
        final nameMatch = existing.name.toLowerCase().trim() == normalizedName;
        
        // 地址匹配（如果都有地址）
        final addressMatch = normalizedAddress != null && existing.address != null && 
                           existing.address!.toLowerCase().contains(normalizedAddress);
        
        // 电话号码匹配（如果都有电话）
        final phoneMatch = normalizedPhone != null && existing.phone != null &&
                          existing.phone!.replaceAll(RegExp(r'[^0-9]'), '').contains(normalizedPhone!);
        
        // 如果名称相同，或者名称+地址/电话匹配，则认为是重复
        if (nameMatch || (nameMatch && (addressMatch || phoneMatch))) {
          return existing;
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error finding duplicate restaurant: $e');
      return null;
    }
  }

  /// 显示重复餐厅确认对话框
  Future<bool> _showDuplicateDialog(BuildContext context, Restaurant restaurant) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现重复餐厅'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统检测到以下餐厅已存在：',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '名称：${restaurant.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (restaurant.address != null)
                    Text('地址：${restaurant.address}'),
                  if (restaurant.cuisine != null)
                    Text('菜系：${restaurant.cuisine}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('是否仍要继续添加并更新信息？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('继续添加'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  /// 显示保存进度对话框
  void _showSaveProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '保存餐厅信息',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _saveProgressMessage,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _saveProgressMessage = '正在处理...';
  
  /// 更新保存进度
  void _updateSaveProgress(String title, String message) {
    _saveProgressMessage = message;
    // 注意：这里不能直接更新对话框状态，因为对话框有自己的context
    // 但可以更新消息内容，对话框会在下次rebuild时显示新内容
  }
} 