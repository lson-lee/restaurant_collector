#!/bin/bash

# 创建启动图标脚本
# 这个脚本会生成各种尺寸的PNG图标

# 创建图标目录
mkdir -p assets/icons/generated/android
mkdir -p assets/icons/generated/ios
mkdir -p assets/icons/generated/web

# 由于环境限制，这里提供生成图标的脚本内容
# 实际使用时需要安装 ImageMagick 或在线转换工具

echo "🎨 餐厅收藏助手图标生成脚本"
echo "================================"
echo ""
echo "步骤1: 将 app_icon.svg 转换为 PNG"
echo "步骤2: 使用 flutter_launcher_icons 生成各种尺寸"
echo "步骤3: 应用图标到应用"
echo ""
echo "使用方法:"
echo "1. 安装 flutter_launcher_icons: flutter pub add flutter_launcher_icons"
echo "2. 将 app_icon.svg 转换为 1024x1024 PNG"
echo "3. 运行: flutter pub run flutter_launcher_icons:main"
echo ""
echo "或者使用在线转换:"
echo "- https://appicon.co/"
echo "- https://icon.kitchen/"
echo ""
echo "图标规格:"
echo "- Android: 48x48, 72x72, 96x96, 144x144, 192x192, 512x512"
echo "- iOS: 20x20, 29x29, 40x40, 50x50, 57x57, 58x58, 60x60, 72x72, 76x76, 80x80, 87x87, 100x100, 114x114, 120x120, 144x144, 152x152, 167x167, 180x180, 1024x1024"
echo "- Web: 16x16, 32x32, 48x48, 192x192, 512x512"