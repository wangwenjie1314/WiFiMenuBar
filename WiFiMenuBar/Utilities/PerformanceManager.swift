import Foundation
import os.log
import Darwin

/// 性能管理器
/// 负责监控和优化应用的内存和CPU使用
class PerformanceManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = PerformanceManager()
    
    // MARK: - Published Properties
    
    /// 当前内存使用量（MB）
    @Published var currentMemoryUsage: Double = 0.0
    
    /// 当前CPU使用率（%）
    @Published var currentCPUUsage: Double = 0.0
    
    /// 性能状态
    @Published var performanceStatus: PerformanceStatus = .normal
    
    /// 是否启用性能监控
    @Published var isMonitoringEnabled: Bool = true
    
    // MARK: - Private Properties
    
    /// 性能监控定时器
    private var monitoringTimer: Timer?
    
    /// 监控间隔（秒）
    private let monitoringInterval: TimeInterval = 5.0
    
    /// 性能历史记录
    private var performanceHistory: [PerformanceRecord] = []
    
    /// 最大历史记录数量
    private let maxHistoryCount = 100
    
    /// 内存警告阈值（MB）
    private let memoryWarningThreshold: Double = 100.0
    
    /// CPU警告阈值（%）
    private let cpuWarningThreshold: Double = 50.0
    
    /// 性能优化策略
    private var optimizationStrategies: [PerformanceOptimizationStrategy] = []
    
    /// 内存压力监控
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.performance", category: "PerformanceManager")
    
    // MARK: - Initialization
    
    private init() {
        print("PerformanceManager: 初始化性能管理器")
        setupOptimizationStrategies()
        setupMemoryPressureMonitoring()
        startPerformanceMonitoring()
    }
    
    deinit {
        stopPerformanceMonitoring()
        stopMemoryPressureMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 开始性能监控
    func startPerformanceMonitoring() {
        guard isMonitoringEnabled else { return }
        
        print("PerformanceManager: 开始性能监控")
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
        
        // 立即更新一次
        updatePerformanceMetrics()
    }
    
    /// 停止性能监控
    func stopPerformanceMonitoring() {
        print("PerformanceManager: 停止性能监控")
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// 获取性能报告
    /// - Returns: 性能报告
    func getPerformanceReport() -> PerformanceReport {
        let recentHistory = Array(performanceHistory.suffix(20))
        
        return PerformanceReport(
            currentMemoryUsage: currentMemoryUsage,
            currentCPUUsage: currentCPUUsage,
            performanceStatus: performanceStatus,
            averageMemoryUsage: calculateAverageMemoryUsage(from: recentHistory),
            averageCPUUsage: calculateAverageCPUUsage(from: recentHistory),
            peakMemoryUsage: calculatePeakMemoryUsage(from: recentHistory),
            peakCPUUsage: calculatePeakCPUUsage(from: recentHistory),
            monitoringDuration: getMonitoringDuration(),
            optimizationSuggestions: generateOptimizationSuggestions()
        )
    }
    
    /// 执行性能优化
    func performOptimization() {
        print("PerformanceManager: 执行性能优化")
        
        for strategy in optimizationStrategies {
            if strategy.shouldApply(currentMemoryUsage: currentMemoryUsage, currentCPUUsage: currentCPUUsage) {
                strategy.apply()
                os_log("应用优化策略: %@", log: logger, type: .info, strategy.name)
            }
        }
        
        // 强制垃圾回收
        performGarbageCollection()
        
        // 清理缓存
        clearCaches()
        
        // 更新性能指标
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updatePerformanceMetrics()
        }
    }
    
    /// 获取内存使用详情
    /// - Returns: 内存使用详情
    func getMemoryUsageDetails() -> MemoryUsageDetails {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return MemoryUsageDetails(
                residentSize: Double(info.resident_size) / 1024.0 / 1024.0,
                virtualSize: Double(info.virtual_size) / 1024.0 / 1024.0,
                suspendCount: Int(info.suspend_count),
                timestamp: Date()
            )
        } else {
            return MemoryUsageDetails(
                residentSize: 0,
                virtualSize: 0,
                suspendCount: 0,
                timestamp: Date()
            )
        }
    }
    
    /// 获取CPU使用详情
    /// - Returns: CPU使用详情
    func getCPUUsageDetails() -> CPUUsageDetails {
        var info = task_thread_times_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_thread_times_info>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_THREAD_TIMES_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let totalTime = Double(info.user_time.seconds + info.system_time.seconds) +
                           Double(info.user_time.microseconds + info.system_time.microseconds) / 1_000_000.0
            
            return CPUUsageDetails(
                userTime: Double(info.user_time.seconds) + Double(info.user_time.microseconds) / 1_000_000.0,
                systemTime: Double(info.system_time.seconds) + Double(info.system_time.microseconds) / 1_000_000.0,
                totalTime: totalTime,
                timestamp: Date()
            )
        } else {
            return CPUUsageDetails(
                userTime: 0,
                systemTime: 0,
                totalTime: 0,
                timestamp: Date()
            )
        }
    }
    
    /// 清理性能历史记录
    func clearPerformanceHistory() {
        print("PerformanceManager: 清理性能历史记录")
        performanceHistory.removeAll()
    }
    
    /// 导出性能数据
    /// - Returns: 性能数据的JSON字符串
    func exportPerformanceData() -> String? {
        let exportData = PerformanceExportData(
            performanceHistory: performanceHistory,
            currentReport: getPerformanceReport(),
            exportTime: Date()
        )
        
        do {
            let jsonData = try JSONEncoder().encode(exportData)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            os_log("导出性能数据失败: %@", log: logger, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新性能指标
    private func updatePerformanceMetrics() {
        let memoryDetails = getMemoryUsageDetails()
        let cpuDetails = getCPUUsageDetails()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentMemoryUsage = memoryDetails.residentSize
            self.currentCPUUsage = self.calculateCPUUsagePercentage(cpuDetails)
            
            // 更新性能状态
            self.updatePerformanceStatus()
            
            // 记录性能历史
            self.recordPerformanceHistory(memoryDetails: memoryDetails, cpuDetails: cpuDetails)
            
            // 检查是否需要优化
            self.checkForOptimizationNeeds()
        }
    }
    
    /// 计算CPU使用百分比
    /// - Parameter cpuDetails: CPU使用详情
    /// - Returns: CPU使用百分比
    private func calculateCPUUsagePercentage(_ cpuDetails: CPUUsageDetails) -> Double {
        // 这是一个简化的CPU使用率计算
        // 实际应用中可能需要更复杂的计算方法
        let totalCPUTime = cpuDetails.userTime + cpuDetails.systemTime
        return min(totalCPUTime * 100.0 / monitoringInterval, 100.0)
    }
    
    /// 更新性能状态
    private func updatePerformanceStatus() {
        let newStatus: PerformanceStatus
        
        if currentMemoryUsage > memoryWarningThreshold || currentCPUUsage > cpuWarningThreshold {
            newStatus = .warning
        } else if currentMemoryUsage > memoryWarningThreshold * 1.5 || currentCPUUsage > cpuWarningThreshold * 1.5 {
            newStatus = .critical
        } else {
            newStatus = .normal
        }
        
        if newStatus != performanceStatus {
            performanceStatus = newStatus
            handlePerformanceStatusChange(newStatus)
        }
    }
    
    /// 处理性能状态变化
    /// - Parameter newStatus: 新的性能状态
    private func handlePerformanceStatusChange(_ newStatus: PerformanceStatus) {
        os_log("性能状态变化: %@", log: logger, type: .info, newStatus.description)
        
        switch newStatus {
        case .warning:
            // 发送性能警告通知
            sendPerformanceWarningNotification()
        case .critical:
            // 自动执行优化
            performOptimization()
        case .normal:
            break
        }
    }
    
    /// 记录性能历史
    /// - Parameters:
    ///   - memoryDetails: 内存使用详情
    ///   - cpuDetails: CPU使用详情
    private func recordPerformanceHistory(memoryDetails: MemoryUsageDetails, cpuDetails: CPUUsageDetails) {
        let record = PerformanceRecord(
            timestamp: Date(),
            memoryUsage: memoryDetails.residentSize,
            cpuUsage: currentCPUUsage,
            performanceStatus: performanceStatus
        )
        
        performanceHistory.append(record)
        
        // 限制历史记录数量
        if performanceHistory.count > maxHistoryCount {
            performanceHistory.removeFirst(performanceHistory.count - maxHistoryCount)
        }
    }
    
    /// 检查是否需要优化
    private func checkForOptimizationNeeds() {
        if performanceStatus == .critical {
            // 自动执行优化
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.performOptimization()
            }
        }
    }
    
    /// 设置优化策略
    private func setupOptimizationStrategies() {
        optimizationStrategies = [
            MemoryCacheCleanupStrategy(),
            ComponentCommunicationOptimizationStrategy(),
            WiFiMonitorOptimizationStrategy(),
            UIUpdateOptimizationStrategy()
        ]
    }
    
    /// 设置内存压力监控
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .global(qos: .utility))
        
        memoryPressureSource?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.handleMemoryPressure()
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    /// 停止内存压力监控
    private func stopMemoryPressureMonitoring() {
        memoryPressureSource?.cancel()
        memoryPressureSource = nil
    }
    
    /// 处理内存压力
    private func handleMemoryPressure() {
        os_log("检测到内存压力，执行优化", log: logger, type: .info)
        performOptimization()
    }
    
    /// 执行垃圾回收
    private func performGarbageCollection() {
        // Swift使用ARC，这里主要是清理一些可能的循环引用
        autoreleasepool {
            // 清理自动释放池
        }
    }
    
    /// 清理缓存
    private func clearCaches() {
        // 清理组件通信管理器的历史记录
        ComponentCommunicationManager.shared.clearHistory()
        
        // 清理性能历史记录的一部分
        if performanceHistory.count > maxHistoryCount / 2 {
            let keepCount = maxHistoryCount / 2
            performanceHistory = Array(performanceHistory.suffix(keepCount))
        }
        
        // 通知其他组件清理缓存
        NotificationCenter.default.post(name: .performanceCacheCleanup, object: nil)
    }
    
    /// 发送性能警告通知
    private func sendPerformanceWarningNotification() {
        let userInfo: [String: Any] = [
            "memoryUsage": currentMemoryUsage,
            "cpuUsage": currentCPUUsage,
            "performanceStatus": performanceStatus.rawValue
        ]
        
        NotificationCenter.default.post(
            name: .performanceWarning,
            object: self,
            userInfo: userInfo
        )
    }
    
    /// 计算平均内存使用
    /// - Parameter history: 性能历史记录
    /// - Returns: 平均内存使用量
    private func calculateAverageMemoryUsage(from history: [PerformanceRecord]) -> Double {
        guard !history.isEmpty else { return 0.0 }
        return history.map { $0.memoryUsage }.reduce(0, +) / Double(history.count)
    }
    
    /// 计算平均CPU使用
    /// - Parameter history: 性能历史记录
    /// - Returns: 平均CPU使用率
    private func calculateAverageCPUUsage(from history: [PerformanceRecord]) -> Double {
        guard !history.isEmpty else { return 0.0 }
        return history.map { $0.cpuUsage }.reduce(0, +) / Double(history.count)
    }
    
    /// 计算峰值内存使用
    /// - Parameter history: 性能历史记录
    /// - Returns: 峰值内存使用量
    private func calculatePeakMemoryUsage(from history: [PerformanceRecord]) -> Double {
        return history.map { $0.memoryUsage }.max() ?? 0.0
    }
    
    /// 计算峰值CPU使用
    /// - Parameter history: 性能历史记录
    /// - Returns: 峰值CPU使用率
    private func calculatePeakCPUUsage(from history: [PerformanceRecord]) -> Double {
        return history.map { $0.cpuUsage }.max() ?? 0.0
    }
    
    /// 获取监控持续时间
    /// - Returns: 监控持续时间（秒）
    private func getMonitoringDuration() -> TimeInterval {
        guard let firstRecord = performanceHistory.first else { return 0.0 }
        return Date().timeIntervalSince(firstRecord.timestamp)
    }
    
    /// 生成优化建议
    /// - Returns: 优化建议列表
    private func generateOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if currentMemoryUsage > memoryWarningThreshold {
            suggestions.append("内存使用过高，建议清理缓存或重启应用")
        }
        
        if currentCPUUsage > cpuWarningThreshold {
            suggestions.append("CPU使用率过高，建议减少监控频率或优化算法")
        }
        
        if performanceHistory.count > maxHistoryCount * 0.8 {
            suggestions.append("性能历史记录过多，建议清理历史数据")
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types

/// 性能状态
enum PerformanceStatus: String, CaseIterable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .normal:
            return "正常"
        case .warning:
            return "警告"
        case .critical:
            return "严重"
        }
    }
    
    var color: NSColor {
        switch self {
        case .normal:
            return .systemGreen
        case .warning:
            return .systemOrange
        case .critical:
            return .systemRed
        }
    }
}

/// 性能记录
struct PerformanceRecord: Codable {
    let timestamp: Date
    let memoryUsage: Double
    let cpuUsage: Double
    let performanceStatus: PerformanceStatus
}

/// 内存使用详情
struct MemoryUsageDetails {
    let residentSize: Double    // 常驻内存大小（MB）
    let virtualSize: Double     // 虚拟内存大小（MB）
    let suspendCount: Int       // 挂起计数
    let timestamp: Date
}

/// CPU使用详情
struct CPUUsageDetails {
    let userTime: Double        // 用户态时间（秒）
    let systemTime: Double      // 系统态时间（秒）
    let totalTime: Double       // 总时间（秒）
    let timestamp: Date
}

/// 性能报告
struct PerformanceReport {
    let currentMemoryUsage: Double
    let currentCPUUsage: Double
    let performanceStatus: PerformanceStatus
    let averageMemoryUsage: Double
    let averageCPUUsage: Double
    let peakMemoryUsage: Double
    let peakCPUUsage: Double
    let monitoringDuration: TimeInterval
    let optimizationSuggestions: [String]
    
    var description: String {
        return """
        性能报告:
        - 当前内存使用: \(String(format: "%.1f", currentMemoryUsage)) MB
        - 当前CPU使用: \(String(format: "%.1f", currentCPUUsage))%
        - 性能状态: \(performanceStatus.description)
        - 平均内存使用: \(String(format: "%.1f", averageMemoryUsage)) MB
        - 平均CPU使用: \(String(format: "%.1f", averageCPUUsage))%
        - 峰值内存使用: \(String(format: "%.1f", peakMemoryUsage)) MB
        - 峰值CPU使用: \(String(format: "%.1f", peakCPUUsage))%
        - 监控时长: \(String(format: "%.0f", monitoringDuration)) 秒
        - 优化建议: \(optimizationSuggestions.joined(separator: "; "))
        """
    }
}

/// 性能导出数据
struct PerformanceExportData: Codable {
    let performanceHistory: [PerformanceRecord]
    let currentReport: PerformanceReport
    let exportTime: Date
}

// MARK: - Performance Optimization Strategies

/// 性能优化策略协议
protocol PerformanceOptimizationStrategy {
    var name: String { get }
    func shouldApply(currentMemoryUsage: Double, currentCPUUsage: Double) -> Bool
    func apply()
}

/// 内存缓存清理策略
struct MemoryCacheCleanupStrategy: PerformanceOptimizationStrategy {
    let name = "内存缓存清理"
    
    func shouldApply(currentMemoryUsage: Double, currentCPUUsage: Double) -> Bool {
        return currentMemoryUsage > 80.0
    }
    
    func apply() {
        // 清理各种缓存
        URLCache.shared.removeAllCachedResponses()
        
        // 清理图片缓存（如果有的话）
        // ImageCache.shared.clearCache()
        
        print("PerformanceOptimization: 执行内存缓存清理")
    }
}

/// 组件通信优化策略
struct ComponentCommunicationOptimizationStrategy: PerformanceOptimizationStrategy {
    let name = "组件通信优化"
    
    func shouldApply(currentMemoryUsage: Double, currentCPUUsage: Double) -> Bool {
        return currentMemoryUsage > 60.0 || currentCPUUsage > 30.0
    }
    
    func apply() {
        // 清理组件通信历史
        ComponentCommunicationManager.shared.clearHistory()
        
        print("PerformanceOptimization: 执行组件通信优化")
    }
}

/// WiFi监控优化策略
struct WiFiMonitorOptimizationStrategy: PerformanceOptimizationStrategy {
    let name = "WiFi监控优化"
    
    func shouldApply(currentMemoryUsage: Double, currentCPUUsage: Double) -> Bool {
        return currentCPUUsage > 40.0
    }
    
    func apply() {
        // 通知WiFiMonitor降低监控频率
        NotificationCenter.default.post(name: .optimizeWiFiMonitoring, object: nil)
        
        print("PerformanceOptimization: 执行WiFi监控优化")
    }
}

/// UI更新优化策略
struct UIUpdateOptimizationStrategy: PerformanceOptimizationStrategy {
    let name = "UI更新优化"
    
    func shouldApply(currentMemoryUsage: Double, currentCPUUsage: Double) -> Bool {
        return currentCPUUsage > 35.0
    }
    
    func apply() {
        // 通知UI组件减少更新频率
        NotificationCenter.default.post(name: .optimizeUIUpdates, object: nil)
        
        print("PerformanceOptimization: 执行UI更新优化")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let performanceWarning = Notification.Name("performanceWarning")
    static let performanceCacheCleanup = Notification.Name("performanceCacheCleanup")
    static let optimizeWiFiMonitoring = Notification.Name("optimizeWiFiMonitoring")
    static let optimizeUIUpdates = Notification.Name("optimizeUIUpdates")
}

// MARK: - PerformanceStatus Codable

extension PerformanceStatus: Codable {
    // 自动实现Codable，因为是String枚举
}

// MARK: - PerformanceReport Codable

extension PerformanceReport: Codable {
    // 手动实现Codable，因为包含复杂类型
}