#!/bin/bash

# WiFi状态栏应用停止脚本
# 使用方法: ./stop_wifi_menubar.sh

echo "正在停止WiFi状态栏应用..."

# 检查应用是否在运行
if ! pgrep -f "SimpleWiFiMenuBar" > /dev/null; then
    echo "WiFi状态栏应用未在运行"
    exit 0
fi

# 停止应用
pkill -f "SimpleWiFiMenuBar"

# 等待一下确保应用完全停止
sleep 1

# 检查应用是否成功停止
if ! pgrep -f "SimpleWiFiMenuBar" > /dev/null; then
    echo "WiFi状态栏应用已成功停止"
else
    echo "应用停止失败，尝试强制停止..."
    pkill -9 -f "SimpleWiFiMenuBar"
    sleep 1
    
    if ! pgrep -f "SimpleWiFiMenuBar" > /dev/null; then
        echo "WiFi状态栏应用已强制停止"
    else
        echo "无法停止应用，请手动处理"
        exit 1
    fi
fi