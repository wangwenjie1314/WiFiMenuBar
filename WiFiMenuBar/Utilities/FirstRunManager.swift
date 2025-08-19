import Foundation
import Cocoa

/// 首次运行管理器
/// 负责管理应用的首次运行流程和用户引导
class FirstRunManager {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = FirstRunManager()
    
    // MARK: - Properties
    
    /// 首次运行标识键
    private let firstRunKey = "HasLaunchedBefore"
    
    /// 版本标识键
    private let lastVersionKey = "LastRunVersion"
    
    /// 首次运行完成标识键
    private let firstRunCompletedKey = "FirstRunCompleted"
    
    /// 当前应用版本
    private var currentVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 当前构建版本
    private var currentBuildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 首次运行状态
    private var _isFirstRun: Bool?
    
    // MARK: - Initialization
    
    private init() {
        print("FirstRunManager: 初始化首次运行管理器")
    }
    
    // MARK: - Public Methods
    
    /// 检查是否为首次运行
    /// - Returns: 是否为首次运行
    func isFirstRun() -> Bool {
        if let cached = _isFirstRun {
            return cached
        }
        
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: firstRunKey)
        let isFirstRun = !hasLaunchedBefore
        
        _isFirstRun = isFirstRun
        
        print("FirstRunManager: 首次运行检查结果: \(isFirstRun)")
        return isFirstRun
    }
    
    /// 检查是否为版本更新后的首次运行
    /// - Returns: 是否为版本更新后的首次运行
    func isFirstRunAfterUpdate() -> Bool {
        let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)
        let isUpdate = lastVersion != nil && lastVersion != currentVersion
        
        print("FirstRunManager: 版本更新检查 - 上次版本: \(lastVersion ?? "无"), 当前版本: \(currentVersion), 是否更新: \(isUpdate)")
        return isUpdate
    }
    
    /// 开始首次运行流程
    /// - Parameter completion: 完成回调
    func startFirstRunFlow(completion: @escaping (Bool) -> Void) {
        print("FirstRunManager: 开始首次运行流程")
        
        guard isFirstRun() else {
            print("FirstRunManager: 不是首次运行，跳过首次运行流程")
            completion(true)
            return
        }
        
        // 显示欢迎界面
        showWelcomeScreen { [weak self] welcomeCompleted in
            guard welcomeCompleted else {
                completion(false)
                return
            }
            
            // 请求权限
            self?.requestInitialPermissions { permissionsGranted in
                // 显示功能介绍
                self?.showFeatureIntroduction { introCompleted in
                    // 设置默认偏好设置
                    self?.setupDefaultPreferences()
                    
                    // 标记首次运行完成
                    self?.markFirstRunCompleted()
                    
                    completion(introCompleted)
                }
            }
        }
    }
    
    /// 开始版本更新流程
    /// - Parameter completion: 完成回调
    func startUpdateFlow(completion: @escaping (Bool) -> Void) {
        print("FirstRunManager: 开始版本更新流程")
        
        guard isFirstRunAfterUpdate() else {
            completion(true)
            return
        }
        
        showUpdateWelcomeScreen { [weak self] updateCompleted in
            // 更新版本记录
            self?.updateVersionRecord()
            completion(updateCompleted)
        }
    }
    
    /// 显示快速设置向导
    /// - Parameter completion: 完成回调
    func showQuickSetupWizard(completion: @escaping (Bool) -> Void) {
        print("FirstRunManager: 显示快速设置向导")
        
        let wizard = QuickSetupWizard()
        wizard.show { result in
            completion(result)
        }
    }
    
    /// 获取首次运行信息
    /// - Returns: 首次运行信息
    func getFirstRunInfo() -> FirstRunInfo {
        return FirstRunInfo(
            isFirstRun: isFirstRun(),
            isFirstRunAfterUpdate: isFirstRunAfterUpdate(),
            currentVersion: currentVersion,
            currentBuildVersion: currentBuildVersion,
            lastVersion: UserDefaults.standard.string(forKey: lastVersionKey),
            firstRunCompleted: UserDefaults.standard.bool(forKey: firstRunCompletedKey),
            installationDate: getInstallationDate()
        )
    }
    
    /// 重置首次运行状态（用于测试）
    func resetFirstRunStatus() {
        print("FirstRunManager: 重置首次运行状态")
        
        UserDefaults.standard.removeObject(forKey: firstRunKey)
        UserDefaults.standard.removeObject(forKey: lastVersionKey)
        UserDefaults.standard.removeObject(forKey: firstRunCompletedKey)
        UserDefaults.standard.synchronize()
        
        _isFirstRun = nil
    }
    
    // MARK: - Private Methods
    
    /// 显示欢迎界面
    /// - Parameter completion: 完成回调
    private func showWelcomeScreen(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "欢迎使用WiFi菜单栏"
            alert.informativeText = """
            感谢您选择WiFi菜单栏！
            
            这个应用将在您的菜单栏中显示当前的WiFi网络信息，让您随时了解网络连接状态。
            
            接下来我们将引导您完成初始设置。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "开始设置")
            alert.addButton(withTitle: "稍后设置")
            
            let response = alert.runModal()
            completion(response == .alertFirstButtonReturn)
        }
    }
    
    /// 显示版本更新欢迎界面
    /// - Parameter completion: 完成回调
    private func showUpdateWelcomeScreen(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let lastVersion = UserDefaults.standard.string(forKey: self.lastVersionKey) ?? "未知"
            
            let alert = NSAlert()
            alert.messageText = "WiFi菜单栏已更新"
            alert.informativeText = """
            WiFi菜单栏已从版本 \(lastVersion) 更新到 \(self.currentVersion)。
            
            新版本包含了性能改进和新功能。您可以在偏好设置中查看详细信息。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "了解更多")
            alert.addButton(withTitle: "继续使用")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // 显示更新日志或新功能介绍
                self.showUpdateFeatures {
                    completion(true)
                }
            } else {
                completion(true)
            }
        }
    }
    
    /// 显示更新功能介绍
    /// - Parameter completion: 完成回调
    private func showUpdateFeatures(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "新功能介绍"
            alert.informativeText = """
            版本 \(self.currentVersion) 的新功能：
            
            • 改进的权限管理
            • 更好的首次运行体验
            • 增强的数据流监控
            • 优化的性能和稳定性
            
            您可以在偏好设置中探索这些新功能。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "打开偏好设置")
            alert.addButton(withTitle: "稍后查看")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // 打开偏好设置
                NotificationCenter.default.post(name: .showPreferences, object: nil)
            }
            
            completion()
        }
    }
    
    /// 请求初始权限
    /// - Parameter completion: 完成回调
    private func requestInitialPermissions(completion: @escaping (Bool) -> Void) {
        print("FirstRunManager: 请求初始权限")
        
        PermissionManager.shared.requestAllRequiredPermissions { allGranted in
            if !allGranted {
                DispatchQueue.main.async {
                    self.showPermissionGuidance {
                        completion(true) // 即使权限未完全授予也继续
                    }
                }
            } else {
                completion(true)
            }
        }
    }
    
    /// 显示权限指导
    /// - Parameter completion: 完成回调
    private func showPermissionGuidance(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "权限设置"
            alert.informativeText = """
            为了获得最佳体验，WiFi菜单栏需要以下权限：
            
            • 通知权限：接收网络状态变化通知
            • 网络权限：监控WiFi连接状态
            
            您可以稍后在系统偏好设置中授予这些权限。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "打开系统偏好设置")
            alert.addButton(withTitle: "稍后设置")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                PermissionManager.shared.openSystemPreferencesForPermission(.notification)
            }
            
            completion()
        }
    }
    
    /// 显示功能介绍
    /// - Parameter completion: 完成回调
    private func showFeatureIntroduction(completion: @escaping (Bool) -> Void) {
        print("FirstRunManager: 显示功能介绍")
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "功能介绍"
            alert.informativeText = """
            WiFi菜单栏的主要功能：
            
            • 在菜单栏显示当前WiFi网络名称
            • 实时监控网络连接状态
            • 可自定义显示格式和样式
            • 支持开机自动启动
            • 提供详细的网络信息
            
            右键点击菜单栏图标可以访问更多选项和设置。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "开始使用")
            alert.addButton(withTitle: "打开设置")
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn {
                // 打开偏好设置
                NotificationCenter.default.post(name: .showPreferences, object: nil)
            }
            
            completion(true)
        }
    }
    
    /// 设置默认偏好设置
    private func setupDefaultPreferences() {
        print("FirstRunManager: 设置默认偏好设置")
        
        // 重置为默认设置
        PreferencesManager.shared.resetToDefaults()
        
        // 设置一些首次运行的特定默认值
        var preferences = PreferencesManager.shared.getCurrentPreferences()
        preferences.enableNotifications = true
        preferences.autoStart = true
        
        PreferencesManager.shared.updatePreferences(preferences)
    }
    
    /// 标记首次运行完成
    private func markFirstRunCompleted() {
        print("FirstRunManager: 标记首次运行完成")
        
        UserDefaults.standard.set(true, forKey: firstRunKey)
        UserDefaults.standard.set(true, forKey: firstRunCompletedKey)
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
        UserDefaults.standard.synchronize()
        
        _isFirstRun = false
    }
    
    /// 更新版本记录
    private func updateVersionRecord() {
        print("FirstRunManager: 更新版本记录")
        
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
        UserDefaults.standard.synchronize()
    }
    
    /// 获取安装日期
    /// - Returns: 安装日期
    private func getInstallationDate() -> Date? {
        guard let bundlePath = Bundle.main.bundlePath else { return nil }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: bundlePath)
            return attributes[.creationDate] as? Date
        } catch {
            print("FirstRunManager: 无法获取安装日期: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

/// 首次运行信息
struct FirstRunInfo {
    let isFirstRun: Bool
    let isFirstRunAfterUpdate: Bool
    let currentVersion: String
    let currentBuildVersion: String
    let lastVersion: String?
    let firstRunCompleted: Bool
    let installationDate: Date?
    
    var description: String {
        return """
        首次运行信息:
        - 是否首次运行: \(isFirstRun)
        - 是否版本更新后首次运行: \(isFirstRunAfterUpdate)
        - 当前版本: \(currentVersion) (\(currentBuildVersion))
        - 上次版本: \(lastVersion ?? "无")
        - 首次运行已完成: \(firstRunCompleted)
        - 安装日期: \(installationDate?.description ?? "未知")
        """
    }
}

/// 快速设置向导
class QuickSetupWizard {
    
    /// 显示向导
    /// - Parameter completion: 完成回调
    func show(completion: @escaping (Bool) -> Void) {
        showStep1 { step1Result in
            guard step1Result else {
                completion(false)
                return
            }
            
            self.showStep2 { step2Result in
                guard step2Result else {
                    completion(false)
                    return
                }
                
                self.showStep3 { step3Result in
                    completion(step3Result)
                }
            }
        }
    }
    
    /// 步骤1：显示格式设置
    private func showStep1(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "设置显示格式"
            alert.informativeText = "选择您希望在菜单栏中显示WiFi信息的格式："
            alert.alertStyle = .informational
            alert.addButton(withTitle: "仅显示名称")
            alert.addButton(withTitle: "名称 + 信号强度")
            alert.addButton(withTitle: "跳过")
            
            let response = alert.runModal()
            
            if response != .alertThirdButtonReturn {
                let format: DisplayFormat = response == .alertFirstButtonReturn ? .nameOnly : .nameWithSignal
                PreferencesManager.shared.setDisplayFormat(format)
            }
            
            completion(response != .alertThirdButtonReturn)
        }
    }
    
    /// 步骤2：自动启动设置
    private func showStep2(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "自动启动设置"
            alert.informativeText = "是否希望WiFi菜单栏在系统启动时自动运行？"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "是，自动启动")
            alert.addButton(withTitle: "否，手动启动")
            alert.addButton(withTitle: "跳过")
            
            let response = alert.runModal()
            
            if response != .alertThirdButtonReturn {
                let autoStart = response == .alertFirstButtonReturn
                PreferencesManager.shared.setAutoStart(autoStart)
            }
            
            completion(true)
        }
    }
    
    /// 步骤3：完成设置
    private func showStep3(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "设置完成"
            alert.informativeText = """
            快速设置已完成！
            
            WiFi菜单栏现在已准备就绪。您可以随时在偏好设置中调整这些选项。
            
            右键点击菜单栏中的WiFi信息可以访问更多功能。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "完成")
            alert.addButton(withTitle: "打开偏好设置")
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn {
                NotificationCenter.default.post(name: .showPreferences, object: nil)
            }
            
            completion(true)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
}