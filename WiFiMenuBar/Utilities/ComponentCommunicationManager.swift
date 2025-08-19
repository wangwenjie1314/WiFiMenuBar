import Foundation
import Combine

/// 组件间通信管理器
/// 负责协调应用内各组件之间的数据流和通信
class ComponentCommunicationManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = ComponentCommunicationManager()
    
    // MARK: - Publishers
    
    /// WiFi状态变化发布者
    @Published var currentWiFiStatus: WiFiStatus = .unknown
    
    /// 网络连接状态发布者
    @Published var isNetworkConnected: Bool = false
    
    /// 当前连接的网络发布者
    @Published var currentNetwork: WiFiNetwork?
    
    /// 偏好设置变化发布者
    @Published var currentPreferences: AppPreferences = AppPreferences()
    
    /// 应用状态发布者
    @Published var appState: AppState = .launching
    
    /// 错误状态发布者
    @Published var lastError: WiFiMonitorError?
    
    /// 通知状态发布者
    @Published var notificationPermissionStatus: NotificationPermissionStatus = .unknown
    
    // MARK: - Private Properties
    
    /// Combine订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 数据流历史记录
    private var dataFlowHistory: [DataFlowEvent] = []
    
    /// 最大历史记录数量
    private let maxHistoryCount = 100
    
    /// 通信统计
    private var communicationStats = CommunicationStats()
    
    // MARK: - Initialization
    
    private init() {
        print("ComponentCommunicationManager: 初始化组件通信管理器")
        setupDataFlowLogging()
        loadInitialState()
    }
    
    // MARK: - Public Methods
    
    /// 更新WiFi状态
    /// - Parameter status: 新的WiFi状态
    func updateWiFiStatus(_ status: WiFiStatus) {
        guard status != currentWiFiStatus else { return }
        
        let oldStatus = currentWiFiStatus
        currentWiFiStatus = status
        
        // 更新相关状态
        updateNetworkConnectionStatus(from: status)
        updateCurrentNetwork(from: status)
        
        // 记录数据流事件
        recordDataFlowEvent(.wifiStatusChanged(from: oldStatus, to: status))
        
        // 发送通知
        sendWiFiStatusChangeNotification(from: oldStatus, to: status)
        
        print("ComponentCommunicationManager: WiFi状态已更新 - \(oldStatus.shortDescription) -> \(status.shortDescription)")
    }
    
    /// 更新偏好设置
    /// - Parameter preferences: 新的偏好设置
    func updatePreferences(_ preferences: AppPreferences) {
        guard preferences != currentPreferences else { return }
        
        let oldPreferences = currentPreferences
        currentPreferences = preferences
        
        // 记录数据流事件
        recordDataFlowEvent(.preferencesChanged(from: oldPreferences, to: preferences))
        
        // 发送通知
        sendPreferencesChangeNotification(from: oldPreferences, to: preferences)
        
        print("ComponentCommunicationManager: 偏好设置已更新")
    }
    
    /// 更新应用状态
    /// - Parameter state: 新的应用状态
    func updateAppState(_ state: AppState) {
        guard state != appState else { return }
        
        let oldState = appState
        appState = state
        
        // 记录数据流事件
        recordDataFlowEvent(.appStateChanged(from: oldState, to: state))
        
        print("ComponentCommunicationManager: 应用状态已更新 - \(oldState.description) -> \(state.description)")
    }
    
    /// 更新错误状态
    /// - Parameter error: 错误信息
    func updateError(_ error: WiFiMonitorError?) {
        lastError = error
        
        if let error = error {
            recordDataFlowEvent(.errorOccurred(error))
            sendErrorNotification(error)
            print("ComponentCommunicationManager: 错误状态已更新 - \(error.localizedDescription)")
        }
    }
    
    /// 更新通知权限状态
    /// - Parameter status: 通知权限状态
    func updateNotificationPermissionStatus(_ status: NotificationPermissionStatus) {
        guard status != notificationPermissionStatus else { return }
        
        let oldStatus = notificationPermissionStatus
        notificationPermissionStatus = status
        
        recordDataFlowEvent(.notificationPermissionChanged(from: oldStatus, to: status))
        
        print("ComponentCommunicationManager: 通知权限状态已更新 - \(oldStatus) -> \(status)")
    }
    
    /// 获取通信统计信息
    /// - Returns: 通信统计数据
    func getCommunicationStats() -> CommunicationStats {
        return communicationStats
    }
    
    /// 获取数据流历史
    /// - Returns: 数据流事件历史
    func getDataFlowHistory() -> [DataFlowEvent] {
        return Array(dataFlowHistory.suffix(50)) // 返回最近50个事件
    }
    
    /// 清除历史记录
    func clearHistory() {
        dataFlowHistory.removeAll()
        communicationStats = CommunicationStats()
        print("ComponentCommunicationManager: 历史记录已清除")
    }
    
    /// 重置所有状态
    func resetAllStates() {
        currentWiFiStatus = .unknown
        isNetworkConnected = false
        currentNetwork = nil
        lastError = nil
        notificationPermissionStatus = .unknown
        
        clearHistory()
        
        print("ComponentCommunicationManager: 所有状态已重置")
    }
    
    // MARK: - Private Methods
    
    /// 设置数据流日志记录
    private func setupDataFlowLogging() {
        // 监听WiFi状态变化
        $currentWiFiStatus
            .sink { [weak self] status in
                self?.communicationStats.wifiStatusUpdateCount += 1
            }
            .store(in: &cancellables)
        
        // 监听偏好设置变化
        $currentPreferences
            .sink { [weak self] preferences in
                self?.communicationStats.preferencesUpdateCount += 1
            }
            .store(in: &cancellables)
        
        // 监听应用状态变化
        $appState
            .sink { [weak self] state in
                self?.communicationStats.appStateUpdateCount += 1
            }
            .store(in: &cancellables)
    }
    
    /// 加载初始状态
    private func loadInitialState() {
        // 从PreferencesManager加载偏好设置
        currentPreferences = PreferencesManager.shared.getCurrentPreferences()
        
        // 检查通知权限状态
        checkNotificationPermissionStatus()
    }
    
    /// 更新网络连接状态
    /// - Parameter status: WiFi状态
    private func updateNetworkConnectionStatus(from status: WiFiStatus) {
        let wasConnected = isNetworkConnected
        
        switch status {
        case .connected:
            isNetworkConnected = true
        case .disconnected, .disabled, .error:
            isNetworkConnected = false
        default:
            break
        }
        
        if wasConnected != isNetworkConnected {
            recordDataFlowEvent(.networkConnectionChanged(connected: isNetworkConnected))
        }
    }
    
    /// 更新当前网络信息
    /// - Parameter status: WiFi状态
    private func updateCurrentNetwork(from status: WiFiStatus) {
        switch status {
        case .connected(let network):
            currentNetwork = network
        case .disconnected, .disabled, .error:
            currentNetwork = nil
        default:
            break
        }
    }
    
    /// 记录数据流事件
    /// - Parameter event: 数据流事件
    private func recordDataFlowEvent(_ event: DataFlowEvent) {
        dataFlowHistory.append(event)
        
        // 限制历史记录数量
        if dataFlowHistory.count > maxHistoryCount {
            dataFlowHistory.removeFirst(dataFlowHistory.count - maxHistoryCount)
        }
        
        // 更新统计
        communicationStats.totalEventCount += 1
        communicationStats.lastEventTime = Date()
    }
    
    /// 发送WiFi状态变化通知
    /// - Parameters:
    ///   - oldStatus: 旧状态
    ///   - newStatus: 新状态
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
    
    /// 发送偏好设置变化通知
    /// - Parameters:
    ///   - oldPreferences: 旧偏好设置
    ///   - newPreferences: 新偏好设置
    private func sendPreferencesChangeNotification(from oldPreferences: AppPreferences, to newPreferences: AppPreferences) {
        let userInfo: [String: Any] = [
            "oldPreferences": oldPreferences,
            "newPreferences": newPreferences,
            "timestamp": Date()
        ]
        
        NotificationCenter.default.post(
            name: .preferencesDidChange,
            object: self,
            userInfo: userInfo
        )
    }
    
    /// 发送错误通知
    /// - Parameter error: 错误信息
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
    
    /// 检查通知权限状态
    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                let status = NotificationPermissionStatus(from: settings.authorizationStatus)
                self?.updateNotificationPermissionStatus(status)
            }
        }
    }
}

// MARK: - Supporting Types

/// 数据流事件
enum DataFlowEvent {
    case wifiStatusChanged(from: WiFiStatus, to: WiFiStatus)
    case preferencesChanged(from: AppPreferences, to: AppPreferences)
    case appStateChanged(from: AppState, to: AppState)
    case networkConnectionChanged(connected: Bool)
    case errorOccurred(WiFiMonitorError)
    case notificationPermissionChanged(from: NotificationPermissionStatus, to: NotificationPermissionStatus)
    
    var timestamp: Date {
        return Date()
    }
    
    var description: String {
        switch self {
        case .wifiStatusChanged(let from, let to):
            return "WiFi状态变化: \(from.shortDescription) -> \(to.shortDescription)"
        case .preferencesChanged:
            return "偏好设置变化"
        case .appStateChanged(let from, let to):
            return "应用状态变化: \(from.description) -> \(to.description)"
        case .networkConnectionChanged(let connected):
            return "网络连接变化: \(connected ? "已连接" : "已断开")"
        case .errorOccurred(let error):
            return "错误发生: \(error.localizedDescription)"
        case .notificationPermissionChanged(let from, let to):
            return "通知权限变化: \(from) -> \(to)"
        }
    }
}

/// 通信统计
struct CommunicationStats {
    var totalEventCount: Int = 0
    var wifiStatusUpdateCount: Int = 0
    var preferencesUpdateCount: Int = 0
    var appStateUpdateCount: Int = 0
    var errorCount: Int = 0
    var lastEventTime: Date?
    
    var description: String {
        return """
        通信统计:
        - 总事件数: \(totalEventCount)
        - WiFi状态更新: \(wifiStatusUpdateCount)
        - 偏好设置更新: \(preferencesUpdateCount)
        - 应用状态更新: \(appStateUpdateCount)
        - 错误数量: \(errorCount)
        - 最后事件时间: \(lastEventTime?.description ?? "无")
        """
    }
}

/// 通知权限状态
enum NotificationPermissionStatus {
    case unknown
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    
    init(from authorizationStatus: UNAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .provisional:
            self = .provisional
        case .ephemeral:
            self = .ephemeral
        @unknown default:
            self = .unknown
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let wifiStatusDidChange = Notification.Name("wifiStatusDidChange")
    static let preferencesDidChange = Notification.Name("preferencesDidChange")
    static let wifiErrorOccurred = Notification.Name("wifiErrorOccurred")
    static let networkConnectionDidChange = Notification.Name("networkConnectionDidChange")
}