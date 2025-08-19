import Foundation
import os.log

/// 稳定性诊断工具
/// 提供深度的稳定性分析和诊断功能
class StabilityDiagnosticTool {
    
    // MARK: - Properties
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.diagnostic", category: "StabilityDiagnosticTool")
    
    /// 稳定性管理器
    private let stabilityManager = StabilityManager.shared
    
    /// 健康监控器
    private let healthMonitor = ApplicationHealthMonitor.shared
    
    /// 性能管理器
    private let performanceManager = PerformanceManager.shared
    
    // MARK: - Public Methods
    
    /// 执行完整的稳定性诊断
    func performComprehensiveDiagnosis() -> ComprehensiveDiagnosisResult {
        print("StabilityDiagnosticTool: 执行完整稳定性诊断")
        
        let diagnosisStartTime = Date()
        
        // 1. 基础健康检查
        let healthCheck = performBasicHealthCheck()
        
        // 2. 稳定性分析
        let stabilityAnalysis = performStabilityAnalysis()
        
        // 3. 性能分析
        let performanceAnalysis = performPerformanceAnalysis()
        
        // 4. 组件状态分析
        let componentAnalysis = performComponentAnalysis()
        
        // 5. 历史趋势分析
        let trendAnalysis = performTrendAnalysis()
        
        // 6. 风险评估
        let riskAssessment = performRiskAssessment()
        
        // 7. 生成综合建议
        let recommendations = generateComprehensiveRecommendations(
            healthCheck: healthCheck,
            stabilityAnalysis: stabilityAnalysis,
            performanceAnalysis: performanceAnalysis,
            componentAnalysis: componentAnalysis,
            trendAnalysis: trendAnalysis,
            riskAssessment: riskAssessment
        )
        
        let diagnosisDuration = Date().timeIntervalSince(diagnosisStartTime)
        
        let result = ComprehensiveDiagnosisResult(
            timestamp: diagnosisStartTime,
            duration: diagnosisDuration,
            healthCheck: healthCheck,
            stabilityAnalysis: stabilityAnalysis,
            performanceAnalysis: performanceAnalysis,
            componentAnalysis: componentAnalysis,
            trendAnalysis: trendAnalysis,
            riskAssessment: riskAssessment,
            recommendations: recommendations
        )
        
        os_log("完整稳定性诊断完成，耗时: %.2f 秒", log: logger, type: .info, diagnosisDuration)
        
        return result
    }
    
    /// 执行快速诊断
    func performQuickDiagnosis() -> QuickDiagnosisResult {
        print("StabilityDiagnosticTool: 执行快速诊断")
        
        let diagnosisStartTime = Date()
        
        // 快速检查关键指标
        let memoryUsage = performanceManager.currentMemoryUsage
        let cpuUsage = performanceManager.currentCPUUsage
        let healthStatus = healthMonitor.currentHealthStatus
        let stabilityScore = stabilityManager.getStabilityReport().stabilityScore
        
        // 检查是否有严重问题
        var criticalIssues: [String] = []
        var warnings: [String] = []
        
        if memoryUsage > 200.0 {
            criticalIssues.append("内存使用过高: \(String(format: "%.1f", memoryUsage)) MB")
        } else if memoryUsage > 150.0 {
            warnings.append("内存使用较高: \(String(format: "%.1f", memoryUsage)) MB")
        }
        
        if cpuUsage > 80.0 {
            criticalIssues.append("CPU使用率过高: \(String(format: "%.1f", cpuUsage))%")
        } else if cpuUsage > 50.0 {
            warnings.append("CPU使用率较高: \(String(format: "%.1f", cpuUsage))%")
        }
        
        if healthStatus == .critical || healthStatus == .poor {
            criticalIssues.append("应用健康状态: \(healthStatus.description)")
        }
        
        if stabilityScore < 50.0 {
            criticalIssues.append("稳定性分数过低: \(String(format: "%.1f", stabilityScore))")
        } else if stabilityScore < 70.0 {
            warnings.append("稳定性分数较低: \(String(format: "%.1f", stabilityScore))")
        }
        
        // 确定整体状态
        let overallStatus: DiagnosisStatus
        if !criticalIssues.isEmpty {
            overallStatus = .critical
        } else if !warnings.isEmpty {
            overallStatus = .warning
        } else {
            overallStatus = .healthy
        }
        
        let diagnosisDuration = Date().timeIntervalSince(diagnosisStartTime)
        
        return QuickDiagnosisResult(
            timestamp: diagnosisStartTime,
            duration: diagnosisDuration,
            overallStatus: overallStatus,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            healthStatus: healthStatus,
            stabilityScore: stabilityScore,
            criticalIssues: criticalIssues,
            warnings: warnings
        )
    }
    
    /// 生成稳定性报告
    func generateStabilityReport() -> StabilityDiagnosticReport {
        print("StabilityDiagnosticTool: 生成稳定性报告")
        
        let comprehensiveDiagnosis = performComprehensiveDiagnosis()
        let quickDiagnosis = performQuickDiagnosis()
        
        // 收集系统信息
        let systemInfo = collectSystemInformation()
        
        // 收集应用信息
        let appInfo = collectApplicationInformation()
        
        return StabilityDiagnosticReport(
            reportTime: Date(),
            comprehensiveDiagnosis: comprehensiveDiagnosis,
            quickDiagnosis: quickDiagnosis,
            systemInfo: systemInfo,
            appInfo: appInfo
        )
    }
    
    /// 导出诊断数据
    func exportDiagnosticData() -> String? {
        let report = generateStabilityReport()
        
        do {
            let jsonData = try JSONEncoder().encode(report)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            os_log("导出诊断数据失败: %@", log: logger, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 执行基础健康检查
    private func performBasicHealthCheck() -> BasicHealthCheckResult {
        let healthStatus = healthMonitor.performHealthCheck()
        let healthReport = healthMonitor.getHealthReport()
        let diagnosticResults = healthMonitor.getDetailedDiagnostics()
        
        return BasicHealthCheckResult(
            healthStatus: healthStatus,
            averageScore: healthReport.averageScore,
            trend: healthReport.trend,
            diagnosticResults: diagnosticResults
        )
    }
    
    /// 执行稳定性分析
    private func performStabilityAnalysis() -> StabilityAnalysisResult {
        let stabilityReport = stabilityManager.getStabilityReport()
        let crashHistory = stabilityManager.getCrashHistory()
        let exceptionHistory = stabilityManager.getExceptionHistory()
        let stabilityTrend = stabilityManager.getStabilityTrend()
        
        // 分析崩溃模式
        let crashPatterns = analyzeCrashPatterns(crashHistory)
        
        // 分析异常模式
        let exceptionPatterns = analyzeExceptionPatterns(exceptionHistory)
        
        return StabilityAnalysisResult(
            stabilityScore: stabilityReport.stabilityScore,
            crashCount: stabilityReport.crashCount,
            exceptionCount: stabilityReport.exceptionCount,
            uptime: stabilityReport.uptime,
            stabilityTrend: stabilityTrend,
            crashPatterns: crashPatterns,
            exceptionPatterns: exceptionPatterns
        )
    }
    
    /// 执行性能分析
    private func performPerformanceAnalysis() -> PerformanceAnalysisResult {
        let memoryUsage = performanceManager.currentMemoryUsage
        let cpuUsage = performanceManager.currentCPUUsage
        let performanceStatus = performanceManager.performanceStatus
        let memoryDetails = performanceManager.getMemoryUsageDetails()
        
        // 分析性能趋势
        let performanceHistory = performanceManager.getPerformanceHistory()
        let performanceTrend = analyzePerformanceTrend(performanceHistory)
        
        return PerformanceAnalysisResult(
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            performanceStatus: performanceStatus,
            memoryDetails: memoryDetails,
            performanceTrend: performanceTrend
        )
    }
    
    /// 执行组件分析
    private func performComponentAnalysis() -> ComponentAnalysisResult {
        var componentStates: [String: ComponentHealthStatus] = [:]
        
        // 检查WiFi监控器
        let wifiStatus = ComponentCommunicationManager.shared.currentWiFiStatus
        componentStates["WiFiMonitor"] = determineComponentHealth(from: wifiStatus)
        
        // 检查稳定性管理器
        let stabilityHealth = stabilityManager.healthStatus
        componentStates["StabilityManager"] = convertHealthStatus(stabilityHealth)
        
        // 检查性能管理器
        let performanceHealth = performanceManager.performanceStatus
        componentStates["PerformanceManager"] = convertPerformanceStatus(performanceHealth)
        
        // 检查健康监控器
        let healthMonitorStatus = healthMonitor.currentHealthStatus
        componentStates["HealthMonitor"] = convertApplicationHealthStatus(healthMonitorStatus)
        
        return ComponentAnalysisResult(
            componentStates: componentStates,
            healthyComponents: componentStates.filter { $0.value == .healthy }.count,
            warningComponents: componentStates.filter { $0.value == .warning }.count,
            criticalComponents: componentStates.filter { $0.value == .critical }.count
        )
    }
    
    /// 执行趋势分析
    private func performTrendAnalysis() -> TrendAnalysisResult {
        let healthHistory = healthMonitor.getHealthHistory(limit: 20)
        let stabilityTrend = stabilityManager.getStabilityTrend()
        
        // 分析健康趋势
        let healthTrend = analyzeHealthTrend(healthHistory)
        
        // 分析长期趋势
        let longTermTrend = analyzeLongTermTrend(healthHistory)
        
        return TrendAnalysisResult(
            healthTrend: healthTrend,
            stabilityTrend: stabilityTrend,
            longTermTrend: longTermTrend,
            trendConfidence: calculateTrendConfidence(healthHistory)
        )
    }
    
    /// 执行风险评估
    private func performRiskAssessment() -> RiskAssessmentResult {
        var riskFactors: [RiskFactor] = []
        var riskScore = 0.0
        
        // 评估崩溃风险
        let crashHistory = stabilityManager.getCrashHistory()
        if crashHistory.count > 0 {
            let recentCrashes = crashHistory.filter { Date().timeIntervalSince($0.timestamp) < 86400 }
            if recentCrashes.count > 0 {
                riskFactors.append(RiskFactor(
                    type: .crashHistory,
                    severity: recentCrashes.count > 2 ? .high : .medium,
                    description: "最近24小时内发生 \(recentCrashes.count) 次崩溃"
                ))
                riskScore += Double(recentCrashes.count) * 15.0
            }
        }
        
        // 评估内存风险
        let memoryUsage = performanceManager.currentMemoryUsage
        if memoryUsage > 200.0 {
            riskFactors.append(RiskFactor(
                type: .memoryUsage,
                severity: .high,
                description: "内存使用过高: \(String(format: "%.1f", memoryUsage)) MB"
            ))
            riskScore += 20.0
        } else if memoryUsage > 150.0 {
            riskFactors.append(RiskFactor(
                type: .memoryUsage,
                severity: .medium,
                description: "内存使用较高: \(String(format: "%.1f", memoryUsage)) MB"
            ))
            riskScore += 10.0
        }
        
        // 评估稳定性风险
        let stabilityScore = stabilityManager.getStabilityReport().stabilityScore
        if stabilityScore < 50.0 {
            riskFactors.append(RiskFactor(
                type: .stability,
                severity: .high,
                description: "稳定性分数过低: \(String(format: "%.1f", stabilityScore))"
            ))
            riskScore += 25.0
        } else if stabilityScore < 70.0 {
            riskFactors.append(RiskFactor(
                type: .stability,
                severity: .medium,
                description: "稳定性分数较低: \(String(format: "%.1f", stabilityScore))"
            ))
            riskScore += 12.0
        }
        
        // 确定风险等级
        let riskLevel: RiskLevel
        if riskScore > 50.0 {
            riskLevel = .high
        } else if riskScore > 25.0 {
            riskLevel = .medium
        } else if riskScore > 10.0 {
            riskLevel = .low
        } else {
            riskLevel = .minimal
        }
        
        return RiskAssessmentResult(
            riskLevel: riskLevel,
            riskScore: riskScore,
            riskFactors: riskFactors
        )
    }
    
    /// 生成综合建议
    private func generateComprehensiveRecommendations(
        healthCheck: BasicHealthCheckResult,
        stabilityAnalysis: StabilityAnalysisResult,
        performanceAnalysis: PerformanceAnalysisResult,
        componentAnalysis: ComponentAnalysisResult,
        trendAnalysis: TrendAnalysisResult,
        riskAssessment: RiskAssessmentResult
    ) -> [DiagnosticRecommendation] {
        
        var recommendations: [DiagnosticRecommendation] = []
        
        // 基于风险等级的建议
        switch riskAssessment.riskLevel {
        case .high:
            recommendations.append(DiagnosticRecommendation(
                priority: .critical,
                category: .stability,
                title: "立即重启应用",
                description: "检测到高风险因素，建议立即重启应用以恢复稳定性",
                action: .restartApplication
            ))
            
        case .medium:
            recommendations.append(DiagnosticRecommendation(
                priority: .high,
                category: .maintenance,
                title: "执行维护操作",
                description: "建议清理缓存并重置组件状态",
                action: .performMaintenance
            ))
            
        case .low:
            recommendations.append(DiagnosticRecommendation(
                priority: .medium,
                category: .optimization,
                title: "优化性能",
                description: "建议执行性能优化以提升稳定性",
                action: .optimizePerformance
            ))
            
        case .minimal:
            recommendations.append(DiagnosticRecommendation(
                priority: .low,
                category: .monitoring,
                title: "继续监控",
                description: "应用状态良好，继续正常监控",
                action: .continueMonitoring
            ))
        }
        
        // 基于性能分析的建议
        if performanceAnalysis.memoryUsage > 150.0 {
            recommendations.append(DiagnosticRecommendation(
                priority: .high,
                category: .performance,
                title: "内存清理",
                description: "内存使用较高，建议执行内存清理",
                action: .cleanupMemory
            ))
        }
        
        // 基于组件分析的建议
        if componentAnalysis.criticalComponents > 0 {
            recommendations.append(DiagnosticRecommendation(
                priority: .critical,
                category: .components,
                title: "修复组件",
                description: "发现 \(componentAnalysis.criticalComponents) 个严重组件问题",
                action: .repairComponents
            ))
        }
        
        // 基于趋势分析的建议
        if trendAnalysis.longTermTrend == .declining {
            recommendations.append(DiagnosticRecommendation(
                priority: .medium,
                category: .stability,
                title: "关注稳定性趋势",
                description: "长期稳定性趋势下降，建议加强监控",
                action: .enhanceMonitoring
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// 分析崩溃模式
    private func analyzeCrashPatterns(_ crashHistory: [CrashRecord]) -> [CrashPattern] {
        var patterns: [CrashPattern] = []
        
        // 按崩溃类型分组
        let crashesByType = Dictionary(grouping: crashHistory) { $0.crashInfo.type }
        
        for (type, crashes) in crashesByType {
            if crashes.count > 1 {
                patterns.append(CrashPattern(
                    type: type,
                    frequency: crashes.count,
                    description: "\(type.description) 发生 \(crashes.count) 次"
                ))
            }
        }
        
        return patterns
    }
    
    /// 分析异常模式
    private func analyzeExceptionPatterns(_ exceptionHistory: [ExceptionRecord]) -> [ExceptionPattern] {
        var patterns: [ExceptionPattern] = []
        
        // 按异常名称分组
        let exceptionsByName = Dictionary(grouping: exceptionHistory) { $0.exceptionName }
        
        for (name, exceptions) in exceptionsByName {
            if exceptions.count > 1 {
                patterns.append(ExceptionPattern(
                    exceptionName: name,
                    frequency: exceptions.count,
                    description: "\(name) 发生 \(exceptions.count) 次"
                ))
            }
        }
        
        return patterns
    }
    
    /// 分析性能趋势
    private func analyzePerformanceTrend(_ performanceHistory: [PerformanceSnapshot]) -> PerformanceTrend {
        guard performanceHistory.count >= 3 else {
            return PerformanceTrend(direction: .stable, confidence: 0.0)
        }
        
        let recentSnapshots = Array(performanceHistory.suffix(5))
        let memoryValues = recentSnapshots.map { $0.memoryUsage }
        
        // 简单的线性趋势分析
        let firstHalf = Array(memoryValues.prefix(memoryValues.count / 2))
        let secondHalf = Array(memoryValues.suffix(memoryValues.count / 2))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let difference = secondAverage - firstAverage
        let threshold = 10.0 // MB
        
        let direction: TrendDirection
        if difference > threshold {
            direction = .declining
        } else if difference < -threshold {
            direction = .improving
        } else {
            direction = .stable
        }
        
        let confidence = min(1.0, abs(difference) / threshold)
        
        return PerformanceTrend(direction: direction, confidence: confidence)
    }
    
    /// 分析健康趋势
    private func analyzeHealthTrend(_ healthHistory: [HealthSnapshot]) -> HealthTrend {
        guard healthHistory.count >= 3 else {
            return .stable
        }
        
        let recentScores = healthHistory.suffix(5).map { $0.overallScore }
        let earlierScores = healthHistory.prefix(5).map { $0.overallScore }
        
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
    
    /// 分析长期趋势
    private func analyzeLongTermTrend(_ healthHistory: [HealthSnapshot]) -> TrendDirection {
        guard healthHistory.count >= 10 else {
            return .stable
        }
        
        let allScores = healthHistory.map { $0.overallScore }
        let firstQuarter = Array(allScores.prefix(allScores.count / 4))
        let lastQuarter = Array(allScores.suffix(allScores.count / 4))
        
        let firstAverage = firstQuarter.reduce(0, +) / Double(firstQuarter.count)
        let lastAverage = lastQuarter.reduce(0, +) / Double(lastQuarter.count)
        
        let difference = lastAverage - firstAverage
        
        if difference > 10.0 {
            return .improving
        } else if difference < -10.0 {
            return .declining
        } else {
            return .stable
        }
    }
    
    /// 计算趋势置信度
    private func calculateTrendConfidence(_ healthHistory: [HealthSnapshot]) -> Double {
        guard healthHistory.count >= 5 else {
            return 0.0
        }
        
        let scores = healthHistory.map { $0.overallScore }
        let variance = calculateVariance(scores)
        
        // 方差越小，趋势越可信
        return max(0.0, min(1.0, 1.0 - variance / 100.0))
    }
    
    /// 计算方差
    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    /// 确定组件健康状态
    private func determineComponentHealth(from wifiStatus: WiFiStatus) -> ComponentHealthStatus {
        switch wifiStatus {
        case .connected:
            return .healthy
        case .disconnected, .disabled:
            return .warning
        case .error:
            return .critical
        default:
            return .warning
        }
    }
    
    /// 转换健康状态
    private func convertHealthStatus(_ healthStatus: HealthStatus) -> ComponentHealthStatus {
        switch healthStatus {
        case .healthy:
            return .healthy
        case .warning:
            return .warning
        case .critical:
            return .critical
        case .unknown:
            return .warning
        }
    }
    
    /// 转换性能状态
    private func convertPerformanceStatus(_ performanceStatus: PerformanceStatus) -> ComponentHealthStatus {
        switch performanceStatus {
        case .optimal, .good:
            return .healthy
        case .warning:
            return .warning
        case .critical:
            return .critical
        }
    }
    
    /// 转换应用健康状态
    private func convertApplicationHealthStatus(_ healthStatus: ApplicationHealthStatus) -> ComponentHealthStatus {
        switch healthStatus {
        case .excellent, .good:
            return .healthy
        case .fair, .poor:
            return .warning
        case .critical:
            return .critical
        case .unknown:
            return .warning
        }
    }
    
    /// 收集系统信息
    private func collectSystemInformation() -> SystemInformation {
        let processInfo = ProcessInfo.processInfo
        
        return SystemInformation(
            operatingSystem: processInfo.operatingSystemVersionString,
            processorCount: processInfo.processorCount,
            physicalMemory: processInfo.physicalMemory,
            systemUptime: processInfo.systemUptime
        )
    }
    
    /// 收集应用信息
    private func collectApplicationInformation() -> ApplicationInformation {
        let bundle = Bundle.main
        
        return ApplicationInformation(
            appName: bundle.infoDictionary?["CFBundleName"] as? String ?? "WiFiMenuBar",
            appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            buildVersion: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            bundleIdentifier: bundle.bundleIdentifier ?? "unknown"
        )
    }
}

// MARK: - Supporting Types

/// 诊断状态
enum DiagnosisStatus: String, CaseIterable, Codable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .healthy: return "健康"
        case .warning: return "警告"
        case .critical: return "严重"
        }
    }
}

/// 组件健康状态
enum ComponentHealthStatus: String, CaseIterable, Codable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .healthy: return "健康"
        case .warning: return "警告"
        case .critical: return "严重"
        }
    }
}

/// 风险等级
enum RiskLevel: String, CaseIterable, Codable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var description: String {
        switch self {
        case .minimal: return "极低"
        case .low: return "低"
        case .medium: return "中等"
        case .high: return "高"
        }
    }
}

/// 风险因素类型
enum RiskFactorType: String, CaseIterable, Codable {
    case crashHistory = "crashHistory"
    case memoryUsage = "memoryUsage"
    case stability = "stability"
    case performance = "performance"
    case components = "components"
    
    var description: String {
        switch self {
        case .crashHistory: return "崩溃历史"
        case .memoryUsage: return "内存使用"
        case .stability: return "稳定性"
        case .performance: return "性能"
        case .components: return "组件"
        }
    }
}

/// 风险严重程度
enum RiskSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var description: String {
        switch self {
        case .low: return "低"
        case .medium: return "中等"
        case .high: return "高"
        }
    }
}

/// 建议优先级
enum RecommendationPriority: Int, CaseIterable, Codable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low: return "低"
        case .medium: return "中等"
        case .high: return "高"
        case .critical: return "严重"
        }
    }
}

/// 建议类别
enum RecommendationCategory: String, CaseIterable, Codable {
    case stability = "stability"
    case performance = "performance"
    case maintenance = "maintenance"
    case optimization = "optimization"
    case monitoring = "monitoring"
    case components = "components"
    
    var description: String {
        switch self {
        case .stability: return "稳定性"
        case .performance: return "性能"
        case .maintenance: return "维护"
        case .optimization: return "优化"
        case .monitoring: return "监控"
        case .components: return "组件"
        }
    }
}

/// 建议操作
enum RecommendationAction: String, CaseIterable, Codable {
    case restartApplication = "restartApplication"
    case performMaintenance = "performMaintenance"
    case optimizePerformance = "optimizePerformance"
    case continueMonitoring = "continueMonitoring"
    case cleanupMemory = "cleanupMemory"
    case repairComponents = "repairComponents"
    case enhanceMonitoring = "enhanceMonitoring"
    
    var description: String {
        switch self {
        case .restartApplication: return "重启应用"
        case .performMaintenance: return "执行维护"
        case .optimizePerformance: return "优化性能"
        case .continueMonitoring: return "继续监控"
        case .cleanupMemory: return "清理内存"
        case .repairComponents: return "修复组件"
        case .enhanceMonitoring: return "加强监控"
        }
    }
}

/// 性能趋势
struct PerformanceTrend: Codable {
    let direction: TrendDirection
    let confidence: Double
}

/// 风险因素
struct RiskFactor: Codable {
    let type: RiskFactorType
    let severity: RiskSeverity
    let description: String
}

/// 崩溃模式
struct CrashPattern: Codable {
    let type: CrashType
    let frequency: Int
    let description: String
}

/// 异常模式
struct ExceptionPattern: Codable {
    let exceptionName: String
    let frequency: Int
    let description: String
}

/// 诊断建议
struct DiagnosticRecommendation: Codable {
    let priority: RecommendationPriority
    let category: RecommendationCategory
    let title: String
    let description: String
    let action: RecommendationAction
}

/// 系统信息
struct SystemInformation: Codable {
    let operatingSystem: String
    let processorCount: Int
    let physicalMemory: UInt64
    let systemUptime: TimeInterval
}

/// 应用信息
struct ApplicationInformation: Codable {
    let appName: String
    let appVersion: String
    let buildVersion: String
    let bundleIdentifier: String
}

// MARK: - Result Types

/// 基础健康检查结果
struct BasicHealthCheckResult: Codable {
    let healthStatus: ApplicationHealthStatus
    let averageScore: Double
    let trend: HealthTrend
    let diagnosticResults: [DiagnosticResult]
}

/// 稳定性分析结果
struct StabilityAnalysisResult: Codable {
    let stabilityScore: Double
    let crashCount: Int
    let exceptionCount: Int
    let uptime: TimeInterval
    let stabilityTrend: StabilityTrend
    let crashPatterns: [CrashPattern]
    let exceptionPatterns: [ExceptionPattern]
}

/// 性能分析结果
struct PerformanceAnalysisResult: Codable {
    let memoryUsage: Double
    let cpuUsage: Double
    let performanceStatus: PerformanceStatus
    let memoryDetails: MemoryUsageDetails
    let performanceTrend: PerformanceTrend
}

/// 组件分析结果
struct ComponentAnalysisResult: Codable {
    let componentStates: [String: ComponentHealthStatus]
    let healthyComponents: Int
    let warningComponents: Int
    let criticalComponents: Int
}

/// 趋势分析结果
struct TrendAnalysisResult: Codable {
    let healthTrend: HealthTrend
    let stabilityTrend: StabilityTrend
    let longTermTrend: TrendDirection
    let trendConfidence: Double
}

/// 风险评估结果
struct RiskAssessmentResult: Codable {
    let riskLevel: RiskLevel
    let riskScore: Double
    let riskFactors: [RiskFactor]
}

/// 快速诊断结果
struct QuickDiagnosisResult: Codable {
    let timestamp: Date
    let duration: TimeInterval
    let overallStatus: DiagnosisStatus
    let memoryUsage: Double
    let cpuUsage: Double
    let healthStatus: ApplicationHealthStatus
    let stabilityScore: Double
    let criticalIssues: [String]
    let warnings: [String]
}

/// 综合诊断结果
struct ComprehensiveDiagnosisResult: Codable {
    let timestamp: Date
    let duration: TimeInterval
    let healthCheck: BasicHealthCheckResult
    let stabilityAnalysis: StabilityAnalysisResult
    let performanceAnalysis: PerformanceAnalysisResult
    let componentAnalysis: ComponentAnalysisResult
    let trendAnalysis: TrendAnalysisResult
    let riskAssessment: RiskAssessmentResult
    let recommendations: [DiagnosticRecommendation]
}

/// 稳定性诊断报告
struct StabilityDiagnosticReport: Codable {
    let reportTime: Date
    let comprehensiveDiagnosis: ComprehensiveDiagnosisResult
    let quickDiagnosis: QuickDiagnosisResult
    let systemInfo: SystemInformation
    let appInfo: ApplicationInformation
}