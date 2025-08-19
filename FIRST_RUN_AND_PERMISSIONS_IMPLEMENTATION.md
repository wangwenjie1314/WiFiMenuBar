# 首次运行和权限管理实现文档

## 概述

本文档描述了WiFi菜单栏应用的首次运行流程和权限管理系统的实现，包括用户引导、权限请求和状态管理。

## 实现的组件

### 1. FirstRunManager（首次运行管理器）
- **文件**: `Utilities/FirstRunManager.swift`
- **功能**: 管理应用的首次运行流程和用户引导
- **特性**:
  - 单例模式确保全局唯一实例
  - 检测首次运行和版本更新
  - 提供完整的用户引导流程
  - 支持快速设置向导

### 2. PermissionManager（权限管理器）
- **文件**: `Utilities/PermissionManager.swift`
- **功能**: 管理应用所需的各种系统权限
- **特性**:
  - 响应式权限状态管理
  - 自动权限检查和更新
  - 权限请求对话框
  - 系统偏好设置集成

### 3. PermissionStatusView（权限状态视图）
- **文件**: `Views/PermissionStatusView.swift`
- **功能**: 可视化权限状态和管理界面
- **特性**:
  - 实时权限状态显示
  - 权限请求操作
  - 首次运行信息展示
  - 管理操作界面

## 首次运行流程

### 1. 首次运行检测
```swift
func isFirstRun() -> Bool {
    let hasLaunchedBefore = UserDefaults.standard.bool(forKey: firstRunKey)
    return !hasLaunchedBefore
}

func isFirstRunAfterUpdate() -> Bool {
    let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)
    return lastVersion != nil && lastVersion != currentVersion
}
```

### 2. 首次运行流程
```swift
func startFirstRunFlow(completion: @escaping (Bool) -> Void) {
    // 1. 显示欢迎界面
    showWelcomeScreen { welcomeCompleted in
        // 2. 请求权限
        self.requestInitialPermissions { permissionsGranted in
            // 3. 显示功能介绍
            self.showFeatureIntroduction { introCompleted in
                // 4. 设置默认偏好设置
                self.setupDefaultPreferences()
                
                // 5. 标记首次运行完成
                self.markFirstRunCompleted()
                
                completion(introCompleted)
            }
        }
    }
}
```

### 3. 版本更新流程
```swift
func startUpdateFlow(completion: @escaping (Bool) -> Void) {
    showUpdateWelcomeScreen { updateCompleted in
        self.updateVersionRecord()
        completion(updateCompleted)
    }
}
```

### 4. 快速设置向导
```swift
class QuickSetupWizard {
    func show(completion: @escaping (Bool) -> Void) {
        showStep1 { step1Result in  // 显示格式设置
            self.showStep2 { step2Result in  // 自动启动设置
                self.showStep3 { step3Result in  // 完成设置
                    completion(step3Result)
                }
            }
        }
    }
}
```

## 权限管理系统

### 1. 权限类型定义
```swift
enum PermissionType: String, CaseIterable {
    case notification = "notification"      // 通知权限（必需）
    case network = "network"               // 网络权限（必需）
    case wifi = "wifi"                     // WiFi权限（必需）
    case location = "location"             // 位置权限（可选）
    case screenRecording = "screenRecording" // 屏幕录制权限（可选）
    case accessibility = "accessibility"   // 辅助功能权限（可选）
}
```

### 2. 权限状态管理
```swift
enum PermissionStatus: String, CaseIterable {
    case unknown = "unknown"
    case notDetermined = "notDetermined"
    case denied = "denied"
    case granted = "granted"
    case notRequired = "notRequired"
}
```

### 3. 响应式权限状态
```swift
class PermissionManager: ObservableObject {
    @Published var notificationPermissionStatus: PermissionStatus = .unknown
    @Published var networkPermissionStatus: PermissionStatus = .unknown
    @Published var wifiPermissionStatus: PermissionStatus = .unknown
    // ... 其他权限状态
}
```

### 4. 权限检查和请求
```swift
func checkAllPermissions() {
    checkNotificationPermission()
    checkNetworkPermission()
    checkWiFiPermission()
    // ... 检查其他权限
}

func requestAllRequiredPermissions(completion: @escaping (Bool) -> Void) {
    let group = DispatchGroup()
    var allGranted = true
    
    // 请求通知权限
    group.enter()
    requestNotificationPermission { granted in
        if !granted { allGranted = false }
        group.leave()
    }
    
    group.notify(queue: .main) {
        completion(allGranted)
    }
}
```

## AppDelegate集成

### 1. 首次运行处理
```swift
private func handleFirstRunAndUpdates() {
    if firstRunManager.isFirstRun() {
        // 首次运行流程
        firstRunManager.startFirstRunFlow { success in
            self.completeApplicationLaunch()
        }
    } else if firstRunManager.isFirstRunAfterUpdate() {
        // 版本更新流程
        firstRunManager.startUpdateFlow { success in
            self.completeApplicationLaunch()
        }
    } else {
        // 正常启动
        completeApplicationLaunch()
    }
}
```

### 2. 权限管理集成
```swift
private func requestRequiredPermissions() {
    permissionManager.requestAllRequiredPermissions { allGranted in
        if allGranted {
            print("所有必要权限已授予")
        } else {
            self.showPermissionWarning()
        }
    }
}

private func checkPermissionsAndShowWarnings() {
    permissionManager.checkAllPermissions()
    
    let missingPermissions = permissionManager.getMissingPermissions()
    if !missingPermissions.isEmpty {
        showMissingPermissionsWarning(missingPermissions)
    }
}
```

## 用户界面集成

### 1. 权限状态视图
```swift
struct PermissionStatusView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        VStack {
            // 权限状态概览
            permissionOverviewSection
            
            // 详细权限状态
            detailedPermissionSection
            
            // 首次运行信息
            firstRunSection
            
            // 操作按钮
            actionButtonsSection
        }
    }
}
```

### 2. 权限行视图
```swift
struct PermissionRow: View {
    let type: PermissionType
    let status: PermissionStatus
    let isRequired: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(type.displayName)
                Text(status.displayName)
            }
            
            Spacer()
            
            if status != .granted && status != .notRequired {
                Button("请求权限") {
                    onRequest()
                }
            }
        }
    }
}
```

### 3. 首次运行信息视图
```swift
struct FirstRunInfoView: View {
    var body: some View {
        VStack(alignment: .leading) {
            let info = FirstRunManager.shared.getFirstRunInfo()
            
            InfoRow(label: "是否首次运行", value: info.isFirstRun ? "是" : "否")
            InfoRow(label: "当前版本", value: info.currentVersion)
            InfoRow(label: "首次运行已完成", value: info.firstRunCompleted ? "是" : "否")
            // ... 其他信息行
        }
    }
}
```

## 权限请求对话框

### 1. 权限请求对话框
```swift
func showPermissionRequestDialog(for permissionType: PermissionType, completion: @escaping (Bool) -> Void) {
    let alert = NSAlert()
    alert.messageText = getPermissionRequestTitle(for: permissionType)
    alert.informativeText = getPermissionRequestMessage(for: permissionType)
    alert.addButton(withTitle: "授予权限")
    alert.addButton(withTitle: "稍后")
    alert.addButton(withTitle: "打开系统偏好设置")
    
    let response = alert.runModal()
    // 处理用户响应
}
```

### 2. 系统偏好设置集成
```swift
func openSystemPreferencesForPermission(_ permissionType: PermissionType) {
    let url: String
    
    switch permissionType {
    case .notification:
        url = "x-apple.systempreferences:com.apple.preference.notifications"
    case .network:
        url = "x-apple.systempreferences:com.apple.preference.network"
    // ... 其他权限的URL
    }
    
    if let settingsURL = URL(string: url) {
        NSWorkspace.shared.open(settingsURL)
    }
}
```

## 数据持久化

### 1. 首次运行状态
```swift
private let firstRunKey = "HasLaunchedBefore"
private let lastVersionKey = "LastRunVersion"
private let firstRunCompletedKey = "FirstRunCompleted"

private func markFirstRunCompleted() {
    UserDefaults.standard.set(true, forKey: firstRunKey)
    UserDefaults.standard.set(true, forKey: firstRunCompletedKey)
    UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
    UserDefaults.standard.synchronize()
}
```

### 2. 权限状态缓存
```swift
private var permissionCache: [PermissionType: (status: PermissionStatus, timestamp: Date)] = [:]
private let cacheValidityDuration: TimeInterval = 30.0

private func updatePermissionStatus(_ permissionType: PermissionType, status: PermissionStatus) {
    permissionCache[permissionType] = (status: status, timestamp: Date())
    // 更新Published属性
}
```

## 通知和通信

### 1. 自定义通知
```swift
extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
}

// 在AppDelegate中监听
NotificationCenter.default.addObserver(
    self,
    selector: #selector(showPreferencesNotification),
    name: .showPreferences,
    object: nil
)
```

### 2. 与ComponentCommunicationManager集成
```swift
private func updatePermissionStatus(_ permissionType: PermissionType, status: PermissionStatus) {
    // 更新本地状态
    switch permissionType {
    case .notification:
        notificationPermissionStatus = status
    // ... 其他权限类型
    }
    
    // 更新通信管理器
    ComponentCommunicationManager.shared.updateNotificationPermissionStatus(
        NotificationPermissionStatus(from: status)
    )
}
```

## 错误处理和恢复

### 1. 权限请求失败处理
```swift
private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        DispatchQueue.main.async {
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
                // 记录错误并提供恢复建议
            }
            
            completion(granted)
        }
    }
}
```

### 2. 首次运行流程中断处理
```swift
func startFirstRunFlow(completion: @escaping (Bool) -> Void) {
    showWelcomeScreen { welcomeCompleted in
        guard welcomeCompleted else {
            // 用户取消了欢迎界面
            completion(false)
            return
        }
        
        // 继续后续流程
    }
}
```

## 测试覆盖

### 1. 单元测试
- **文件**: `WiFiMenuBarTests/Utilities/PermissionManagerTests.swift`
- **覆盖范围**:
  - 权限状态检查和更新
  - 权限请求流程
  - 系统偏好设置集成
  - 权限状态枚举和转换
  - 性能测试和并发访问

### 2. 首次运行测试
- 首次运行检测逻辑
- 版本更新检测
- 首次运行流程执行
- 状态重置功能

### 3. 集成测试
- AppDelegate集成验证
- 用户界面响应测试
- 通知机制测试

## 性能优化

### 1. 权限检查优化
```swift
private var permissionCheckTimer: Timer?

private func startPeriodicPermissionCheck() {
    permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
        self.checkAllPermissions()
    }
}
```

### 2. 缓存机制
```swift
private func updatePermissionStatus(_ permissionType: PermissionType, status: PermissionStatus) {
    // 检查缓存是否有效
    if let cached = permissionCache[permissionType],
       Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration,
       cached.status == status {
        return // 使用缓存，避免重复更新
    }
    
    // 更新缓存和状态
    permissionCache[permissionType] = (status: status, timestamp: Date())
}
```

## 用户体验优化

### 1. 渐进式权限请求
- 只在需要时请求权限
- 提供清晰的权限说明
- 支持稍后请求选项

### 2. 智能提醒
- 避免重复提醒
- 提供"不再提醒"选项
- 在合适的时机显示提醒

### 3. 优雅降级
- 权限被拒绝时提供替代方案
- 保持核心功能可用
- 提供手动设置入口

## 扩展性

### 1. 添加新权限类型
1. 在`PermissionType`枚举中添加新类型
2. 在`PermissionManager`中添加检查方法
3. 更新UI显示和请求逻辑
4. 添加相应的测试

### 2. 自定义首次运行流程
1. 扩展`FirstRunManager`的流程方法
2. 添加新的引导步骤
3. 更新UI和用户交互
4. 保持向后兼容性

### 3. 集成新的系统API
1. 添加新的权限检查方法
2. 更新系统偏好设置URL
3. 处理新的权限状态
4. 更新文档和测试

## 最佳实践

### 1. 权限管理
- 最小权限原则
- 清晰的权限说明
- 优雅的权限处理
- 定期权限检查

### 2. 用户引导
- 简洁明了的介绍
- 渐进式信息披露
- 可跳过的非关键步骤
- 保存用户选择

### 3. 错误处理
- 详细的错误日志
- 用户友好的错误信息
- 提供恢复建议
- 优雅的降级方案

## 总结

首次运行和权限管理实现提供了：
- 完整的用户引导流程
- 全面的权限管理系统
- 响应式的状态管理
- 用户友好的界面
- 智能的权限请求策略
- 完善的错误处理机制
- 全面的测试覆盖

该实现满足了任务6.3的所有要求，为用户提供了流畅的首次使用体验和可靠的权限管理功能。