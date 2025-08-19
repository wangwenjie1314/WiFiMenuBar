import Foundation
import os.log
import Cocoa

/// 稳定性管理器
/// 负责提升应用稳定性，包括崩溃恢复、异常处理和健康监控
class StabilityManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = StabilityManager()
    
    // MARK: - Published Properties
    
    /// 应用健康状态
    @Published var healthStatus: HealthStatus = .unknown
    
    /// 是否启用稳定性监控
    @Published var isStabilityMonitoringEnabled: Bool = true
    
    /// 崩溃恢复状态
    @Published var crashRecoveryStatus: CrashRecoveryStatus = .none
    
    // MARK: - Private Properties
    
    /// 健康检查定时器
    private var healthCheckTimer: Timer?
    
    /// 健康检查间隔（秒）
    private let healthCheckInterval: TimeInterval = 30.0
    
    /// 崩溃记录
    private var crashHistory: [CrashRecord] = []
    
    /// 异常记录
    private var exceptionHistory: [ExceptionRecord] = []
    
    /// 最大记录数量
    private let maxRecordCount = 50
    
    /// 应用状态持久化管理器
    private let statePersistenceManager = StatePersistenceManager()
    
    /// 健康监控器
    private let healthMonitor = HealthMonitor()
    
    /// 崩溃恢复管理器
    private let crashRecoveryManager = CrashRecoveryManager()
    
    /// 异常处理器
    private let exceptionHandler = ExceptionHandler()
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.stability", category: "StabilityManager")
    
    /// 上次健康检查时间
    private var lastHealthCheckTime: Date?
    
    /// 连续健康检查失败次数
    private var consecutiveHealthCheckFailures = 0
    
    /// 最大连续失败次数
    private let maxConsecutiveFailures = 3
    
    // MARK: - Initialization
    
    private init() {
        print("StabilityManager: 初始化稳定性管理器")
        setupStabilityMonitoring()
        loadCrashHistory()
        checkForPreviousCrash()
    }
    
    deinit {
        stopStabilityMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 开始稳定性监控
    func startStabilityMonitoring() {
        guard isStabilityMonitoringEnabled else { return }
        
        print("StabilityManager: 开始稳定性监控")
        
        // 设置异常处理
        exceptionHandler.setupExceptionHandling()
        
        // 开始健康检查
        startHealthCheck()
        
        // 启动状态持久化
        statePersistenceManager.startPeriodicSave()
        
        os_log("稳定性监控已启动", log: logger, type: .info)
    }
    
    /// 停止稳定性监控
    func stopStabilityMonitoring() {
        print("StabilityManager: 停止稳定性监控")
        
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        
        statePersistenceManager.stopPeriodicSave()
        
        os_log("稳定性监控已停止", log: logger, type: .info)
    }
    
    /// 执行健康检查
    func performHealthCheck() -> HealthCheckResult {
        let result = healthMonitor.performComprehensiveHealthCheck()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateHealthStatus(result)
        }
        
        return result
    }
    
    /// 记录崩溃
    /// - Parameter crashInfo: 崩溃信息
    func recordCrash(_ crashInfo: CrashInfo) {
        let crashRecord = CrashRecord(
            crashInfo: crashInfo,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            buildVersion: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        )
        
        crashHistory.append(crashRecord)
        limitRecordCount(&crashHistory)
        saveCrashHistory()
        
        os_log("记录崩溃: %@", log: logger, type: .error, crashInfo.description)
        
        // 触发崩溃恢复流程
        DispatchQueue.main.async { [weak self] in
            self?.crashRecoveryStatus = .recovering
            self?.crashRecoveryManager.initiateCrashRecovery(crashRecord)
        }
    }
    
    /// 记录异常
    /// - Parameter exception: 异常信息
    func recordException(_ exception: NSException) {
        let exceptionRecord = ExceptionRecord(
            exception: exception,
            timestamp: Date(),
            stackTrace: exception.callStackSymbols
        )
        
        exceptionHistory.append(exceptionRecord)
        limitRecordCount(&exceptionHistory)
        
        os_log("记录异常: %@", log: logger, type: .error, exception.description)
        
        // 尝试恢复
        handleException(exceptionRecord)
    }
    
    /// 获取稳定性报告
    /// - Returns: 稳定性报告
    func getStabilityReport() -> StabilityReport {
        let uptime = Date().timeIntervalSince(statePersistenceManager.getAppStartTime())
        
        return StabilityReport(
            healthStatus: healthStatus,
            uptime: uptime,
            crashCount: crashHistory.count,
            exceptionCount: exceptionHistory.count,
            lastCrashTime: crashHistory.last?.timestamp,
            lastExceptionTime: exceptionHistory.last?.timestamp,
            consecutiveHealthCheckFailures: consecutiveHealthCheckFailures,
            recoveryActions: crashRecoveryManager.getRecoveryActions(),
            stabilityScore: calculateStabilityScore()
        )
    }
    
    /// 执行应用恢复
    func performApplicationRecovery() {
        print("StabilityManager: 执行应用恢复")
        
        crashRecoveryStatus = .recovering
        
        // 记录恢复开始时间
        let recoveryStartTime = Date()
        
        // 1. 重置组件状态
        resetComponentStates()
        
        // 2. 清理资源
        cleanupResources()
        
        // 3. 重新初始化关键组件
        reinitializeCriticalComponents()
        
        // 4. 恢复应用状态
        restoreApplicationState()
        
        // 5. 验证恢复结果
        let recoveryResult = verifyRecoveryResult()
        
        if recoveryResult.isSuccessful {
            crashRecoveryStatus = .recovered
            let recoveryTime = Date().timeIntervalSince(recoveryStartTime)
            os_log("应用恢复完成，耗时: %.2f 秒", log: logger, type: .info, recoveryTime)
            
            // 发送恢复成功通知
            NotificationCenter.default.post(name: .applicationRecoveryCompleted, object: recoveryResult)
        } else {
            crashRecoveryStatus = .needsRecovery
            os_log("应用恢复失败: %@", log: logger, type: .error, recoveryResult.failureReason ?? "未知原因")
            
            // 尝试更激进的恢复策略
            performEmergencyRecovery(issues: [])
        }
    }
    
    /// 获取崩溃历史
    /// - Returns: 崩溃记录数组
    func getCrashHistory() -> [CrashRecord] {
        return crashHistory
    }
    
    /// 获取异常历史
    /// - Returns: 异常记录数组
    func getExceptionHistory() -> [ExceptionRecord] {
        return exceptionHistory
    }
    
    /// 清除历史记录
    func clearHistory() {
        crashHistory.removeAll()
        exceptionHistory.removeAll()
        saveCrashHistory()
        
        // 重置连续失败计数
        consecutiveHealthCheckFailures = 0
        
        os_log("历史记录已清除", log: logger, type: .info)
    }
    
    /// 获取应用健康度评估
    func getApplicationHealthAssessment() -> HealthAssessment {
        let stabilityReport = getStabilityReport()
        let uptime = Date().timeIntervalSince(statePersistenceManager.getAppStartTime())
        
        // 计算健康度指标
        let crashRate = Double(crashHistory.count) / max(uptime / 3600, 1.0) // 每小时崩溃次数
        let exceptionRate = Double(exceptionHistory.count) / max(uptime / 3600, 1.0) // 每小时异常次数
        
        var healthScore = 100.0
        
        // 根据各种因素调整健康分数
        healthScore -= crashRate * 20.0 // 每小时崩溃一次扣20分
        healthScore -= exceptionRate * 10.0 // 每小时异常一次扣10分
        healthScore -= Double(consecutiveHealthCheckFailures) * 5.0 // 连续失败扣分
        
        // 根据当前健康状态调整
        switch healthStatus {
        case .critical:
            healthScore -= 30.0
        case .warning:
            healthScore -= 15.0
        case .healthy:
            break
        case .unknown:
            healthScore -= 10.0
        }
        
        healthScore = max(0.0, min(100.0, healthScore))
        
        let assessment = HealthAssessment(
            overallScore: healthScore,
            stabilityScore: stabilityReport.stabilityScore,
            crashRate: crashRate,
            exceptionRate: exceptionRate,
            uptime: uptime,
            currentStatus: healthStatus,
            recommendations: generateHealthRecommendations(score: healthScore)
        )
        
        return assessment
    }
    
    /// 生成健康建议
    private func generateHealthRecommendations(score: Double) -> [String] {
        var recommendations: [String] = []
        
        if score < 50 {
            recommendations.append("应用稳定性较差，建议重启应用")
            recommendations.append("检查系统资源使用情况")
            recommendations.append("考虑重置应用设置")
        } else if score < 70 {
            recommendations.append("建议清理应用缓存")
            recommendations.append("检查网络连接稳定性")
        } else if score < 85 {
            recommendations.append("应用运行良好，建议定期重启")
        } else {
            recommendations.append("应用运行状态优秀")
        }
        
        // 根据具体问题添加建议
        if crashHistory.count > 0 {
            recommendations.append("检测到崩溃记录，建议查看崩溃日志")
        }
        
        if exceptionHistory.count > 5 {
            recommendations.append("异常次数较多，建议检查应用配置")
        }
        
        if consecutiveHealthCheckFailures > 0 {
            recommendations.append("健康检查失败，建议检查系统资源")
        }
        
        return recommendations
    }
    
    /// 导出稳定性数据
    /// - Returns: 稳定性数据的JSON字符串
    func exportStabilityData() -> String? {
        let exportData = StabilityExportData(
            stabilityReport: getStabilityReport(),
            crashHistory: crashHistory,
            exceptionHistory: exceptionHistory,
            exportTime: Date()
        )
        
        do {
            let jsonData = try JSONEncoder().encode(exportData)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            os_log("导出稳定性数据失败: %@", log: logger, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置稳定性监控
    private func setupStabilityMonitoring() {
        // 设置崩溃处理
        setupCrashHandling()
        
        // 设置内存警告处理
        setupMemoryWarningHandling()
        
        // 设置应用状态监控
        setupApplicationStateMonitoring()
    }
    
    /// 设置崩溃处理
    private func setupCrashHandling() {
        // 设置未捕获异常处理器
        NSSetUncaughtExceptionHandler { [weak self] exception in
            self?.recordException(exception)
        }
        
        // 设置信号处理器
        signal(SIGABRT) { signal in
            StabilityManager.shared.handleSignal(signal)
        }
        
        signal(SIGILL) { signal in
            StabilityManager.shared.handleSignal(signal)
        }
        
        signal(SIGSEGV) { signal in
            StabilityManager.shared.handleSignal(signal)
        }
        
        signal(SIGFPE) { signal in
            StabilityManager.shared.handleSignal(signal)
        }
        
        signal(SIGBUS) { signal in
            StabilityManager.shared.handleSignal(signal)
        }
    }
    
    /// 处理信号
    /// - Parameter signal: 信号类型
    private func handleSignal(_ signal: Int32) {
        let crashInfo = CrashInfo(
            type: .signal,
            signal: signal,
            description: "应用收到信号 \(signal)",
            stackTrace: Thread.callStackSymbols
        )
        
        recordCrash(crashInfo)
        
        // 尝试优雅退出
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
    
    /// 设置内存警告处理
    private func setupMemoryWarningHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: .performanceWarning,
            object: nil
        )
    }
    
    /// 处理内存警告
    @objc private func handleMemoryWarning(_ notification: Notification) {
        os_log("收到内存警告，执行紧急清理", log: logger, type: .info)
        
        // 执行紧急内存清理
        performEmergencyCleanup()
    }
    
    /// 设置应用状态监控
    private func setupApplicationStateMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    /// 应用即将终止
    @objc private func applicationWillTerminate(_ notification: Notification) {
        // 保存当前状态
        statePersistenceManager.saveCurrentState()
        
        // 记录正常退出
        os_log("应用正常退出", log: logger, type: .info)
    }
    
    /// 开始健康检查
    private func startHealthCheck() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicHealthCheck()
        }
        
        // 立即执行一次健康检查
        performPeriodicHealthCheck()
    }
    
    /// 执行定期健康检查
    private func performPeriodicHealthCheck() {
        let result = performHealthCheck()
        lastHealthCheckTime = Date()
        
        if result.isHealthy {
            consecutiveHealthCheckFailures = 0
        } else {
            consecutiveHealthCheckFailures += 1
            
            if consecutiveHealthCheckFailures >= maxConsecutiveFailures {
                os_log("连续健康检查失败，触发恢复流程", log: logger, type: .error)
                performApplicationRecovery()
            }
        }
    }
    
    /// 更新健康状态
    /// - Parameter result: 健康检查结果
    private func updateHealthStatus(_ result: HealthCheckResult) {
        let newStatus: HealthStatus
        
        if result.isHealthy {
            newStatus = .healthy
        } else if result.criticalIssues.isEmpty {
            newStatus = .warning
        } else {
            newStatus = .critical
        }
        
        if newStatus != healthStatus {
            healthStatus = newStatus
            handleHealthStatusChange(newStatus, result: result)
        }
    }
    
    /// 处理健康状态变化
    /// - Parameters:
    ///   - newStatus: 新的健康状态
    ///   - result: 健康检查结果
    private func handleHealthStatusChange(_ newStatus: HealthStatus, result: HealthCheckResult) {
        os_log("健康状态变化: %@", log: logger, type: .info, newStatus.description)
        
        switch newStatus {
        case .critical:
            // 严重状态，执行紧急恢复
            performEmergencyRecovery(issues: result.criticalIssues)
        case .warning:
            // 警告状态，执行预防性措施
            performPreventiveMeasures(issues: result.warnings)
        case .healthy:
            // 健康状态，重置恢复状态
            if crashRecoveryStatus == .recovered {
                crashRecoveryStatus = .none
            }
        case .unknown:
            break
        }
    }
    
    /// 执行紧急恢复
    /// - Parameter issues: 严重问题列表
    private func performEmergencyRecovery(issues: [HealthIssue]) {
        os_log("执行紧急恢复，问题数量: %d", log: logger, type: .error, issues.count)
        
        for issue in issues {
            switch issue.type {
            case .memoryLeak:
                performEmergencyCleanup()
            case .componentFailure:
                reinitializeCriticalComponents()
            case .resourceExhaustion:
                cleanupResources()
            case .networkFailure:
                resetNetworkComponents()
            }
        }
    }
    
    /// 执行预防性措施
    /// - Parameter issues: 警告问题列表
    private func performPreventiveMeasures(issues: [HealthIssue]) {
        os_log("执行预防性措施，问题数量: %d", log: logger, type: .info, issues.count)
        
        for issue in issues {
            switch issue.type {
            case .memoryLeak:
                // 轻度内存清理
                PerformanceManager.shared.performOptimization()
            case .componentFailure:
                // 重启有问题的组件
                restartFailedComponents()
            case .resourceExhaustion:
                // 清理部分资源
                cleanupNonCriticalResources()
            case .networkFailure:
                // 重置网络连接
                resetNetworkConnections()
            }
        }
    }
    
    /// 处理异常
    /// - Parameter exceptionRecord: 异常记录
    private func handleException(_ exceptionRecord: ExceptionRecord) {
        // 根据异常类型采取不同的恢复策略
        let exceptionName = exceptionRecord.exception.name.rawValue
        
        switch exceptionName {
        case "NSInvalidArgumentException":
            // 参数异常，通常是编程错误
            os_log("处理参数异常", log: logger, type: .error)
        case "NSRangeException":
            // 范围异常
            os_log("处理范围异常", log: logger, type: .error)
        case "NSGenericException":
            // 通用异常
            os_log("处理通用异常", log: logger, type: .error)
        default:
            os_log("处理未知异常: %@", log: logger, type: .error, exceptionName)
        }
        
        // 尝试恢复
        performLightweightRecovery()
    }
    
    /// 执行轻量级恢复
    private func performLightweightRecovery() {
        // 清理缓存
        ComponentCommunicationManager.shared.clearHistory()
        
        // 重置错误状态
        NotificationCenter.default.post(name: .resetErrorStates, object: nil)
        
        os_log("轻量级恢复完成", log: logger, type: .info)
    }
    
    /// 重置组件状态
    private func resetComponentStates() {
        // 重置WiFi监控器
        NotificationCenter.default.post(name: .resetWiFiMonitor, object: nil)
        
        // 重置状态栏控制器
        NotificationCenter.default.post(name: .resetStatusBarController, object: nil)
        
        // 重置偏好设置管理器
        NotificationCenter.default.post(name: .resetPreferencesManager, object: nil)
    }
    
    /// 清理资源
    private func cleanupResources() {
        // 清理缓存
        URLCache.shared.removeAllCachedResponses()
        
        // 清理临时文件
        cleanupTemporaryFiles()
        
        // 强制垃圾回收
        autoreleasepool {
            // 清理自动释放池
        }
    }
    
    /// 重新初始化关键组件
    private func reinitializeCriticalComponents() {
        // 通知组件重新初始化
        NotificationCenter.default.post(name: .reinitializeComponents, object: nil)
    }
    
    /// 恢复应用状态
    private func restoreApplicationState() {
        statePersistenceManager.restoreApplicationState()
    }
    
    /// 执行紧急清理
    private func performEmergencyCleanup() {
        // 清理所有缓存
        ComponentCommunicationManager.shared.clearHistory()
        PerformanceManager.shared.clearPerformanceHistory()
        
        // 清理历史记录
        if crashHistory.count > 10 {
            crashHistory = Array(crashHistory.suffix(10))
        }
        
        if exceptionHistory.count > 10 {
            exceptionHistory = Array(exceptionHistory.suffix(10))
        }
        
        os_log("紧急清理完成", log: logger, type: .info)
    }
    
    /// 重启失败的组件
    private func restartFailedComponents() {
        // 检查并重启失败的组件
        NotificationCenter.default.post(name: .restartFailedComponents, object: nil)
    }
    
    /// 清理非关键资源
    private func cleanupNonCriticalResources() {
        // 清理非关键的缓存和资源
        NotificationCenter.default.post(name: .cleanupNonCriticalResources, object: nil)
    }
    
    /// 重置网络组件
    private func resetNetworkComponents() {
        // 重置网络相关组件
        NotificationCenter.default.post(name: .resetNetworkComponents, object: nil)
    }
    
    /// 重置网络连接
    private func resetNetworkConnections() {
        // 重置网络连接
        NotificationCenter.default.post(name: .resetNetworkConnections, object: nil)
    }
    
    /// 清理临时文件
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
            os_log("清理临时文件失败: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    /// 限制记录数量
    /// - Parameter records: 记录数组
    private func limitRecordCount<T>(_ records: inout [T]) {
        if records.count > maxRecordCount {
            records = Array(records.suffix(maxRecordCount))
        }
    }
    
    /// 计算稳定性分数
    /// - Returns: 稳定性分数（0-100）
    private func calculateStabilityScore() -> Double {
        var score = 100.0
        
        // 根据崩溃次数扣分
        score -= Double(crashHistory.count) * 10.0
        
        // 根据异常次数扣分
        score -= Double(exceptionHistory.count) * 5.0
        
        // 根据连续健康检查失败次数扣分
        score -= Double(consecutiveHealthCheckFailures) * 15.0
        
        // 根据健康状态扣分
        switch healthStatus {
        case .critical:
            score -= 30.0
        case .warning:
            score -= 15.0
        case .healthy:
            break
        case .unknown:
            score -= 5.0
        }
        
        return max(0.0, score)
    }
    
    /// 检查之前的崩溃
    private func checkForPreviousCrash() {
        if let lastCrash = crashHistory.last {
            let timeSinceLastCrash = Date().timeIntervalSince(lastCrash.timestamp)
            
            // 如果最后一次崩溃是在最近5分钟内，认为可能需要恢复
            if timeSinceLastCrash < 300 {
                crashRecoveryStatus = .needsRecovery
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.showCrashRecoveryDialog()
                }
            }
        }
    }
    
    /// 显示崩溃恢复对话框
    private func showCrashRecoveryDialog() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "检测到应用异常退出"
            alert.informativeText = "WiFi菜单栏检测到上次运行时发生了异常。是否要执行恢复操作？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "执行恢复")
            alert.addButton(withTitle: "正常启动")
            alert.addButton(withTitle: "查看详情")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                self.performApplicationRecovery()
            case .alertThirdButtonReturn:
                self.showCrashDetails()
            default:
                self.crashRecoveryStatus = .none
            }
        }
    }
    
    /// 显示崩溃详情
    private func showCrashDetails() {
        guard let lastCrash = crashHistory.last else { return }
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "崩溃详情"
            alert.informativeText = """
            崩溃时间: \(lastCrash.timestamp)
            崩溃类型: \(lastCrash.crashInfo.type.description)
            描述: \(lastCrash.crashInfo.description)
            应用版本: \(lastCrash.appVersion)
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    /// 加载崩溃历史
    private func loadCrashHistory() {
        // 从UserDefaults加载崩溃历史
        if let data = UserDefaults.standard.data(forKey: "CrashHistory"),
           let history = try? JSONDecoder().decode([CrashRecord].self, from: data) {
            crashHistory = history
        }
    }
    
    /// 保存崩溃历史
    private func saveCrashHistory() {
        if let data = try? JSONEncoder().encode(crashHistory) {
            UserDefaults.standard.set(data, forKey: "CrashHistory")
        }
    }
    
    /// 验证恢复结果
    private func verifyRecoveryResult() -> RecoveryResult {
        var isSuccessful = true
        var failureReason: String?
        var verificationDetails: [String] = []
        
        // 检查关键组件是否正常
        let healthResult = performHealthCheck()
        
        if !healthResult.isHealthy {
            isSuccessful = false
            failureReason = "健康检查失败"
            verificationDetails.append("健康检查发现 \(healthResult.criticalIssues.count) 个严重问题")
        }
        
        // 检查WiFi监控是否正常
        let wifiStatus = ComponentCommunicationManager.shared.currentWiFiStatus
        if case .error = wifiStatus {
            isSuccessful = false
            failureReason = failureReason ?? "WiFi监控异常"
            verificationDetails.append("WiFi监控状态异常")
        }
        
        // 检查内存使用是否正常
        let memoryUsage = PerformanceManager.shared.currentMemoryUsage
        if memoryUsage > 200.0 {
            isSuccessful = false
            failureReason = failureReason ?? "内存使用过高"
            verificationDetails.append("内存使用: \(String(format: "%.1f", memoryUsage)) MB")
        }
        
        if isSuccessful {
            verificationDetails.append("所有关键组件验证通过")
        }
        
        return RecoveryResult(
            isSuccessful: isSuccessful,
            failureReason: failureReason,
            verificationDetails: verificationDetails,
            recoveryTime: Date()
        )
    }
    
    /// 执行自动修复
    func performAutoRepair() -> AutoRepairResult {
        print("StabilityManager: 执行自动修复")
        
        var repairedIssues: [String] = []
        var failedRepairs: [String] = []
        
        // 1. 修复内存问题
        if PerformanceManager.shared.currentMemoryUsage > 150.0 {
            performEmergencyCleanup()
            repairedIssues.append("执行内存清理")
        }
        
        // 2. 修复网络问题
        let wifiStatus = ComponentCommunicationManager.shared.currentWiFiStatus
        if case .error = wifiStatus {
            NotificationCenter.default.post(name: .resetNetworkComponents, object: nil)
            repairedIssues.append("重置网络组件")
        }
        
        // 3. 修复组件问题
        let healthResult = performHealthCheck()
        if !healthResult.criticalIssues.isEmpty {
            resetComponentStates()
            repairedIssues.append("重置组件状态")
        }
        
        // 4. 清理损坏的缓存
        ComponentCommunicationManager.shared.clearHistory()
        repairedIssues.append("清理缓存")
        
        // 5. 验证修复结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            let verificationResult = self?.performHealthCheck()
            if let result = verificationResult, !result.isHealthy {
                failedRepairs.append("健康检查仍然失败")
            }
        }
        
        let result = AutoRepairResult(
            repairedIssues: repairedIssues,
            failedRepairs: failedRepairs,
            repairTime: Date()
        )
        
        os_log("自动修复完成 - 修复: %d, 失败: %d", log: logger, type: .info, repairedIssues.count, failedRepairs.count)
        
        return result
    }
    
    /// 获取稳定性趋势分析
    func getStabilityTrend() -> StabilityTrend {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        // 分析最近1小时的稳定性
        let recentCrashes = crashHistory.filter { $0.timestamp > oneHourAgo }
        let recentExceptions = exceptionHistory.filter { $0.timestamp > oneHourAgo }
        
        // 分析最近24小时的稳定性
        let dailyCrashes = crashHistory.filter { $0.timestamp > oneDayAgo }
        let dailyExceptions = exceptionHistory.filter { $0.timestamp > oneDayAgo }
        
        // 计算趋势
        let hourlyTrend: TrendDirection
        if recentCrashes.count > 1 || recentExceptions.count > 3 {
            hourlyTrend = .declining
        } else if recentCrashes.isEmpty && recentExceptions.count <= 1 {
            hourlyTrend = .improving
        } else {
            hourlyTrend = .stable
        }
        
        let dailyTrend: TrendDirection
        if dailyCrashes.count > 3 || dailyExceptions.count > 10 {
            dailyTrend = .declining
        } else if dailyCrashes.count <= 1 && dailyExceptions.count <= 3 {
            dailyTrend = .improving
        } else {
            dailyTrend = .stable
        }
        
        return StabilityTrend(
            hourlyTrend: hourlyTrend,
            dailyTrend: dailyTrend,
            recentCrashCount: recentCrashes.count,
            recentExceptionCount: recentExceptions.count,
            dailyCrashCount: dailyCrashes.count,
            dailyExceptionCount: dailyExceptions.count
        )
    }
}

// MARK: - Supporting Types

/// 健康状态
enum HealthStatus: String, CaseIterable {
    case unknown = "unknown"
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .unknown: return "未知"
        case .healthy: return "健康"
        case .warning: return "警告"
        case .critical: return "严重"
        }
    }
    
    var color: NSColor {
        switch self {
        case .healthy: return .systemGreen
        case .warning: return .systemOrange
        case .critical: return .systemRed
        case .unknown: return .systemGray
        }
    }
}

/// 崩溃恢复状态
enum CrashRecoveryStatus: String, CaseIterable {
    case none = "none"
    case needsRecovery = "needsRecovery"
    case recovering = "recovering"
    case recovered = "recovered"
    
    var description: String {
        switch self {
        case .none: return "无需恢复"
        case .needsRecovery: return "需要恢复"
        case .recovering: return "恢复中"
        case .recovered: return "已恢复"
        }
    }
}

/// 崩溃信息
struct CrashInfo: Codable {
    let type: CrashType
    let signal: Int32?
    let description: String
    let stackTrace: [String]
}

/// 崩溃类型
enum CrashType: String, Codable, CaseIterable {
    case signal = "signal"
    case exception = "exception"
    case assertion = "assertion"
    case memoryError = "memoryError"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .signal: return "信号崩溃"
        case .exception: return "异常崩溃"
        case .assertion: return "断言失败"
        case .memoryError: return "内存错误"
        case .unknown: return "未知崩溃"
        }
    }
}

/// 崩溃记录
struct CrashRecord: Codable {
    let crashInfo: CrashInfo
    let timestamp: Date
    let appVersion: String
    let buildVersion: String
    let id = UUID()
}

/// 异常记录
struct ExceptionRecord: Codable {
    let exceptionName: String
    let reason: String?
    let timestamp: Date
    let stackTrace: [String]
    let id = UUID()
    
    init(exception: NSException, timestamp: Date, stackTrace: [String]) {
        self.exceptionName = exception.name.rawValue
        self.reason = exception.reason
        self.timestamp = timestamp
        self.stackTrace = stackTrace
    }
}

/// 稳定性报告
struct StabilityReport: Codable {
    let healthStatus: HealthStatus
    let uptime: TimeInterval
    let crashCount: Int
    let exceptionCount: Int
    let lastCrashTime: Date?
    let lastExceptionTime: Date?
    let consecutiveHealthCheckFailures: Int
    let recoveryActions: [String]
    let stabilityScore: Double
    
    var description: String {
        return """
        稳定性报告:
        - 健康状态: \(healthStatus.description)
        - 运行时间: \(String(format: "%.0f", uptime)) 秒
        - 崩溃次数: \(crashCount)
        - 异常次数: \(exceptionCount)
        - 连续健康检查失败: \(consecutiveHealthCheckFailures)
        - 稳定性分数: \(String(format: "%.1f", stabilityScore))
        - 恢复操作: \(recoveryActions.joined(separator: ", "))
        """
    }
}

/// 稳定性导出数据
struct StabilityExportData: Codable {
    let stabilityReport: StabilityReport
    let crashHistory: [CrashRecord]
    let exceptionHistory: [ExceptionRecord]
    let exportTime: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let resetErrorStates = Notification.Name("resetErrorStates")
    static let resetWiFiMonitor = Notification.Name("resetWiFiMonitor")
    static let resetStatusBarController = Notification.Name("resetStatusBarController")
    static let resetPreferencesManager = Notification.Name("resetPreferencesManager")
    static let reinitializeComponents = Notification.Name("reinitializeComponents")
    static let restartFailedComponents = Notification.Name("restartFailedComponents")
    static let cleanupNonCriticalResources = Notification.Name("cleanupNonCriticalResources")
    static let resetNetworkComponents = Notification.Name("resetNetworkComponents")
    static let resetNetworkConnections = Notification.Name("resetNetworkConnections")
}

// MARK: - HealthStatus Codable

extension HealthStatus: Codable {
    // 自动实现Codable，因为是String枚举
}

// MARK: - CrashRecoveryStatus Codable

extension CrashRecoveryStatus: Codable {
    // 自动实现Codable，因为是String枚举
}

// MARK: - Additional Supporting Types

/// 恢复结果
struct RecoveryResult {
    let isSuccessful: Bool
    let failureReason: String?
    let verificationDetails: [String]
    let recoveryTime: Date
    
    var description: String {
        let status = isSuccessful ? "成功" : "失败"
        let reason = failureReason ?? "无"
        let details = verificationDetails.joined(separator: ", ")
        
        return """
        恢复结果: \(status)
        失败原因: \(reason)
        验证详情: \(details)
        恢复时间: \(recoveryTime)
        """
    }
}

/// 自动修复结果
struct AutoRepairResult {
    let repairedIssues: [String]
    let failedRepairs: [String]
    let repairTime: Date
    
    var isSuccessful: Bool {
        return !repairedIssues.isEmpty && failedRepairs.isEmpty
    }
    
    var description: String {
        return """
        自动修复结果:
        - 修复的问题: \(repairedIssues.joined(separator: ", "))
        - 修复失败: \(failedRepairs.joined(separator: ", "))
        - 修复时间: \(repairTime)
        - 整体状态: \(isSuccessful ? "成功" : "部分失败")
        """
    }
}

/// 健康度评估
struct HealthAssessment {
    let overallScore: Double
    let stabilityScore: Double
    let crashRate: Double
    let exceptionRate: Double
    let uptime: TimeInterval
    let currentStatus: HealthStatus
    let recommendations: [String]
    
    var healthGrade: HealthGrade {
        switch overallScore {
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
    
    var description: String {
        return """
        健康度评估:
        - 总体评分: \(String(format: "%.1f", overallScore))/100
        - 稳定性评分: \(String(format: "%.1f", stabilityScore))/100
        - 健康等级: \(healthGrade.description)
        - 崩溃率: \(String(format: "%.2f", crashRate))/小时
        - 异常率: \(String(format: "%.2f", exceptionRate))/小时
        - 运行时间: \(String(format: "%.0f", uptime)) 秒
        - 当前状态: \(currentStatus.description)
        - 建议: \(recommendations.joined(separator: "; "))
        """
    }
}

/// 健康等级
enum HealthGrade: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
    
    var description: String {
        switch self {
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
        }
    }
}

/// 稳定性趋势
struct StabilityTrend {
    let hourlyTrend: TrendDirection
    let dailyTrend: TrendDirection
    let recentCrashCount: Int
    let recentExceptionCount: Int
    let dailyCrashCount: Int
    let dailyExceptionCount: Int
    
    var description: String {
        return """
        稳定性趋势:
        - 小时趋势: \(hourlyTrend.description)
        - 日趋势: \(dailyTrend.description)
        - 最近1小时崩溃: \(recentCrashCount)
        - 最近1小时异常: \(recentExceptionCount)
        - 最近24小时崩溃: \(dailyCrashCount)
        - 最近24小时异常: \(dailyExceptionCount)
        """
    }
}

/// 趋势方向
enum TrendDirection: String, CaseIterable {
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
    
    var color: NSColor {
        switch self {
        case .improving: return .systemGreen
        case .stable: return .systemBlue
        case .declining: return .systemRed
        }
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let applicationRecoveryCompleted = Notification.Name("applicationRecoveryCompleted")
    static let autoRepairCompleted = Notification.Name("autoRepairCompleted")
    static let stabilityTrendChanged = Notification.Name("stabilityTrendChanged")
}