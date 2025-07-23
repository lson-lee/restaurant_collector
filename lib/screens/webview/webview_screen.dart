import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/webview_service.dart';
import '../../services/kimi_service.dart';
import '../../services/hive_service.dart'; // Added for duplicate check

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _currentUrl;
  String? _pageTitle;
  String? _errorMessage;
  
  // 进度对话框相关状态
  int _currentStep = 0;
  String _currentStepTitle = '';
  String _currentStepDescription = '';
  
  // 对话框的setState函数引用
  StateSetter? _dialogSetState;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          if (mounted) {
            // 可以在这里显示加载进度
            debugPrint('WebView加载进度: $progress%');
          }
        },
        onPageStarted: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _currentUrl = url;
              _errorMessage = null;
            });
            debugPrint('开始加载页面: $url');
          }
        },
        onPageFinished: (String url) async {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            debugPrint('页面加载完成: $url');
            
            // 设置手机视口和样式
            try {
              await _controller.runJavaScript('''
                // 设置viewport为手机模式
                var viewport = document.querySelector('meta[name="viewport"]');
                if (!viewport) {
                  viewport = document.createElement('meta');
                  viewport.name = 'viewport';
                  document.head.appendChild(viewport);
                }
                viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                
                // 添加手机端样式
                var style = document.createElement('style');
                style.textContent = \`
                  body { 
                    font-size: 16px !important; 
                    -webkit-text-size-adjust: 100% !important;
                    touch-action: manipulation !important;
                  }
                  * { 
                    max-width: 100% !important; 
                    box-sizing: border-box !important;
                  }
                \`;
                document.head.appendChild(style);
              ''');
            } catch (e) {
              debugPrint('设置手机视口失败: $e');
            }
            
            // 获取页面标题
            try {
              final title = await _controller.runJavaScriptReturningResult(
                'document.title'
              );
              if (mounted) {
                setState(() {
                  _pageTitle = title.toString().replaceAll('"', '');
                });
              }
            } catch (e) {
              debugPrint('获取页面标题失败: $e');
            }
          }
        },
        onWebResourceError: (WebResourceError error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = '${error.description}\n错误代码: ${error.errorCode}';
            });
            debugPrint('WebView加载错误: ${error.description} (${error.errorCode})');
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          debugPrint('导航请求: ${request.url}');
          // 允许所有导航
          return NavigationDecision.navigate;
        },
      ))
      ..setUserAgent(
        // 使用iPhone的User-Agent，确保网站以手机模式显示
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
      );

    // 加载URL
    _loadUrl();
  }

  void _loadUrl() {
    try {
      debugPrint('正在加载URL: ${widget.url}');
      _controller.loadRequest(Uri.parse(widget.url));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'URL格式错误: $e';
        });
      }
      debugPrint('URL加载失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pageTitle ?? '加载中...',
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_currentUrl != null)
              Text(
                Uri.parse(_currentUrl!).host,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
              _loadUrl();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreMenu,
          ),
        ],
      ),
      body: Center(
        child: Container(
          // 设置手机比例容器 (9:16 比例，模拟iPhone)
          width: 400,
          height: 700,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // WebView
                if (!_hasError)
                  WebViewWidget(controller: _controller),
                
                // 错误页面
                if (_hasError)
                  Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                            '页面加载失败',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            '建议:\n1. 检查网络连接\n2. 确认URL格式正确\n3. 尝试使用HTTPS链接',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _errorMessage = null;
                              });
                              _loadUrl();
                            },
                            child: const Text('重新加载'),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // 加载指示器
                if (_isLoading && !_hasError)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('正在加载页面...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📱 当前以手机模式显示 - 请在上方页面中完成必要的操作（如登录、搜索等），然后点击确认按钮开始解析餐厅信息。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _hasError) ? null : _confirmAndExtract,
                      child: const Text('确认并解析'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 确认并提取餐厅信息（手动模式，分5个步骤）
  Future<void> _confirmAndExtract() async {
    try {
      debugPrint('🔍 开始手动获取餐厅信息流程...');

      // 显示5步骤进度对话框
      _showStepProgressDialog();

      // 第一步：获取页面信息并立即查重
      debugPrint('📄 第一步：获取完整页面信息');
      _updateStepProgress(1, '获取完整页面信息', '正在提取页面HTML内容...');

      await Future.delayed(const Duration(milliseconds: 500));

      final readyState = await _controller.runJavaScriptReturningResult('document.readyState');
      debugPrint('📊 页面状态: $readyState');

      final extractedContent = await WebViewService.extractAllContent(_controller);
      debugPrint('📊 原始内容提取完成 - HTML: ${extractedContent.htmlContent.length} 字符');

      // 立即进行查重检查（基于URL）
      _updateStepProgress(1, '获取完整页面信息', '正在检查是否为重复餐厅...');
      await Future.delayed(const Duration(milliseconds: 500));

      final currentUrl = await _controller.currentUrl();
      if (currentUrl != null) {
        // 基于URL查重
        final isDuplicate = await _checkDuplicateByUrl(currentUrl);
        if (isDuplicate) {
          debugPrint('❌ 发现重复餐厅URL: $currentUrl');
          if (mounted) {
            _dialogSetState = null;
            Navigator.of(context).pop(); // 关闭进度对话框
            _showErrorDialog('重复餐厅', '此餐厅已存在于收藏夹中');
          }
          return;
        }
      }

      debugPrint('✅ 餐厅不重复，继续处理流程');
      await Future.delayed(const Duration(milliseconds: 500));

      // 第二步：清理HTML
      debugPrint('🧹 第二步：正在清理HTML内容');
      _updateStepProgress(2, '正在保存信息', '清理HTML中的无用样式和类名...');
      
      await Future.delayed(const Duration(milliseconds: 500));

      final cleanedHtml = WebViewService.cleanHtmlContent(extractedContent.htmlContent);
      debugPrint('🧹 HTML清理完成 - 清理后长度: ${cleanedHtml.length} 字符');
      debugPrint('📊 HTML压缩比例: ${((extractedContent.htmlContent.length - cleanedHtml.length) / extractedContent.htmlContent.length * 100).toStringAsFixed(1)}%');

      // 使用清理后的HTML创建新的content对象
      final cleanedContent = ExtractedContent(
        htmlContent: cleanedHtml,
        textContent: extractedContent.textContent,
        images: extractedContent.images,
        jsonData: extractedContent.jsonData,
        metadata: extractedContent.metadata,
      );

      // 第三步：AI解析
      debugPrint('🤖 第三步：正在询问AI');
      _updateStepProgress(3, '正在询问AI', '发送清理后的HTML给AI进行解析...');

      await Future.delayed(const Duration(milliseconds: 800));

      final restaurant = await KimiService.parseRestaurantContent(cleanedContent);
      
      debugPrint('✅ AI解析完成');
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 第四步：处理数据
      debugPrint('💾 第四步：正在处理数据');
      _updateStepProgress(4, '正在处理数据', '准备餐厅数据...');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 添加源URL到餐厅对象
      final restaurantWithHtml = restaurant.copyWith(
        sourceUrl: extractedContent.metadata['url'],
        description: restaurant.description ?? '通过AI自动解析获取',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      debugPrint('💾 准备返回餐厅数据: ${restaurantWithHtml.name}');
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 第五步：解析完成
      debugPrint('✅ 第五步：解析完成');
      _updateStepProgress(5, '解析完成', '餐厅信息已成功解析，准备返回...');
      
      await Future.delayed(const Duration(milliseconds: 1000)); // 让用户看到完成状态
      
      // 关闭进度对话框并返回结果
      if (mounted) {
        _dialogSetState = null; // 清理引用
        Navigator.of(context).pop(); // 关闭进度对话框
        Navigator.of(context).pop(restaurantWithHtml); // 返回餐厅数据
      }
      
      debugPrint('✅ 手动获取流程完成');
      
    } catch (e) {
      debugPrint('❌ 手动获取过程出错: $e');
      debugPrint('错误堆栈: ${e.toString()}');
      if (mounted) {
        _dialogSetState = null; // 清理引用
        Navigator.of(context).pop(); // 关闭进度对话框
        _showErrorDialog('获取失败', '获取餐厅信息时出现错误: $e');
      }
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示更多菜单
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('回到首页'),
              onTap: () {
                Navigator.pop(context);
                _controller.loadRequest(Uri.parse(widget.url));
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back_outlined),
              title: const Text('后退'),
              onTap: () async {
                Navigator.pop(context);
                final canGoBack = await _controller.canGoBack();
                if (canGoBack) {
                  await _controller.goBack();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_forward_outlined),
              title: const Text('前进'),
              onTap: () async {
                Navigator.pop(context);
                final canGoForward = await _controller.canGoForward();
                if (canGoForward) {
                  await _controller.goForward();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: const Text('刷新页面'),
              onTap: () {
                Navigator.pop(context);
                _controller.reload();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('使用说明'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌐 1. 在页面中浏览并找到目标餐厅'),
              SizedBox(height: 8),
              Text('🔍 2. 如需要，可进行登录或搜索操作'),
              SizedBox(height: 8),
              Text('✅ 3. 确保页面显示完整的餐厅信息'),
              SizedBox(height: 8),
              Text('🤖 4. 点击"确认并解析"开始AI分析'),
              SizedBox(height: 16),
              Text(
                '新的AI处理流程包含5个步骤：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('📄 1. 获取完整页面信息'),
              Text('🧹 2. 清理HTML中无用内容'),
              Text('🤖 3. AI解析餐厅信息'),
              Text('🔍 4. 检查重复并保存数据'),
              Text('✅ 5. 完成并跳转到列表'),
              SizedBox(height: 16),
              Text(
                '💡 提示：我们的AI会自动提取餐厅名称、地址、菜系、推荐菜品等信息，并检查是否重复。',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示5步骤进度对话框
  void _showStepProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, dialogSetState) {
            // 保存对话框的setState函数引用
            _dialogSetState = dialogSetState;
            
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings_applications, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('AI处理流程'),
                ],
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 进度指示器
                    LinearProgressIndicator(
                      value: (_currentStep / 5.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 当前步骤信息
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$_currentStep',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentStepTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentStepDescription,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentStep <= 5)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 步骤列表
                    ...List.generate(5, (index) {
                      final stepIndex = index + 1;
                      final isCompleted = stepIndex < _currentStep;
                      final isCurrent = stepIndex == _currentStep;
                      final isPending = stepIndex > _currentStep;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green
                                    : isCurrent
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : Text(
                                        '$stepIndex',
                                        style: TextStyle(
                                          color: isCurrent ? Colors.white : Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getStepTitle(stepIndex),
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.green
                                      : isCurrent
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  /// 更新步骤进度
  void _updateStepProgress(int step, String title, String description) {
    _currentStep = step;
    _currentStepTitle = title;
    _currentStepDescription = description;
    
    // 使用对话框的setState更新UI
    if (_dialogSetState != null) {
      _dialogSetState!(() {});
    }
  }
  
  /// 获取步骤标题
  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return '获取完整页面信息';
      case 2:
        return '正在保存信息';
      case 3:
        return '正在询问AI';
      case 4:
        return '正在处理数据';
      case 5:
        return '解析完成';
      default:
        return '未知步骤';
    }
  }

  /// 基于URL检查重复餐厅
  Future<bool> _checkDuplicateByUrl(String url) async {
    try {
      // 这里可以根据需要实现更智能的URL匹配逻辑
      // 例如：去掉参数、统一域名格式等
      
      // 使用HiveService检查是否有相同的sourceUrl
      final allRestaurants = await HiveService.getAllRestaurants();
      
      for (final restaurant in allRestaurants) {
        if (restaurant.sourceUrl == url) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ URL查重检查失败: $e');
      return false; // 查重失败时不阻止流程
    }
  }
} 