import Cocoa
import Foundation

/// 图标管理器
/// 负责管理应用图标和菜单栏图标的显示和切换
class IconManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = IconManager()
    
    // MARK: - Properties
    
    /// 当前图标状态
    @Published var currentIconStatus: IconStatus = .unknown
    
    /// 是否启用动态图标
    @Published var isDynamicIconEnabled: Bool = true
    
    /// 是否启用彩色图标
    @Published var isColorIconEnabled: Bool = false
    
    /// 当前主题模式
    @Published var currentTheme: IconTheme = .auto
    
    // MARK: - Private Properties
    
    /// 图标缓存
    private var iconCache: [String: NSImage] = [:]
    
    /// 资源加载器
    private let resourceLoader = IconResourceLoader.shared
    
    /// 动画定时器
    private var animationTimer: Timer?
    
    /// 动画帧索引
    private var animationFrameIndex = 0
    
    /// 是否正在动画
    private var isAnimating = false
    
    // MARK: - Initialization
    
    private init() {
        print("IconManager: 初始化图标管理器")
        setupIconCache()
        observeThemeChanges()
    }
    
    deinit {
        stopAnimation()
    }
    
    // MARK: - Public Methods
    
    /// 获取状态栏图标
    /// - Parameter status: WiFi状态
    /// - Returns: 对应的图标
    func getStatusBarIcon(for status: WiFiStatus) -> NSImage? {
        let iconStatus = convertWiFiStatusToIconStatus(status)
        return getIcon(for: iconStatus, type: .statusBar)
    }
    
    /// 获取应用图标
    /// - Returns: 应用图标
    func getAppIcon() -> NSImage? {
        return getIcon(for: .connected, type: .application)
    }
    
    /// 更新图标状态
    /// - Parameter status: WiFi状态
    func updateIconStatus(_ status: WiFiStatus) {
        let newIconStatus = convertWiFiStatusToIconStatus(status)
        
        if newIconStatus != currentIconStatus {
            currentIconStatus = newIconStatus
            
            // 如果是连接中状态，启动动画
            if newIconStatus == .connecting && isDynamicIconEnabled {
                startConnectingAnimation()
            } else {
                stopAnimation()
            }
            
            print("IconManager: 图标状态更新为 \(newIconStatus.description)")
        }
    }
    
    /// 设置主题模式
    /// - Parameter theme: 主题模式
    func setTheme(_ theme: IconTheme) {
        guard theme != currentTheme else { return }
        
        currentTheme = theme
        clearIconCache()
        
        print("IconManager: 主题模式更新为 \(theme.description)")
        
        // 通知图标需要更新
        NotificationCenter.default.post(name: .iconThemeChanged, object: self)
    }
    
    /// 设置动态图标启用状态
    /// - Parameter enabled: 是否启用
    func setDynamicIconEnabled(_ enabled: Bool) {
        isDynamicIconEnabled = enabled
        
        if !enabled {
            stopAnimation()
        } else if currentIconStatus == .connecting {
            startConnectingAnimation()
        }
        
        print("IconManager: 动态图标 \(enabled ? "启用" : "禁用")")
    }
    
    /// 设置彩色图标启用状态
    /// - Parameter enabled: 是否启用
    func setColorIconEnabled(_ enabled: Bool) {
        isColorIconEnabled = enabled
        clearIconCache()
        
        print("IconManager: 彩色图标 \(enabled ? "启用" : "禁用")")
        
        // 通知图标需要更新
        NotificationCenter.default.post(name: .iconColorModeChanged, object: self)
    }
    
    /// 生成图标
    /// - Parameters:
    ///   - status: 图标状态
    ///   - size: 图标大小
    ///   - isTemplate: 是否为模板图标
    /// - Returns: 生成的图标
    func generateIcon(for status: IconStatus, size: CGSize, isTemplate: Bool = true) -> NSImage? {
        let cacheKey = "\(status.rawValue)_\(size.width)x\(size.height)_\(isTemplate)_\(currentTheme.rawValue)_\(isColorIconEnabled)"
        
        if let cachedIcon = iconCache[cacheKey] {
            return cachedIcon
        }
        
        let icon = createIcon(for: status, size: size, isTemplate: isTemplate)
        iconCache[cacheKey] = icon
        
        return icon
    }
    
    /// 预加载图标
    func preloadIcons() {
        print("IconManager: 预加载图标")
        
        // 使用资源加载器预加载
        resourceLoader.preloadIconResources()
        
        let statuses: [IconStatus] = [.connected, .disconnected, .error, .connecting, .disabled]
        let sizes: [CGSize] = [
            CGSize(width: 16, height: 16),
            CGSize(width: 18, height: 18),
            CGSize(width: 20, height: 20),
            CGSize(width: 22, height: 22)
        ]
        
        for status in statuses {
            for size in sizes {
                _ = generateIcon(for: status, size: size, isTemplate: true)
                _ = generateIcon(for: status, size: size, isTemplate: false)
            }
        }
        
        print("IconManager: 图标预加载完成")
    }
    
    /// 清除图标缓存
    func clearIconCache() {
        iconCache.removeAll()
        print("IconManager: 图标缓存已清除")
    }
    
    /// 获取图标信息
    func getIconInfo() -> IconInfo {
        return IconInfo(
            currentStatus: currentIconStatus,
            isDynamicEnabled: isDynamicIconEnabled,
            isColorEnabled: isColorIconEnabled,
            currentTheme: currentTheme,
            cacheSize: iconCache.count,
            isAnimating: isAnimating
        )
    }
    
    // MARK: - Private Methods
    
    /// 设置图标缓存
    private func setupIconCache() {
        // 预加载常用图标
        preloadIcons()
    }
    
    /// 观察主题变化
    private func observeThemeChanges() {
        // 监听系统外观变化
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    /// 系统外观变化处理
    @objc private func systemAppearanceChanged() {
        if currentTheme == .auto {
            clearIconCache()
            NotificationCenter.default.post(name: .iconThemeChanged, object: self)
        }
    }
    
    /// 转换WiFi状态到图标状态
    /// - Parameter wifiStatus: WiFi状态
    /// - Returns: 图标状态
    private func convertWiFiStatusToIconStatus(_ wifiStatus: WiFiStatus) -> IconStatus {
        switch wifiStatus {
        case .connected:
            return .connected
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .disconnecting:
            return .disconnected
        case .error:
            return .error
        case .disabled:
            return .disabled
        case .unknown:
            return .unknown
        }
    }
    
    /// 获取图标
    /// - Parameters:
    ///   - status: 图标状态
    ///   - type: 图标类型
    /// - Returns: 图标
    private func getIcon(for status: IconStatus, type: IconType) -> NSImage? {
        let size = type.defaultSize
        let isTemplate = type.isTemplate
        
        return generateIcon(for: status, size: size, isTemplate: isTemplate)
    }
    
    /// 创建图标
    /// - Parameters:
    ///   - status: 图标状态
    ///   - size: 图标大小
    ///   - isTemplate: 是否为模板图标
    /// - Returns: 创建的图标
    private func createIcon(for status: IconStatus, size: CGSize, isTemplate: Bool) -> NSImage? {
        // 首先尝试从资源包加载
        if let bundleIcon = loadIconFromBundle(for: status, size: size) {
            if isTemplate {
                bundleIcon.isTemplate = true
            }
            return bundleIcon
        }
        
        // 如果资源包中没有，则程序化生成
        return generateIconProgrammatically(for: status, size: size, isTemplate: isTemplate)
    }
    
    /// 从资源包加载图标
    /// - Parameters:
    ///   - status: 图标状态
    ///   - size: 图标大小
    /// - Returns: 加载的图标
    private func loadIconFromBundle(for status: IconStatus, size: CGSize) -> NSImage? {
        return resourceLoader.loadStatusBarIcon(for: status)
    }
    
    /// 获取图像名称
    /// - Parameter status: 图标状态
    /// - Returns: 图像名称
    private func getImageName(for status: IconStatus) -> String {
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
    
    /// 程序化生成图标
    /// - Parameters:
    ///   - status: 图标状态
    ///   - size: 图标大小
    ///   - isTemplate: 是否为模板图标
    /// - Returns: 生成的图标
    private func generateIconProgrammatically(for status: IconStatus, size: CGSize, isTemplate: Bool) -> NSImage? {
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        let rect = NSRect(origin: .zero, size: size)
        
        // 根据当前主题确定颜色
        let color = getIconColor(for: status, isTemplate: isTemplate)
        
        // 绘制WiFi图标
        drawWiFiIcon(in: rect, status: status, color: color)
        
        if isTemplate {
            image.isTemplate = true
        }
        
        return image
    }
    
    /// 获取图标颜色
    /// - Parameters:
    ///   - status: 图标状态
    ///   - isTemplate: 是否为模板图标
    /// - Returns: 图标颜色
    private func getIconColor(for status: IconStatus, isTemplate: Bool) -> NSColor {
        if isTemplate {
            return .controlAccentColor
        }
        
        if !isColorIconEnabled {
            return isDarkMode() ? .white : .black
        }
        
        switch status {
        case .connected:
            return .systemGreen
        case .disconnected:
            return .systemGray
        case .connecting:
            return .systemBlue
        case .error:
            return .systemRed
        case .disabled:
            return .systemGray
        case .unknown:
            return .systemGray
        }
    }
    
    /// 判断是否为深色模式
    /// - Returns: 是否为深色模式
    private func isDarkMode() -> Bool {
        if currentTheme == .light {
            return false
        } else if currentTheme == .dark {
            return true
        } else {
            // 自动模式，检查系统设置
            let appearance = NSApp.effectiveAppearance
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }
    
    /// 绘制WiFi图标
    /// - Parameters:
    ///   - rect: 绘制区域
    ///   - status: 图标状态
    ///   - color: 绘制颜色
    private func drawWiFiIcon(in rect: NSRect, status: IconStatus, color: NSColor) {
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        
        color.setFill()
        color.setStroke()
        
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = min(rect.width, rect.height) * 0.4
        
        // 绘制WiFi信号弧线
        drawWiFiArcs(centerX: centerX, centerY: centerY, radius: radius, status: status)
        
        // 绘制中心点
        if status != .disabled {
            let dotRadius = radius * 0.15
            let dotRect = NSRect(
                x: centerX - dotRadius,
                y: centerY - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            NSBezierPath(ovalIn: dotRect).fill()
        }
        
        // 根据状态添加额外的视觉元素
        drawStatusIndicator(in: rect, status: status, color: color)
        
        context?.restoreGState()
    }
    
    /// 绘制WiFi弧线
    /// - Parameters:
    ///   - centerX: 中心X坐标
    ///   - centerY: 中心Y坐标
    ///   - radius: 半径
    ///   - status: 图标状态
    private func drawWiFiArcs(centerX: CGFloat, centerY: CGFloat, radius: CGFloat, status: IconStatus) {
        let arcCount = getArcCount(for: status)
        let lineWidth: CGFloat = 1.5
        
        for i in 1...arcCount {
            let arcRadius = radius * CGFloat(i) / 3.0
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            
            // 绘制弧线（从底部向上的扇形）
            path.addArc(
                withCenter: NSPoint(x: centerX, y: centerY),
                radius: arcRadius,
                startAngle: 225,
                endAngle: 315,
                clockwise: false
            )
            
            // 根据状态调整透明度
            let alpha = getArcAlpha(for: status, arcIndex: i)
            NSColor(calibratedWhite: isDarkMode() ? 1.0 : 0.0, alpha: alpha).setStroke()
            
            path.stroke()
        }
    }
    
    /// 获取弧线数量
    /// - Parameter status: 图标状态
    /// - Returns: 弧线数量
    private func getArcCount(for status: IconStatus) -> Int {
        switch status {
        case .connected:
            return 3
        case .disconnected:
            return 1
        case .connecting:
            return isAnimating ? (animationFrameIndex % 3) + 1 : 2
        case .error:
            return 3
        case .disabled:
            return 0
        case .unknown:
            return 1
        }
    }
    
    /// 获取弧线透明度
    /// - Parameters:
    ///   - status: 图标状态
    ///   - arcIndex: 弧线索引
    /// - Returns: 透明度
    private func getArcAlpha(for status: IconStatus, arcIndex: Int) -> CGFloat {
        switch status {
        case .connected:
            return 1.0
        case .disconnected:
            return 0.3
        case .connecting:
            return arcIndex <= (animationFrameIndex % 3) + 1 ? 1.0 : 0.3
        case .error:
            return 0.8
        case .disabled:
            return 0.1
        case .unknown:
            return 0.5
        }
    }
    
    /// 绘制状态指示器
    /// - Parameters:
    ///   - rect: 绘制区域
    ///   - status: 图标状态
    ///   - color: 绘制颜色
    private func drawStatusIndicator(in rect: NSRect, status: IconStatus, color: NSColor) {
        switch status {
        case .error:
            // 绘制错误标识（X）
            drawErrorIndicator(in: rect, color: .systemRed)
        case .disabled:
            // 绘制禁用标识（斜线）
            drawDisabledIndicator(in: rect, color: .systemGray)
        default:
            break
        }
    }
    
    /// 绘制错误指示器
    /// - Parameters:
    ///   - rect: 绘制区域
    ///   - color: 绘制颜色
    private func drawErrorIndicator(in rect: NSRect, color: NSColor) {
        color.setStroke()
        
        let size = min(rect.width, rect.height) * 0.3
        let centerX = rect.maxX - size * 0.7
        let centerY = rect.maxY - size * 0.7
        
        let path = NSBezierPath()
        path.lineWidth = 2.0
        
        // 绘制X
        path.move(to: NSPoint(x: centerX - size/2, y: centerY - size/2))
        path.line(to: NSPoint(x: centerX + size/2, y: centerY + size/2))
        path.move(to: NSPoint(x: centerX + size/2, y: centerY - size/2))
        path.line(to: NSPoint(x: centerX - size/2, y: centerY + size/2))
        
        path.stroke()
    }
    
    /// 绘制禁用指示器
    /// - Parameters:
    ///   - rect: 绘制区域
    ///   - color: 绘制颜色
    private func drawDisabledIndicator(in rect: NSRect, color: NSColor) {
        color.setStroke()
        
        let path = NSBezierPath()
        path.lineWidth = 2.0
        
        // 绘制斜线
        path.move(to: NSPoint(x: rect.minX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        
        path.stroke()
    }
    
    /// 开始连接动画
    private func startConnectingAnimation() {
        guard isDynamicIconEnabled && !isAnimating else { return }
        
        isAnimating = true
        animationFrameIndex = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateAnimationFrame()
        }
        
        print("IconManager: 开始连接动画")
    }
    
    /// 停止动画
    private func stopAnimation() {
        guard isAnimating else { return }
        
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
        animationFrameIndex = 0
        
        print("IconManager: 停止动画")
    }
    
    /// 更新动画帧
    private func updateAnimationFrame() {
        animationFrameIndex += 1
        
        // 通知需要更新图标
        NotificationCenter.default.post(name: .iconAnimationFrameChanged, object: self)
    }
}

// MARK: - Supporting Types

/// 图标状态
enum IconStatus: String, CaseIterable {
    case connected = "connected"
    case disconnected = "disconnected"
    case connecting = "connecting"
    case error = "error"
    case disabled = "disabled"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .connected: return "已连接"
        case .disconnected: return "未连接"
        case .connecting: return "连接中"
        case .error: return "错误"
        case .disabled: return "已禁用"
        case .unknown: return "未知"
        }
    }
}

/// 图标主题
enum IconTheme: String, CaseIterable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"
    
    var description: String {
        switch self {
        case .auto: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

/// 图标类型
enum IconType {
    case statusBar
    case application
    case menuItem
    
    var defaultSize: CGSize {
        switch self {
        case .statusBar:
            return CGSize(width: 18, height: 18)
        case .application:
            return CGSize(width: 512, height: 512)
        case .menuItem:
            return CGSize(width: 16, height: 16)
        }
    }
    
    var isTemplate: Bool {
        switch self {
        case .statusBar, .menuItem:
            return true
        case .application:
            return false
        }
    }
}

/// 图标信息
struct IconInfo {
    let currentStatus: IconStatus
    let isDynamicEnabled: Bool
    let isColorEnabled: Bool
    let currentTheme: IconTheme
    let cacheSize: Int
    let isAnimating: Bool
    
    var description: String {
        return """
        图标信息:
        - 当前状态: \(currentStatus.description)
        - 动态图标: \(isDynamicEnabled ? "启用" : "禁用")
        - 彩色图标: \(isColorEnabled ? "启用" : "禁用")
        - 主题模式: \(currentTheme.description)
        - 缓存大小: \(cacheSize)
        - 动画状态: \(isAnimating ? "运行中" : "停止")
        """
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let iconThemeChanged = Notification.Name("iconThemeChanged")
    static let iconColorModeChanged = Notification.Name("iconColorModeChanged")
    static let iconAnimationFrameChanged = Notification.Name("iconAnimationFrameChanged")
}