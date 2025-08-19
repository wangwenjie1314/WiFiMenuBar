import Foundation
import os.log

/// 异常处理器
/// 负责设置和处理应用异常
class ExceptionHandler {
    
    // MARK: - Properties
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.exception", category: "ExceptionHandler")
    
    /// 是否已设置异常处理
    private var isExceptionHandlingSetup = false
    
    // MARK: - Public Methods
    
    /// 设置异常处理
    func setupExceptionHandling() {
        guard !isExceptionHandlingSetup else { return }
        
        print("ExceptionHandler: 设置异常处理")
        
        // 设置未捕获异常处理器
        NSSetUncaughtExceptionHandler { exception in
            ExceptionHandler.handleUncaughtException(exception)
        }
        
        // 设置信号处理器
        setupSignalHandlers()
        
        isExceptionHandlingSetup = true
        
        os_log("异常处理已设置", log: logger, type: .info)
    }
    
    /// 处理未捕获的异常
    /// - Parameter exception: 异常对象
    static func handleUncaughtException(_ exception: NSException) {
        let handler = ExceptionHandler()
        handler.processException(exception)
    }
    
    /// 处理异常
    /// - Parameter exception: 异常对象
    func processException(_ exception: NSException) {
        os_log("处理未捕获异常: %@", log: logger, type: .error, exception.name.rawValue)
        
        // 记录异常详情
        logExceptionDetails(exception)
        
        // 尝试保存当前状态
        saveApplicationStateOnException()
        
        // 通知稳定性管理器
        StabilityManager.shared.recordException(exception)
        
        // 尝试优雅恢复
        attemptGracefulRecovery(for: exception)
    }
    
    // MARK: - Private Methods
    
    /// 设置信号处理器
    private func setupSignalHandlers() {
        // 设置各种信号的处理器
        signal(SIGABRT, handleSignal)
        signal(SIGILL, handleSignal)
        signal(SIGSEGV, handleSignal)
        signal(SIGFPE, handleSignal)
        signal(SIGBUS, handleSignal)
        signal(SIGPIPE, handleSignal)
    }
    
    /// 记录异常详情
    /// - Parameter exception: 异常对象
    private func logExceptionDetails(_ exception: NSException) {
        let exceptionInfo = """
        异常详情:
        - 名称: \(exception.name.rawValue)
        - 原因: \(exception.reason ?? "无")
        - 用户信息: \(exception.userInfo ?? [:])
        - 调用栈: \(exception.callStackSymbols.joined(separator: "\n"))
        """
        
        os_log("%@", log: logger, type: .error, exceptionInfo)
        
        // 写入崩溃日志文件
        writeCrashLogToFile(exceptionInfo)
    }
    
    /// 保存异常时的应用状态
    private func saveApplicationStateOnException() {
        do {
            // 尝试保存当前状态
            let statePersistence = StatePersistenceManager()
            statePersistence.saveCurrentState()
            
            os_log("异常时应用状态已保存", log: logger, type: .info)
        } catch {
            os_log("保存异常时应用状态失败: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    /// 尝试优雅恢复
    /// - Parameter exception: 异常对象
    private func attemptGracefulRecovery(for exception: NSException) {
        let exceptionName = exception.name.rawValue
        
        switch exceptionName {
        case "NSInvalidArgumentException":
            handleInvalidArgumentException(exception)
        case "NSRangeException":
            handleRangeException(exception)
        case "NSGenericException":
            handleGenericException(exception)
        case "NSInternalInconsistencyException":
            handleInternalInconsistencyException(exception)
        default:
            handleUnknownException(exception)
        }
    }
    
    /// 处理无效参数异常
    /// - Parameter exception: 异常对象
    private func handleInvalidArgumentException(_ exception: NSException) {
        os_log("处理无效参数异常", log: logger, type: .info)
        
        // 尝试重置相关组件
        NotificationCenter.default.post(name: .resetErrorStates, object: nil)
        
        // 清理可能损坏的数据
        ComponentCommunicationManager.shared.clearHistory()
    }
    
    /// 处理范围异常
    /// - Parameter exception: 异常对象
    private func handleRangeException(_ exception: NSException) {
        os_log("处理范围异常", log: logger, type: .info)
        
        // 清理可能导致范围错误的数据
        PerformanceManager.shared.clearPerformanceHistory()
    }
    
    /// 处理通用异常
    /// - Parameter exception: 异常对象
    private func handleGenericException(_ exception: NSException) {
        os_log("处理通用异常", log: logger, type: .info)
        
        // 执行通用恢复操作
        performGeneralRecovery()
    }
    
    /// 处理内部不一致异常
    /// - Parameter exception: 异常对象
    private func handleInternalInconsistencyException(_ exception: NSException) {
        os_log("处理内部不一致异常", log: logger, type: .error)
        
        // 这种异常通常比较严重，需要更彻底的恢复
        performEmergencyRecovery()
    }
    
    /// 处理未知异常
    /// - Parameter exception: 异常对象
    private func handleUnknownException(_ exception: NSException) {
        os_log("处理未知异常: %@", log: logger, type: .error, exception.name.rawValue)
        
        // 对于未知异常，采用保守的恢复策略
        performGeneralRecovery()
    }
    
    /// 执行通用恢复
    private func performGeneralRecovery() {
        // 清理缓存
        ComponentCommunicationManager.shared.clearHistory()
        
        // 重置错误状态
        NotificationCenter.default.post(name: .resetErrorStates, object: nil)
        
        os_log("通用恢复完成", log: logger, type: .info)
    }
    
    /// 执行紧急恢复
    private func performEmergencyRecovery() {
        // 清理所有缓存
        ComponentCommunicationManager.shared.clearHistory()
        PerformanceManager.shared.clearPerformanceHistory()
        
        // 重置所有组件
        NotificationCenter.default.post(name: .resetWiFiMonitor, object: nil)
        NotificationCenter.default.post(name: .resetStatusBarController, object: nil)
        
        // 清理临时文件
        cleanupTemporaryFiles()
        
        os_log("紧急恢复完成", log: logger, type: .info)
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
    
    /// 写入崩溃日志文件
    /// - Parameter logContent: 日志内容
    private func writeCrashLogToFile(_ logContent: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let crashLogURL = documentsURL.appendingPathComponent("WiFiMenuBar_Crash_\(Date().timeIntervalSince1970).log")
        
        do {
            try logContent.write(to: crashLogURL, atomically: true, encoding: .utf8)
            os_log("崩溃日志已写入: %@", log: logger, type: .info, crashLogURL.path)
        } catch {
            os_log("写入崩溃日志失败: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - Signal Handling

/// 信号处理函数
/// - Parameter signal: 信号类型
private func handleSignal(_ signal: Int32) {
    let signalName = getSignalName(signal)
    
    print("ExceptionHandler: 收到信号 \(signal) (\(signalName))")
    
    // 创建崩溃信息
    let crashInfo = CrashInfo(
        type: .signal,
        signal: signal,
        description: "应用收到信号 \(signal) (\(signalName))",
        stackTrace: Thread.callStackSymbols
    )
    
    // 记录崩溃
    StabilityManager.shared.recordCrash(crashInfo)
    
    // 尝试保存状态
    let statePersistence = StatePersistenceManager()
    statePersistence.saveCurrentState()
    
    // 优雅退出
    DispatchQueue.main.async {
        NSApp.terminate(nil)
    }
}

/// 获取信号名称
/// - Parameter signal: 信号类型
/// - Returns: 信号名称
private func getSignalName(_ signal: Int32) -> String {
    switch signal {
    case SIGABRT:
        return "SIGABRT"
    case SIGILL:
        return "SIGILL"
    case SIGSEGV:
        return "SIGSEGV"
    case SIGFPE:
        return "SIGFPE"
    case SIGBUS:
        return "SIGBUS"
    case SIGPIPE:
        return "SIGPIPE"
    default:
        return "UNKNOWN"
    }
}