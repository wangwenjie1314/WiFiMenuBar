import Foundation

/// 偏好设置管理器
/// 负责管理应用的用户设置，包括显示格式、自动启动等配置
class PreferencesManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = PreferencesManager()
    
    // MARK: - Properties
    
    /// UserDefaults实例
    private let userDefaults = UserDefaults.standard
    
    /// 设置变更通知名称
    static let preferencesDidChangeNotification = Notification.Name("PreferencesDidChange")
    
    /// 当前应用偏好设置
    @Published private(set) var preferences: AppPreferences {
        didSet {
            if preferences != oldValue {
                savePreferences()
                postChangeNotification()
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let displayFormat = "displayFormat"
        static let autoStart = "autoStart"
        static let maxDisplayLength = "maxDisplayLength"
        static let refreshInterval = "refreshInterval"
        static let showSignalStrength = "showSignalStrength"
        static let showNetworkIcon = "showNetworkIcon"
        static let enableNotifications = "enableNotifications"
        static let minimizeToTray = "minimizeToTray"
        static let launchAtLogin = "launchAtLogin"
        static let checkForUpdates = "checkForUpdates"
    }
    
    // MARK: - Initialization
    
    private init() {
        // 加载保存的设置或使用默认值
        self.preferences = loadPreferences()
        
        // 监听UserDefaults变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 获取当前偏好设置
    func getCurrentPreferences() -> AppPreferences {
        return preferences
    }
    
    /// 更新偏好设置
    /// - Parameter newPreferences: 新的偏好设置
    func updatePreferences(_ newPreferences: AppPreferences) {
        guard newPreferences != preferences else { return }
        
        print("PreferencesManager: 更新偏好设置")
        
        // 更新通信管理器
        ComponentCommunicationManager.shared.updatePreferences(newPreferences)
        
        preferences = newPreferences
    }
    
    /// 重置为默认设置
    func resetToDefaults() {
        print("PreferencesManager: 重置为默认设置")
        preferences = AppPreferences()
    }
    
    /// 导出设置到字典
    /// - Returns: 设置字典
    func exportSettings() -> [String: Any] {
        return [
            Keys.displayFormat: preferences.displayFormat.rawValue,
            Keys.autoStart: preferences.autoStart,
            Keys.maxDisplayLength: preferences.maxDisplayLength,
            Keys.refreshInterval: preferences.refreshInterval,
            Keys.showSignalStrength: preferences.showSignalStrength,
            Keys.showNetworkIcon: preferences.showNetworkIcon,
            Keys.enableNotifications: preferences.enableNotifications,
            Keys.minimizeToTray: preferences.minimizeToTray,
            Keys.launchAtLogin: preferences.launchAtLogin,
            Keys.checkForUpdates: preferences.checkForUpdates
        ]
    }
    
    /// 从字典导入设置
    /// - Parameter settings: 设置字典
    /// - Returns: 是否导入成功
    @discardableResult
    func importSettings(from settings: [String: Any]) -> Bool {
        do {
            let importedPreferences = try parseSettingsDictionary(settings)
            updatePreferences(importedPreferences)
            print("PreferencesManager: 设置导入成功")
            return true
        } catch {
            print("PreferencesManager: 设置导入失败: \(error)")
            return false
        }
    }
    
    /// 验证设置的有效性
    /// - Parameter preferences: 要验证的设置
    /// - Returns: 验证结果
    func validatePreferences(_ preferences: AppPreferences) -> ValidationResult {
        var errors: [String] = []
        
        // 验证最大显示长度
        if preferences.maxDisplayLength < 5 || preferences.maxDisplayLength > 50 {
            errors.append("最大显示长度必须在5-50之间")
        }
        
        // 验证刷新间隔
        if preferences.refreshInterval < 1.0 || preferences.refreshInterval > 60.0 {
            errors.append("刷新间隔必须在1-60秒之间")
        }
        
        // 验证显示格式
        if !DisplayFormat.allCases.contains(preferences.displayFormat) {
            errors.append("无效的显示格式")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Convenience Methods
    
    /// 更新显示格式
    /// - Parameter format: 新的显示格式
    func setDisplayFormat(_ format: DisplayFormat) {
        var newPreferences = preferences
        newPreferences.displayFormat = format
        updatePreferences(newPreferences)
    }
    
    /// 更新自动启动设置
    /// - Parameter enabled: 是否启用自动启动
    func setAutoStart(_ enabled: Bool) {
        var newPreferences = preferences
        newPreferences.autoStart = enabled
        updatePreferences(newPreferences)
    }
    
    /// 更新最大显示长度
    /// - Parameter length: 新的最大显示长度
    func setMaxDisplayLength(_ length: Int) {
        guard length >= 5 && length <= 50 else {
            print("PreferencesManager: 无效的显示长度: \(length)")
            return
        }
        
        var newPreferences = preferences
        newPreferences.maxDisplayLength = length
        updatePreferences(newPreferences)
    }
    
    /// 更新刷新间隔
    /// - Parameter interval: 新的刷新间隔（秒）
    func setRefreshInterval(_ interval: TimeInterval) {
        guard interval >= 1.0 && interval <= 60.0 else {
            print("PreferencesManager: 无效的刷新间隔: \(interval)")
            return
        }
        
        var newPreferences = preferences
        newPreferences.refreshInterval = interval
        updatePreferences(newPreferences)
    }
    
    /// 更新通知设置
    /// - Parameter enabled: 是否启用通知
    func setNotificationsEnabled(_ enabled: Bool) {
        var newPreferences = preferences
        newPreferences.enableNotifications = enabled
        updatePreferences(newPreferences)
    }
    
    /// 更新登录启动设置
    /// - Parameter enabled: 是否在登录时启动
    func setLaunchAtLogin(_ enabled: Bool) {
        // 先尝试设置系统登录项
        let success = LaunchAtLoginManager.shared.setLaunchAtLogin(enabled)
        
        if success {
            var newPreferences = preferences
            newPreferences.launchAtLogin = enabled
            updatePreferences(newPreferences)
            print("PreferencesManager: 登录启动设置已更新为 \(enabled)")
        } else {
            print("PreferencesManager: 设置登录启动失败")
            // 即使系统设置失败，也更新偏好设置以保持一致性
            var newPreferences = preferences
            newPreferences.launchAtLogin = enabled
            updatePreferences(newPreferences)
        }
    }
    
    /// 同步登录启动状态
    /// 检查系统实际状态并更新偏好设置
    func syncLaunchAtLoginStatus() {
        let systemStatus = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled()
        if systemStatus != preferences.launchAtLogin {
            print("PreferencesManager: 同步登录启动状态 - 系统: \(systemStatus), 设置: \(preferences.launchAtLogin)")
            var newPreferences = preferences
            newPreferences.launchAtLogin = systemStatus
            updatePreferences(newPreferences)
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载偏好设置
    /// - Returns: 加载的偏好设置
    private func loadPreferences() -> AppPreferences {
        print("PreferencesManager: 加载偏好设置")
        
        // 从UserDefaults加载设置
        let displayFormatRaw = userDefaults.string(forKey: Keys.displayFormat) ?? AppPreferences().displayFormat.rawValue
        let displayFormat = DisplayFormat(rawValue: displayFormatRaw) ?? AppPreferences().displayFormat
        
        let autoStart = userDefaults.object(forKey: Keys.autoStart) as? Bool ?? AppPreferences().autoStart
        let maxDisplayLength = userDefaults.object(forKey: Keys.maxDisplayLength) as? Int ?? AppPreferences().maxDisplayLength
        let refreshInterval = userDefaults.object(forKey: Keys.refreshInterval) as? TimeInterval ?? AppPreferences().refreshInterval
        let showSignalStrength = userDefaults.object(forKey: Keys.showSignalStrength) as? Bool ?? AppPreferences().showSignalStrength
        let showNetworkIcon = userDefaults.object(forKey: Keys.showNetworkIcon) as? Bool ?? AppPreferences().showNetworkIcon
        let enableNotifications = userDefaults.object(forKey: Keys.enableNotifications) as? Bool ?? AppPreferences().enableNotifications
        let minimizeToTray = userDefaults.object(forKey: Keys.minimizeToTray) as? Bool ?? AppPreferences().minimizeToTray
        let launchAtLogin = userDefaults.object(forKey: Keys.launchAtLogin) as? Bool ?? AppPreferences().launchAtLogin
        let checkForUpdates = userDefaults.object(forKey: Keys.checkForUpdates) as? Bool ?? AppPreferences().checkForUpdates
        
        let loadedPreferences = AppPreferences(
            displayFormat: displayFormat,
            autoStart: autoStart,
            maxDisplayLength: maxDisplayLength,
            refreshInterval: refreshInterval,
            showSignalStrength: showSignalStrength,
            showNetworkIcon: showNetworkIcon,
            enableNotifications: enableNotifications,
            minimizeToTray: minimizeToTray,
            launchAtLogin: launchAtLogin,
            checkForUpdates: checkForUpdates
        )
        
        // 验证加载的设置
        let validation = validatePreferences(loadedPreferences)
        if !validation.isValid {
            print("PreferencesManager: 加载的设置无效，使用默认设置")
            print("PreferencesManager: 验证错误: \(validation.errors)")
            return AppPreferences()
        }
        
        return loadedPreferences
    }
    
    /// 保存偏好设置
    private func savePreferences() {
        print("PreferencesManager: 保存偏好设置")
        
        userDefaults.set(preferences.displayFormat.rawValue, forKey: Keys.displayFormat)
        userDefaults.set(preferences.autoStart, forKey: Keys.autoStart)
        userDefaults.set(preferences.maxDisplayLength, forKey: Keys.maxDisplayLength)
        userDefaults.set(preferences.refreshInterval, forKey: Keys.refreshInterval)
        userDefaults.set(preferences.showSignalStrength, forKey: Keys.showSignalStrength)
        userDefaults.set(preferences.showNetworkIcon, forKey: Keys.showNetworkIcon)
        userDefaults.set(preferences.enableNotifications, forKey: Keys.enableNotifications)
        userDefaults.set(preferences.minimizeToTray, forKey: Keys.minimizeToTray)
        userDefaults.set(preferences.launchAtLogin, forKey: Keys.launchAtLogin)
        userDefaults.set(preferences.checkForUpdates, forKey: Keys.checkForUpdates)
        
        // 同步到磁盘
        userDefaults.synchronize()
    }
    
    /// 发送设置变更通知
    private func postChangeNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.preferencesDidChangeNotification,
                object: self,
                userInfo: ["preferences": self.preferences]
            )
        }
    }
    
    /// UserDefaults变化处理
    @objc private func userDefaultsDidChange() {
        // 检查是否有外部修改
        let currentSaved = loadPreferences()
        if currentSaved != preferences {
            print("PreferencesManager: 检测到外部设置变更")
            preferences = currentSaved
        }
    }
    
    /// 解析设置字典
    /// - Parameter settings: 设置字典
    /// - Returns: 解析的偏好设置
    /// - Throws: 解析错误
    private func parseSettingsDictionary(_ settings: [String: Any]) throws -> AppPreferences {
        guard let displayFormatRaw = settings[Keys.displayFormat] as? String,
              let displayFormat = DisplayFormat(rawValue: displayFormatRaw) else {
            throw PreferencesError.invalidDisplayFormat
        }
        
        guard let autoStart = settings[Keys.autoStart] as? Bool else {
            throw PreferencesError.invalidAutoStart
        }
        
        guard let maxDisplayLength = settings[Keys.maxDisplayLength] as? Int,
              maxDisplayLength >= 5 && maxDisplayLength <= 50 else {
            throw PreferencesError.invalidMaxDisplayLength
        }
        
        guard let refreshInterval = settings[Keys.refreshInterval] as? TimeInterval,
              refreshInterval >= 1.0 && refreshInterval <= 60.0 else {
            throw PreferencesError.invalidRefreshInterval
        }
        
        let showSignalStrength = settings[Keys.showSignalStrength] as? Bool ?? false
        let showNetworkIcon = settings[Keys.showNetworkIcon] as? Bool ?? false
        let enableNotifications = settings[Keys.enableNotifications] as? Bool ?? true
        let minimizeToTray = settings[Keys.minimizeToTray] as? Bool ?? true
        let launchAtLogin = settings[Keys.launchAtLogin] as? Bool ?? false
        let checkForUpdates = settings[Keys.checkForUpdates] as? Bool ?? true
        
        return AppPreferences(
            displayFormat: displayFormat,
            autoStart: autoStart,
            maxDisplayLength: maxDisplayLength,
            refreshInterval: refreshInterval,
            showSignalStrength: showSignalStrength,
            showNetworkIcon: showNetworkIcon,
            enableNotifications: enableNotifications,
            minimizeToTray: minimizeToTray,
            launchAtLogin: launchAtLogin,
            checkForUpdates: checkForUpdates
        )
    }
}

// MARK: - Supporting Types

/// 应用偏好设置数据结构
struct AppPreferences: Equatable, Codable {
    /// 显示格式
    var displayFormat: DisplayFormat = .nameOnly
    
    /// 自动启动
    var autoStart: Bool = true
    
    /// 最大显示长度
    var maxDisplayLength: Int = 20
    
    /// 刷新间隔（秒）
    var refreshInterval: TimeInterval = 5.0
    
    /// 显示信号强度
    var showSignalStrength: Bool = false
    
    /// 显示网络图标
    var showNetworkIcon: Bool = false
    
    /// 启用通知
    var enableNotifications: Bool = true
    
    /// 最小化到托盘
    var minimizeToTray: Bool = true
    
    /// 登录时启动
    var launchAtLogin: Bool = false
    
    /// 检查更新
    var checkForUpdates: Bool = true
    
    /// 创建默认设置
    init() {}
    
    /// 创建自定义设置
    init(displayFormat: DisplayFormat = .nameOnly,
         autoStart: Bool = true,
         maxDisplayLength: Int = 20,
         refreshInterval: TimeInterval = 5.0,
         showSignalStrength: Bool = false,
         showNetworkIcon: Bool = false,
         enableNotifications: Bool = true,
         minimizeToTray: Bool = true,
         launchAtLogin: Bool = false,
         checkForUpdates: Bool = true) {
        self.displayFormat = displayFormat
        self.autoStart = autoStart
        self.maxDisplayLength = maxDisplayLength
        self.refreshInterval = refreshInterval
        self.showSignalStrength = showSignalStrength
        self.showNetworkIcon = showNetworkIcon
        self.enableNotifications = enableNotifications
        self.minimizeToTray = minimizeToTray
        self.launchAtLogin = launchAtLogin
        self.checkForUpdates = checkForUpdates
    }
}

/// 设置验证结果
struct ValidationResult {
    /// 是否有效
    let isValid: Bool
    
    /// 错误列表
    let errors: [String]
    
    /// 创建验证结果
    init(isValid: Bool, errors: [String] = []) {
        self.isValid = isValid
        self.errors = errors
    }
}

/// 偏好设置错误
enum PreferencesError: Error, LocalizedError {
    case invalidDisplayFormat
    case invalidAutoStart
    case invalidMaxDisplayLength
    case invalidRefreshInterval
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDisplayFormat:
            return "无效的显示格式"
        case .invalidAutoStart:
            return "无效的自动启动设置"
        case .invalidMaxDisplayLength:
            return "无效的最大显示长度"
        case .invalidRefreshInterval:
            return "无效的刷新间隔"
        case .saveFailed:
            return "保存设置失败"
        case .loadFailed:
            return "加载设置失败"
        }
    }
}