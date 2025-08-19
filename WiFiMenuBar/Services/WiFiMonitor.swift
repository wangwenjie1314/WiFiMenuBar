import Foundation
import CoreWLAN
import Network

/// WiFi监控器委托协议
/// 用于通知WiFi状态变化
protocol WiFiMonitorDelegate: AnyObject {
    /// WiFi连接到新网络时调用
    /// - Parameter network: 连接的网络信息
    func wifiDidConnect(to network: WiFiNetwork)
    
    /// WiFi断开连接时调用
    func wifiDidDisconnect()
    
    /// WiFi状态发生变化时调用
    /// - Parameter status: 新的WiFi状态
    func wifiStatusDidChange(_ status: WiFiStatus)
}

/// WiFi监控器
/// 负责监控WiFi连接状态变化并获取网络信息
class WiFiMonitor: NSObject {
    
    // MARK: - Properties
    
    /// 委托对象
    weak var delegate: WiFiMonitorDelegate?
    
    /// CoreWLAN WiFi客户端
    private var wifiClient: CWWiFiClient?
    
    /// 当前WiFi接口
    private var wifiInterface: CWInterface?
    
    /// 网络路径监控器
    private var pathMonitor: NWPathMonitor?
    
    /// 监控队列
    private let monitorQueue = DispatchQueue(label: "com.wifimenubar.monitor", qos: .utility)
    
    /// 当前WiFi状态
    private var currentStatus: WiFiStatus = .unknown {
        didSet {
            if currentStatus != oldValue {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // 更新通信管理器
                    ComponentCommunicationManager.shared.updateWiFiStatus(self.currentStatus)
                    
                    // 通知委托
                    self.delegate?.wifiStatusDidChange(self.currentStatus)
                    
                    // 发送特定的连接/断开通知
                    switch self.currentStatus {
                    case .connected(let network):
                        self.delegate?.wifiDidConnect(to: network)
                    case .disconnected:
                        self.delegate?.wifiDidDisconnect()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// 是否正在监控
    private var isMonitoring = false
    
    /// 监控间隔（秒）
    private var monitoringInterval: TimeInterval = 2.0
    
    /// 默认监控间隔
    private let defaultMonitoringInterval: TimeInterval = 2.0
    
    /// 优化模式监控间隔
    private let optimizedMonitoringInterval: TimeInterval = 5.0
    
    /// 监控定时器
    private var monitoringTimer: Timer?
    
    /// 网络状态缓存
    private var statusCache: WiFiStatusCache
    
    /// 连接状态历史记录
    private var connectionHistory: [ConnectionEvent] = []
    
    /// 最大历史记录数量
    private let maxHistoryCount = 50
    
    /// 网络变化检测的最小间隔（秒）
    private let minimumChangeInterval: TimeInterval = 0.5
    
    /// 上次状态更新时间
    private var lastStatusUpdateTime: Date = Date()
    
    /// 错误处理和重试机制
    private var errorHandler: WiFiErrorHandler
    
    /// 重试管理器
    private var retryManager: RetryManager
    
    /// 权限检查器
    private var permissionChecker: PermissionChecker
    
    // MARK: - Initialization
    
    override init() {
        statusCache = WiFiStatusCache()
        errorHandler = WiFiErrorHandler()
        retryManager = RetryManager()
        permissionChecker = PermissionChecker()
        super.init()
        setupWiFiClient()
        setupPerformanceOptimizationListeners()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 开始监控WiFi状态
    func startMonitoring() {
        guard !isMonitoring else {
            print("WiFiMonitor: 已经在监控中")
            return
        }
        
        print("WiFiMonitor: 开始监控WiFi状态")
        isMonitoring = true
        
        // 立即检查一次当前状态
        updateCurrentStatus()
        
        // 启动网络路径监控
        startNetworkPathMonitoring()
        
        // 启动定时监控
        startPeriodicMonitoring()
    }
    
    /// 停止监控WiFi状态
    func stopMonitoring() {
        guard isMonitoring else {
            print("WiFiMonitor: 没有在监控中")
            return
        }
        
        print("WiFiMonitor: 停止监控WiFi状态")
        isMonitoring = false
        
        // 停止网络路径监控
        stopNetworkPathMonitoring()
        
        // 停止定时监控
        stopPeriodicMonitoring()
    }
    
    /// 暂停监控WiFi状态（保持监控状态但停止活动监控）
    func pauseMonitoring() {
        guard isMonitoring else {
            print("WiFiMonitor: 没有在监控中，无法暂停")
            return
        }
        
        print("WiFiMonitor: 暂停监控WiFi状态")
        
        // 停止定时监控但保持isMonitoring状态
        stopPeriodicMonitoring()
        
        // 暂停网络路径监控
        pathMonitor?.cancel()
    }
    
    /// 恢复监控WiFi状态
    func resumeMonitoring() {
        guard isMonitoring else {
            print("WiFiMonitor: 没有在监控中，无法恢复")
            return
        }
        
        print("WiFiMonitor: 恢复监控WiFi状态")
        
        // 重新启动网络路径监控
        startNetworkPathMonitoring()
        
        // 重新启动定时监控
        startPeriodicMonitoring()
        
        // 立即刷新一次状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.forceRefreshStatus()
        }
    }
    
    /// 获取当前连接的WiFi网络
    /// - Returns: 当前连接的网络信息，如果未连接则返回nil
    func getCurrentNetwork() -> WiFiNetwork? {
        guard let interface = wifiInterface else {
            print("WiFiMonitor: WiFi接口不可用")
            return nil
        }
        
        // 检查接口是否开启
        guard interface.powerOn() else {
            print("WiFiMonitor: WiFi已关闭")
            return nil
        }
        
        // 获取当前连接的网络
        guard let ssid = interface.ssid(), !ssid.isEmpty else {
            print("WiFiMonitor: 未连接到任何网络")
            return nil
        }
        
        return createWiFiNetwork(from: interface)
    }
    
    /// 获取当前信号强度
    /// - Returns: 信号强度值，如果无法获取则返回nil
    func getSignalStrength() -> Int? {
        guard let interface = wifiInterface,
              interface.powerOn(),
              interface.ssid() != nil else {
            return nil
        }
        
        return interface.rssiValue()
    }
    
    /// 刷新WiFi状态
    func refreshStatus() {
        updateCurrentStatus()
    }
    
    /// 强制刷新状态（忽略缓存和频率限制）
    func forceRefreshStatus() {
        statusCache.clearCache()
        lastStatusUpdateTime = Date.distantPast
        updateCurrentStatus()
    }
    
    /// 获取网络连接统计信息
    func getConnectionStats() -> ConnectionStats {
        return ConnectionStats(
            totalEvents: connectionHistory.count,
            connectionCount: connectionHistory.filter { 
                if case .connected = $0.type { return true }
                return false
            }.count,
            disconnectionCount: connectionHistory.filter {
                if case .disconnected = $0.type { return true }
                return false
            }.count,
            errorCount: connectionHistory.filter {
                if case .error = $0.type { return true }
                return false
            }.count,
            lastEventTime: connectionHistory.last?.timestamp
        )
    }
    
    /// 清除连接历史记录
    func clearConnectionHistory() {
        connectionHistory.removeAll()
    }
    
    /// 检查网络连接稳定性
    func getConnectionStability() -> ConnectionStability {
        guard !connectionHistory.isEmpty else {
            return ConnectionStability(isStable: true, stabilityScore: 1.0, issues: [])
        }
        
        let recentEvents = connectionHistory.suffix(10) // 最近10个事件
        var issues: [String] = []
        var stabilityScore: Double = 1.0
        
        // 检查频繁断开重连
        let disconnectionCount = recentEvents.filter {
            if case .disconnected = $0.type { return true }
            return false
        }.count
        
        if disconnectionCount > 3 {
            issues.append("频繁断开连接")
            stabilityScore -= 0.3
        }
        
        // 检查信号强度波动
        let signalChangeCount = recentEvents.filter {
            if case .signalChanged = $0.type { return true }
            return false
        }.count
        
        if signalChangeCount > 5 {
            issues.append("信号强度不稳定")
            stabilityScore -= 0.2
        }
        
        // 检查错误频率
        let errorCount = recentEvents.filter {
            if case .error = $0.type { return true }
            return false
        }.count
        
        if errorCount > 2 {
            issues.append("网络错误频繁")
            stabilityScore -= 0.4
        }
        
        stabilityScore = max(0.0, stabilityScore)
        
        return ConnectionStability(
            isStable: stabilityScore > 0.7,
            stabilityScore: stabilityScore,
            issues: issues
        )
    }
    
    /// 获取错误处理统计信息
    func getErrorHandlingStats() -> ErrorHandlingStats {
        return errorHandler.getStats()
    }
    
    /// 获取重试管理器状态
    func getRetryStatus() -> RetryStatus {
        return retryManager.getStatus()
    }
    
    /// 手动重试连接
    func retryConnection() {
        guard retryManager.canRetry() else {
            print("WiFiMonitor: 已达到最大重试次数")
            return
        }
        
        print("WiFiMonitor: 手动重试连接")
        retryManager.incrementRetryCount()
        
        // 重新设置WiFi客户端
        setupWiFiClient()
        
        // 强制刷新状态
        forceRefreshStatus()
    }
    
    /// 重置错误状态
    func resetErrorState() {
        errorHandler.clearErrors()
        retryManager.resetRetryCount()
        statusCache.clearCache()
        print("WiFiMonitor: 错误状态已重置")
    }
    
    // MARK: - Private Methods
    
    /// 设置WiFi客户端
    private func setupWiFiClient() {
        do {
            // 检查权限
            let permissionStatus = permissionChecker.checkNetworkPermissions()
            if permissionStatus != .granted {
                let error = WiFiMonitorError.permissionDenied
                handleError(error)
                return
            }
            
            wifiClient = CWWiFiClient.shared()
            
            // 获取默认WiFi接口
            if let interfaceName = CWWiFiClient.interfaceNames()?.first {
                wifiInterface = CWInterface(name: interfaceName)
                print("WiFiMonitor: 使用WiFi接口: \(interfaceName)")
                
                // 重置重试计数器
                retryManager.resetRetryCount()
            } else {
                print("WiFiMonitor: 未找到WiFi接口")
                let error = WiFiMonitorError.hardwareError
                handleError(error)
            }
        } catch {
            print("WiFiMonitor: 初始化WiFi客户端失败: \(error)")
            let wifiError = WiFiMonitorError.coreWLANError(error._code)
            handleError(wifiError)
        }
    }
    
    /// 启动网络路径监控
    private func startNetworkPathMonitoring() {
        pathMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
        
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path)
        }
        
        pathMonitor?.start(queue: monitorQueue)
    }
    
    /// 停止网络路径监控
    private func stopNetworkPathMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }
    
    /// 启动定时监控
    private func startPeriodicMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateCurrentStatus()
        }
    }
    
    /// 停止定时监控
    private func stopPeriodicMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// 处理网络路径更新
    /// - Parameter path: 网络路径信息
    private func handleNetworkPathUpdate(_ path: NWPath) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentStatus()
        }
    }
    
    /// 更新当前WiFi状态
    private func updateCurrentStatus() {
        // 检查更新频率限制
        let now = Date()
        if now.timeIntervalSince(lastStatusUpdateTime) < minimumChangeInterval {
            return
        }
        lastStatusUpdateTime = now
        
        // 首先检查缓存
        if let cachedStatus = statusCache.getCachedStatus() {
            if cachedStatus == currentStatus {
                return // 状态没有变化，无需更新
            }
        }
        
        // 执行带错误处理的状态更新
        performStatusUpdateWithErrorHandling()
    }
    
    /// 执行带错误处理的状态更新
    private func performStatusUpdateWithErrorHandling() {
        do {
            try updateStatusSafely()
        } catch let error as WiFiMonitorError {
            handleError(error)
        } catch {
            let wifiError = WiFiMonitorError.unknownError(error.localizedDescription)
            handleError(wifiError)
        }
    }
    
    /// 安全地更新状态（可能抛出错误）
    private func updateStatusSafely() throws {
        guard let interface = wifiInterface else {
            throw WiFiMonitorError.hardwareError
        }
        
        // 检查权限
        let permissionStatus = permissionChecker.checkNetworkPermissions()
        if permissionStatus != .granted {
            throw WiFiMonitorError.permissionDenied
        }
        
        // 检查WiFi是否开启
        guard interface.powerOn() else {
            updateStatusAndCache(.disabled)
            return
        }
        
        // 检查是否连接到网络
        guard let ssid = interface.ssid(), !ssid.isEmpty else {
            updateStatusAndCache(.disconnected)
            return
        }
        
        // 创建网络信息
        if let network = createWiFiNetwork(from: interface) {
            updateStatusAndCache(.connected(network))
            // 成功获取状态，重置重试计数器
            retryManager.resetRetryCount()
        } else {
            throw WiFiMonitorError.unknownError("无法获取网络信息")
        }
    }
    
    /// 更新状态并更新缓存
    private func updateStatusAndCache(_ newStatus: WiFiStatus) {
        let oldStatus = currentStatus
        
        // 更新缓存
        statusCache.updateCache(with: newStatus)
        
        // 记录连接事件
        recordConnectionEvent(from: oldStatus, to: newStatus)
        
        // 更新当前状态（这会触发委托回调）
        currentStatus = newStatus
    }
    
    /// 记录连接事件
    private func recordConnectionEvent(from oldStatus: WiFiStatus, to newStatus: WiFiStatus) {
        let event: ConnectionEvent.EventType
        
        switch (oldStatus, newStatus) {
        case (.disconnected, .connected(let network)):
            event = .connected(network)
            
        case (.connected, .disconnected):
            event = .disconnected
            
        case (.connected(let oldNetwork), .connected(let newNetwork)):
            if oldNetwork != newNetwork {
                event = .reconnected(from: oldNetwork, to: newNetwork)
            } else if let oldStrength = oldNetwork.signalStrength,
                      let newStrength = newNetwork.signalStrength,
                      abs(oldStrength - newStrength) >= 5 {
                event = .signalChanged(newNetwork, oldStrength: oldStrength, newStrength: newStrength)
            } else {
                return // 没有显著变化，不记录事件
            }
            
        case (_, .error(let error)):
            event = .error(error)
            
        default:
            return // 其他状态变化不记录
        }
        
        let connectionEvent = ConnectionEvent(type: event)
        connectionHistory.append(connectionEvent)
        
        // 限制历史记录数量
        if connectionHistory.count > maxHistoryCount {
            connectionHistory.removeFirst(connectionHistory.count - maxHistoryCount)
        }
    }
    
    /// 从WiFi接口创建网络信息
    /// - Parameter interface: WiFi接口
    /// - Returns: WiFi网络信息
    private func createWiFiNetwork(from interface: CWInterface) -> WiFiNetwork? {
        guard let ssid = interface.ssid(), !ssid.isEmpty else {
            return nil
        }
        
        // 获取基本信息
        let bssid = interface.bssid()
        let rssi = interface.rssiValue()
        let signalStrength = (rssi != 0) ? rssi : nil
        
        // 获取安全信息
        let isSecure = interface.security() != .none
        
        // 获取频率和信道信息
        let channel = interface.wlanChannel()
        let frequency = channel?.channelNumber != 0 ? Double(channel?.channelNumber ?? 0) * 5 + 2407 : nil
        
        // 获取网络标准
        let standard = getNetworkStandard(from: interface)
        
        return WiFiNetwork(
            ssid: ssid,
            bssid: bssid,
            signalStrength: signalStrength,
            isSecure: isSecure,
            frequency: frequency,
            channel: channel?.channelNumber,
            standard: standard,
            connectedAt: Date()
        )
    }
    
    /// 获取网络标准描述
    /// - Parameter interface: WiFi接口
    /// - Returns: 网络标准字符串
    private func getNetworkStandard(from interface: CWInterface) -> String? {
        // 这里可以根据接口信息推断网络标准
        // CoreWLAN没有直接提供这个信息，所以我们基于其他信息推断
        
        if let channel = interface.wlanChannel() {
            let channelNumber = channel.channelNumber
            let channelWidth = channel.channelWidth
            
            // 基于信道和带宽推断标准
            if channelNumber > 14 {
                // 5GHz频段
                switch channelWidth {
                case .width20MHz:
                    return "802.11a/n"
                case .width40MHz:
                    return "802.11n"
                case .width80MHz:
                    return "802.11ac"
                case .width160MHz:
                    return "802.11ac/ax"
                default:
                    return "802.11a/n/ac"
                }
            } else {
                // 2.4GHz频段
                switch channelWidth {
                case .width20MHz:
                    return "802.11b/g/n"
                case .width40MHz:
                    return "802.11n"
                default:
                    return "802.11b/g/n"
                }
            }
        }
        
        return nil
    }
    
    /// 处理错误
    private func handleError(_ error: WiFiMonitorError) {
        print("WiFiMonitor: 处理错误: \(error.localizedDescription)")
        
        // 更新通信管理器的错误状态
        ComponentCommunicationManager.shared.updateError(error)
        
        // 记录错误
        errorHandler.recordError(error)
        
        // 更新状态为错误状态
        updateStatusAndCache(.error(error))
        
        // 如果错误可以重试，安排重试
        if error.isRetryable && retryManager.canRetry() {
            scheduleRetry(for: error)
        } else if error.requiresUserIntervention {
            // 需要用户干预的错误，通知委托
            notifyUserInterventionRequired(for: error)
        }
    }
    
    /// 安排重试
    private func scheduleRetry(for error: WiFiMonitorError) {
        let retryDelay = retryManager.getNextRetryDelay()
        
        print("WiFiMonitor: 将在 \(retryDelay) 秒后重试")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            self?.performRetry(for: error)
        }
    }
    
    /// 执行重试
    private func performRetry(for error: WiFiMonitorError) {
        guard retryManager.canRetry() else {
            print("WiFiMonitor: 已达到最大重试次数")
            return
        }
        
        retryManager.incrementRetryCount()
        print("WiFiMonitor: 执行重试 (第 \(retryManager.getCurrentRetryCount()) 次)")
        
        switch error {
        case .networkUnavailable, .hardwareError:
            // 重新初始化WiFi客户端
            setupWiFiClient()
            
        case .coreWLANError, .timeout:
            // 强制刷新状态
            forceRefreshStatus()
            
        case .unknownError:
            // 完全重新初始化
            setupWiFiClient()
            forceRefreshStatus()
            
        default:
            // 其他错误，尝试刷新状态
            forceRefreshStatus()
        }
    }
    
    /// 通知需要用户干预
    private func notifyUserInterventionRequired(for error: WiFiMonitorError) {
        print("WiFiMonitor: 错误需要用户干预: \(error.localizedDescription)")
        print("WiFiMonitor: 建议: \(error.recoverySuggestion ?? "无建议")")
        
        // 这里可以通过委托通知UI显示用户干预提示
        // 或者发送通知等
    }
    
    // MARK: - Performance Optimization
    
    /// 设置性能优化监听器
    private func setupPerformanceOptimizationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(optimizeMonitoring),
            name: .optimizeWiFiMonitoring,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(performCacheCleanup),
            name: .performanceCacheCleanup,
            object: nil
        )
    }
    
    /// 优化监控频率
    @objc private func optimizeMonitoring() {
        print("WiFiMonitor: 优化监控频率")
        
        // 切换到优化模式的监控间隔
        monitoringInterval = optimizedMonitoringInterval
        
        // 重启定时监控以应用新的间隔
        if isMonitoring {
            stopPeriodicMonitoring()
            startPeriodicMonitoring()
        }
        
        // 清理部分历史记录
        if connectionHistory.count > 25 {
            connectionHistory = Array(connectionHistory.suffix(25))
        }
    }
    
    /// 执行缓存清理
    @objc private func performCacheCleanup() {
        print("WiFiMonitor: 执行缓存清理")
        
        // 清理状态缓存
        statusCache.clearCache()
        
        // 清理连接历史记录的一部分
        if connectionHistory.count > 20 {
            connectionHistory = Array(connectionHistory.suffix(20))
        }
        
        // 重置错误处理器的历史记录
        errorHandler.clearOldRecords(olderThan: Date().addingTimeInterval(-3600)) // 清理1小时前的记录
    }
    
    /// 恢复正常监控频率
    func restoreNormalMonitoring() {
        print("WiFiMonitor: 恢复正常监控频率")
        
        monitoringInterval = defaultMonitoringInterval
        
        // 重启定时监控以应用新的间隔
        if isMonitoring {
            stopPeriodicMonitoring()
            startPeriodicMonitoring()
        }
    }
    
    /// 获取当前监控间隔
    func getCurrentMonitoringInterval() -> TimeInterval {
        return monitoringInterval
    }
    
    /// 获取内存使用情况
    func getMemoryUsage() -> Double {
        // 估算WiFiMonitor的内存使用
        let historySize = connectionHistory.count * MemoryLayout<ConnectionEvent>.size
        let cacheSize = statusCache.estimatedMemoryUsage()
        let errorHistorySize = errorHandler.estimatedMemoryUsage()
        
        return Double(historySize + cacheSize + errorHistorySize) / 1024.0 / 1024.0 // 转换为MB
    }
}

// MARK: - WiFiMonitor Extensions

extension WiFiMonitor {
    /// 获取当前状态
    var status: WiFiStatus {
        return currentStatus
    }
    
    /// 检查是否正在监控
    var monitoring: Bool {
        return isMonitoring
    }
    
    /// 获取可用的WiFi接口名称列表
    static func availableInterfaceNames() -> [String] {
        return CWWiFiClient.interfaceNames() ?? []
    }
    
    /// 检查WiFi功能是否可用
    static func isWiFiAvailable() -> Bool {
        return !availableInterfaceNames().isEmpty
    }
    
    /// 获取连接历史记录
    var connectionHistory: [ConnectionEvent] {
        return self.connectionHistory
    }
    
    /// 获取状态缓存信息
    var cacheInfo: WiFiStatusCacheInfo {
        return statusCache.info
    }
}

// MARK: - Supporting Types

/// 连接事件记录
struct ConnectionEvent {
    /// 事件类型
    enum EventType {
        case connected(WiFiNetwork)
        case disconnected
        case reconnected(from: WiFiNetwork, to: WiFiNetwork)
        case signalChanged(WiFiNetwork, oldStrength: Int?, newStrength: Int?)
        case error(WiFiMonitorError)
    }
    
    /// 事件类型
    let type: EventType
    
    /// 事件时间
    let timestamp: Date
    
    /// 事件持续时间（如果适用）
    let duration: TimeInterval?
    
    init(type: EventType, timestamp: Date = Date(), duration: TimeInterval? = nil) {
        self.type = type
        self.timestamp = timestamp
        self.duration = duration
    }
}

/// WiFi状态缓存
class WiFiStatusCache {
    /// 缓存的状态
    private var cachedStatus: WiFiStatus?
    
    /// 缓存时间
    private var cacheTime: Date?
    
    /// 缓存有效期（秒）
    private let cacheValidityPeriod: TimeInterval = 1.0
    
    /// 状态变化次数
    private var changeCount = 0
    
    /// 最后一次网络信息
    private var lastNetwork: WiFiNetwork?
    
    /// 获取缓存的状态（如果有效）
    func getCachedStatus() -> WiFiStatus? {
        guard let cacheTime = cacheTime,
              Date().timeIntervalSince(cacheTime) < cacheValidityPeriod else {
            return nil
        }
        return cachedStatus
    }
    
    /// 更新缓存
    func updateCache(with status: WiFiStatus) {
        let shouldUpdate = shouldUpdateCache(with: status)
        
        if shouldUpdate {
            cachedStatus = status
            cacheTime = Date()
            changeCount += 1
            
            // 更新最后一次网络信息
            if case .connected(let network) = status {
                lastNetwork = network
            } else if case .disconnected = status {
                lastNetwork = nil
            }
        }
    }
    
    /// 判断是否应该更新缓存
    private func shouldUpdateCache(with newStatus: WiFiStatus) -> Bool {
        guard let cachedStatus = cachedStatus else {
            return true // 首次缓存
        }
        
        // 检查状态是否真的发生了变化
        switch (cachedStatus, newStatus) {
        case (.connected(let oldNetwork), .connected(let newNetwork)):
            // 检查网络是否真的变化了
            return oldNetwork != newNetwork || hasSignificantSignalChange(oldNetwork, newNetwork)
            
        case (.connected, .disconnected), (.disconnected, .connected):
            return true // 连接状态变化
            
        case (.disconnected, .disconnected):
            return false // 都是断开状态，无需更新
            
        case (.error(let oldError), .error(let newError)):
            return oldError.localizedDescription != newError.localizedDescription
            
        default:
            return cachedStatus != newStatus
        }
    }
    
    /// 检查信号强度是否有显著变化
    private func hasSignificantSignalChange(_ oldNetwork: WiFiNetwork, _ newNetwork: WiFiNetwork) -> Bool {
        guard let oldStrength = oldNetwork.signalStrength,
              let newStrength = newNetwork.signalStrength else {
            return oldNetwork.signalStrength != newNetwork.signalStrength
        }
        
        // 信号强度变化超过5dBm才认为是显著变化
        return abs(oldStrength - newStrength) >= 5
    }
    
    /// 清除缓存
    func clearCache() {
        cachedStatus = nil
        cacheTime = nil
    }
    
    /// 获取缓存信息
    var info: WiFiStatusCacheInfo {
        return WiFiStatusCacheInfo(
            hasCache: cachedStatus != nil,
            cacheTime: cacheTime,
            changeCount: changeCount,
            lastNetwork: lastNetwork
        )
    }
    
    /// 估算内存使用量（字节）
    func estimatedMemoryUsage() -> Int {
        var size = MemoryLayout<WiFiStatusCache>.size
        
        if let cachedStatus = cachedStatus {
            size += MemoryLayout<WiFiStatus>.size
            
            // 如果是连接状态，还要计算网络信息的大小
            if case .connected(let network) = cachedStatus {
                size += MemoryLayout<WiFiNetwork>.size
                size += network.ssid.utf8.count
                size += network.bssid?.utf8.count ?? 0
            }
        }
        
        if let lastNetwork = lastNetwork {
            size += MemoryLayout<WiFiNetwork>.size
            size += lastNetwork.ssid.utf8.count
            size += lastNetwork.bssid?.utf8.count ?? 0
        }
        
        return size
    }
}

/// WiFi状态缓存信息
struct WiFiStatusCacheInfo {
    /// 是否有缓存
    let hasCache: Bool
    
    /// 缓存时间
    let cacheTime: Date?
    
    /// 状态变化次数
    let changeCount: Int
    
    /// 最后一次连接的网络
    let lastNetwork: WiFiNetwork?
}

/// 连接统计信息
struct ConnectionStats {
    /// 总事件数
    let totalEvents: Int
    
    /// 连接次数
    let connectionCount: Int
    
    /// 断开次数
    let disconnectionCount: Int
    
    /// 错误次数
    let errorCount: Int
    
    /// 最后一次事件时间
    let lastEventTime: Date?
    
    /// 连接成功率
    var connectionSuccessRate: Double {
        let totalAttempts = connectionCount + errorCount
        return totalAttempts > 0 ? Double(connectionCount) / Double(totalAttempts) : 1.0
    }
    
    /// 连接稳定性（基于断开/连接比率）
    var connectionStabilityRatio: Double {
        return connectionCount > 0 ? Double(disconnectionCount) / Double(connectionCount) : 0.0
    }
}

/// 连接稳定性信息
struct ConnectionStability {
    /// 是否稳定
    let isStable: Bool
    
    /// 稳定性评分（0.0-1.0）
    let stabilityScore: Double
    
    /// 发现的问题列表
    let issues: [String]
    
    /// 稳定性等级
    var stabilityLevel: StabilityLevel {
        switch stabilityScore {
        case 0.9...1.0:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.5..<0.7:
            return .fair
        case 0.3..<0.5:
            return .poor
        default:
            return .critical
        }
    }
}

/// 稳定性等级
enum StabilityLevel: String, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
    case critical = "严重"
    
    var description: String {
        switch self {
        case .excellent:
            return "网络连接非常稳定"
        case .good:
            return "网络连接稳定"
        case .fair:
            return "网络连接基本稳定，偶有波动"
        case .poor:
            return "网络连接不稳定，经常出现问题"
        case .critical:
            return "网络连接极不稳定，需要检查"
        }
    }
}

// MARK: - Error Handling Support Classes

/// WiFi错误处理器
class WiFiErrorHandler {
    /// 错误记录
    private var errorHistory: [ErrorRecord] = []
    
    /// 最大错误记录数量
    private let maxErrorHistory = 100
    
    /// 记录错误
    func recordError(_ error: WiFiMonitorError) {
        let record = ErrorRecord(error: error, timestamp: Date())
        errorHistory.append(record)
        
        // 限制历史记录数量
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst(errorHistory.count - maxErrorHistory)
        }
    }
    
    /// 获取错误统计
    func getStats() -> ErrorHandlingStats {
        let now = Date()
        let recentErrors = errorHistory.filter { now.timeIntervalSince($0.timestamp) < 3600 } // 最近1小时
        
        var errorCounts: [String: Int] = [:]
        for record in recentErrors {
            let errorType = String(describing: record.error)
            errorCounts[errorType, default: 0] += 1
        }
        
        return ErrorHandlingStats(
            totalErrors: errorHistory.count,
            recentErrors: recentErrors.count,
            errorCounts: errorCounts,
            lastErrorTime: errorHistory.last?.timestamp
        )
    }
    
    /// 清除错误记录
    func clearErrors() {
        errorHistory.removeAll()
    }
    
    /// 获取最近的错误
    func getRecentErrors(limit: Int = 10) -> [ErrorRecord] {
        return Array(errorHistory.suffix(limit))
    }
    
    /// 清理旧记录
    func clearOldRecords(olderThan date: Date) {
        errorHistory.removeAll { $0.timestamp < date }
    }
    
    /// 估算内存使用量（字节）
    func estimatedMemoryUsage() -> Int {
        var size = MemoryLayout<WiFiErrorHandler>.size
        size += errorHistory.count * MemoryLayout<ErrorRecord>.size
        
        // 估算错误描述字符串的大小
        for record in errorHistory {
            size += record.error.localizedDescription.utf8.count
        }
        
        return size
    }
}

/// 错误记录
struct ErrorRecord {
    let error: WiFiMonitorError
    let timestamp: Date
    let id = UUID()
}

/// 错误处理统计信息
struct ErrorHandlingStats {
    let totalErrors: Int
    let recentErrors: Int
    let errorCounts: [String: Int]
    let lastErrorTime: Date?
    
    /// 错误率（每小时）
    var errorRate: Double {
        return Double(recentErrors) // 最近1小时的错误数
    }
    
    /// 最常见的错误类型
    var mostCommonError: String? {
        return errorCounts.max(by: { $0.value < $1.value })?.key
    }
}

/// 重试管理器
class RetryManager {
    /// 当前重试次数
    private var currentRetryCount = 0
    
    /// 最大重试次数
    private let maxRetryCount = 5
    
    /// 基础重试延迟（秒）
    private let baseRetryDelay: TimeInterval = 2.0
    
    /// 最大重试延迟（秒）
    private let maxRetryDelay: TimeInterval = 60.0
    
    /// 上次重试时间
    private var lastRetryTime: Date?
    
    /// 检查是否可以重试
    func canRetry() -> Bool {
        return currentRetryCount < maxRetryCount
    }
    
    /// 增加重试次数
    func incrementRetryCount() {
        currentRetryCount += 1
        lastRetryTime = Date()
    }
    
    /// 重置重试次数
    func resetRetryCount() {
        currentRetryCount = 0
        lastRetryTime = nil
    }
    
    /// 获取当前重试次数
    func getCurrentRetryCount() -> Int {
        return currentRetryCount
    }
    
    /// 获取下次重试延迟（指数退避）
    func getNextRetryDelay() -> TimeInterval {
        let exponentialDelay = baseRetryDelay * pow(2.0, Double(currentRetryCount))
        return min(exponentialDelay, maxRetryDelay)
    }
    
    /// 获取重试状态
    func getStatus() -> RetryStatus {
        return RetryStatus(
            currentRetryCount: currentRetryCount,
            maxRetryCount: maxRetryCount,
            canRetry: canRetry(),
            lastRetryTime: lastRetryTime,
            nextRetryDelay: canRetry() ? getNextRetryDelay() : nil
        )
    }
}

/// 重试状态信息
struct RetryStatus {
    let currentRetryCount: Int
    let maxRetryCount: Int
    let canRetry: Bool
    let lastRetryTime: Date?
    let nextRetryDelay: TimeInterval?
    
    /// 重试进度（0.0-1.0）
    var retryProgress: Double {
        return Double(currentRetryCount) / Double(maxRetryCount)
    }
    
    /// 剩余重试次数
    var remainingRetries: Int {
        return max(0, maxRetryCount - currentRetryCount)
    }
}

/// 权限检查器
class PermissionChecker {
    /// 权限状态
    enum PermissionStatus {
        case granted
        case denied
        case notDetermined
        case restricted
    }
    
    /// 检查网络权限
    func checkNetworkPermissions() -> PermissionStatus {
        // 在macOS中，网络权限通常是自动授予的
        // 但我们可以检查一些基本的系统状态
        
        // 检查是否有WiFi接口
        guard !CWWiFiClient.interfaceNames()?.isEmpty ?? true else {
            return .restricted
        }
        
        // 尝试创建WiFi客户端来测试权限
        do {
            let _ = CWWiFiClient.shared()
            return .granted
        } catch {
            return .denied
        }
    }
    
    /// 请求网络权限（在macOS中通常不需要）
    func requestNetworkPermissions(completion: @escaping (PermissionStatus) -> Void) {
        // 在macOS中，网络权限通常是自动的
        // 这里我们只是检查当前状态
        let status = checkNetworkPermissions()
        DispatchQueue.main.async {
            completion(status)
        }
    }
    
    /// 检查是否需要用户手动授权
    func requiresManualAuthorization() -> Bool {
        let status = checkNetworkPermissions()
        return status == .denied || status == .restricted
    }
    
    /// 获取权限状态描述
    func getPermissionStatusDescription() -> String {
        let status = checkNetworkPermissions()
        switch status {
        case .granted:
            return "网络权限已授予"
        case .denied:
            return "网络权限被拒绝"
        case .notDetermined:
            return "网络权限未确定"
        case .restricted:
            return "网络权限受限制"
        }
    }
}