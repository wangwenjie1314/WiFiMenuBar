import Cocoa
import Foundation

/// 图标资源加载器
/// 负责从资源包和配置文件加载图标资源
class IconResourceLoader {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = IconResourceLoader()
    
    // MARK: - Properties
    
    /// 图标配置
    private var iconConfiguration: [String: Any] = [:]
    
    /// 资源缓存
    private var resourceCache: [String: Any] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadIconConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// 加载状态栏图标
    /// - Parameter status: 图标状态
    /// - Returns: 图标图像
    func loadStatusBarIcon(for status: IconStatus) -> NSImage? {
        let cacheKey = "statusbar_\(status.rawValue)"
        
        if let cachedImage = resourceCache[cacheKey] as? NSImage {
            return cachedImage
        }
        
        let imageName = getImageName(for: status)
        let image = loadImageFromBundle(named: imageName)
        
        if let image = image {
            // 设置为模板图像
            image.isTemplate = true
            resourceCache[cacheKey] = image
        }
        
        return image
    }
    
    /// 加载应用图标
    /// - Parameter size: 图标尺寸
    /// - Returns: 图标图像
    func loadAppIcon(size: CGSize = CGSize(width: 512, height: 512)) -> NSImage? {
        let cacheKey = "appicon_\(size.width)x\(size.height)"
        
        if let cachedImage = resourceCache[cacheKey] as? NSImage {
            return cachedImage
        }
        
        let image = loadImageFromBundle(named: "AppIcon")
        
        if let image = image {
            // 调整尺寸
            let resizedImage = resizeImage(image, to: size)
            resourceCache[cacheKey] = resizedImage
            return resizedImage
        }
        
        return image
    }
    
    /// 获取图标配置
    /// - Parameter key: 配置键
    /// - Returns: 配置值
    func getIconConfiguration(for key: String) -> Any? {
        return iconConfiguration[key]
    }
    
    /// 获取状态栏图标配置
    /// - Parameter status: 图标状态
    /// - Returns: 图标配置
    func getStatusBarIconConfiguration(for status: IconStatus) -> [String: Any]? {
        guard let statusBarIcons = iconConfiguration["StatusBarIcons"] as? [String: Any] else {
            return nil
        }
        
        let configKey = status.configurationKey
        return statusBarIcons[configKey] as? [String: Any]
    }
    
    /// 获取动画设置
    /// - Returns: 动画设置
    func getAnimationSettings() -> [String: Any]? {
        return iconConfiguration["AnimationSettings"] as? [String: Any]
    }
    
    /// 获取主题配置
    /// - Parameter theme: 主题名称
    /// - Returns: 主题配置
    func getThemeConfiguration(for theme: String) -> [String: Any]? {
        guard let iconThemes = iconConfiguration["IconThemes"] as? [String: Any] else {
            return nil
        }
        
        return iconThemes[theme] as? [String: Any]
    }
    
    /// 预加载图标资源
    func preloadIconResources() {
        print("IconResourceLoader: 预加载图标资源")
        
        // 预加载所有状态栏图标
        for status in IconStatus.allCases {
            _ = loadStatusBarIcon(for: status)
        }
        
        // 预加载应用图标
        _ = loadAppIcon()
        
        print("IconResourceLoader: 图标资源预加载完成")
    }
    
    /// 清除资源缓存
    func clearResourceCache() {
        resourceCache.removeAll()
        print("IconResourceLoader: 资源缓存已清除")
    }
    
    /// 重新加载配置
    func reloadConfiguration() {
        loadIconConfiguration()
        clearResourceCache()
        print("IconResourceLoader: 配置已重新加载")
    }
    
    /// 检查图标资源完整性
    /// - Returns: 检查结果
    func checkIconResourceIntegrity() -> IconResourceIntegrityResult {
        var missingResources: [String] = []
        var availableResources: [String] = []
        
        // 检查状态栏图标
        for status in IconStatus.allCases {
            let imageName = getImageName(for: status)
            if loadImageFromBundle(named: imageName) != nil {
                availableResources.append(imageName)
            } else {
                missingResources.append(imageName)
            }
        }
        
        // 检查应用图标
        if loadImageFromBundle(named: "AppIcon") != nil {
            availableResources.append("AppIcon")
        } else {
            missingResources.append("AppIcon")
        }
        
        return IconResourceIntegrityResult(
            isComplete: missingResources.isEmpty,
            availableResources: availableResources,
            missingResources: missingResources
        )
    }
    
    /// 获取资源统计信息
    /// - Returns: 资源统计信息
    func getResourceStatistics() -> IconResourceStatistics {
        let integrityResult = checkIconResourceIntegrity()
        
        return IconResourceStatistics(
            totalResources: integrityResult.availableResources.count + integrityResult.missingResources.count,
            availableResources: integrityResult.availableResources.count,
            missingResources: integrityResult.missingResources.count,
            cacheSize: resourceCache.count,
            configurationLoaded: !iconConfiguration.isEmpty
        )
    }
    
    // MARK: - Private Methods
    
    /// 加载图标配置
    private func loadIconConfiguration() {
        guard let configPath = Bundle.main.path(forResource: "IconConfiguration", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: configPath) as? [String: Any] else {
            print("IconResourceLoader: 无法加载图标配置文件")
            return
        }
        
        iconConfiguration = configData
        print("IconResourceLoader: 图标配置已加载")
    }
    
    /// 获取图像名称
    /// - Parameter status: 图标状态
    /// - Returns: 图像名称
    private func getImageName(for status: IconStatus) -> String {
        // 首先尝试从配置文件获取
        if let config = getStatusBarIconConfiguration(for: status),
           let imageName = config["ImageName"] as? String {
            return imageName
        }
        
        // 使用默认映射
        switch status {
        case .connected:
            return "WiFiConnected"
        case .disconnected:
            return "WiFiDisconnected"
        case .connecting:
            return "WiFiConnecting"
        case .error:
            return "WiFiError"
        case .disabled:
            return "WiFiDisconnected"
        case .unknown:
            return "WiFiDisconnected"
        }
    }
    
    /// 从资源包加载图像
    /// - Parameter name: 图像名称
    /// - Returns: 图像对象
    private func loadImageFromBundle(named name: String) -> NSImage? {
        // 首先尝试从主包加载
        if let image = NSImage(named: name) {
            return image
        }
        
        // 尝试从Assets.xcassets加载
        if let image = NSImage(named: NSImage.Name(name)) {
            return image
        }
        
        // 尝试加载系统图标作为后备
        return loadSystemFallbackIcon(for: name)
    }
    
    /// 加载系统后备图标
    /// - Parameter name: 图像名称
    /// - Returns: 系统图标
    private func loadSystemFallbackIcon(for name: String) -> NSImage? {
        // 根据名称映射到系统图标
        switch name {
        case "WiFiConnected":
            return NSImage(systemSymbolName: "wifi", accessibilityDescription: "WiFi Connected")
        case "WiFiDisconnected":
            return NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "WiFi Disconnected")
        case "WiFiError":
            return NSImage(systemSymbolName: "wifi.exclamationmark", accessibilityDescription: "WiFi Error")
        case "WiFiConnecting":
            return NSImage(systemSymbolName: "wifi", accessibilityDescription: "WiFi Connecting")
        default:
            return NSImage(systemSymbolName: "questionmark", accessibilityDescription: "Unknown")
        }
    }
    
    /// 调整图像尺寸
    /// - Parameters:
    ///   - image: 原始图像
    ///   - size: 目标尺寸
    /// - Returns: 调整后的图像
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
}

// MARK: - Supporting Types

/// 图标资源完整性检查结果
struct IconResourceIntegrityResult {
    let isComplete: Bool
    let availableResources: [String]
    let missingResources: [String]
    
    var description: String {
        return """
        图标资源完整性检查:
        - 完整性: \(isComplete ? "完整" : "不完整")
        - 可用资源: \(availableResources.count) 个
        - 缺失资源: \(missingResources.count) 个
        - 缺失列表: \(missingResources.joined(separator: ", "))
        """
    }
}

/// 图标资源统计信息
struct IconResourceStatistics {
    let totalResources: Int
    let availableResources: Int
    let missingResources: Int
    let cacheSize: Int
    let configurationLoaded: Bool
    
    var description: String {
        return """
        图标资源统计:
        - 总资源数: \(totalResources)
        - 可用资源: \(availableResources)
        - 缺失资源: \(missingResources)
        - 缓存大小: \(cacheSize)
        - 配置已加载: \(configurationLoaded ? "是" : "否")
        """
    }
}

// MARK: - IconStatus Extension

extension IconStatus {
    /// 配置键
    var configurationKey: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .error:
            return "Error"
        case .disabled:
            return "Disconnected"
        case .unknown:
            return "Disconnected"
        }
    }
}