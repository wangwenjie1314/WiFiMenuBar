#!/usr/bin/env python3
"""
WiFi菜单栏图标生成脚本
生成不同状态和尺寸的WiFi图标
"""

import os
import sys
from PIL import Image, ImageDraw
import argparse

def create_wifi_icon(size, status, scale=1):
    """
    创建WiFi图标
    
    Args:
        size: 基础尺寸
        status: 图标状态 (connected, disconnected, error, connecting)
        scale: 缩放倍数 (1x, 2x, 3x)
    
    Returns:
        PIL Image对象
    """
    actual_size = size * scale
    image = Image.new('RGBA', (actual_size, actual_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # 计算中心点和半径
    center_x = actual_size // 2
    center_y = actual_size // 2
    radius = actual_size * 0.4
    
    # 根据状态设置颜色
    if status == 'connected':
        color = (0, 0, 0, 255)  # 黑色
        arc_count = 3
    elif status == 'disconnected':
        color = (128, 128, 128, 255)  # 灰色
        arc_count = 1
    elif status == 'error':
        color = (255, 0, 0, 255)  # 红色
        arc_count = 3
    elif status == 'connecting':
        color = (0, 100, 255, 255)  # 蓝色
        arc_count = 2
    else:
        color = (128, 128, 128, 255)  # 默认灰色
        arc_count = 1
    
    # 绘制WiFi弧线
    line_width = max(1, actual_size // 16)
    
    for i in range(1, arc_count + 1):
        arc_radius = radius * i / 3
        
        # 计算弧线的边界框
        left = center_x - arc_radius
        top = center_y - arc_radius
        right = center_x + arc_radius
        bottom = center_y + arc_radius
        
        # 绘制弧线（从225度到315度，即底部的90度扇形）
        draw.arc([left, top, right, bottom], 225, 315, fill=color, width=line_width)
    
    # 绘制中心点
    if status != 'disabled':
        dot_radius = max(2, actual_size // 20)
        dot_left = center_x - dot_radius
        dot_top = center_y - dot_radius
        dot_right = center_x + dot_radius
        dot_bottom = center_y + dot_radius
        
        draw.ellipse([dot_left, dot_top, dot_right, dot_bottom], fill=color)
    
    # 根据状态添加额外的视觉元素
    if status == 'error':
        # 绘制错误标识（X）
        error_size = actual_size * 0.3
        error_x = center_x + actual_size * 0.2
        error_y = center_y - actual_size * 0.2
        
        draw.line([error_x - error_size/2, error_y - error_size/2, 
                  error_x + error_size/2, error_y + error_size/2], 
                 fill=(255, 0, 0, 255), width=line_width)
        draw.line([error_x + error_size/2, error_y - error_size/2, 
                  error_x - error_size/2, error_y + error_size/2], 
                 fill=(255, 0, 0, 255), width=line_width)
    
    return image

def generate_icon_set(base_path, icon_name, status, sizes):
    """
    生成一套图标（1x, 2x, 3x）
    
    Args:
        base_path: 基础路径
        icon_name: 图标名称
        status: 图标状态
        sizes: 尺寸列表
    """
    for size in sizes:
        # 1x图标
        icon_1x = create_wifi_icon(size, status, 1)
        icon_1x.save(os.path.join(base_path, f"{icon_name}-{size}.png"))
        
        # 2x图标
        icon_2x = create_wifi_icon(size, status, 2)
        icon_2x.save(os.path.join(base_path, f"{icon_name}-{size}@2x.png"))
        
        # 3x图标（如果需要）
        if size <= 32:  # 只为小尺寸生成3x
            icon_3x = create_wifi_icon(size, status, 3)
            icon_3x.save(os.path.join(base_path, f"{icon_name}-{size}@3x.png"))

def generate_app_icons(base_path):
    """
    生成应用图标
    
    Args:
        base_path: 基础路径
    """
    app_icon_sizes = [16, 32, 128, 256, 512]
    
    for size in app_icon_sizes:
        # 1x图标
        icon_1x = create_wifi_icon(size, 'connected', 1)
        icon_1x.save(os.path.join(base_path, f"app-icon-{size}.png"))
        
        # 2x图标
        icon_2x = create_wifi_icon(size, 'connected', 2)
        icon_2x.save(os.path.join(base_path, f"app-icon-{size}@2x.png"))

def main():
    parser = argparse.ArgumentParser(description='生成WiFi菜单栏图标')
    parser.add_argument('--output', '-o', default='./icons', help='输出目录')
    parser.add_argument('--status-bar-only', action='store_true', help='只生成状态栏图标')
    parser.add_argument('--app-icon-only', action='store_true', help='只生成应用图标')
    
    args = parser.parse_args()
    
    # 创建输出目录
    os.makedirs(args.output, exist_ok=True)
    
    if not args.app_icon_only:
        print("生成状态栏图标...")
        
        # 状态栏图标尺寸
        status_bar_sizes = [16, 18, 20, 22]
        
        # 生成不同状态的图标
        statuses = {
            'wifi-connected': 'connected',
            'wifi-disconnected': 'disconnected',
            'wifi-error': 'error',
            'wifi-connecting': 'connecting'
        }
        
        for icon_name, status in statuses.items():
            print(f"  生成 {icon_name} 图标...")
            generate_icon_set(args.output, icon_name, status, status_bar_sizes)
    
    if not args.status_bar_only:
        print("生成应用图标...")
        generate_app_icons(args.output)
    
    print(f"图标生成完成！输出目录: {args.output}")

if __name__ == '__main__':
    try:
        import PIL
    except ImportError:
        print("错误: 需要安装Pillow库")
        print("请运行: pip install Pillow")
        sys.exit(1)
    
    main()