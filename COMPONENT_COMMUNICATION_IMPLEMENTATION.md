# 组件间通信和数据流实现文档

## 概述

本文档描述了WiFi菜单栏应用的组件间通信和数据流实现，包括通信管理器、数据流监控和组件协调机制。

## 实现的组件

### 1. ComponentCommunicationManager
- **文件**: `Utilities/ComponentCommunicationManager.swift`
- **功能**: 中央化的组件间通信管理器
- **特性**:
  - 单例模式，确保全局唯一的通信中心
  - 使用Combine框架实现响应式数据流
  - 自动记录数据流历史和统计信息
  - 支持通知机制和事件分发

### 2. 核心功能

#### 状态管理
```swift
@Published var currentWiFiStatus: WiFiStatus = .unknown
@Published var isNetworkConnected: Bool = false
@Published var currentNetwork: WiFiNetwork?
@Published var currentPreferences: AppPreferences = AppPreferences()
@Published var appState: AppState = .launching
@Published var lastError: WiFiMonitorError?
```

#### 数据流记录
```swift
func updateWiFiStatus(_ status: WiFiStatus)
func updatePreferences(_ preferences: AppPreferences)
func updateAppState(_ state: AppState)
func updateError(_ error: WiFiMonitorError?)
```

#### 历史和统计
```swift
func getDataFlowHistory() -> [DataFlowEvent]
func getCommunicationStats() -> CommunicationStats
func clearHistory()
func resetAllStates()
```

### 3. 数据流事件类型

#### DataFlowEvent枚举
```swift
enum DataFlowEvent {
    case wifiStatusChanged(from: WiFiStatus, to: WiFiStatus)
    case preferencesChanged(from: AppPreferences, to: AppPreferences)
    case appStateChanged(from: AppState, to: AppState)
    case networkConnectionChanged(connected: Bool)
    case errorOccurred(WiFiMonitorError)
    case notificationPermissionChanged(from: NotificationPermissionStatus, to: NotificationPermissionStatus)
}
```

#### 通信统计
```swift
struct CommunicationStats {
    var totalEventCount: Int = 0
    var wifiStatusUpdateCount: Int = 0
    var preferencesUpdateCount: Int = 0
    var appStateUpdateCount: Int = 0
    var errorCount: Int = 0
    var lastEventTime: Date?
}
```

## 组件集成

### 1. WiFiMonitor集成
```swift
// 在状态变化时更新通信管理器
private var currentStatus: WiFiStatus = .unknown {
    didSet {
        if currentStatus != oldValue {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 更新通信管理器
                ComponentCommunicationManager.shared.updateWiFiStatus(self.currentStatus)
                
                // 通知委托
                self.delegate?.wifiStatusDidChange(self.currentStatus)
            }
        }
    }
}

// 在错误处理时更新通信管理器
private func handleError(_ error: WiFiMonitorError) {
    ComponentCommunicationManager.shared.updateError(error)
    // ... 其他错误处理逻辑
}
```

### 2. PreferencesManager集成
```swift
func updatePreferences(_ newPreferences: AppPreferences) {
    guard newPreferences != preferences else { return }
    
    // 更新通信管理器
    ComponentCommunicationManager.shared.updatePreferences(newPreferences)
    
    preferences = newPreferences
}
```

### 3. AppDelegate集成
```swift
private var appState: AppState = .launching {
    didSet {
        if appState != oldValue {
            ComponentCommunicationManager.shared.updateAppState(appState)
        }
    }
}
```

## 数据流监控

### 1. DataFlowMonitorView
- **文件**: `Views/DataFlowMonitorView.swift`
- **功能**: 可视化数据流和组件间通信
- **特性**:
  - 实时显示数据流历史
  - 通信统计信息展示
  - 当前状态监控
  - 事件详情查看
  - 数据导出功能

### 2. 监控界面组件

#### 数据流历史视图
```swift
private var dataFlowHistoryView: some View {
    ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(Array(dataFlowHistory.enumerated().reversed()), id: \.offset) { index, event in
                DataFlowEventRow(
                    event: event,
                    index: dataFlowHistory.count - index,
                    isSelected: selectedEvent?.description == event.description
                ) {
                    selectedEvent = event
                }
            }
        }
    }
}
```

#### 统计信息视图
```swift
private var statisticsView: some View {
    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
        GridRow {
            Text("总事件数:")
            Text("\(communicationStats.totalEventCount)")
        }
        // ... 其他统计项
    }
}
```

#### 当前状态视图
```swift
private var currentStatusView: some View {
    VStack(alignment: .leading, spacing: 8) {
        StatusRow(
            label: "WiFi状态",
            value: communicationManager.currentWiFiStatus.shortDescription,
            color: statusColor(for: communicationManager.currentWiFiStatus)
        )
        // ... 其他状态项
    }
}
```

### 3. 数据导出功能
```swift
private func exportData() {
    let exportData = DataFlowExportData(
        history: dataFlowHistory,
        statistics: communicationStats,
        currentStatus: DataFlowCurrentStatus(...),
        exportTime: Date()
    )
    
    let jsonData = try JSONEncoder().encode(exportData)
    try jsonData.write(to: url)
}
```

## 通知机制

### 1. 自定义通知名称
```swift
extension Notification.Name {
    static let wifiStatusDidChange = Notification.Name("wifiStatusDidChange")
    static let preferencesDidChange = Notification.Name("preferencesDidChange")
    static let wifiErrorOccurred = Notification.Name("wifiErrorOccurred")
    static let networkConnectionDidChange = Notification.Name("networkConnectionDidChange")
}
```

### 2. 通知发送
```swift
private func sendWiFiStatusChangeNotification(from oldStatus: WiFiStatus, to newStatus: WiFiStatus) {
    let userInfo: [String: Any] = [
        "oldStatus": oldStatus,
        "newStatus": newStatus,
        "timestamp": Date()
    ]
    
    NotificationCenter.default.post(
        name: .wifiStatusDidChange,
        object: self,
        userInfo: userInfo
    )
}
```

### 3. 通知监听
```swift
// 在组件中监听通知
NotificationCenter.default.addObserver(
    forName: .wifiStatusDidChange,
    object: nil,
    queue: .main
) { notification in
    // 处理通知
}
```

## Combine响应式编程

### 1. Publisher设置
```swift
// 使用@Published属性包装器创建Publisher
@Published var currentWiFiStatus: WiFiStatus = .unknown
@Published var currentPreferences: AppPreferences = AppPreferences()
```

### 2. 订阅和响应
```swift
// 在视图中订阅状态变化
@ObservedObject private var communicationManager = ComponentCommunicationManager.shared

// 在代码中订阅
communicationManager.$currentWiFiStatus
    .sink { status in
        // 响应状态变化
    }
    .store(in: &cancellables)
```

### 3. 数据流日志记录
```swift
private func setupDataFlowLogging() {
    // 监听WiFi状态变化
    $currentWiFiStatus
        .sink { [weak self] status in
            self?.communicationStats.wifiStatusUpdateCount += 1
        }
        .store(in: &cancellables)
}
```

## 性能优化

### 1. 历史记录限制
```swift
private func recordDataFlowEvent(_ event: DataFlowEvent) {
    dataFlowHistory.append(event)
    
    // 限制历史记录数量
    if dataFlowHistory.count > maxHistoryCount {
        dataFlowHistory.removeFirst(dataFlowHistory.count - maxHistoryCount)
    }
}
```

### 2. 状态变化检测
```swift
func updateWiFiStatus(_ status: WiFiStatus) {
    guard status != currentWiFiStatus else { return } // 避免重复更新
    
    let oldStatus = currentWiFiStatus
    currentWiFiStatus = status
    // ... 处理变化
}
```

### 3. 异步处理
```swift
DispatchQueue.main.async { [weak self] in
    // 在主线程更新UI相关状态
    self?.delegate?.wifiStatusDidChange(self.currentStatus)
}
```

## 错误处理

### 1. 错误状态管理
```swift
func updateError(_ error: WiFiMonitorError?) {
    lastError = error
    
    if let error = error {
        recordDataFlowEvent(.errorOccurred(error))
        sendErrorNotification(error)
    }
}
```

### 2. 错误通知
```swift
private func sendErrorNotification(_ error: WiFiMonitorError) {
    let userInfo: [String: Any] = [
        "error": error,
        "timestamp": Date()
    ]
    
    NotificationCenter.default.post(
        name: .wifiErrorOccurred,
        object: self,
        userInfo: userInfo
    )
}
```

## 测试覆盖

### 1. 单元测试
- **文件**: `WiFiMenuBarTests/Utilities/ComponentCommunicationManagerTests.swift`
- **覆盖范围**:
  - 单例模式验证
  - 状态更新功能
  - 通知机制
  - 数据流历史记录
  - 统计信息准确性
  - 性能测试
  - 并发访问测试

### 2. 集成测试
- 组件间通信验证
- 数据流完整性测试
- 通知传递测试

### 3. 性能测试
```swift
func testUpdatePerformance() {
    measure {
        for _ in 0..<100 {
            communicationManager.updateWiFiStatus(.connected(testNetwork))
            communicationManager.updateWiFiStatus(.disconnected)
        }
    }
}
```

## 使用方式

### 1. 获取通信管理器实例
```swift
let communicationManager = ComponentCommunicationManager.shared
```

### 2. 更新状态
```swift
// 更新WiFi状态
communicationManager.updateWiFiStatus(.connected(network))

// 更新偏好设置
communicationManager.updatePreferences(newPreferences)

// 更新应用状态
communicationManager.updateAppState(.running)
```

### 3. 监听状态变化
```swift
// 使用Combine
communicationManager.$currentWiFiStatus
    .sink { status in
        // 处理状态变化
    }
    .store(in: &cancellables)

// 使用通知
NotificationCenter.default.addObserver(
    forName: .wifiStatusDidChange,
    object: nil,
    queue: .main
) { notification in
    // 处理通知
}
```

### 4. 查看数据流信息
```swift
// 获取历史记录
let history = communicationManager.getDataFlowHistory()

// 获取统计信息
let stats = communicationManager.getCommunicationStats()

// 清除历史
communicationManager.clearHistory()
```

## 调试和监控

### 1. 数据流监控器
- 在高级设置中点击"数据流监控"按钮
- 实时查看组件间通信
- 分析数据流模式
- 导出调试数据

### 2. 日志记录
```swift
print("ComponentCommunicationManager: WiFi状态已更新 - \(oldStatus.shortDescription) -> \(status.shortDescription)")
```

### 3. 统计分析
- 监控事件频率
- 分析通信模式
- 识别性能瓶颈

## 扩展性

### 1. 添加新的状态类型
1. 在ComponentCommunicationManager中添加新的@Published属性
2. 创建对应的更新方法
3. 添加到DataFlowEvent枚举中
4. 更新统计和历史记录逻辑

### 2. 集成新组件
1. 在新组件中调用通信管理器的更新方法
2. 监听相关的状态变化
3. 添加必要的通知处理

### 3. 扩展监控功能
1. 在DataFlowMonitorView中添加新的视图
2. 扩展导出数据格式
3. 添加新的分析功能

## 最佳实践

### 1. 状态管理
- 使用单一数据源原则
- 避免状态重复和不一致
- 及时清理不需要的历史数据

### 2. 性能优化
- 限制历史记录数量
- 避免频繁的状态更新
- 使用适当的队列处理异步操作

### 3. 错误处理
- 记录所有重要的错误事件
- 提供详细的错误信息
- 实现适当的恢复机制

## 总结

组件间通信和数据流实现提供了：
- 中央化的状态管理
- 响应式的数据流
- 完整的历史记录和统计
- 可视化的监控工具
- 灵活的通知机制
- 全面的测试覆盖

该实现满足了任务6.2的所有要求，为应用提供了强大而灵活的组件间通信基础设施。