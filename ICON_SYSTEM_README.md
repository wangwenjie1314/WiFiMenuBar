# WiFi菜单栏图标系统

## 概述

WiFi菜单栏应用的图标系统提供了完整的图标管理功能，包括状态栏图标、应用图标的动态切换、主题支持和动画效果。

## 系统架构

### 核心组件

1. **IconManager** - 图标管理器，负责图标的生成、缓存和状态管理
2. **IconResourceLoader** - 资源加载器，负责从资源包加载图标
3. **IconTestTool** - 测试工具，用于验证图标功能
4. **IconConfiguration.plist** - 图标配置文件

### 图标状态

系统支持以下WiFi状态的图标：

- `connected` - 已连接（绿色WiFi信号图标）
- `disconnected` - 未连接（灰色WiFi信号图标）
- `connecting` - 连接中（蓝色动画WiFi信号图标）
- `error` - 错误状态（红色WiFi信号图标带错误标识）
- `disabled` - WiFi已禁用（灰色禁用图标）
- `unknown` - 未知状态（灰色问号图标）

## 图标资源

### 资源结构

```
WiFiMenuBar/Resources/Assets.xcassets/
├── AppIcon.appiconset/           # 应用图标
├── WiFiConnected.imageset/       # WiFi已连接图标
├── WiFiDisconnected.imageset/    # WiFi未连接图标
├── WiFiConnecting.imageset/      # WiFi连接中图标
└── WiFiError.imageset/           # WiFi错误图标
```

### 图标尺寸

#### 状态栏图标
- 16x16 (1x, 2x)
- 18x18 (1x, 2x) 
- 20x20 (1x, 2x)
- 22x22 (1x, 2x)

#### 应用图标
- 16x16 (1x, 2x)
- 32x32 (1x, 2x)
- 128x128 (1x, 2x)
- 256x256 (1x, 2x)
- 512x512 (1x, 2x)

## 功能特性

### 1. 动态图标切换

图标会根据WiFi连接状态自动切换：

```swift
// 自动更新图标状态
iconManager.updateIconStatus(wifiStatus)

// 获取对应状态的图标
let icon = iconManager.getStatusBarIcon(for: wifiStatus)
```

### 2. 主题支持

支持三种主题模式：

- `auto` - 自动跟随系统主题
- `light` - 浅色主题
- `dark` - 深色主题

```swift
// 设置主题
iconManager.setTheme(.auto)
```

### 3. 动画效果

连接中状态支持动画效果：

```swift
// 启用/禁用动画
iconManager.setDynamicIconEnabled(true)
```

### 4. 图标缓存

自动缓存生成的图标以提高性能：

```swift
// 预加载图标
iconManager.preloadIcons()

// 清除缓存
iconManager.clearIconCache()
```

### 5. 程序化图标生成

当资源文件不存在时，系统会自动生成图标：

- 使用Core Graphics绘制WiFi信号图标
- 支持不同状态的视觉区分
- 自适应主题颜色

## 使用方法

### 基本使用

```swift
// 获取图标管理器实例
let iconManager = IconManager.shared

// 更新图标状态
iconManager.updateIconStatus(.connected(network))

// 获取状态栏图标
if let icon = iconManager.getStatusBarIcon(for: wifiStatus) {
    statusBarButton.image = icon
}
```

### 配置图标

```swift
// 设置主题
iconManager.setTheme(.dark)

// 启用彩色图标
iconManager.setColorIconEnabled(true)

// 启用动态图标
iconManager.setDynamicIconEnabled(true)
```

### 监听图标变化

```swift
// 监听主题变化
NotificationCenter.default.addObserver(
    self,
    selector: #selector(iconThemeChanged),
    name: .iconThemeChanged,
    object: nil
)

// 监听动画帧变化
NotificationCenter.default.addObserver(
    self,
    selector: #selector(iconAnimationFrameChanged),
    name: .iconAnimationFrameChanged,
    object: nil
)
```

## 图标生成

### 自动生成脚本

项目包含两个图标生成脚本：

1. **generate_icons.py** - Python脚本，使用Pillow库生成高质量图标
2. **generate_icons.sh** - Shell脚本，使用macOS内置工具生成简单图标

### 使用Python脚本（推荐）

```bash
# 安装依赖
pip install Pillow

# 生成所有图标
python3 generate_icons.py --output ./icons

# 只生成状态栏图标
python3 generate_icons.py --status-bar-only

# 只生成应用图标
python3 generate_icons.py --app-icon-only
```

### 使用Shell脚本

```bash
# 生成图标
chmod +x generate_icons.sh
./generate_icons.sh
```

## 测试和验证

### 图标测试工具

使用IconTestTool验证图标功能：

```swift
let testTool = IconTestTool()

// 执行完整测试
let result = testTool.performCompleteIconTest()

// 执行快速测试
let quickResult = testTool.performQuickIconTest()

// 生成测试报告
let report = testTool.generateTestReport(result)
print(report)
```

### 测试项目

- 资源完整性检查
- 图标生成测试
- 缓存功能测试
- 主题切换测试
- 动画功能测试
- 性能测试

## 配置文件

### IconConfiguration.plist

图标配置文件定义了图标的各种设置：

```xml
<dict>
    <key>StatusBarIcons</key>
    <dict>
        <key>Connected</key>
        <dict>
            <key>ImageName</key>
            <string>WiFiConnected</string>
            <key>IsTemplate</key>
            <true/>
        </dict>
    </dict>
    <key>AnimationSettings</key>
    <dict>
        <key>ConnectingAnimationDuration</key>
        <real>0.5</real>
    </dict>
</dict>
```

## 性能优化

### 缓存策略

- 图标生成后自动缓存
- 支持多种尺寸和主题的缓存
- 内存使用优化

### 预加载

- 应用启动时预加载常用图标
- 减少首次显示延迟

### 资源管理

- 自动清理过期缓存
- 内存警告时释放非必要资源

## 故障排除

### 常见问题

1. **图标不显示**
   - 检查Assets.xcassets中的图标资源
   - 运行图标生成脚本
   - 检查图标名称是否正确

2. **动画不工作**
   - 确认动态图标已启用
   - 检查连接中状态是否正确设置

3. **主题切换无效**
   - 检查主题设置是否正确
   - 清除图标缓存后重试

### 调试工具

```swift
// 获取图标信息
let iconInfo = iconManager.getIconInfo()
print(iconInfo.description)

// 检查资源完整性
let integrity = IconResourceLoader.shared.checkIconResourceIntegrity()
print(integrity.description)

// 运行测试
let testResult = IconTestTool().performCompleteIconTest()
print(testResult.description)
```

## 最佳实践

1. **图标设计**
   - 使用矢量图标确保清晰度
   - 遵循macOS设计规范
   - 保持视觉一致性

2. **性能优化**
   - 预加载常用图标
   - 合理使用缓存
   - 避免频繁重新生成

3. **用户体验**
   - 提供主题选择
   - 支持动画效果
   - 确保图标清晰可见

4. **维护性**
   - 使用配置文件管理设置
   - 编写测试验证功能
   - 定期检查资源完整性

## 扩展功能

### 自定义图标

可以通过以下方式添加自定义图标：

1. 在Assets.xcassets中添加新的imageset
2. 更新IconConfiguration.plist配置
3. 在IconManager中添加对应的状态处理

### 新增动画效果

可以扩展动画系统支持更多效果：

1. 在IconManager中添加新的动画类型
2. 实现对应的动画逻辑
3. 更新配置文件中的动画设置

## 版本历史

- v1.0 - 基础图标系统
- v1.1 - 添加主题支持
- v1.2 - 添加动画效果
- v1.3 - 添加测试工具
- v1.4 - 性能优化和缓存改进