#!/bin/bash

# WiFi状态栏应用启动脚本
# 使用方法: ./start_wifi_menubar.sh

echo "正在启动WiFi状态栏应用..."

# 检查应用是否已编译
if [ ! -f "SimpleWiFiMenuBar" ]; then
    echo "应用未编译，正在编译..."
    swiftc -framework Cocoa -framework CoreWLAN -framework Network SimpleWiFiMenuBar.swift -o SimpleWiFiMenuBar
    
    if [ $? -eq 0 ]; then
        echo "编译成功！"
    else
        echo "编译失败，请检查错误信息"
        exit 1
    fi
fi

# 启动应用
echo "启动WiFi状态栏应用..."
./SimpleWiFiMenuBar