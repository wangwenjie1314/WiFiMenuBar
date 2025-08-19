# 偏好设置界面实现文档

## 概述

本文档描述了WiFi菜单栏应用的偏好设置界面实现，包括界面结构、功能特性和集成方式。

## 实现的组件

### 1. PreferencesWindowController
- **文件**: `Controllers/PreferencesWindowController.swift`
- **功能**: 管理偏好设置窗口的生命周期和显示
- **特性**:
  - 使用SwiftUI作为内容视图
  - 窗口大小限制和样式配置
  - 浮动窗口级别，便于访问
  - 窗口状态管理（显示/隐藏/切换）

### 2. PreferencesView (主视图)
- **文件**: `Views/PreferencesView.swift`
- **功能**: 偏好设置的主界面，包含标签页导航
- **特性**:
  - 标签页式界面设计
  - 导入/导出设置功能
  - 重置为默认设置功能
  - 响应式布局

### 3. 子视图组件

#### DisplayPreferencesView
- **文件**: `Views/DisplayPreferencesView.swift`
- **功能**: 管理显示相关的设置
- **设置项**:
  - 显示格式选择（仅名称、名称+信号强度等）
  - 最大显示长度滑块
  - 显示选项开关（信号强度、网络图标）
  - 实时预览功能

#### BehaviorPreferencesView
- **文件**: `Views/BehaviorPreferencesView.swift`
- **功能**: 管理应用行为设置
- **设置项**:
  - 开机自动启动
  - 登录时启动
  - 最小化到托盘
  - 自动检查更新
  - 刷新间隔设置

#### NotificationPreferencesView
- **文件**: `Views/NotificationPreferencesView.swift`
- **功能**: 管理通知相关设置
- **设置项**:
  - 通知权限状态显示
  - 通知权限请求
  - 各类通知开关（连接、断开、切换、信号警告）
  - 权限状态指示器

#### AdvancedPreferencesView
- **文件**: `Views/AdvancedPreferencesView.swift`
- **功能**: 高级设置和调试选项
- **设置项**:
  - 日志查看和清除
  - 诊断信息导出
  - 测试通知功能
  - 系统信息显示
  - 缓存管理
  - 重置所有设置

## 集成方式

### 1. StatusBarController集成
```swift
// 在StatusBarController中添加了偏好设置窗口控制器
private lazy var preferencesWindowController = PreferencesWindowController()

// 菜单项点击处理
@objc private func showPreferences() {
    preferencesWindowController.showPreferences()
}
```

### 2. 偏好设置变更监听
```swift
// 监听偏好设置变更通知
NotificationCenter.default.addObserver(
    self,
    selector: #selector(preferencesDidChange),
    name: PreferencesManager.preferencesDidChangeNotification,
    object: nil
)

// 处理设置变更
@objc private func preferencesDidChange(_ notification: Notification) {
    // 更新显示格式等设置
    // 立即刷新界面
}
```

## 用户界面特性

### 1. 现代化设计
- 使用SwiftUI构建，支持暗色模式
- 响应式布局，适配不同窗口大小
- 清晰的视觉层次和分组

### 2. 用户体验
- 实时预览功能
- 设置变更即时生效
- 智能的权限状态提示
- 详细的帮助文本和说明

### 3. 数据管理
- 设置导入/导出功能
- 重置为默认值
- 设置验证和错误处理
- 自动保存机制

## 技术实现细节

### 1. 数据绑定
```swift
// 使用@ObservedObject监听PreferencesManager变化
@ObservedObject private var preferencesManager = PreferencesManager.shared

// 双向绑定示例
Toggle("开机自动启动", isOn: Binding(
    get: { preferences.autoStart },
    set: { preferencesManager.setAutoStart($0) }
))
```

### 2. 权限管理
```swift
// 通知权限检查
private func checkNotificationPermission() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async {
            self.notificationPermissionStatus = settings.authorizationStatus
        }
    }
}
```

### 3. 系统信息获取
```swift
// 获取系统信息用于调试
private func getSystemVersion() -> String {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
}
```

## 测试覆盖

### 1. 单元测试
- **文件**: `WiFiMenuBarTests/Controllers/PreferencesWindowControllerTests.swift`
- **覆盖范围**:
  - 窗口控制器初始化
  - 窗口配置验证
  - 显示/隐藏功能
  - 内存管理
  - 性能测试

### 2. 集成测试
- PreferencesManager集成验证
- 设置变更通知机制
- StatusBarController响应测试

## 使用方式

### 1. 用户访问
- 右键点击菜单栏WiFi图标
- 选择"偏好设置..."菜单项
- 或使用快捷键 Cmd+,

### 2. 设置管理
- 在各个标签页中调整设置
- 设置会自动保存并立即生效
- 可以导出设置备份或导入之前的配置

### 3. 故障排除
- 在"高级"标签页中查看系统信息
- 导出诊断信息用于问题分析
- 重置设置解决配置问题

## 扩展性

### 1. 添加新设置项
1. 在`AppPreferences`结构体中添加新属性
2. 在`PreferencesManager`中添加对应的getter/setter方法
3. 在相应的视图中添加UI控件
4. 更新验证逻辑和默认值

### 2. 添加新标签页
1. 创建新的视图文件
2. 在`PreferencesTab`枚举中添加新选项
3. 在`PreferencesView`的`TabView`中添加新标签

### 3. 自定义样式
- 所有视图都支持SwiftUI的样式修饰符
- 可以通过环境变量传递主题设置
- 支持自定义颜色和字体

## 注意事项

1. **权限处理**: 某些功能需要系统权限，界面会提供相应的引导
2. **数据验证**: 所有用户输入都会进行验证，无效值会被拒绝
3. **性能考虑**: 设置变更会触发界面更新，避免频繁操作
4. **兼容性**: 界面设计兼容macOS 11.0+，使用了现代SwiftUI特性

## 总结

偏好设置界面提供了完整的用户配置体验，包括：
- 直观的标签页式界面
- 丰富的设置选项
- 实时预览和反馈
- 完善的权限管理
- 调试和故障排除工具

该实现满足了任务5.2的所有要求，为用户提供了灵活且易用的设置管理功能。