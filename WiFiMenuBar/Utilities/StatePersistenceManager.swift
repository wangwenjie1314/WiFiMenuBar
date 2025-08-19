import Foundation
import os.log

/// 状态持久化管理器
/// 负责保存和恢复应用状态
class StatePersistenceManager {
    
    // MARK: - Properties
    
    /// 日志记录器
    private let logger = OSLog(subsystem: "com.wifimenubar.persistence", category: "StatePersistenceManager")
    
    /// 应用启动时间
    private let appStartTime = Date()
    
    /// 定期保存定时器
    private var periodicSaveTimer: Timer?
    
    /// 保存间隔（秒）
    private let saveInterval: TimeInterval = 60.0
    
    /// 状态文件路径
    private let stateFileURL: URL
    
    // MARK: - Initialization
    
    init() {
        // 创建状态文件路径
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appURL = appSupportURL.appendingPathComponent("WiFiMenuBar")
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true, attributes: nil)
        
        stateFileURL = appURL.appendingPathComponent("AppState.json")
        
        print("StatePersistenceManager: 初始化状态持久化管理器")
        print("StatePersistenceManager: 状态文件路径: \(stateFileURL.path)")
    }
    
    deinit {
        stopPeriodicSave()
    }
    
    // MARK: - Public Methods
    
    /// 开始定期保存
    func startPeriodicSave() {
        print("StatePersistenceManager: 开始定期保存")
        
        periodicSaveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            self?.saveCurrentState()
        }
    }
    
    /// 停止定期保存
    func stopPeriodicSave() {
        print("StatePersistenceManager: 停止定期保存")
        
        periodicSaveTimer?.invalidate()
        periodicSaveTimer = nil
        
        // 最后保存一次
        saveCurrentState()
    }
    
    /// 保存当前状态
    func saveCurrentState() {
        let appState = collectCurrentState()
        
        do {
            let data = try JSONEncoder().encode(appState)
            try data.write(to: stateFileURL)
            
            os_log("应用状态已保存", log: logger, type: .info)
        } catch {
            os_log("保存应用状态失败: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    /// 恢复应用状态
    func restoreApplicationState() {
        print("StatePersistenceManager: 恢复应用状态")
        
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else {
            print("StatePersistenceManager: 状态文件不存在")
            return
        }
        
        do {
            let data = try Data(contentsOf: stateFileURL)
            let appState = try JSONDecoder().decode(ApplicationState.self, from: data)
            
            applyApplicationState(appState)
            
            os_log("应用状态已恢复", log: logger, type: .info)
        } catch {
            os_log("恢复应用状态失败: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    /// 获取应用启动时间
    func getAppStartTime() -> Date {
        return appStartTime
    }
    
    /// 获取保存的状态信息
    func getSavedStateInfo() -> SavedStateInfo? {
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: stateFileURL)
            let appState = try JSONDecoder().decode(ApplicationState.self, from: data)
            
            return SavedStateInfo(
                saveTime: appState.saveTime,
                appVersion: appState.appVersion,
                buildVersion: appState.buildVersion,
                uptime: appState.uptime,
                componentStates: appState.componentStates.keys.map { String($0) }
            )
        } catch {
            return nil
        }
    }
    
    /// 清除保存的状态
    func clearSavedState() {
        print("StatePersistenceManager: 清除保存的状态")
        
        do {
            try FileManager.default.removeItem(at: stateFileURL)
            os_log("保存的状态已清除", log: logger, type: .info)
        } catch {
            os_log("清除保存的状态失败: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    /// 收集当前状态
    /// - Returns: 应用状态
    private func collectCurrentState() -> ApplicationState {
        let uptime = Date().timeIntervalSince(appStartTime)
        
        var componentStates: [String: ComponentState] = [:]
        
        // 收集WiFiMonitor状态
        componentStates["WiFiMonitor"] = collectWiFiMonitorState()
        
        // 收集StatusBarController状态
        componentStates["StatusBarController"] = collectStatusBarControllerState()
        
        // 收集PreferencesManager状态
        componentStates["PreferencesManager"] = collectPreferencesManagerState()
        
        // 收集PerformanceManager状态
        componentStates["PerformanceManager"] = collectPerformanceManagerState()
        
        return ApplicationState(
            saveTime: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            buildVersion: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            uptime: uptime,
            componentStates: componentStates
        )
    }
    
    /// 收集WiFiMonitor状态
    /// - Returns: 组件状态
    private func collectWiFiMonitorState() -> ComponentState {
        let wifiStatus = ComponentCommunicationManager.shared.currentWiFiStatus
        let isConnected = ComponentCommunicationManager.shared.isNetworkConnected
        
        return ComponentState(
            isActive: true,
            lastUpdateTime: Date(),
            properties: [
                "wifiStatus": wifiStatus.shortDescription,
                "isConnected": String(isConnected)
            ]
        )
    }
    
    /// 收集StatusBarController状态
    /// - Returns: 组件状态
    private func collectStatusBarControllerState() -> ComponentState {
        return ComponentState(
            isActive: true,
            lastUpdateTime: Date(),
            properties: [
                "isVisible": "true" // 假设状态栏总是可见的
            ]
        )
    }
    
    /// 收集PreferencesManager状态
    /// - Returns: 组件状态
    private func collectPreferencesManagerState() -> ComponentState {
        let preferences = PreferencesManager.shared.getCurrentPreferences()
        
        return ComponentState(
            isActive: true,
            lastUpdateTime: Date(),
            properties: [
                "displayFormat": preferences.displayFormat.rawValue,
                "autoStart": String(preferences.autoStart),
                "maxDisplayLength": String(preferences.maxDisplayLength)
            ]
        )
    }
    
    /// 收集PerformanceManager状态
    /// - Returns: 组件状态
    private func collectPerformanceManagerState() -> ComponentState {
        let performanceManager = PerformanceManager.shared
        
        return ComponentState(
            isActive: performanceManager.isMonitoringEnabled,
            lastUpdateTime: Date(),
            properties: [
                "memoryUsage": String(format: "%.1f", performanceManager.currentMemoryUsage),
                "cpuUsage": String(format: "%.1f", performanceManager.currentCPUUsage),
                "performanceStatus": performanceManager.performanceStatus.rawValue
            ]
        )
    }
    
    /// 应用应用状态
    /// - Parameter appState: 应用状态
    private func applyApplicationState(_ appState: ApplicationState) {
        print("StatePersistenceManager: 应用应用状态")
        
        // 恢复组件状态
        for (componentName, componentState) in appState.componentStates {
            applyComponentState(componentName: componentName, state: componentState)
        }
        
        // 发送状态恢复完成通知
        NotificationCenter.default.post(name: .applicationStateRestored, object: appState)
    }
    
    /// 应用组件状态
    /// - Parameters:
    ///   - componentName: 组件名称
    ///   - state: 组件状态
    private func applyComponentState(componentName: String, state: ComponentState) {
        print("StatePersistenceManager: 恢复组件状态 - \(componentName)")
        
        switch componentName {
        case "WiFiMonitor":
            applyWiFiMonitorState(state)
        case "StatusBarController":
            applyStatusBarControllerState(state)
        case "PreferencesManager":
            applyPreferencesManagerState(state)
        case "PerformanceManager":
            applyPerformanceManagerState(state)
        default:
            print("StatePersistenceManager: 未知组件 - \(componentName)")
        }
    }
    
    /// 应用WiFiMonitor状态
    /// - Parameter state: 组件状态
    private func applyWiFiMonitorState(_ state: ComponentState) {
        // WiFiMonitor的状态通常由系统决定，这里主要是记录
        print("StatePersistenceManager: WiFiMonitor状态 - \(state.properties)")
    }
    
    /// 应用StatusBarController状态
    /// - Parameter state: 组件状态
    private func applyStatusBarControllerState(_ state: ComponentState) {
        // StatusBarController的状态恢复
        if state.isActive {
            NotificationCenter.default.post(name: .restoreStatusBarController, object: state)
        }
    }
    
    /// 应用PreferencesManager状态
    /// - Parameter state: 组件状态
    private func applyPreferencesManagerState(_ state: ComponentState) {
        // PreferencesManager的状态通常已经通过UserDefaults恢复
        // 这里可以进行额外的验证或修复
        print("StatePersistenceManager: PreferencesManager状态 - \(state.properties)")
    }
    
    /// 应用PerformanceManager状态
    /// - Parameter state: 组件状态
    private func applyPerformanceManagerState(_ state: ComponentState) {
        // 恢复性能监控状态
        if state.isActive {
            PerformanceManager.shared.startPerformanceMonitoring()
        }
    }
}

// MARK: - Supporting Types

/// 应用状态
struct ApplicationState: Codable {
    let saveTime: Date
    let appVersion: String
    let buildVersion: String
    let uptime: TimeInterval
    let componentStates: [String: ComponentState]
}

/// 组件状态
struct ComponentState: Codable {
    let isActive: Bool
    let lastUpdateTime: Date
    let properties: [String: String]
}

/// 保存的状态信息
struct SavedStateInfo {
    let saveTime: Date
    let appVersion: String
    let buildVersion: String
    let uptime: TimeInterval
    let componentStates: [String]
    
    var description: String {
        return """
        保存的状态信息:
        - 保存时间: \(saveTime)
        - 应用版本: \(appVersion) (\(buildVersion))
        - 运行时间: \(String(format: "%.0f", uptime)) 秒
        - 组件数量: \(componentStates.count)
        - 组件列表: \(componentStates.joined(separator: ", "))
        """
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let applicationStateRestored = Notification.Name("applicationStateRestored")
    static let restoreStatusBarController = Notification.Name("restoreStatusBarController")
}