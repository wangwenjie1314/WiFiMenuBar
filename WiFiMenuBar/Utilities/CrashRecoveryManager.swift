import Foundation
import os.log

/// 崩溃恢复管理器
/// 负责处理应用崩溃后的恢复流程
class CrashRecoveryManager {
    
    // MARK: - Properties
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.recovery", category: "CrashRecoveryManager")
    
    /// 恢复操作历史
    private var recoveryActions: [String] = []
    
    /// 恢复策略
    private let recoveryStrategies: [RecoveryStrategy] = [
        ComponentResetStrategy(),
        CacheCleanupStrategy(),
        PreferencesResetStrategy(),
        NetworkResetStrategy()
    ]
    
    // MARK: - Public Methods
    
    /// 启动崩溃恢复流程
    /// - Parameter crashRecord: 崩溃记录
    func initiateCrashRecovery(_ crashRecord: CrashRecord) {
        print("CrashRecoveryManager: 启动崩溃恢复流程")
        
        os_log("开始崩溃恢复 - 崩溃类型: %@", log: logger, type: .info, crashRecord.crashInfo.type.description)
        
        // 分析崩溃原因
        let crashAnalysis = analyzeCrash(crashRecord)
        
        // 选择恢复策略
        let selectedStrategies = selectRecoveryStrategies(for: crashAnalysis)
        
        // 执行恢复策略
        executeRecoveryStrategies(selectedStrategies)
        
        // 记录恢复操作
        recordRecoveryAction("崩溃恢复完成 - 崩溃类型: \(crashRecord.crashInfo.type.description)")
        
        os_log("崩溃恢复流程完成", log: logger, type: .info)
    }
    
    /// 获取恢复操作历史
    /// - Returns: 恢复操作列表
    func getRecoveryActions() -> [String] {
        return recoveryActions
    }
    
    /// 清除恢复操作历史
    func clearRecoveryActions() {
        recoveryActions.removeAll()
        os_log("恢复操作历史已清除", log: logger, type: .info)
    }
    
    /// 执行手动恢复
    /// - Parameter recoveryType: 恢复类型
    func performManualRecovery(_ recoveryType: RecoveryType) {
        print("CrashRecoveryManager: 执行手动恢复 - \(recoveryType.description)")
        
        let strategies = recoveryStrategies.filter { $0.canHandle(recoveryType) }
        executeRecoveryStrategies(strategies)
        
        recordRecoveryAction("手动恢复 - \(recoveryType.description)")
    }
    
    // MARK: - Private Methods
    
    /// 分析崩溃
    /// - Parameter crashRecord: 崩溃记录
    /// - Returns: 崩溃分析结果
    private func analyzeCrash(_ crashRecord: CrashRecord) -> CrashAnalysis {
        let crashInfo = crashRecord.crashInfo
        
        var possibleCauses: [CrashCause] = []
        var recommendedActions: [RecoveryType] = []
        
        switch crashInfo.type {
        case .signal:
            if let signal = crashInfo.signal {
                switch signal {
                case SIGSEGV:
                    possibleCauses.append(.memoryCorruption)
                    recommendedActions.append(.componentReset)
                    recommendedActions.append(.cacheCleanup)
                case SIGABRT:
                    possibleCauses.append(.assertionFailure)
                    recommendedActions.append(.componentReset)
                case SIGFPE:
                    possibleCauses.append(.arithmeticError)
                    recommendedActions.append(.componentReset)
                default:
                    possibleCauses.append(.unknownSignal)
                    recommendedActions.append(.fullReset)
                }
            }
            
        case .exception:
            possibleCauses.append(.unhandledException)
            recommendedActions.append(.componentReset)
            recommendedActions.append(.cacheCleanup)
            
        case .assertion:
            possibleCauses.append(.assertionFailure)
            recommendedActions.append(.componentReset)
            
        case .memoryError:
            possibleCauses.append(.memoryCorruption)
            recommendedActions.append(.cacheCleanup)
            recommendedActions.append(.componentReset)
            
        case .unknown:
            possibleCauses.append(.unknown)
            recommendedActions.append(.fullReset)
        }
        
        // 分析堆栈跟踪
        analyzeStackTrace(crashInfo.stackTrace, possibleCauses: &possibleCauses, recommendedActions: &recommendedActions)
        
        return CrashAnalysis(
            crashType: crashInfo.type,
            possibleCauses: possibleCauses,
            recommendedActions: recommendedActions,
            severity: determineSeverity(possibleCauses)
        )
    }
    
    /// 分析堆栈跟踪
    /// - Parameters:
    ///   - stackTrace: 堆栈跟踪
    ///   - possibleCauses: 可能的原因（输出参数）
    ///   - recommendedActions: 推荐的操作（输出参数）
    private func analyzeStackTrace(_ stackTrace: [String], possibleCauses: inout [CrashCause], recommendedActions: inout [RecoveryType]) {
        let stackTraceString = stackTrace.joined(separator: "\n")
        
        // 检查是否包含特定的框架或组件
        if stackTraceString.contains("CoreWLAN") {
            possibleCauses.append(.networkFrameworkError)
            recommendedActions.append(.networkReset)
        }
        
        if stackTraceString.contains("NSStatusBar") {
            possibleCauses.append(.uiFrameworkError)
            recommendedActions.append(.componentReset)
        }
        
        if stackTraceString.contains("UserDefaults") {
            possibleCauses.append(.preferencesCorruption)
            recommendedActions.append(.preferencesReset)
        }
        
        if stackTraceString.contains("malloc") || stackTraceString.contains("free") {
            possibleCauses.append(.memoryCorruption)
            recommendedActions.append(.cacheCleanup)
        }
    }
    
    /// 确定严重程度
    /// - Parameter causes: 可能的原因
    /// - Returns: 严重程度
    private func determineSeverity(_ causes: [CrashCause]) -> CrashSeverity {
        if causes.contains(.memoryCorruption) || causes.contains(.assertionFailure) {
            return .critical
        } else if causes.contains(.unhandledException) || causes.contains(.networkFrameworkError) {
            return .moderate
        } else {
            return .low
        }
    }
    
    /// 选择恢复策略
    /// - Parameter analysis: 崩溃分析结果
    /// - Returns: 选中的恢复策略
    private func selectRecoveryStrategies(for analysis: CrashAnalysis) -> [RecoveryStrategy] {
        var selectedStrategies: [RecoveryStrategy] = []
        
        for action in analysis.recommendedActions {
            let strategies = recoveryStrategies.filter { $0.canHandle(action) }
            selectedStrategies.append(contentsOf: strategies)
        }
        
        // 去重
        return Array(Set(selectedStrategies))
    }
    
    /// 执行恢复策略
    /// - Parameter strategies: 恢复策略列表
    private func executeRecoveryStrategies(_ strategies: [RecoveryStrategy]) {
        for strategy in strategies {
            do {
                try strategy.execute()
                recordRecoveryAction("执行恢复策略: \(strategy.name)")
                os_log("恢复策略执行成功: %@", log: logger, type: .info, strategy.name)
            } catch {
                recordRecoveryAction("恢复策略执行失败: \(strategy.name) - \(error.localizedDescription)")
                os_log("恢复策略执行失败: %@ - %@", log: logger, type: .error, strategy.name, error.localizedDescription)
            }
        }
    }
    
    /// 记录恢复操作
    /// - Parameter action: 恢复操作描述
    private func recordRecoveryAction(_ action: String) {
        let timestampedAction = "[\(Date())] \(action)"
        recoveryActions.append(timestampedAction)
        
        // 限制历史记录数量
        if recoveryActions.count > 50 {
            recoveryActions = Array(recoveryActions.suffix(50))
        }
    }
}

// MARK: - Recovery Strategy Protocol

/// 恢复策略协议
protocol RecoveryStrategy: Hashable {
    var name: String { get }
    func canHandle(_ recoveryType: RecoveryType) -> Bool
    func execute() throws
}

// MARK: - Component Reset Strategy

/// 组件重置策略
struct ComponentResetStrategy: RecoveryStrategy {
    let name = "组件重置"
    
    func canHandle(_ recoveryType: RecoveryType) -> Bool {
        return recoveryType == .componentReset || recoveryType == .fullReset
    }
    
    func execute() throws {
        // 重置所有组件
        NotificationCenter.default.post(name: .resetWiFiMonitor, object: nil)
        NotificationCenter.default.post(name: .resetStatusBarController, object: nil)
        NotificationCenter.default.post(name: .resetPreferencesManager, object: nil)
        
        print("ComponentResetStrategy: 组件重置完成")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: ComponentResetStrategy, rhs: ComponentResetStrategy) -> Bool {
        return lhs.name == rhs.name
    }
}

// MARK: - Cache Cleanup Strategy

/// 缓存清理策略
struct CacheCleanupStrategy: RecoveryStrategy {
    let name = "缓存清理"
    
    func canHandle(_ recoveryType: RecoveryType) -> Bool {
        return recoveryType == .cacheCleanup || recoveryType == .fullReset
    }
    
    func execute() throws {
        // 清理所有缓存
        URLCache.shared.removeAllCachedResponses()
        ComponentCommunicationManager.shared.clearHistory()
        PerformanceManager.shared.clearPerformanceHistory()
        
        // 清理临时文件
        cleanupTemporaryFiles()
        
        print("CacheCleanupStrategy: 缓存清理完成")
    }
    
    private func cleanupTemporaryFiles() {
        let tempDir = NSTemporaryDirectory()
        let fileManager = FileManager.default
        
        do {
            let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDir)
            for file in tempFiles {
                if file.hasPrefix("WiFiMenuBar") {
                    let filePath = (tempDir as NSString).appendingPathComponent(file)
                    try fileManager.removeItem(atPath: filePath)
                }
            }
        } catch {
            print("CacheCleanupStrategy: 清理临时文件失败 - \(error)")
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: CacheCleanupStrategy, rhs: CacheCleanupStrategy) -> Bool {
        return lhs.name == rhs.name
    }
}

// MARK: - Preferences Reset Strategy

/// 偏好设置重置策略
struct PreferencesResetStrategy: RecoveryStrategy {
    let name = "偏好设置重置"
    
    func canHandle(_ recoveryType: RecoveryType) -> Bool {
        return recoveryType == .preferencesReset || recoveryType == .fullReset
    }
    
    func execute() throws {
        // 重置偏好设置
        PreferencesManager.shared.resetToDefaults()
        
        print("PreferencesResetStrategy: 偏好设置重置完成")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: PreferencesResetStrategy, rhs: PreferencesResetStrategy) -> Bool {
        return lhs.name == rhs.name
    }
}

// MARK: - Network Reset Strategy

/// 网络重置策略
struct NetworkResetStrategy: RecoveryStrategy {
    let name = "网络重置"
    
    func canHandle(_ recoveryType: RecoveryType) -> Bool {
        return recoveryType == .networkReset || recoveryType == .fullReset
    }
    
    func execute() throws {
        // 重置网络组件
        NotificationCenter.default.post(name: .resetNetworkComponents, object: nil)
        NotificationCenter.default.post(name: .resetNetworkConnections, object: nil)
        
        print("NetworkResetStrategy: 网络重置完成")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: NetworkResetStrategy, rhs: NetworkResetStrategy) -> Bool {
        return lhs.name == rhs.name
    }
}

// MARK: - Supporting Types

/// 崩溃分析结果
struct CrashAnalysis {
    let crashType: CrashType
    let possibleCauses: [CrashCause]
    let recommendedActions: [RecoveryType]
    let severity: CrashSeverity
}

/// 崩溃原因
enum CrashCause: String, CaseIterable {
    case memoryCorruption = "memoryCorruption"
    case assertionFailure = "assertionFailure"
    case unhandledException = "unhandledException"
    case networkFrameworkError = "networkFrameworkError"
    case uiFrameworkError = "uiFrameworkError"
    case preferencesCorruption = "preferencesCorruption"
    case arithmeticError = "arithmeticError"
    case unknownSignal = "unknownSignal"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .memoryCorruption: return "内存损坏"
        case .assertionFailure: return "断言失败"
        case .unhandledException: return "未处理异常"
        case .networkFrameworkError: return "网络框架错误"
        case .uiFrameworkError: return "UI框架错误"
        case .preferencesCorruption: return "偏好设置损坏"
        case .arithmeticError: return "算术错误"
        case .unknownSignal: return "未知信号"
        case .unknown: return "未知原因"
        }
    }
}

/// 恢复类型
enum RecoveryType: String, CaseIterable {
    case componentReset = "componentReset"
    case cacheCleanup = "cacheCleanup"
    case preferencesReset = "preferencesReset"
    case networkReset = "networkReset"
    case fullReset = "fullReset"
    
    var description: String {
        switch self {
        case .componentReset: return "组件重置"
        case .cacheCleanup: return "缓存清理"
        case .preferencesReset: return "偏好设置重置"
        case .networkReset: return "网络重置"
        case .fullReset: return "完全重置"
        }
    }
}

/// 崩溃严重程度
enum CrashSeverity: String, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .low: return "轻微"
        case .moderate: return "中等"
        case .critical: return "严重"
        }
    }
}