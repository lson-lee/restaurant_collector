import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/restaurant_card.dart';
import '../webview/webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('餐厅收藏助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showStatistics,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索餐厅名称、地址或菜系...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      context.read<RestaurantProvider>().setSearchKeyword(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<RestaurantProvider>(
                  builder: (context, provider, child) {
                    final hasFilters = provider.selectedCuisine != null;
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: hasFilters 
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                hasFilters ? Icons.filter_alt : Icons.filter_list,
                                key: ValueKey(hasFilters),
                                color: hasFilters 
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                            onPressed: _showFilterDialog,
                            tooltip: hasFilters ? '已应用筛选条件' : '筛选餐厅',
                          ),
                        ),
                        if (hasFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 餐厅列表
          Expanded(
            child: Consumer<RestaurantProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refresh(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                final restaurants = provider.filteredRestaurants;

                if (restaurants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchKeyword.isNotEmpty
                              ? '没有找到匹配的餐厅'
                              : '还没有收藏任何餐厅',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchKeyword.isNotEmpty
                              ? '试试其他关键词'
                              : '点击右下角按钮添加第一家餐厅',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RestaurantCard(
                          restaurant: restaurant,
                          onTap: () => _viewRestaurantDetail(restaurant),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRestaurantDialog,
        icon: const Icon(Icons.add),
        label: const Text('添加餐厅'),
      ),
    );
  }

  /// 显示添加餐厅对话框
  void _showAddRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加餐厅'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: '请输入餐厅页面链接...',
                helperText: '支持大众点评、美团等餐厅页面',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _urlController.clear();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = _urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop();
                _addRestaurantFromUrl(url);
                _urlController.clear();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 从URL添加餐厅
  Future<void> _addRestaurantFromUrl(String url) async {
    try {
      final provider = context.read<RestaurantProvider>();
      await provider.addRestaurantFromUrl(url);
      
      // 确保回到首页后刷新数据
      if (mounted) {
        await provider.refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加餐厅失败：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    final provider = context.read<RestaurantProvider>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(dialogContext).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '筛选餐厅',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 20,
                        color: Theme.of(dialogContext).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '选择菜系：',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildAnimatedFilterChip(
                          label: '全部',
                          isSelected: provider.selectedCuisine == null,
                          onTap: () {
                            provider.setSelectedCuisine(null);
                            setDialogState(() {});
                            // 添加触觉反馈
                            HapticFeedback.lightImpact();
                          },
                          context: dialogContext,
                        ),
                        ...provider.availableCuisines.map((cuisine) => 
                          _buildAnimatedFilterChip(
                            label: cuisine,
                            isSelected: provider.selectedCuisine == cuisine,
                            onTap: () {
                              provider.setSelectedCuisine(cuisine);
                              setDialogState(() {});
                              // 添加触觉反馈
                              HapticFeedback.lightImpact();
                            },
                            context: dialogContext,
                          ),
                        ).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 添加筛选结果提示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(dialogContext).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(dialogContext).primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '显示 ${provider.filteredRestaurants.length} / ${provider.restaurants.length} 家餐厅',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(dialogContext).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  provider.clearFilters();
                  setDialogState(() {});
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('清除筛选'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.check),
                label: const Text('确定'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示统计信息
  void _showStatistics() async {
    final provider = context.read<RestaurantProvider>();
    final stats = await provider.getStatistics();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('统计信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('收藏餐厅：${stats['totalRestaurants'] ?? 0} 家'),
              Text('体验记录：${stats['totalExperiences'] ?? 0} 条'),
              const SizedBox(height: 16),
              const Text('菜系分布：'),
              const SizedBox(height: 8),
              if (stats['cuisineStats'] != null)
                ...(stats['cuisineStats'] as Map<String, int>).entries.map(
                  (entry) => Text('${entry.key}：${entry.value} 家'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }

  /// 查看餐厅详情
  void _viewRestaurantDetail(restaurant) {
    // TODO: 导航到餐厅详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('点击了：${restaurant.name}')),
    );
  }

  /// 构建带动画效果的筛选chip
  Widget _buildAnimatedFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(
        begin: 0.0,
        end: isSelected ? 1.0 : 0.0,
      ),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.05), // 轻微的缩放效果
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle,
                            key: const ValueKey('selected'),
                            size: 18,
                            color: Colors.white,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            key: const ValueKey('unselected'),
                            size: 18,
                            color: Colors.grey[600],
                          ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 