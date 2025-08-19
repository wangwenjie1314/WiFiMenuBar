import Foundation
import UserNotifications
import CoreWLAN
import SystemConfiguration

/// 权限管理器
/// 负责管理应用所需的各种系统权限
class PermissionManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = PermissionManager()
    
    // MARK: - Published Properties
    
    /// 通知权限状态
    @Published var notificationPermissionStatus: PermissionStatus = .unknown
    
    /// 网络权限状态
    @Published var networkPermissionStatus: PermissionStatus = .unknown
    
    /// WiFi权限状态
    @Published var wifiPermissionStatus: PermissionStatus = .unknown
    
    /// 位置权限状态（WiFi扫描可能需要）
    @Published var locationPermissionStatus: PermissionStatus = .unknown
    
    /// 全屏控制权限状态（macOS 10.15+）
    @Published var screenRecordingPermissionStatus: PermissionStatus = .unknown
    
    /// 辅助功能权限状态
    @Published var accessibilityPermissionStatus: PermissionStatus = .unknown
    
    // MARK: - Private Properties
    
    /// 权限检查定时器
    private var permissionCheckTimer: Timer?
    
    /// 权限状态缓存
    private var permissionCache: [PermissionType: (status: PermissionStatus, timestamp: Date)] = [:]
    
    /// 缓存有效期（秒）
    private let cacheValidityDuration: TimeInterval = 30.0
    
    /// 权限请求历史
    private var permissionRequestHistory: [PermissionRequestRecord] = []
    
    // MARK: - Initialization
    
    private init() {
        print("PermissionManager: 初始化权限管理器")
        startPeriodicPermissionCheck()
        checkAllPermissions()
    }
    
    deinit {
        stopPeriodicPermissionCheck()
    }
    
    // MARK: - Public Methods
    
    /// 检查所有权限状态
    func checkAllPermissions() {
        print("PermissionManager: 检查所有权限状态")
        
        checkNotificationPermission()
        checkNetworkPermission()
        checkWiFiPermission()
        checkLocationPermission()
        checkScreenRecordingPermission()
        checkAccessibilityPermission()
    }
    
    /// 请求所有必要权限
    /// - Parameter completion: 完成回调，返回是否所有权限都已授予
    func requestAllRequiredPermissions(completion: @escaping (Bool) -> Void) {
        print("PermissionManager: 请求所有必要权限")
        
        let group = DispatchGroup()
        var allGranted = true
        
        // 请求通知权限
        group.enter()
        requestNotificationPermission { granted in
            if !granted { allGranted = false }
            group.leave()
        }
        
        // 检查其他权限（这些通常不需要显式请求）
        checkNetworkPermission()
        checkWiFiPermission()
        checkLocationPermission()
        
        group.notify(queue: .main) {
            completion(allGranted)
        }
    }
    
    /// 获取权限状态摘要
    /// - Returns: 权限状态摘要
    func getPermissionSummary() -> PermissionSummary {
        return PermissionSummary(
            notificationPermission: notificationPermissionStatus,
            networkPermission: networkPermissionStatus,
            wifiPermission: wifiPermissionStatus,
            locationPermission: locationPermissionStatus,
            screenRecordingPermission: screenRecordingPermissionStatus,
            accessibilityPermission: accessibilityPermissionStatus,
            allRequiredGranted: areAllRequiredPermissionsGranted(),
            lastCheckTime: Date()
        )
    }
    
    /// 检查是否所有必需权限都已授予
    /// - Returns: 是否所有必需权限都已授予
    func areAllRequiredPermissionsGranted() -> Bool {
        // 必需权限：通知权限和网络权限
        return notificationPermissionStatus == .granted &&
               networkPermissionStatus == .granted
    }
    
    /// 获取缺失的权限列表
    /// - Returns: 缺失的权限类型数组
    func getMissingPermissions() -> [PermissionType] {
        var missingPermissions: [PermissionType] = []
        
        if notificationPermissionStatus != .granted {
            missingPermissions.append(.notification)
        }
        
        if networkPermissionStatus != .granted {
            missingPermissions.append(.network)
        }
        
        if wifiPermissionStatus != .granted {
            missingPermissions.append(.wifi)
        }
        
        return missingPermissions
    }
    
    /// 打开系统偏好设置到相应权限页面
    /// - Parameter permissionType: 权限类型
    func openSystemPreferencesForPermission(_ permissionType: PermissionType) {
        print("PermissionManager: 打开系统偏好设置 - \(permissionType)")
        
        let url: String
        
        switch permissionType {
        case .notification:
            url = "x-apple.systempreferences:com.apple.preference.notifications"
        case .network:
            url = "x-apple.systempreferences:com.apple.preference.network"
        case .wifi:
            url = "x-apple.systempreferences:com.apple.preference.network"
        case .location:
            url = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        case .screenRecording:
            url = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .accessibility:
            url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
        
        if let settingsURL = URL(string: url) {
            NSWorkspace.shared.open(settingsURL)
        }
    }
    
    /// 显示权限请求对话框
    /// - Parameters:
    ///   - permissionType: 权限类型
    ///   - completion: 完成回调
    func showPermissionRequestDialog(for permissionType: PermissionType, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = self.getPermissionRequestTitle(for: permissionType)
            alert.informativeText = self.getPermissionRequestMessage(for: permissionType)
            alert.alertStyle = .informational
            alert.addButton(withTitle: "授予权限")
            alert.addButton(withTitle: "稍后")
            alert.addButton(withTitle: "打开系统偏好设置")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                // 授予权限
                self.requestSpecificPermission(permissionType, completion: completion)
            case .alertSecondButtonReturn:
                // 稍后
                completion(false)
            case .alertThirdButtonReturn:
                // 打开系统偏好设置
                self.openSystemPreferencesForPermission(permissionType)
                completion(false)
            default:
                completion(false)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 检查通知权限
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                let status = PermissionStatus(from: settings.authorizationStatus)
                self?.updatePermissionStatus(.notification, status: status)
            }
        }
    }
    
    /// 请求通知权限
    /// - Parameter completion: 完成回调
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        recordPermissionRequest(.notification)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                let status: PermissionStatus = granted ? .granted : .denied
                self?.updatePermissionStatus(.notification, status: status)
                
                if let error = error {
                    print("PermissionManager: 通知权限请求失败: \(error.localizedDescription)")
                }
                
                completion(granted)
            }
        }
    }
    
    /// 检查网络权限
    private func checkNetworkPermission() {
        // 通过尝试创建网络连接来检查网络权限
        let status: PermissionStatus
        
        // 检查网络可达性
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            status = .denied
            updatePermissionStatus(.network, status: status)
            return
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            status = flags.contains(.reachable) ? .granted : .denied
        } else {
            status = .denied
        }
        
        updatePermissionStatus(.network, status: status)
    }
    
    /// 检查WiFi权限
    private func checkWiFiPermission() {
        let status: PermissionStatus
        
        do {
            let wifiClient = CWWiFiClient.shared()
            if let interface = wifiClient.interface() {
                // 尝试获取当前网络信息
                let _ = interface.ssid()
                status = .granted
            } else {
                status = .denied
            }
        } catch {
            status = .denied
        }
        
        updatePermissionStatus(.wifi, status: status)
    }
    
    /// 检查位置权限
    private func checkLocationPermission() {
        // macOS上WiFi扫描可能需要位置权限
        let status: PermissionStatus = .notRequired // 大多数情况下不需要
        updatePermissionStatus(.location, status: status)
    }
    
    /// 检查屏幕录制权限
    private func checkScreenRecordingPermission() {
        // 对于WiFi菜单栏应用，通常不需要屏幕录制权限
        let status: PermissionStatus = .notRequired
        updatePermissionStatus(.screenRecording, status: status)
    }
    
    /// 检查辅助功能权限
    private func checkAccessibilityPermission() {
        // 对于WiFi菜单栏应用，通常不需要辅助功能权限
        let status: PermissionStatus = .notRequired
        updatePermissionStatus(.accessibility, status: status)
    }
    
    /// 请求特定权限
    /// - Parameters:
    ///   - permissionType: 权限类型
    ///   - completion: 完成回调
    private func requestSpecificPermission(_ permissionType: PermissionType, completion: @escaping (Bool) -> Void) {
        switch permissionType {
        case .notification:
            requestNotificationPermission(completion: completion)
        case .network, .wifi, .location, .screenRecording, .accessibility:
            // 这些权限通常不能通过代码直接请求，需要用户手动在系统偏好设置中授予
            openSystemPreferencesForPermission(permissionType)
            completion(false)
        }
    }
    
    /// 更新权限状态
    /// - Parameters:
    ///   - permissionType: 权限类型
    ///   - status: 新状态
    private func updatePermissionStatus(_ permissionType: PermissionType, status: PermissionStatus) {
        // 更新缓存
        permissionCache[permissionType] = (status: status, timestamp: Date())
        
        // 更新对应的Published属性
        switch permissionType {
        case .notification:
            if notificationPermissionStatus != status {
                notificationPermissionStatus = status
                print("PermissionManager: 通知权限状态更新为 \(status)")
            }
        case .network:
            if networkPermissionStatus != status {
                networkPermissionStatus = status
                print("PermissionManager: 网络权限状态更新为 \(status)")
            }
        case .wifi:
            if wifiPermissionStatus != status {
                wifiPermissionStatus = status
                print("PermissionManager: WiFi权限状态更新为 \(status)")
            }
        case .location:
            if locationPermissionStatus != status {
                locationPermissionStatus = status
                print("PermissionManager: 位置权限状态更新为 \(status)")
            }
        case .screenRecording:
            if screenRecordingPermissionStatus != status {
                screenRecordingPermissionStatus = status
                print("PermissionManager: 屏幕录制权限状态更新为 \(status)")
            }
        case .accessibility:
            if accessibilityPermissionStatus != status {
                accessibilityPermissionStatus = status
                print("PermissionManager: 辅助功能权限状态更新为 \(status)")
            }
        }
        
        // 更新通信管理器
        ComponentCommunicationManager.shared.updateNotificationPermissionStatus(
            NotificationPermissionStatus(from: notificationPermissionStatus)
        )
    }
    
    /// 开始定期权限检查
    private func startPeriodicPermissionCheck() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkAllPermissions()
        }
    }
    
    /// 停止定期权限检查
    private func stopPeriodicPermissionCheck() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
    
    /// 记录权限请求
    /// - Parameter permissionType: 权限类型
    private func recordPermissionRequest(_ permissionType: PermissionType) {
        let record = PermissionRequestRecord(
            permissionType: permissionType,
            requestTime: Date(),
            requestId: UUID()
        )
        
        permissionRequestHistory.append(record)
        
        // 限制历史记录数量
        if permissionRequestHistory.count > 100 {
            permissionRequestHistory.removeFirst(permissionRequestHistory.count - 100)
        }
    }
    
    /// 获取权限请求标题
    /// - Parameter permissionType: 权限类型
    /// - Returns: 标题文本
    private func getPermissionRequestTitle(for permissionType: PermissionType) -> String {
        switch permissionType {
        case .notification:
            return "需要通知权限"
        case .network:
            return "需要网络权限"
        case .wifi:
            return "需要WiFi权限"
        case .location:
            return "需要位置权限"
        case .screenRecording:
            return "需要屏幕录制权限"
        case .accessibility:
            return "需要辅助功能权限"
        }
    }
    
    /// 获取权限请求消息
    /// - Parameter permissionType: 权限类型
    /// - Returns: 消息文本
    private func getPermissionRequestMessage(for permissionType: PermissionType) -> String {
        switch permissionType {
        case .notification:
            return "WiFi菜单栏需要通知权限来向您发送网络状态变化的通知。这将帮助您及时了解WiFi连接状态。"
        case .network:
            return "WiFi菜单栏需要网络权限来监控WiFi连接状态。这是应用正常工作的必要权限。"
        case .wifi:
            return "WiFi菜单栏需要WiFi权限来获取当前连接的网络信息。这是应用核心功能所必需的。"
        case .location:
            return "WiFi菜单栏可能需要位置权限来扫描附近的WiFi网络。这是可选权限。"
        case .screenRecording:
            return "WiFi菜单栏需要屏幕录制权限来执行某些高级功能。"
        case .accessibility:
            return "WiFi菜单栏需要辅助功能权限来执行某些系统级操作。"
        }
    }
}

// MARK: - Supporting Types

/// 权限状态
enum PermissionStatus: String, CaseIterable {
    case unknown = "unknown"
    case notDetermined = "notDetermined"
    case denied = "denied"
    case granted = "granted"
    case notRequired = "notRequired"
    
    init(from authorizationStatus: UNAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized:
            self = .granted
        case .provisional:
            self = .granted
        case .ephemeral:
            self = .granted
        @unknown default:
            self = .unknown
        }
    }
    
    init(from notificationStatus: NotificationPermissionStatus) {
        switch notificationStatus {
        case .unknown:
            self = .unknown
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized, .provisional, .ephemeral:
            self = .granted
        }
    }
    
    var displayName: String {
        switch self {
        case .unknown:
            return "未知"
        case .notDetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .granted:
            return "已授予"
        case .notRequired:
            return "不需要"
        }
    }
    
    var color: NSColor {
        switch self {
        case .granted:
            return .systemGreen
        case .denied:
            return .systemRed
        case .notDetermined:
            return .systemOrange
        case .notRequired:
            return .systemGray
        case .unknown:
            return .systemGray
        }
    }
}

/// 权限类型
enum PermissionType: String, CaseIterable {
    case notification = "notification"
    case network = "network"
    case wifi = "wifi"
    case location = "location"
    case screenRecording = "screenRecording"
    case accessibility = "accessibility"
    
    var displayName: String {
        switch self {
        case .notification:
            return "通知"
        case .network:
            return "网络"
        case .wifi:
            return "WiFi"
        case .location:
            return "位置"
        case .screenRecording:
            return "屏幕录制"
        case .accessibility:
            return "辅助功能"
        }
    }
    
    var isRequired: Bool {
        switch self {
        case .notification, .network, .wifi:
            return true
        case .location, .screenRecording, .accessibility:
            return false
        }
    }
}

/// 权限摘要
struct PermissionSummary {
    let notificationPermission: PermissionStatus
    let networkPermission: PermissionStatus
    let wifiPermission: PermissionStatus
    let locationPermission: PermissionStatus
    let screenRecordingPermission: PermissionStatus
    let accessibilityPermission: PermissionStatus
    let allRequiredGranted: Bool
    let lastCheckTime: Date
    
    var description: String {
        return """
        权限状态摘要:
        - 通知权限: \(notificationPermission.displayName)
        - 网络权限: \(networkPermission.displayName)
        - WiFi权限: \(wifiPermission.displayName)
        - 位置权限: \(locationPermission.displayName)
        - 屏幕录制权限: \(screenRecordingPermission.displayName)
        - 辅助功能权限: \(accessibilityPermission.displayName)
        - 所有必需权限已授予: \(allRequiredGranted ? "是" : "否")
        - 最后检查时间: \(lastCheckTime)
        """
    }
}

/// 权限请求记录
struct PermissionRequestRecord {
    let permissionType: PermissionType
    let requestTime: Date
    let requestId: UUID
}

// MARK: - NotificationPermissionStatus Extension

extension NotificationPermissionStatus {
    init(from permissionStatus: PermissionStatus) {
        switch permissionStatus {
        case .unknown:
            self = .unknown
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .granted:
            self = .authorized
        case .notRequired:
            self = .unknown
        }
    }
}