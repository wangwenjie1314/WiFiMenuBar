#!/bin/bash

# WiFi MenuBar 构建脚本

echo "开始构建 WiFi MenuBar 应用..."

# 检查是否安装了Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "错误: 需要安装 Xcode 或 Xcode Command Line Tools"
    echo "请运行: xcode-select --install"
    exit 1
fi

# 清理之前的构建
echo "清理之前的构建..."
rm -rf build/

# 构建项目
echo "构建项目..."
xcodebuild -project WiFiMenuBar.xcodeproj \
           -scheme WiFiMenuBar \
           -configuration Debug \
           -derivedDataPath build \
           build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功!"
    echo "应用位置: build/Build/Products/Debug/WiFiMenuBar.app"
else
    echo "❌ 构建失败"
    exit 1
fi