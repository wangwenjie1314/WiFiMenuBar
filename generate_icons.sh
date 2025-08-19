#!/bin/bash

# WiFi菜单栏图标生成脚本
# 使用macOS内置工具生成简单的占位图标

set -e

# 输出目录
OUTPUT_DIR="WiFiMenuBar/Resources/Assets.xcassets"
TEMP_DIR="/tmp/wifi_icons"

# 创建临时目录
mkdir -p "$TEMP_DIR"

echo "生成WiFi菜单栏图标..."

# 生成SVG图标的函数
generate_wifi_svg() {
    local status=$1
    local size=$2
    local output_file=$3
    
    # 根据状态设置颜色
    case $status in
        "connected")
            color="#000000"
            arcs=3
            ;;
        "disconnected")
            color="#808080"
            arcs=1
            ;;
        "error")
            color="#FF0000"
            arcs=3
            ;;
        "connecting")
            color="#0064FF"
            arcs=2
            ;;
        *)
            color="#808080"
            arcs=1
            ;;
    esac
    
    # 生成SVG内容
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg width="$size" height="$size" viewBox="0 0 $size $size" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate($(($size/2)), $(($size/2)))">
    <!-- WiFi弧线 -->
EOF

    # 添加弧线
    local radius_base=$((size * 2 / 10))
    for ((i=1; i<=arcs; i++)); do
        local radius=$((radius_base * i))
        local stroke_width=$((size / 16))
        if [ $stroke_width -lt 1 ]; then
            stroke_width=1
        fi
        
        cat >> "$output_file" << EOF
    <path d="M -$((radius * 7 / 10)),-$((radius * 7 / 10)) A $radius,$radius 0 0,1 $((radius * 7 / 10)),-$((radius * 7 / 10))" 
          fill="none" stroke="$color" stroke-width="$stroke_width" stroke-linecap="round"/>
EOF
    done
    
    # 添加中心点
    local dot_radius=$((size / 20))
    if [ $dot_radius -lt 2 ]; then
        dot_radius=2
    fi
    
    cat >> "$output_file" << EOF
    <!-- 中心点 -->
    <circle cx="0" cy="0" r="$dot_radius" fill="$color"/>
EOF

    # 如果是错误状态，添加X标记
    if [ "$status" = "error" ]; then
        local x_size=$((size / 4))
        local x_offset=$((size / 4))
        cat >> "$output_file" << EOF
    <!-- 错误标记 -->
    <g transform="translate($x_offset, -$x_offset)">
      <line x1="-$((x_size/2))" y1="-$((x_size/2))" x2="$((x_size/2))" y2="$((x_size/2))" stroke="#FF0000" stroke-width="2"/>
      <line x1="$((x_size/2))" y1="-$((x_size/2))" x2="-$((x_size/2))" y2="$((x_size/2))" stroke="#FF0000" stroke-width="2"/>
    </g>
EOF
    fi
    
    cat >> "$output_file" << EOF
  </g>
</svg>
EOF
}

# 转换SVG到PNG的函数
svg_to_png() {
    local svg_file=$1
    local png_file=$2
    local size=$3
    
    # 使用qlmanage转换（macOS内置）
    if command -v qlmanage >/dev/null 2>&1; then
        qlmanage -t -s $size -o "$(dirname "$png_file")" "$svg_file" >/dev/null 2>&1
        # qlmanage生成的文件名会有.png.png后缀，需要重命名
        local generated_file="$(dirname "$png_file")/$(basename "$svg_file" .svg).svg.png"
        if [ -f "$generated_file" ]; then
            mv "$generated_file" "$png_file"
        fi
    else
        echo "警告: 无法找到图像转换工具，跳过PNG生成"
        return 1
    fi
}

# 生成图标集的函数
generate_icon_set() {
    local icon_name=$1
    local status=$2
    local base_size=$3
    local asset_dir="$OUTPUT_DIR/${icon_name}.imageset"
    
    echo "  生成 $icon_name 图标..."
    
    # 生成1x图标
    local svg_1x="$TEMP_DIR/${icon_name}-${base_size}.svg"
    local png_1x="$asset_dir/${icon_name}-${base_size}.png"
    
    generate_wifi_svg "$status" $base_size "$svg_1x"
    svg_to_png "$svg_1x" "$png_1x" $base_size
    
    # 生成2x图标
    local svg_2x="$TEMP_DIR/${icon_name}-${base_size}@2x.svg"
    local png_2x="$asset_dir/${icon_name}-${base_size}@2x.png"
    
    generate_wifi_svg "$status" $((base_size * 2)) "$svg_2x"
    svg_to_png "$svg_2x" "$png_2x" $((base_size * 2))
}

# 生成状态栏图标
echo "生成状态栏图标..."

# WiFi连接状态图标
generate_icon_set "wifi-connected" "connected" 16

# WiFi断开状态图标
generate_icon_set "wifi-disconnected" "disconnected" 16

# WiFi错误状态图标
generate_icon_set "wifi-error" "error" 16

# WiFi连接中状态图标
generate_icon_set "wifi-connecting" "connecting" 16

# 生成应用图标
echo "生成应用图标..."
app_icon_dir="$OUTPUT_DIR/AppIcon.appiconset"

for size in 16 32 128 256 512; do
    echo "  生成应用图标 ${size}x${size}..."
    
    # 1x图标
    svg_file="$TEMP_DIR/app-icon-${size}.svg"
    png_file="$app_icon_dir/app-icon-${size}.png"
    
    generate_wifi_svg "connected" $size "$svg_file"
    svg_to_png "$svg_file" "$png_file" $size
    
    # 2x图标
    svg_file_2x="$TEMP_DIR/app-icon-${size}@2x.svg"
    png_file_2x="$app_icon_dir/app-icon-${size}@2x.png"
    
    generate_wifi_svg "connected" $((size * 2)) "$svg_file_2x"
    svg_to_png "$svg_file_2x" "$png_file_2x" $((size * 2))
done

# 清理临时文件
rm -rf "$TEMP_DIR"

echo "图标生成完成！"
echo "注意: 这些是简单的占位图标，建议使用专业的图标设计工具创建更精美的图标。"