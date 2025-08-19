import Foundation
import os.log
import Cocoa

/// 应用健康状态监控器
/// 负责持续监控应用的整体健康状态并提供详细的诊断信息
class ApplicationHealthMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = ApplicationHealthMonitor()
    
    // MARK: - Published Properties
    
    /// 当前健康状态
    @Published var currentHealthStatus: ApplicationHealthStatus = .unknown
    
    /// 是否启用监控
    @Published var isMonitoringEnabled: Bool = true
    
    /// 最后一次检查时间
    @Published var lastCheckTime: Date?
    
    // MARK: - Private Properties
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.health", category: "ApplicationHealthMonitor")
    
    /// 监控定时器
    private var monitoringTimer: Timer?
    
    /// 监控间隔（秒）
    private let monitoringInterval: TimeInterval = 15.0
    
    /// 健康历史记录
    private var healthHistory: [HealthSnapshot] = []
    
    /// 最大历史记录数量
    private let maxHistoryCount = 100
    
    /// 诊断器列表
    private let diagnostics: [HealthDiagnostic] = [
        MemoryDiagnostic(),
        CPUDiagnostic(),
        NetworkDiagnostic(),
        ComponentDiagnostic(),
        FileSystemDiagnostic(),
        PerformanceDiagnostic()
    ]
    
    // MARK: - Initialization
    
    private init() {
        print("ApplicationHealthMonitor: 初始化应用健康监控器")
        setupMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 开始监控
    func startMonitoring() {
        guard isMonitoringEnabled else { return }
        
        print("ApplicationHealthMonitor: 开始健康监控")
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
        
        // 立即执行一次检查
        performHealthCheck()
        
        os_log("应用健康监控已启动", log: logger, type: .info)
    }
    
    /// 停止监控
    func stopMonitoring() {
        print("ApplicationHealthMonitor: 停止健康监控")
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        os_log("应用健康监控已停止", log: logger, type: .info)
    }
    
    /// 执行健康检查
    @discardableResult
    func performHealthCheck() -> ApplicationHealthStatus {
        let checkStartTime = Date()
        
        var diagnosticResults: [DiagnosticResult] = []
        var overallScore = 100.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        
        // 执行所有诊断
        for diagnostic in diagnostics {
            let result = diagnostic.performDiagnosis()
            diagnosticResults.append(result)
            
            // 累计分数影响
            overallScore -= result.scoreImpact
            
            // 收集问题
            criticalIssues.append(contentsOf: result.criticalIssues)
            warnings.append(contentsOf: result.warnings)
        }
        
        // 确保分数在合理范围内
        overallScore = max(0.0, min(100.0, overallScore))
        
        // 确定健康状态
        let healthStatus = determineHealthStatus(score: overallScore, criticalIssues: criticalIssues)
        
        // 创建健康快照
        let snapshot = HealthSnapshot(
            timestamp: checkStartTime,
            healthStatus: healthStatus,
            overallScore: overallScore,
            diagnosticResults: diagnosticResults,
            criticalIssues: criticalIssues,
            warnings: warnings,
            checkDuration: Date().timeIntervalSince(checkStartTime)
        )
        
        // 更新状态和历史
        updateHealthStatus(snapshot)
        
        lastCheckTime = checkStartTime
        
        os_log("健康检查完成 - 状态: %@, 分数: %.1f", log: logger, type: .info, 
               healthStatus.description, overallScore)
        
        return healthStatus
    }
    
    /// 获取健康报告
    func getHealthReport() -> HealthReport {
        let recentSnapshots = healthHistory.suffix(10)
        let averageScore = recentSnapshots.isEmpty ? 0.0 : recentSnapshots.map { $0.overallScore }.reduce(0, +) / Double(recentSnapshots.count)
        
        let allCriticalIssues = recentSnapshots.flatMap { $0.criticalIssues }
        let allWarnings = recentSnapshots.flatMap { $0.warnings }
        
        // 分析趋势
        let trend = analyzeTrend(snapshots: Array(recentSnapshots))
        
        return HealthReport(
            currentStatus: currentHealthStatus,
            averageScore: averageScore,
            trend: trend,
            totalChecks: healthHistory.count,
            criticalIssuesCount: allCriticalIssues.count,
            warningsCount: allWarnings.count,
            lastCheckTime: lastCheckTime,
            recommendations: generateRecommendations()
        )
    }
    
    /// 获取详细诊断信息
    func getDetailedDiagnostics() -> [DiagnosticResult] {
        return healthHistory.last?.diagnosticResults ?? []
    }
    
    /// 获取健康历史
    func getHealthHistory(limit: Int = 50) -> [HealthSnapshot] {
        return Array(healthHistory.suffix(limit))
    }
    
    /// 清除健康历史
    func clearHealthHistory() {
        healthHistory.removeAll()
        os_log("健康历史已清除", log: logger, type: .info)
    }
    
    /// 导出健康数据
    func exportHealthData() -> String? {
        let exportData = HealthExportData(
            exportTime: Date(),
            currentStatus: currentHealthStatus,
            healthHistory: healthHistory,
            healthReport: getHealthReport()
        )
        
        do {
            let jsonData = try JSONEncoder().encode(exportData)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            os_log("导出健康数据失败: %@", log: logger, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置监控
    private func setupMonitoring() {
        // 监听应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: NSApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    /// 应用变为活跃状态
    @objc private func applicationDidBecomeActive() {
        // 应用变为活跃时执行一次健康检查
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.performHealthCheck()
        }
    }
    
    /// 应用即将失去活跃状态
    @objc private func applicationWillResignActive() {
        // 应用失去活跃状态时保存当前状态
        if let lastSnapshot = healthHistory.last {
            saveHealthSnapshot(lastSnapshot)
        }
    }
    
    /// 确定健康状态
    private func determineHealthStatus(score: Double, criticalIssues: [HealthIssue]) -> ApplicationHealthStatus {
        if !criticalIssues.isEmpty {
            return .critical
        }
        
        switch score {
        case 90...100:
            return .excellent
        case 80..<90:
            return .good
        case 70..<80:
            return .fair
        case 60..<70:
            return .poor
        default:
            return .critical
        }
    }
    
    /// 更新健康状态
    private func updateHealthStatus(_ snapshot: HealthSnapshot) {
        let oldStatus = currentHealthStatus
        currentHealthStatus = snapshot.healthStatus
        
        // 添加到历史记录
        healthHistory.append(snapshot)
        
        // 限制历史记录数量
        if healthHistory.count > maxHistoryCount {
            healthHistory = Array(healthHistory.suffix(maxHistoryCount))
        }
        
        // 如果状态发生变化，发送通知
        if oldStatus != currentHealthStatus {
            NotificationCenter.default.post(
                name: .applicationHealthStatusChanged,
                object: self,
                userInfo: [
                    "oldStatus": oldStatus,
                    "newStatus": currentHealthStatus,
                    "snapshot": snapshot
                ]
            )
        }
    }
    
    /// 分析趋势
    private func analyzeTrend(snapshots: [HealthSnapshot]) -> HealthTrend {
        guard snapshots.count >= 3 else {
            return .stable
        }
        
        let scores = snapshots.map { $0.overallScore }
        let recentScores = Array(scores.suffix(3))
        let earlierScores = Array(scores.prefix(3))
        
        let recentAverage = recentScores.reduce(0, +) / Double(recentScores.count)
        let earlierAverage = earlierScores.reduce(0, +) / Double(earlierScores.count)
        
        let difference = recentAverage - earlierAverage
        
        if difference > 5.0 {
            return .improving
        } else if difference < -5.0 {
            return .declining
        } else {
            return .stable
        }
    }
    
    /// 生成建议
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        guard let lastSnapshot = healthHistory.last else {
            return ["执行健康检查以获取建议"]
        }
        
        // 根据当前状态生成建议
        switch lastSnapshot.healthStatus {
        case .critical:
            recommendations.append("应用状态严重，建议立即重启")
            recommendations.append("检查系统资源使用情况")
            recommendations.append("考虑重置应用设置")
            
        case .poor:
            recommendations.append("应用性能较差，建议清理缓存")
            recommendations.append("检查网络连接稳定性")
            
        case .fair:
            recommendations.append("应用运行一般，建议定期维护")
            
        case .good:
            recommendations.append("应用运行良好，保持当前状态")
            
        case .excellent:
            recommendations.append("应用运行优秀，无需特殊操作")
            
        case .unknown:
            recommendations.append("状态未知，建议执行健康检查")
        }
        
        // 根据具体问题添加建议
        if !lastSnapshot.criticalIssues.isEmpty {
            recommendations.append("发现严重问题，建议查看详细诊断信息")
        }
        
        if lastSnapshot.warnings.count > 3 {
            recommendations.append("警告较多，建议关注应用状态")
        }
        
        return recommendations
    }
    
    /// 保存健康快照
    private func saveHealthSnapshot(_ snapshot: HealthSnapshot) {
        // 这里可以实现将健康快照保存到文件的逻辑
        // 目前只是记录日志
        os_log("保存健康快照 - 状态: %@, 分数: %.1f", log: logger, type: .debug,
               snapshot.healthStatus.description, snapshot.overallScore)
    }
}

// MARK: - Health Diagnostic Protocol

/// 健康诊断协议
protocol HealthDiagnostic {
    var name: String { get }
    func performDiagnosis() -> DiagnosticResult
}

// MARK: - Memory Diagnostic

/// 内存诊断器
struct MemoryDiagnostic: HealthDiagnostic {
    let name = "内存诊断"
    
    func performDiagnosis() -> DiagnosticResult {
        let memoryDetails = PerformanceManager.shared.getMemoryUsageDetails()
        
        var scoreImpact = 0.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        
        // 检查物理内存使用
        if memoryDetails.residentSize > 300.0 {
            criticalIssues.append(HealthIssue(
                type: .memoryLeak,
                description: "物理内存使用过高: \(String(format: "%.1f", memoryDetails.residentSize)) MB",
                severity: .critical
            ))
            scoreImpact += 25.0
        } else if memoryDetails.residentSize > 200.0 {
            warnings.append(HealthIssue(
                type: .memoryLeak,
                description: "物理内存使用较高: \(String(format: "%.1f", memoryDetails.residentSize)) MB",
                severity: .warning
            ))
            scoreImpact += 10.0
        }
        
        // 检查虚拟内存使用
        if memoryDetails.virtualSize > 2000.0 {
            warnings.append(HealthIssue(
                type: .memoryLeak,
                description: "虚拟内存使用较高: \(String(format: "%.1f", memoryDetails.virtualSize)) MB",
                severity: .warning
            ))
            scoreImpact += 5.0
        }
        
        return DiagnosticResult(
            diagnosticName: name,
            isHealthy: criticalIssues.isEmpty,
            scoreImpact: scoreImpact,
            criticalIssues: criticalIssues,
            warnings: warnings,
            details: [
                "物理内存": "\(String(format: "%.1f", memoryDetails.residentSize)) MB",
                "虚拟内存": "\(String(format: "%.1f", memoryDetails.virtualSize)) MB"
            ]
        )
    }
}

// MARK: - CPU Diagnostic

/// CPU诊断器
struct CPUDiagnostic: HealthDiagnostic {
    let name = "CPU诊断"
    
    func performDiagnosis() -> DiagnosticResult {
        let cpuUsage = PerformanceManager.shared.currentCPUUsage
        
        var scoreImpact = 0.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        
        if cpuUsage > 90.0 {
            criticalIssues.append(HealthIssue(
                type: .resourceExhaustion,
                description: "CPU使用率过高: \(String(format: "%.1f", cpuUsage))%",
                severity: .critical
            ))
            scoreImpact += 20.0
        } else if cpuUsage > 70.0 {
            warnings.append(HealthIssue(
                type: .resourceExhaustion,
                description: "CPU使用率较高: \(String(format: "%.1f", cpuUsage))%",
                severity: .warning
            ))
            scoreImpact += 8.0
        }
        
        return DiagnosticResult(
            diagnosticName: name,
            isHealthy: criticalIssues.isEmpty,
            scoreImpact: scoreImpact,
            criticalIssues: criticalIssues,
            warnings: warnings,
            details: [
                "CPU使用率": "\(String(format: "%.1f", cpuUsage))%"
            ]
        )
    }
}

// MARK: - Network Diagnostic

/// 网络诊断器
struct NetworkDiagnostic: HealthDiagnostic {
    let name = "网络诊断"
    
    func performDiagnosis() -> DiagnosticResult {
        let wifiStatus = ComponentCommunicationManager.shared.currentWiFiStatus
        let isConnected = ComponentCommunicationManager.shared.isNetworkConnected
        
        var scoreImpact = 0.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        
        switch wifiStatus {
        case .error(let error):
            criticalIssues.append(HealthIssue(
                type: .networkFailure,
                description: "WiFi错误: \(error.localizedDescription)",
                severity: .critical
            ))
            scoreImpact += 15.0
            
        case .disabled:
            warnings.append(HealthIssue(
                type: .networkFailure,
                description: "WiFi已禁用",
                severity: .warning
            ))
            scoreImpact += 5.0
            
        case .disconnected:
            if !isConnected {
                warnings.append(HealthIssue(
                    type: .networkFailure,
                    description: "网络未连接",
                    severity: .warning
                ))
                scoreImpact += 3.0
            }
            
        default:
            break
        }
        
        return DiagnosticResult(
            diagnosticName: name,
            isHealthy: criticalIssues.isEmpty,
            scoreImpact: scoreImpact,
            criticalIssues: criticalIssues,
            warnings: warnings,
            details: [
                "WiFi状态": wifiStatus.shortDescription,
                "网络连接": isConnected ? "已连接" : "未连接"
            ]
        )
    }
}

// MARK: - Component Diagnostic

/// 组件诊断器
struct ComponentDiagnostic: HealthDiagnostic {
    let name = "组件诊断"
    
    func performDiagnosis() -> DiagnosticResult {
        var scoreImpact = 0.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        var details: [String: String] = [:]
        
        // 检查稳定性管理器状态
        let stabilityManager = StabilityManager.shared
        let healthStatus = stabilityManager.healthStatus
        
        switch healthStatus {
        case .critical:
            criticalIssues.append(HealthIssue(
                type: .componentFailure,
                description: "稳定性管理器状态严重",
                severity: .critical
            ))
            scoreImpact += 20.0
            
        case .warning:
            warnings.append(HealthIssue(
                type: .componentFailure,
                description: "稳定性管理器状态警告",
                severity: .warning
            ))
            scoreImpact += 8.0
            
        default:
            break
        }
        
        details["稳定性状态"] = healthStatus.description
        
        // 检查崩溃恢复状态
        let crashRecoveryStatus = stabilityManager.crashRecoveryStatus
        if crashRecoveryStatus != .none {
            warnings.append(HealthIssue(
                type: .componentFailure,
                description: "崩溃恢复状态: \(crashRecoveryStatus.description)",
                severity: .warning
            ))
            scoreImpact += 5.0
        }
        
        details["崩溃恢复"] = crashRecoveryStatus.description
        
        return DiagnosticResult(
            diagnosticName: name,
            isHealthy: criticalIssues.isEmpty,
            scoreImpact: scoreImpact,
            criticalIssues: criticalIssues,
            warnings: warnings,
            details: details
        )
    }
}

// MARK: - File System Diagnostic

/// 文件系统诊断器
struct FileSystemDiagnostic: HealthDiagnostic {
    let name = "文件系统诊断"
    
    func performDiagnosis() -> DiagnosticResult {
        var scoreImpact = 0.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        var details: [String: String] = [:]
        
        // 检查磁盘空间
        if let diskSpace = getDiskSpace() {
            let freeSpaceGB = Double(diskSpace.free) / 1024 / 1024 / 1024
            let totalSpaceGB = Double(diskSpace.total) / 1024 / 1024 / 1024
            let usagePercentage = (1.0 - Double(diskSpace.free) / Double(diskSpace.total)) * 100
            
            details["可用空间"] = "\(String(format: "%.1f", freeSpaceGB)) GB"
            details["总空间"] = "\(String(format: "%.1f", totalSpaceGB)) GB"
            details["使用率"] = "\(String(format: "%.1f", usagePercentage))%"
            
            if freeSpaceGB < 1.0 {
                criticalIssues.append(HealthIssue(
                    type: .resourceExhaustion,
                    description: "磁盘空间严重不足: \(String(format: "%.1f", freeSpaceGB)) GB",
                    severity: .critical
                ))
                scoreImpact += 15.0
            } else if freeSpaceGB < 5.0 {
                warnings.append(HealthIssue(
                    type: .resourceExhaustion,
                    description: "磁盘空间不足: \(String(format: "%.1f", freeSpaceGB)) GB",
                    severity: .warning
                ))
                scoreImpact += 5.0
            }
        }
        
        // 检查应用数据目录
        if !checkApplicationDataDirectory() {
            criticalIssues.append(HealthIssue(
                type: .componentFailure,
                description: "应用数据目录不可访问",
                severity: .critical
            ))
            scoreImpact += 10.0
        }
        
        return DiagnosticResult(
            diagnosticName: name,
            isHealthy: criticalIssues.isEmpty,
            scoreImpact: scoreImpact,
            criticalIssues: criticalIssues,
            warnings: warnings,
            details: details
        )
    }
    
    private func getDiskSpace() -> (free: Int64, total: Int64)? {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        
        do {
            let values = try homeURL.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey
            ])
            
            guard let free = values.volumeAvailableCapacity,
                  let total = values.volumeTotalCapacity else {
                return nil
            }
            
            return (free: Int64(free), total: Int64(total))
        } catch {
            return nil
        }
    }
    
    private func checkApplicationDataDirectory() -> Bool {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let appURL = appSupportURL?.appendingPathComponent("WiFiMenuBar") else {
            return false
        }
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: appURL.path, isDirectory: &isDirectory)
        
        return exists && isDirectory.boolValue
    }
}

// MARK: - Performance Diagnostic

/// 性能诊断器
struct PerformanceDiagnostic: HealthDiagnostic {
    let name = "性能诊断"
    
    func performDiagnosis() -> DiagnosticResult {
        let performanceManager = PerformanceManager.shared
        let performanceStatus = performanceManager.performanceStatus
        
        var scoreImpact = 0.0
        var criticalIssues: [HealthIssue] = []
        var warnings: [HealthIssue] = []
        
        switch performanceStatus {
        case .critical:
            criticalIssues.append(HealthIssue(
                type: .resourceExhaustion,
                description: "性能状态严重",
                severity: .critical
            ))
            scoreImpact += 20.0
            
        case .warning:
            warnings.append(HealthIssue(
                type: .resourceExhaustion,
                description: "性能状态警告",
                severity: .warning
            ))
            scoreImpact += 8.0
            
        default:
            break
        }
        
        return DiagnosticResult(
            diagnosticName: name,
            isHealthy: criticalIssues.isEmpty,
            scoreImpact: scoreImpact,
            criticalIssues: criticalIssues,
            warnings: warnings,
            details: [
                "性能状态": performanceStatus.description,
                "监控状态": performanceManager.isMonitoringEnabled ? "启用" : "禁用"
            ]
        )
    }
}

// MARK: - Supporting Types

/// 应用健康状态
enum ApplicationHealthStatus: String, CaseIterable, Codable {
    case unknown = "unknown"
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .unknown: return "未知"
        case .excellent: return "优秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "较差"
        case .critical: return "严重"
        }
    }
    
    var color: NSColor {
        switch self {
        case .excellent: return .systemGreen
        case .good: return .systemBlue
        case .fair: return .systemYellow
        case .poor: return .systemOrange
        case .critical: return .systemRed
        case .unknown: return .systemGray
        }
    }
}

/// 健康趋势
enum HealthTrend: String, CaseIterable, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var description: String {
        switch self {
        case .improving: return "改善中"
        case .stable: return "稳定"
        case .declining: return "恶化中"
        }
    }
}

/// 诊断结果
struct DiagnosticResult: Codable {
    let diagnosticName: String
    let isHealthy: Bool
    let scoreImpact: Double
    let criticalIssues: [HealthIssue]
    let warnings: [HealthIssue]
    let details: [String: String]
    let timestamp: Date
    
    init(diagnosticName: String, isHealthy: Bool, scoreImpact: Double, criticalIssues: [HealthIssue], warnings: [HealthIssue], details: [String: String]) {
        self.diagnosticName = diagnosticName
        self.isHealthy = isHealthy
        self.scoreImpact = scoreImpact
        self.criticalIssues = criticalIssues
        self.warnings = warnings
        self.details = details
        self.timestamp = Date()
    }
}

/// 健康快照
struct HealthSnapshot: Codable {
    let timestamp: Date
    let healthStatus: ApplicationHealthStatus
    let overallScore: Double
    let diagnosticResults: [DiagnosticResult]
    let criticalIssues: [HealthIssue]
    let warnings: [HealthIssue]
    let checkDuration: TimeInterval
}

/// 健康报告
struct HealthReport: Codable {
    let currentStatus: ApplicationHealthStatus
    let averageScore: Double
    let trend: HealthTrend
    let totalChecks: Int
    let criticalIssuesCount: Int
    let warningsCount: Int
    let lastCheckTime: Date?
    let recommendations: [String]
    
    var description: String {
        return """
        健康报告:
        - 当前状态: \(currentStatus.description)
        - 平均分数: \(String(format: "%.1f", averageScore))
        - 趋势: \(trend.description)
        - 检查次数: \(totalChecks)
        - 严重问题: \(criticalIssuesCount)
        - 警告: \(warningsCount)
        - 最后检查: \(lastCheckTime?.description ?? "无")
        - 建议: \(recommendations.joined(separator: "; "))
        """
    }
}

/// 健康导出数据
struct HealthExportData: Codable {
    let exportTime: Date
    let currentStatus: ApplicationHealthStatus
    let healthHistory: [HealthSnapshot]
    let healthReport: HealthReport
}

// MARK: - Notification Names

extension Notification.Name {
    static let applicationHealthStatusChanged = Notification.Name("applicationHealthStatusChanged")
}