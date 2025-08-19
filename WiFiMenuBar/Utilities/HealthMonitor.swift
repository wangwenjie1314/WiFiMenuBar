import Foundation
import os.log

/// 健康监控器
/// 负责监控应用各个组件的健康状态
class HealthMonitor {
    
    // MARK: - Properties
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.health", category: "HealthMonitor")
    
    /// 健康检查项目
    private let healthCheckers: [HealthChecker] = [
        MemoryHealthChecker(),
        CPUHealthChecker(),
        ComponentHealthChecker(),
        NetworkHealthChecker(),
        FileSystemHealthChecker()
    ]
    
    // MARK: - Public Methods
    
    /// 执行综合健康检查
    /// - Returns: 健康检查结果
    func performComprehensiveHealthCheck() -> HealthCheckResult {
        var warnings: [HealthIssue] = []
        var criticalIssues: [HealthIssue] = []
        var healthyComponents: [String] = []
        
        for checker in healthCheckers {
            let result = checker.performCheck()
            
            warnings.append(contentsOf: result.warnings)
            criticalIssues.append(contentsOf: result.criticalIssues)
            
            if result.isHealthy {
                healthyComponents.append(checker.componentName)
            }
        }
        
        let isHealthy = criticalIssues.isEmpty && warnings.count < 3
        
        let result = HealthCheckResult(
            isHealthy: isHealthy,
            warnings: warnings,
            criticalIssues: criticalIssues,
            healthyComponents: healthyComponents,
            checkTime: Date()
        )
        
        os_log("健康检查完成 - 健康: %@, 警告: %d, 严重: %d", 
               log: logger, type: .info, 
               isHealthy ? "是" : "否", warnings.count, criticalIssues.count)
        
        return result
    }
    
    /// 检查特定组件的健康状态
    /// - Parameter componentName: 组件名称
    /// - Returns: 健康检查结果
    func checkComponentHealth(_ componentName: String) -> HealthCheckResult {
        guard let checker = healthCheckers.first(where: { $0.componentName == componentName }) else {
            return HealthCheckResult(
                isHealthy: false,
                warnings: [],
                criticalIssues: [HealthIssue(type: .componentFailure, description: "未找到组件检查器: \(componentName)", severity: .critical)],
                healthyComponents: [],
                checkTime: Date()
            )
        }
        
        return checker.performCheck()
    }
}

// MARK: - Health Checker Protocol

/// 健康检查器协议
protocol HealthChecker {
    var componentName: String { get }
    func performCheck() -> HealthCheckResult
}

// MARK: - Memory Health Checker

/// 内存健康检查器
class MemoryHealthChecker: HealthChecker {
    let componentName = "内存"
    
    func performCheck() -> HealthCheckResult {
        let memoryDetails = PerformanceManager.shared.getMemoryUsageDetails()
        
        var warnings: [HealthIssue] = []
        var criticalIssues: [HealthIssue] = []
        
        // 检查内存使用量
        if memoryDetails.residentSize > 200.0 {
            criticalIssues.append(HealthIssue(
                type: .memoryLeak,
                description: "内存使用过高: \(String(format: "%.1f", memoryDetails.residentSize)) MB",
                severity: .critical
            ))
        } else if memoryDetails.residentSize > 100.0 {
            warnings.append(HealthIssue(
                type: .memoryLeak,
                description: "内存使用较高: \(String(format: "%.1f", memoryDetails.residentSize)) MB",
                severity: .warning
            ))
        }
        
        // 检查虚拟内存
        if memoryDetails.virtualSize > 1000.0 {
            warnings.append(HealthIssue(
                type: .memoryLeak,
                description: "虚拟内存使用较高: \(String(format: "%.1f", memoryDetails.virtualSize)) MB",
                severity: .warning
            ))
        }
        
        return HealthCheckResult(
            isHealthy: criticalIssues.isEmpty,
            warnings: warnings,
            criticalIssues: criticalIssues,
            healthyComponents: criticalIssues.isEmpty ? [componentName] : [],
            checkTime: Date()
        )
    }
}

// MARK: - CPU Health Checker

/// CPU健康检查器
class CPUHealthChecker: HealthChecker {
    let componentName = "CPU"
    
    func performCheck() -> HealthCheckResult {
        let cpuUsage = PerformanceManager.shared.currentCPUUsage
        
        var warnings: [HealthIssue] = []
        var criticalIssues: [HealthIssue] = []
        
        if cpuUsage > 80.0 {
            criticalIssues.append(HealthIssue(
                type: .resourceExhaustion,
                description: "CPU使用率过高: \(String(format: "%.1f", cpuUsage))%",
                severity: .critical
            ))
        } else if cpuUsage > 50.0 {
            warnings.append(HealthIssue(
                type: .resourceExhaustion,
                description: "CPU使用率较高: \(String(format: "%.1f", cpuUsage))%",
                severity: .warning
            ))
        }
        
        return HealthCheckResult(
            isHealthy: criticalIssues.isEmpty,
            warnings: warnings,
            criticalIssues: criticalIssues,
            healthyComponents: criticalIssues.isEmpty ? [componentName] : [],
            checkTime: Date()
        )
    }
}

// MARK: - Component Health Checker

/// 组件健康检查器
class ComponentHealthChecker: HealthChecker {
    let componentName = "组件"
    
    func performCheck() -> HealthCheckResult {
        var warnings: [HealthIssue] = []
        var criticalIssues: [HealthIssue] = []
        var healthyComponents: [String] = []
        
        // 检查WiFiMonitor
        if checkWiFiMonitorHealth() {
            healthyComponents.append("WiFiMonitor")
        } else {
            criticalIssues.append(HealthIssue(
                type: .componentFailure,
                description: "WiFiMonitor组件异常",
                severity: .critical
            ))
        }
        
        // 检查StatusBarController
        if checkStatusBarControllerHealth() {
            healthyComponents.append("StatusBarController")
        } else {
            warnings.append(HealthIssue(
                type: .componentFailure,
                description: "StatusBarController组件异常",
                severity: .warning
            ))
        }
        
        // 检查PreferencesManager
        if checkPreferencesManagerHealth() {
            healthyComponents.append("PreferencesManager")
        } else {
            warnings.append(HealthIssue(
                type: .componentFailure,
                description: "PreferencesManager组件异常",
                severity: .warning
            ))
        }
        
        return HealthCheckResult(
            isHealthy: criticalIssues.isEmpty,
            warnings: warnings,
            criticalIssues: criticalIssues,
            healthyComponents: healthyComponents,
            checkTime: Date()
        )
    }
    
    private func checkWiFiMonitorHealth() -> Bool {
        // 检查WiFiMonitor是否正常工作
        // 这里可以添加具体的检查逻辑
        return true
    }
    
    private func checkStatusBarControllerHealth() -> Bool {
        // 检查StatusBarController是否正常工作
        return true
    }
    
    private func checkPreferencesManagerHealth() -> Bool {
        // 检查PreferencesManager是否正常工作
        return true
    }
}

// MARK: - Network Health Checker

/// 网络健康检查器
class NetworkHealthChecker: HealthChecker {
    let componentName = "网络"
    
    func performCheck() -> HealthCheckResult {
        var warnings: [HealthIssue] = []
        var criticalIssues: [HealthIssue] = []
        
        // 检查网络连接状态
        let isConnected = ComponentCommunicationManager.shared.isNetworkConnected
        
        if !isConnected {
            warnings.append(HealthIssue(
                type: .networkFailure,
                description: "网络连接断开",
                severity: .warning
            ))
        }
        
        // 检查WiFi状态
        let wifiStatus = ComponentCommunicationManager.shared.currentWiFiStatus
        
        switch wifiStatus {
        case .error:
            criticalIssues.append(HealthIssue(
                type: .networkFailure,
                description: "WiFi状态错误",
                severity: .critical
            ))
        case .disabled:
            warnings.append(HealthIssue(
                type: .networkFailure,
                description: "WiFi已禁用",
                severity: .warning
            ))
        default:
            break
        }
        
        return HealthCheckResult(
            isHealthy: criticalIssues.isEmpty,
            warnings: warnings,
            criticalIssues: criticalIssues,
            healthyComponents: criticalIssues.isEmpty ? [componentName] : [],
            checkTime: Date()
        )
    }
}

// MARK: - File System Health Checker

/// 文件系统健康检查器
class FileSystemHealthChecker: HealthChecker {
    let componentName = "文件系统"
    
    func performCheck() -> HealthCheckResult {
        var warnings: [HealthIssue] = []
        var criticalIssues: [HealthIssue] = []
        
        // 检查磁盘空间
        if let diskSpace = getDiskSpace() {
            let freeSpaceGB = diskSpace.free / 1024 / 1024 / 1024
            
            if freeSpaceGB < 1.0 {
                criticalIssues.append(HealthIssue(
                    type: .resourceExhaustion,
                    description: "磁盘空间不足: \(String(format: "%.1f", freeSpaceGB)) GB",
                    severity: .critical
                ))
            } else if freeSpaceGB < 5.0 {
                warnings.append(HealthIssue(
                    type: .resourceExhaustion,
                    description: "磁盘空间较少: \(String(format: "%.1f", freeSpaceGB)) GB",
                    severity: .warning
                ))
            }
        }
        
        // 检查应用数据目录
        if !checkApplicationDataDirectory() {
            criticalIssues.append(HealthIssue(
                type: .componentFailure,
                description: "应用数据目录不可访问",
                severity: .critical
            ))
        }
        
        return HealthCheckResult(
            isHealthy: criticalIssues.isEmpty,
            warnings: warnings,
            criticalIssues: criticalIssues,
            healthyComponents: criticalIssues.isEmpty ? [componentName] : [],
            checkTime: Date()
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
        
        if !exists {
            // 尝试创建目录
            do {
                try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true, attributes: nil)
                return true
            } catch {
                return false
            }
        }
        
        return isDirectory.boolValue
    }
}

// MARK: - Supporting Types

/// 健康检查结果
struct HealthCheckResult {
    let isHealthy: Bool
    let warnings: [HealthIssue]
    let criticalIssues: [HealthIssue]
    let healthyComponents: [String]
    let checkTime: Date
    
    var description: String {
        return """
        健康检查结果:
        - 整体健康: \(isHealthy ? "是" : "否")
        - 警告数量: \(warnings.count)
        - 严重问题数量: \(criticalIssues.count)
        - 健康组件: \(healthyComponents.joined(separator: ", "))
        - 检查时间: \(checkTime)
        """
    }
}

/// 健康问题
struct HealthIssue {
    let type: HealthIssueType
    let description: String
    let severity: HealthIssueSeverity
    let timestamp: Date
    
    init(type: HealthIssueType, description: String, severity: HealthIssueSeverity) {
        self.type = type
        self.description = description
        self.severity = severity
        self.timestamp = Date()
    }
}

/// 健康问题类型
enum HealthIssueType: String, CaseIterable {
    case memoryLeak = "memoryLeak"
    case componentFailure = "componentFailure"
    case resourceExhaustion = "resourceExhaustion"
    case networkFailure = "networkFailure"
    
    var description: String {
        switch self {
        case .memoryLeak: return "内存泄漏"
        case .componentFailure: return "组件故障"
        case .resourceExhaustion: return "资源耗尽"
        case .networkFailure: return "网络故障"
        }
    }
}

/// 健康问题严重程度
enum HealthIssueSeverity: String, CaseIterable {
    case warning = "warning"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .warning: return "警告"
        case .critical: return "严重"
        }
    }
    
    var color: NSColor {
        switch self {
        case .warning: return .systemOrange
        case .critical: return .systemRed
        }
    }
}