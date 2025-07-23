import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logger/logger.dart';

/// WebView服务类 - 处理网页内容的加载和提取
class WebViewService {
  static final Logger _logger = Logger();
  
  /// 创建WebView控制器
  static WebViewController createController(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 移除setBackgroundColor调用，因为在macOS上不支持
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          _logger.d('WebView loading progress: $progress%');
        },
        onPageStarted: (String url) {
          _logger.d('WebView started loading: $url');
        },
        onPageFinished: (String url) {
          _logger.d('WebView finished loading: $url');
        },
        onWebResourceError: (WebResourceError error) {
          _logger.e('WebView error: ${error.description}');
        },
        onNavigationRequest: (NavigationRequest request) {
          _logger.d('WebView navigation request: ${request.url}');
          return NavigationDecision.navigate;
        },
      ))
      ..setUserAgent(_getMobileUserAgent());
    
    return controller;
  }

  /// 加载URL
  static Future<void> loadUrl(WebViewController controller, String url) async {
    try {
      await controller.loadRequest(Uri.parse(url));
    } catch (e) {
      _logger.e('Failed to load URL: $url, error: $e');
      rethrow;
    }
  }

  /// 等待页面加载完成 (等待一定时间确保动态内容加载)
  static Future<void> waitForPageLoad(WebViewController controller, {int delaySeconds = 3}) async {
    await Future.delayed(Duration(seconds: delaySeconds));
    
    // 确保页面完全加载
    try {
      await controller.runJavaScript('''
        // 等待页面完全加载
        if (document.readyState !== 'complete') {
          await new Promise(resolve => {
            window.addEventListener('load', resolve);
          });
        }
        
        // 等待可能的异步内容
        await new Promise(resolve => setTimeout(resolve, 2000));
      ''');
    } catch (e) {
      _logger.w('Failed to wait for page load with JavaScript: $e');
    }
  }

  /// 获取页面标题
  static Future<String> _extractTitle(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('document.title');
      return result.toString().replaceAll('"', '');
    } catch (e) {
      _logger.w('Failed to extract title: $e');
      return '';
    }
  }

  /// 获取当前URL
  static Future<String> _extractCurrentUrl(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('window.location.href');
      return result.toString().replaceAll('"', '');
    } catch (e) {
      _logger.w('Failed to extract URL: $e');
      return '';
    }
  }

  /// 获取页面描述
  static Future<String> _extractDescription(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        var meta = document.querySelector('meta[name="description"]') || 
                  document.querySelector('meta[property="og:description"]');
        meta ? meta.content : '';
      ''');
      return result.toString().replaceAll('"', '');
    } catch (e) {
      _logger.w('Failed to extract description: $e');
      return '';
    }
  }

  /// 提取HTML内容
  static Future<String> _extractHtmlContent(WebViewController controller) async {
    try {
      _logger.d('Extracting HTML content...');
      final result = await controller.runJavaScriptReturningResult('document.documentElement.outerHTML');
      
      // 处理JavaScript返回的字符串，去除外层引号
      String htmlContent = result.toString();
      if (htmlContent.startsWith('"') && htmlContent.endsWith('"')) {
        htmlContent = htmlContent.substring(1, htmlContent.length - 1);
      }
      
      // 解码转义字符
      htmlContent = htmlContent
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', '\\')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t');
      
      _logger.d('Extracted HTML content: ${htmlContent.length} characters');
      return htmlContent;
    } catch (e) {
      _logger.e('Failed to extract HTML content: $e');
      return '';
    }
  }

  /// 提取页面文本内容
  static Future<String> _extractTextContent(WebViewController controller) async {
    try {
      _logger.d('Extracting text content...');
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          // 获取页面主要文本内容，过滤掉脚本和样式
          var textContent = '';
          
          // 移除脚本和样式标签
          var scripts = document.querySelectorAll('script, style, noscript');
          scripts.forEach(function(el) { el.remove(); });
          
          // 获取餐厅名称
          var nameSelectors = [
            'h1', '.title', '.name', '.shop-name', '.restaurant-name',
            '[class*="name"]', '[class*="title"]', '.poi-name',
            '.shopName', '.shop-title'
          ];
          for (var i = 0; i < nameSelectors.length; i++) {
            var elem = document.querySelector(nameSelectors[i]);
            if (elem && elem.textContent.trim()) {
              textContent += '餐厅名称: ' + elem.textContent.trim() + '\\n';
              break;
            }
          }
          
          // 获取地址信息
          var addressSelectors = [
            '.address', '.location', '.addr', '[class*="address"]', 
            '.poi-address', '.shop-address', '.shopAddr'
          ];
          for (var i = 0; i < addressSelectors.length; i++) {
            var elem = document.querySelector(addressSelectors[i]);
            if (elem && elem.textContent.trim()) {
              textContent += '地址: ' + elem.textContent.trim() + '\\n';
              break;
            }
          }
          
          // 获取评分信息
          var ratingSelectors = [
            '.rating', '.score', '.star', '[class*="rating"]',
            '[class*="score"]', '.review-score', '.shopScore'
          ];
          for (var i = 0; i < ratingSelectors.length; i++) {
            var elem = document.querySelector(ratingSelectors[i]);
            if (elem && elem.textContent.trim()) {
              textContent += '评分: ' + elem.textContent.trim() + '\\n';
              break;
            }
          }
          
          // 获取价格信息
          var priceSelectors = [
            '.price', '.cost', '[class*="price"]', '[class*="cost"]',
            '.per-person', '.avg-price', '.shopPrice'
          ];
          for (var i = 0; i < priceSelectors.length; i++) {
            var elem = document.querySelector(priceSelectors[i]);
            if (elem && elem.textContent.trim()) {
              textContent += '价格: ' + elem.textContent.trim() + '\\n';
              break;
            }
          }
          
          // 获取推荐菜品
          var dishSelectors = [
            '.dish', '.menu', '.recommend', '[class*="dish"]',
            '[class*="menu"]', '[class*="recommend"]', '.dishName'
          ];
          var dishes = [];
          for (var i = 0; i < dishSelectors.length; i++) {
            var elems = document.querySelectorAll(dishSelectors[i]);
            for (var j = 0; j < elems.length && dishes.length < 10; j++) {
              if (elems[j].textContent.trim()) {
                dishes.push(elems[j].textContent.trim());
              }
            }
            if (dishes.length > 0) break;
          }
          if (dishes.length > 0) {
            textContent += '推荐菜品: ' + dishes.join(', ') + '\\n';
          }
          
          // 获取营业时间
          var timeSelectors = [
            '.time', '.hours', '.business-time', '[class*="time"]',
            '[class*="hours"]', '.open-time', '.businessTime'
          ];
          for (var i = 0; i < timeSelectors.length; i++) {
            var elem = document.querySelector(timeSelectors[i]);
            if (elem && elem.textContent.trim()) {
              textContent += '营业时间: ' + elem.textContent.trim() + '\\n';
              break;
            }
          }
          
          // 获取页面所有文本内容作为补充
          var bodyText = document.body.innerText || document.body.textContent || '';
          
          // 清理文本内容
          bodyText = bodyText.replace(/\\s+/g, ' ').trim();
          
          textContent += '\\n页面完整文本:\\n' + bodyText;
          
          return textContent;
        })()
      ''');
      
      // 处理JavaScript返回的字符串
      String textContent = result.toString();
      if (textContent.startsWith('"') && textContent.endsWith('"')) {
        textContent = textContent.substring(1, textContent.length - 1);
      }
      
      // 解码转义字符
      textContent = textContent
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', ' ')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', '\\');
      
      _logger.d('Extracted text content: ${textContent.length} characters');
      return textContent;
    } catch (e) {
      _logger.e('Failed to extract text content: $e');
      return '';
    }
  }

  /// 提取JSON数据
  static Future<List<String>> _extractJsonData(WebViewController controller) async {
    try {
      _logger.d('Extracting JSON data...');
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          var jsonData = [];
          
          // 查找script标签中的JSON数据
          var scripts = document.querySelectorAll('script');
          for (var i = 0; i < scripts.length; i++) {
            var script = scripts[i];
            var content = script.textContent || script.innerHTML;
            if (content && (content.includes('{') || content.includes('['))) {
              // 尝试提取看起来像JSON的部分
              var jsonMatches = content.match(/\\{[^{}]*(?:\\{[^{}]*\\}[^{}]*)*\\}/g);
              var arrayMatches = content.match(/\\[[^\\[\\]]*(?:\\[[^\\[\\]]*\\][^\\[\\]]*)*\\]/g);
              
              if (jsonMatches) {
                for (var j = 0; j < jsonMatches.length; j++) {
                  var match = jsonMatches[j];
                  if (match.length > 50 && match.length < 10000) {
                    jsonData.push(match);
                  }
                }
              }
              
              if (arrayMatches) {
                for (var j = 0; j < arrayMatches.length; j++) {
                  var match = arrayMatches[j];
                  if (match.length > 50 && match.length < 10000) {
                    jsonData.push(match);
                  }
                }
              }
            }
          }
          
          // 查找可能的数据属性
          var dataElems = document.querySelectorAll('[data-json], [data-data], [data-config]');
          for (var i = 0; i < dataElems.length; i++) {
            var elem = dataElems[i];
            for (var j = 0; j < elem.attributes.length; j++) {
              var attr = elem.attributes[j];
              if (attr.name.startsWith('data-') && attr.value.includes('{')) {
                jsonData.push(attr.value);
              }
            }
          }
          
          return jsonData;
        })()
      ''');
      
      // 处理JavaScript返回的结果
      if (result is List) {
        return result.map((item) => item.toString()).toList();
      } else {
        final jsonString = result.toString();
        if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
          // 尝试解析为字符串列表
          try {
            // 简单解析，移除外层括号并分割
            final content = jsonString.substring(1, jsonString.length - 1);
            if (content.isEmpty) return <String>[];
            
            // 这里简化处理，实际应该用proper JSON parser
            final List<String> items = [];
            String current = '';
            bool inQuotes = false;
            int braceLevel = 0;
            
            for (int i = 0; i < content.length; i++) {
              final char = content[i];
              if (char == '"' && (i == 0 || content[i-1] != '\\')) {
                inQuotes = !inQuotes;
              } else if (!inQuotes) {
                if (char == '{') braceLevel++;
                else if (char == '}') braceLevel--;
                else if (char == ',' && braceLevel == 0) {
                  if (current.trim().isNotEmpty) {
                    items.add(current.trim().replaceAll(RegExp(r'^"|"$'), ''));
                  }
                  current = '';
                  continue;
                }
              }
              current += char;
            }
            
            if (current.trim().isNotEmpty) {
              items.add(current.trim().replaceAll(RegExp(r'^"|"$'), ''));
            }
            
            return items;
          } catch (e) {
            _logger.w('Failed to parse JSON array: $e');
            return <String>[];
          }
        }
        return <String>[];
      }
    } catch (e) {
      _logger.e('Failed to extract JSON data: $e');
      return <String>[];
    }
  }

  /// 提取图片
  static Future<List<String>> _extractImages(WebViewController controller) async {
    try {
      _logger.d('Extracting images...');
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          var images = [];
          var imgElements = document.querySelectorAll('img');
          
          for (var i = 0; i < imgElements.length; i++) {
            var img = imgElements[i];
            var src = img.src || img.dataset.src || img.dataset.original || img.getAttribute('data-src');
            if (src && src.startsWith('http') && !src.includes('avatar') && !src.includes('icon')) {
              images.push(src);
            }
          }
          
          // 也查找背景图片
          var elemsWithBg = document.querySelectorAll('*');
          for (var i = 0; i < elemsWithBg.length; i++) {
            var elem = elemsWithBg[i];
            if (elem.style && elem.style.backgroundImage) {
              var bgImage = elem.style.backgroundImage;
              if (bgImage && bgImage !== 'none' && bgImage.includes('url(')) {
                var urlMatch = bgImage.match(/url\\(["']?([^"')]+)["']?\\)/);
                if (urlMatch && urlMatch[1] && urlMatch[1].startsWith('http')) {
                  images.push(urlMatch[1]);
                }
              }
            }
          }
          
          // 去重并限制数量
          var uniqueImages = [];
          for (var i = 0; i < images.length && uniqueImages.length < 20; i++) {
            if (uniqueImages.indexOf(images[i]) === -1) {
              uniqueImages.push(images[i]);
            }
          }
          
          return uniqueImages;
        })()
      ''');
      
      // 处理JavaScript返回的结果
      if (result is List) {
        return result.map((item) => item.toString()).toList();
      } else {
        final imagesString = result.toString();
        if (imagesString.startsWith('[') && imagesString.endsWith(']')) {
          try {
            // 简单解析图片数组
            final content = imagesString.substring(1, imagesString.length - 1);
            if (content.isEmpty) return <String>[];
            
            final List<String> images = content
                .split('","')
                .map((url) => url.replaceAll('"', '').trim())
                .where((url) => url.isNotEmpty && url.startsWith('http'))
                .toList();
            
            return images;
          } catch (e) {
            _logger.w('Failed to parse images array: $e');
            return <String>[];
          }
        }
        return <String>[];
      }
    } catch (e) {
      _logger.e('Failed to extract images: $e');
      return <String>[];
    }
  }

  /// 提取页面元数据
  static Future<Map<String, String>> extractMetadata(WebViewController controller) async {
    try {
      final metadata = <String, String>{};
      
      // 提取title
      final title = await controller.runJavaScriptReturningResult(
        'document.title || ""'
      );
      metadata['title'] = _cleanJavaScriptString(title.toString());
      
      // 提取meta description
      final description = await controller.runJavaScriptReturningResult(
        'document.querySelector(\'meta[name="description"]\')?.content || ""'
      );
      metadata['description'] = _cleanJavaScriptString(description.toString());
      
      // 提取keywords
      final keywords = await controller.runJavaScriptReturningResult(
        'document.querySelector(\'meta[name="keywords"]\')?.content || ""'
      );
      metadata['keywords'] = _cleanJavaScriptString(keywords.toString());
      
      // 提取当前URL
      final url = await controller.runJavaScriptReturningResult(
        'window.location.href'
      );
      metadata['url'] = _cleanJavaScriptString(url.toString());
      
      _logger.d('Extracted metadata: $metadata');
      return metadata;
    } catch (e) {
      _logger.e('Failed to extract metadata: $e');
      return {};
    }
  }

  /// 提取图片URL列表
  static Future<List<String>> extractImages(WebViewController controller) async {
    try {
      final images = await controller.runJavaScriptReturningResult('''
        Array.from(document.images)
          .map(img => img.src)
          .filter(src => src && src.startsWith('http'))
          .slice(0, 20)
      ''');
      
      final imageString = _cleanJavaScriptString(images.toString());
      if (imageString.isEmpty) return [];
      
      // 解析JavaScript数组格式
      final List<String> imageUrls = [];
      final RegExp urlPattern = RegExp(r'https?://[^\s,]+');
      final matches = urlPattern.allMatches(imageString);
      
      for (final match in matches) {
        final url = match.group(0);
        if (url != null) {
          imageUrls.add(url);
        }
      }
      
      _logger.d('Extracted ${imageUrls.length} image URLs');
      return imageUrls;
    } catch (e) {
      _logger.e('Failed to extract images: $e');
      return [];
    }
  }

  /// 注入自定义JavaScript (用于特殊页面处理)
  static Future<void> injectCustomScript(WebViewController controller, String script) async {
    try {
      await controller.runJavaScript(script);
      _logger.d('Injected custom script successfully');
    } catch (e) {
      _logger.e('Failed to inject custom script: $e');
    }
  }

  /// 获取手机版User-Agent
  static String _getMobileUserAgent() {
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
  }

  /// 清理JavaScript返回的字符串
  static String _cleanJavaScriptString(String jsString) {
    if (jsString.startsWith('"') && jsString.endsWith('"')) {
      jsString = jsString.substring(1, jsString.length - 1);
    }
    
    return jsString
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .trim();
  }

  /// 验证JSON字符串是否有效
  static bool _isValidJson(String jsonString) {
    try {
      // 简单的JSON验证
      if (jsonString.trim().isEmpty) return false;
      
      final trimmed = jsonString.trim();
      if (!((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']')))) {
        return false;
      }
      
      // 这里可以添加更复杂的JSON验证逻辑
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清理HTML内容，去除无业务意义的样式和类名
  static String cleanHtmlContent(String html) {
    try {
      _logger.d('开始清理HTML内容，原始长度: ${html.length}');
      
      String cleanedHtml = html;
      
      // 1. 移除所有<style>标签及其内容
      cleanedHtml = cleanedHtml.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
      
      // 2. 移除所有<script>标签及其内容（保留包含JSON数据的script）
      cleanedHtml = cleanedHtml.replaceAllMapped(
        RegExp(r'<script[^>]*>(.*?)</script>', dotAll: true),
        (match) {
          final scriptContent = match.group(1) ?? '';
          // 如果script包含可能的业务数据（JSON），则保留但清理
          if (scriptContent.contains('{') || scriptContent.contains('[')) {
            return '<script type="application/json">${scriptContent}</script>';
          }
          return ''; // 否则完全移除
        },
      );
      
      // 3. 移除内联样式属性
      cleanedHtml = cleanedHtml.replaceAll(RegExp(r'\s+style\s*=\s*"[^"]*"'), '');
      cleanedHtml = cleanedHtml.replaceAll(RegExp(r"\s+style\s*=\s*'[^']*'"), '');
      
      // 4. 清理class属性，保留可能有业务意义的class
      cleanedHtml = cleanedHtml.replaceAllMapped(
        RegExp(r'\s+class\s*=\s*"([^"]*)"'),
        (match) {
          final classNames = match.group(1) ?? '';
          // 保留可能有业务意义的class名
          final meaningfulClasses = classNames.split(' ').where((className) {
            final lowerClass = className.toLowerCase();
            return lowerClass.contains('name') ||
                   lowerClass.contains('title') ||
                   lowerClass.contains('address') ||
                   lowerClass.contains('phone') ||
                   lowerClass.contains('rating') ||
                   lowerClass.contains('price') ||
                   lowerClass.contains('menu') ||
                   lowerClass.contains('dish') ||
                   lowerClass.contains('restaurant') ||
                   lowerClass.contains('shop') ||
                   lowerClass.contains('store') ||
                   lowerClass.contains('poi') ||
                   lowerClass.contains('location') ||
                   lowerClass.contains('time') ||
                   lowerClass.contains('hour') ||
                   lowerClass.contains('business') ||
                   lowerClass.contains('score') ||
                   lowerClass.contains('star') ||
                   lowerClass.contains('review') ||
                   lowerClass.contains('image') ||
                   lowerClass.contains('photo') ||
                   lowerClass.contains('pic');
          }).toList();
          
          if (meaningfulClasses.isNotEmpty) {
            return ' class="${meaningfulClasses.join(' ')}"';
          }
          return '';
        },
      );
      
      // 5. 移除其他无用属性
      final uselessAttributes = [
        'data-v-[a-zA-Z0-9]+',
        'data-reactid',
        'data-react-',
        'ng-[a-zA-Z-]+',
        'v-[a-zA-Z-]+',
        'aria-hidden',
        'role="presentation"',
        'tabindex',
        'autocomplete',
        'spellcheck',
      ];
      
      for (final attr in uselessAttributes) {
        cleanedHtml = cleanedHtml.replaceAll(RegExp('\\s+$attr\\s*=\\s*"[^"]*"'), '');
      }
      
      // 6. 移除注释
      cleanedHtml = cleanedHtml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      
      // 7. 移除多余的空白字符
      cleanedHtml = cleanedHtml.replaceAll(RegExp(r'\s+'), ' ');
      cleanedHtml = cleanedHtml.replaceAll(RegExp(r'>\s+<'), '><');
      
      // 8. 移除无用的标签（保留可能有内容的标签）
      final uselessTags = ['noscript', 'meta', 'link'];
      for (final tag in uselessTags) {
        cleanedHtml = cleanedHtml.replaceAll(RegExp('<$tag[^>]*>', dotAll: true), '');
        cleanedHtml = cleanedHtml.replaceAll(RegExp('</$tag>', dotAll: true), '');
      }
      
      _logger.d('HTML清理完成，清理后长度: ${cleanedHtml.length}');
      _logger.d('压缩比例: ${((html.length - cleanedHtml.length) / html.length * 100).toStringAsFixed(1)}%');
      
      return cleanedHtml.trim();
    } catch (e) {
      _logger.e('HTML清理失败: $e');
      return html; // 如果清理失败，返回原始HTML
    }
  }

  /// 提取所有页面内容
  static Future<ExtractedContent> extractAllContent(WebViewController controller) async {
    try {
      _logger.i('开始提取页面内容...');
      
      // 首先等待一下确保页面稳定
      await Future.delayed(const Duration(seconds: 2));
      
      // 检查WebView状态
      try {
        final url = await controller.runJavaScriptReturningResult('window.location.href');
        _logger.i('当前页面URL: $url');
        
        if (url.toString().contains('about:blank')) {
          throw Exception('WebView显示空白页面，无法提取内容');
        }
      } catch (e) {
        _logger.e('无法获取页面URL: $e');
        throw Exception('WebView状态异常: $e');
      }
      
      // 检查页面基本状态
      try {
        final readyState = await controller.runJavaScriptReturningResult('document.readyState');
        final hasBody = await controller.runJavaScriptReturningResult('!!document.body');
        _logger.i('页面状态 - readyState: $readyState, hasBody: $hasBody');
        
        if (hasBody.toString() != 'true') {
          throw Exception('页面DOM未正确加载');
        }
      } catch (e) {
        _logger.e('页面状态检查失败: $e');
        throw Exception('页面状态异常: $e');
      }
      
      // 并行获取各种内容，但使用更可靠的方法
      _logger.i('开始并行提取各类内容...');
      
      final List<Future> futures = [
        _extractTitle(controller),
        _extractCurrentUrl(controller),
        _extractDescription(controller),
        _extractHtmlContent(controller),
        _extractTextContent(controller),
        _extractImages(controller),
      ];
      
      final results = await Future.wait(futures);
      
      final title = results[0] as String;
      final url = results[1] as String;
      final description = results[2] as String;
      final htmlContent = results[3] as String;
      final textContent = results[4] as String;
      final images = results[5] as List<String>;
      
      // 单独获取JSON数据（可能比较慢）
      final jsonData = await _extractJsonData(controller);
      
      // 验证提取的内容
      _logger.i('内容验证 - HTML长度: ${htmlContent.length}, 文本长度: ${textContent.length}');
      
      if (htmlContent.length < 100) {
        _logger.w('警告: HTML内容过短，可能提取不完整');
      }
      
      if (textContent.length < 50) {
        _logger.w('警告: 文本内容过短，可能页面为空或被阻止');
      }
      
      final extractedContent = ExtractedContent(
        htmlContent: htmlContent,
        textContent: textContent,
        jsonData: jsonData,
        metadata: {
          'title': title,
          'url': url,
          'description': description,
        },
        images: images,
      );
      
      // 详细打印要传递给AI的内容
      _printPromptContent(extractedContent);
      
      _logger.i('页面内容提取完成');
      return extractedContent;
    } catch (e) {
      _logger.e('Failed to extract content: $e');
      rethrow;
    }
  }

  /// 打印传递给AI的详细内容
  static void _printPromptContent(ExtractedContent content) {
    print('\n' + '='*80);
    print('🤖 AI PROMPT 内容详情');
    print('='*80);
    
    print('\n📄 页面元数据：');
    print('标题: ${content.metadata['title']}');
    print('URL: ${content.metadata['url']}');
    print('描述: ${content.metadata['description']}');
    
    print('\n📝 页面文本内容 (前1000字符):');
    final textPreview = content.textContent.length > 1000 
        ? content.textContent.substring(0, 1000) + '...[截断]'
        : content.textContent;
    print(textPreview);
    
    print('\n📊 JSON数据块数量: ${content.jsonData.length}');
    if (content.jsonData.isNotEmpty) {
      print('JSON数据预览 (前3个):');
      for (int i = 0; i < content.jsonData.length && i < 3; i++) {
        final jsonPreview = content.jsonData[i].length > 200
            ? content.jsonData[i].substring(0, 200) + '...[截断]'
            : content.jsonData[i];
        print('JSON[$i]: $jsonPreview');
      }
    }
    
    print('\n🖼️ 图片数量: ${content.images.length}');
    if (content.images.isNotEmpty) {
      print('图片URL预览 (前5个):');
      for (int i = 0; i < content.images.length && i < 5; i++) {
        print('图片[$i]: ${content.images[i]}');
      }
    }
    
    print('\n📏 内容统计:');
    print('HTML长度: ${content.htmlContent.length} 字符');
    print('文本长度: ${content.textContent.length} 字符');
    print('JSON块数: ${content.jsonData.length}');
    print('图片数: ${content.images.length}');
    
    print('\n🎯 将要发送给Kimi AI的完整Prompt:');
    print('-'*60);
    print('这些内容将被格式化为Prompt发送给AI进行解析...');
    print('='*80 + '\n');
  }
}

/// 提取的内容数据类
class ExtractedContent {
  final String htmlContent;
  final String textContent;
  final List<String> jsonData;
  final Map<String, String> metadata;
  final List<String> images;

  ExtractedContent({
    required this.htmlContent,
    required this.textContent,
    required this.jsonData,
    required this.metadata,
    required this.images,
  });

  @override
  String toString() {
    return 'ExtractedContent(htmlLength: ${htmlContent.length}, textLength: ${textContent.length}, jsonBlocks: ${jsonData.length}, images: ${images.length})';
  }
} 