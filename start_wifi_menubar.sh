#!/bin/bash

# WiFi状态栏应用启动脚本
# 使用方法: ./start_wifi_menubar.sh

# 检查应用是否已在运行
if pgrep -f "SimpleWiFiMenuBar" > /dev/null; then
    echo "WiFi状态栏应用已在运行中"
    exit 0
fi

echo "正在启动WiFi状态栏应用..."

# 重新编译应用以确保使用最新代码
echo "正在编译最新版本..."
swiftc -framework Cocoa -framework CoreWLAN -framework Network SimpleWiFiMenuBar.swift -o SimpleWiFiMenuBar

if [ $? -eq 0 ]; then
    echo "编译成功！"
else
    echo "编译失败，请检查错误信息"
    exit 1
fi

# 在后台静默启动应用
echo "启动WiFi状态栏应用（后台运行）..."
nohup ./SimpleWiFiMenuBar > /dev/null 2>&1 &

# 等待一下确保应用启动
sleep 1

# 检查应用是否成功启动
if pgrep -f "SimpleWiFiMenuBar" > /dev/null; then
    echo "WiFi状态栏应用已成功启动并在后台运行"
    echo "应用将在状态栏显示WiFi信息，只有关机或手动退出才会关闭"
else
    echo "应用启动失败，请检查权限设置"
    exit 1
fi