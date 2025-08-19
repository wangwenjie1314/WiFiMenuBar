# AppDelegate实现文档

## 概述

本文档描述了WiFi菜单栏应用的AppDelegate实现，包括完整的应用生命周期管理、组件初始化和系统集成。

## 实现的功能

### 1. 应用生命周期管理

#### 启动流程
```swift
func applicationDidFinishLaunching(_ aNotification: Notification)
```
- 配置应用基本设置
- 检查首次运行状态
- 初始化核心组件
- 设置组件间通信
- 启动应用服务
- 请求必要权限

#### 终止流程
```swift
func applicationWillTerminate(_ aNotification: Notification)
```
- 停止所有服务
- 保存应用状态
- 清理资源
- 移除通知观察者

#### 状态管理
```swift
func applicationWillBecomeActive(_ notification: Notification)
func applicationDidBecomeActive(_ notification: Notification)
func applicationWillResignActive(_ notification: Notification)
func applicationDidResignActive(_ notification: Notification)
```
- 跟踪应用活跃状态
- 在状态变化时刷新WiFi信息
- 同步偏好设置

### 2. 核心组件初始化

#### WiFiMonitor初始化
```swift
private func initializeCoreComponents() {
    wifiMonitor = WiFiMonitor()
    statusBarController = StatusBarController(wifiMonitor: wifiMonitor)
}
```

#### 组件间通信设置
```swift
private func setupComponentCommunication() {
    wifiMonitor.delegate = statusBarController
    setupNotificationObservers()
}
```

### 3. 系统集成

#### 菜单栏应用配置
```swift
private func configureApplication() {
    NSApp.setActivationPolicy(.accessory)  // 不显示在Dock中
}
```

#### 权限管理
```swift
private func requestRequiredPermissions() {
    requestNotificationPermission()
    checkNetworkPermissions()
}
```

#### 系统事件监听
```swift
private func setupNotificationObservers() {
    // 监听偏好设置变更
    // 监听系统睡眠/唤醒
}
```

## 应用状态管理

### 1. AppState枚举
```swift
enum AppState {
    case launching      // 启动中
    case running        // 运行中
    case active         // 活跃状态
    case inactive       // 非活跃状态
    case terminating    // 终止中
    case terminated     // 已终止
}
```

### 2. 状态跟踪
- 实时跟踪应用当前状态
- 提供状态查询接口
- 状态变化时执行相应操作

### 3. 状态持久化
```swift
private func saveApplicationState() {
    let appState: [String: Any] = [
        "lastRunTime": Date(),
        "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown",
        "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown"
    ]
    UserDefaults.standard.set(appState, forKey: "AppState")
}
```

## 首次运行处理

### 1. 首次运行检测
```swift
private var isFirstRun: Bool {
    return !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
}
```

### 2. 欢迎流程
```swift
private func handleFirstRun() {
    showWelcomeMessage()
    preferencesManager.resetToDefaults()
    UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
}
```

### 3. 欢迎消息
- 显示欢迎对话框
- 提供快速设置入口
- 引导用户了解功能

## 权限管理

### 1. 通知权限
```swift
private func requestNotificationPermission() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        // 处理权限结果
    }
}
```

### 2. 网络权限
```swift
private func checkNetworkPermissions() {
    // 检查WiFi访问权限
    let currentNetwork = wifiMonitor.getCurrentNetwork()
    if currentNetwork == nil {
        print("可能缺少网络访问权限")
    }
}
```

## 系统事件处理

### 1. 偏好设置变更
```swift
@objc private func preferencesDidChange(_ notification: Notification) {
    // 处理全局偏好设置变更
}
```

### 2. 系统睡眠/唤醒
```swift
@objc private func systemWillSleep(_ notification: Notification) {
    wifiMonitor?.pauseMonitoring()
}

@objc private func systemDidWake(_ notification: Notification) {
    wifiMonitor?.resumeMonitoring()
    wifiMonitor?.forceRefreshStatus()
}
```

### 3. 应用重新打开
```swift
func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    statusBarController?.showPreferences()
    return true
}
```

## 错误处理和日志

### 1. 异常处理
```swift
private func setupExceptionHandling() {
    NSSetUncaughtExceptionHandler { exception in
        print("未捕获的异常: \(exception)")
        print("调用栈: \(exception.callStackSymbols)")
    }
}
```

### 2. 日志系统
```swift
private func setupLogging() {
    // 配置日志系统
}
```

## 公共接口

### 1. 应用信息
```swift
var appInfo: [String: Any] {
    return [
        "name": Bundle.main.infoDictionary?["CFBundleName"] ?? "WiFiMenuBar",
        "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown",
        "build": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown",
        "identifier": Bundle.main.bundleIdentifier ?? "unknown",
        "startTime": appStartTime,
        "uptime": uptime,
        "state": appState.description
    ]
}
```

### 2. 健康检查
```swift
var isHealthy: Bool {
    guard let wifiMonitor = wifiMonitor,
          let statusBarController = statusBarController else {
        return false
    }
    
    return appState == .running || appState == .active
}
```

### 3. 状态刷新
```swift
func refreshAllStatus() {
    wifiMonitor?.forceRefreshStatus()
    statusBarController?.forceRefresh()
    preferencesManager.syncLaunchAtLoginStatus()
}
```

## 内存管理

### 1. 资源清理
```swift
private func cleanupResources() {
    NotificationCenter.default.removeObserver(self)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    
    wifiMonitor = nil
    statusBarController = nil
}
```

### 2. 弱引用使用
- 使用weak引用避免循环引用
- 在适当的时候清理资源
- 监听内存警告

## 测试覆盖

### 1. 单元测试
- **文件**: `WiFiMenuBarTests/AppDelegateTests.swift`
- **覆盖范围**:
  - 应用生命周期方法
  - 状态管理
  - 权限处理
  - 系统事件响应
  - 错误处理
  - 性能测试

### 2. 集成测试
- 组件初始化验证
- 组件间通信测试
- 首次运行流程测试

### 3. 边界情况测试
- 内存管理测试
- 异常情况处理
- 并发访问测试

## 性能考虑

### 1. 启动性能
- 延迟非关键初始化
- 异步执行耗时操作
- 缓存常用数据

### 2. 运行时性能
- 避免频繁的状态检查
- 使用适当的监控间隔
- 在系统睡眠时暂停监控

### 3. 内存使用
- 及时释放不需要的资源
- 使用弱引用避免循环引用
- 监控内存使用情况

## 扩展性

### 1. 添加新的生命周期处理
1. 在相应的生命周期方法中添加逻辑
2. 更新状态管理
3. 添加相应的测试

### 2. 集成新的系统服务
1. 在初始化方法中添加服务
2. 设置适当的通信机制
3. 处理服务的生命周期

### 3. 扩展权限管理
1. 添加新的权限检查方法
2. 更新权限请求流程
3. 处理权限变化

## 最佳实践

### 1. 生命周期管理
- 在适当的生命周期方法中执行相应操作
- 确保资源的正确初始化和清理
- 处理异常情况

### 2. 状态管理
- 保持状态的一致性
- 提供清晰的状态查询接口
- 在状态变化时执行必要的操作

### 3. 错误处理
- 捕获和记录异常
- 提供恢复机制
- 向用户提供有用的错误信息

## 调试和故障排除

### 1. 日志记录
- 记录关键操作和状态变化
- 包含足够的上下文信息
- 使用适当的日志级别

### 2. 状态检查
- 提供应用健康检查接口
- 监控关键组件状态
- 提供诊断信息

### 3. 恢复机制
- 在组件失败时尝试重新初始化
- 提供手动刷新功能
- 保存和恢复应用状态

## 总结

AppDelegate实现提供了：
- 完整的应用生命周期管理
- 核心组件的初始化和协调
- 系统集成和权限管理
- 错误处理和恢复机制
- 性能优化和资源管理
- 全面的测试覆盖

该实现满足了任务6.1的所有要求，为WiFi菜单栏应用提供了稳定可靠的应用框架。