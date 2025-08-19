import Cocoa
import Foundation

/// 状态栏控制器
/// 负责管理菜单栏中的WiFi信息显示和用户交互
class StatusBarController: NSObject, WiFiMonitorDelegate {
    
    // MARK: - Properties
    
    /// 状态栏项目
    private var statusItem: NSStatusItem?
    
    /// 下拉菜单
    private var menu: NSMenu?
    
    /// WiFi监控器
    private weak var wifiMonitor: WiFiMonitor?
    
    /// 当前显示格式
    private var displayFormat: DisplayFormat = .nameOnly
    
    /// 最大显示长度
    private let maxDisplayLength = 20
    
    /// 是否显示在菜单栏
    private var isVisible = false
    
    /// 菜单项缓存
    private var menuItemCache: [String: NSMenuItem] = [:]
    
    /// 状态更新定时器
    private var updateTimer: Timer?
    
    /// 上次更新时间
    private var lastUpdateTime: Date = Date.distantPast
    
    /// 最小更新间隔（秒）
    private let minimumUpdateInterval: TimeInterval = 1.0
    
    /// 偏好设置窗口控制器
    private lazy var preferencesWindowController = PreferencesWindowController()
    
    /// 图标管理器
    private let iconManager = IconManager.shared
    
    /// 测试启动器（仅在调试模式下）
    #if DEBUG
    private lazy var testLauncher = TestLauncher()
    #endif
    
    // MARK: - Initialization
    
    /// 初始化状态栏控制器
    /// - Parameter wifiMonitor: WiFi监控器实例
    init(wifiMonitor: WiFiMonitor) {
        self.wifiMonitor = wifiMonitor
        super.init()
        
        // 设置委托
        wifiMonitor.delegate = self
        
        // 监听偏好设置变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: PreferencesManager.preferencesDidChangeNotification,
            object: nil
        )
        
        // 监听图标变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iconThemeChanged),
            name: .iconThemeChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iconAnimationFrameChanged),
            name: .iconAnimationFrameChanged,
            object: nil
        )
        
        setupStatusBar()
        setupMenu()
        loadPreferences()
    }
    
    deinit {
        hideFromStatusBar()
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 显示在状态栏
    func showInStatusBar() {
        guard !isVisible else {
            print("StatusBarController: 已经在状态栏中显示")
            return
        }
        
        print("StatusBarController: 显示在状态栏")
        isVisible = true
        
        // 立即更新显示（使用当前WiFi状态）
        if let currentStatus = wifiMonitor?.status {
            updateDisplay(with: currentStatus)
        } else {
            updateDisplay()
        }
        
        // 启动定时更新
        startPeriodicUpdate()
    }
    
    /// 从状态栏隐藏
    func hideFromStatusBar() {
        guard isVisible else {
            print("StatusBarController: 没有在状态栏中显示")
            return
        }
        
        print("StatusBarController: 从状态栏隐藏")
        isVisible = false
        
        // 停止定时更新
        stopPeriodicUpdate()
        
        // 移除状态栏项目
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    /// 更新显示内容
    /// - Parameter status: WiFi状态（可选，如果为nil则从监控器获取）
    func updateDisplay(with status: WiFiStatus? = nil) {
        // 检查更新频率限制
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) < minimumUpdateInterval {
            return
        }
        lastUpdateTime = now
        
        guard isVisible, let statusItem = statusItem else {
            return
        }
        
        // 获取当前状态
        let currentStatus = status ?? wifiMonitor?.status ?? .unknown
        
        // 格式化显示文本
        let displayText = displayFormat.formatStatus(currentStatus, maxLength: maxDisplayLength)
        
        // 更新状态栏显示
        DispatchQueue.main.async {
            if let button = statusItem.button {
                button.title = displayText
                button.toolTip = self.createToolTip(for: currentStatus)
                
                // 更新图标
                self.updateStatusBarIcon(for: currentStatus)
            }
        }
        
        // 更新菜单内容
        updateMenuContent(with: currentStatus)
    }
    
    /// 设置显示格式
    /// - Parameter format: 新的显示格式
    func setDisplayFormat(_ format: DisplayFormat) {
        guard format != displayFormat else { return }
        
        print("StatusBarController: 更新显示格式为 \(format.displayName)")
        displayFormat = format
        
        // 立即更新显示
        updateDisplay()
    }
    
    /// 获取当前显示格式
    var currentDisplayFormat: DisplayFormat {
        return displayFormat
    }
    
    /// 强制刷新显示
    func forceRefresh() {
        lastUpdateTime = Date.distantPast
        updateDisplay()
    }
    
    /// 更新状态栏图标
    /// - Parameter status: WiFi状态
    private func updateStatusBarIcon(for status: WiFiStatus) {
        guard let button = statusItem?.button else { return }
        
        // 更新图标管理器状态
        iconManager.updateIconStatus(status)
        
        // 获取对应的图标
        if let icon = iconManager.getStatusBarIcon(for: status) {
            button.image = icon
            button.imagePosition = .imageLeft
            
            // 如果只显示图标，隐藏文字
            if shouldShowIconOnly() {
                button.title = ""
                button.imagePosition = .imageOnly
            }
        }
    }
    
    /// 判断是否只显示图标
    /// - Returns: 是否只显示图标
    private func shouldShowIconOnly() -> Bool {
        // 可以根据偏好设置决定是否只显示图标
        return false // 暂时总是显示文字
    }
    
    // MARK: - Private Methods
    
    /// 设置状态栏
    private func setupStatusBar() {
        // 创建状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("StatusBarController: 无法创建状态栏项目")
            return
        }
        
        // 配置状态栏按钮
        if let button = statusItem.button {
            button.title = "WiFi"
            button.toolTip = "WiFi菜单栏"
            
            // 设置点击事件
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            
            // 设置右键菜单
            statusItem.menu = menu
        }
        
        print("StatusBarController: 状态栏设置完成")
    }
    
    /// 设置菜单
    private func setupMenu() {
        menu = NSMenu()
        menu?.autoenablesItems = false
        
        // 创建基础菜单项
        createBasicMenuItems()
        
        print("StatusBarController: 菜单设置完成")
    }
    
    /// 创建基础菜单项
    private func createBasicMenuItems() {
        guard let menu = menu else { return }
        
        // WiFi状态信息项
        let statusMenuItem = NSMenuItem(title: "WiFi状态: 未知", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menuItemCache["status"] = statusMenuItem
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 网络详细信息项
        let detailsMenuItem = NSMenuItem(title: "网络详情", action: #selector(showNetworkDetails), keyEquivalent: "")
        detailsMenuItem.target = self
        menu.addItem(detailsMenuItem)
        menuItemCache["details"] = detailsMenuItem
        
        // 连接统计项
        let statsMenuItem = NSMenuItem(title: "连接统计", action: #selector(showConnectionStats), keyEquivalent: "")
        statsMenuItem.target = self
        menu.addItem(statsMenuItem)
        menuItemCache["stats"] = statsMenuItem
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 刷新项
        let refreshMenuItem = NSMenuItem(title: "刷新", action: #selector(refreshStatus), keyEquivalent: "r")
        refreshMenuItem.target = self
        menu.addItem(refreshMenuItem)
        menuItemCache["refresh"] = refreshMenuItem
        
        // 重试连接项
        let retryMenuItem = NSMenuItem(title: "重试连接", action: #selector(retryConnection), keyEquivalent: "")
        retryMenuItem.target = self
        menu.addItem(retryMenuItem)
        menuItemCache["retry"] = retryMenuItem
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 偏好设置项
        let preferencesMenuItem = NSMenuItem(title: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesMenuItem.target = self
        menu.addItem(preferencesMenuItem)
        menuItemCache["preferences"] = preferencesMenuItem
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 测试菜单项（仅在调试模式下显示）
        #if DEBUG
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        let testMenuItem = NSMenuItem(title: "运行测试", action: #selector(showTestInterface), keyEquivalent: "t")
        testMenuItem.target = self
        menu.addItem(testMenuItem)
        menuItemCache["test"] = testMenuItem
        #endif
        
        // 退出项
        let quitMenuItem = NSMenuItem(title: "退出", action: #selector(quitApplication), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        menuItemCache["quit"] = quitMenuItem
    }
    
    /// 更新菜单内容
    /// - Parameter status: 当前WiFi状态
    private func updateMenuContent(with status: WiFiStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.performMenuUpdate(with: status)
        }
    }
    
    /// 执行菜单更新
    /// - Parameter status: 当前WiFi状态
    private func performMenuUpdate(with status: WiFiStatus) {
        // 更新状态菜单项
        if let statusMenuItem = menuItemCache["status"] {
            statusMenuItem.title = "WiFi状态: \(status.shortDescription)"
        }
        
        // 更新重试菜单项的可用性
        if let retryMenuItem = menuItemCache["retry"] {
            let retryStatus = wifiMonitor?.getRetryStatus()
            retryMenuItem.isEnabled = retryStatus?.canRetry ?? false
            
            if let retryCount = retryStatus?.currentRetryCount, retryCount > 0 {
                retryMenuItem.title = "重试连接 (\(retryCount)/\(retryStatus?.maxRetryCount ?? 5))"
            } else {
                retryMenuItem.title = "重试连接"
            }
        }
        
        // 根据状态更新菜单项可用性
        updateMenuItemsAvailability(for: status)
    }
    
    /// 更新菜单项可用性
    /// - Parameter status: 当前WiFi状态
    private func updateMenuItemsAvailability(for status: WiFiStatus) {
        let isConnected = status.isConnected
        let hasError = status.isError
        
        // 网络详情只在连接时可用
        menuItemCache["details"]?.isEnabled = isConnected
        
        // 连接统计始终可用
        menuItemCache["stats"]?.isEnabled = true
        
        // 刷新始终可用
        menuItemCache["refresh"]?.isEnabled = true
        
        // 重试在有错误且可以重试时可用
        if let retryMenuItem = menuItemCache["retry"] {
            let canRetry = wifiMonitor?.getRetryStatus().canRetry ?? false
            retryMenuItem.isEnabled = hasError && canRetry
        }
    }
    
    /// 创建工具提示
    /// - Parameter status: WiFi状态
    /// - Returns: 工具提示文本
    private func createToolTip(for status: WiFiStatus) -> String {
        switch status {
        case .connected(let network):
            var tooltip = "已连接到: \(network.ssid)"
            if let strength = network.signalStrength {
                tooltip += "\n信号强度: \(strength)dBm (\(network.signalStrengthPercentage)%)"
            }
            if let frequency = network.frequency {
                tooltip += "\n频段: \(network.frequencyBand)"
            }
            tooltip += "\n安全性: \(network.securityDescription)"
            return tooltip
            
        case .disconnected:
            return "未连接到WiFi网络"
            
        case .connecting(let networkName):
            return "正在连接到: \(networkName)"
            
        case .disconnecting:
            return "正在断开连接"
            
        case .error(let error):
            return "WiFi错误: \(error.localizedDescription)"
            
        case .disabled:
            return "WiFi已关闭"
            
        case .unknown:
            return "WiFi状态未知"
        }
    }
    
    /// 启动定时更新
    private func startPeriodicUpdate() {
        stopPeriodicUpdate() // 确保没有重复的定时器
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }
    
    /// 停止定时更新
    private func stopPeriodicUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Menu Actions
    
    /// 状态栏按钮点击事件
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        // 左键点击显示菜单（由系统自动处理）
        // 这里可以添加其他点击逻辑
        print("StatusBarController: 状态栏按钮被点击")
    }
    
    /// 显示网络详情
    @objc private func showNetworkDetails() {
        guard let currentNetwork = wifiMonitor?.getCurrentNetwork() else {
            showAlert(title: "网络详情", message: "当前未连接到任何WiFi网络")
            return
        }
        
        let details = """
        网络名称: \(currentNetwork.ssid)
        BSSID: \(currentNetwork.bssid ?? "未知")
        信号强度: \(currentNetwork.signalStrength?.description ?? "未知")dBm (\(currentNetwork.signalStrengthPercentage)%)
        频段: \(currentNetwork.frequencyBand)
        信道: \(currentNetwork.channel?.description ?? "未知")
        网络标准: \(currentNetwork.standard ?? "未知")
        安全性: \(currentNetwork.securityDescription)
        连接时间: \(currentNetwork.connectedAt?.description ?? "未知")
        """
        
        showAlert(title: "网络详情", message: details)
    }
    
    /// 显示连接统计
    @objc private func showConnectionStats() {
        guard let stats = wifiMonitor?.getConnectionStats() else {
            showAlert(title: "连接统计", message: "无法获取连接统计信息")
            return
        }
        
        let stability = wifiMonitor?.getConnectionStability()
        
        let statsText = """
        总事件数: \(stats.totalEvents)
        连接次数: \(stats.connectionCount)
        断开次数: \(stats.disconnectionCount)
        错误次数: \(stats.errorCount)
        连接成功率: \(String(format: "%.1f", stats.connectionSuccessRate * 100))%
        稳定性评分: \(String(format: "%.1f", stability?.stabilityScore ?? 0.0))
        稳定性等级: \(stability?.stabilityLevel.rawValue ?? "未知")
        """
        
        showAlert(title: "连接统计", message: statsText)
    }
    
    /// 刷新状态
    @objc private func refreshStatus() {
        print("StatusBarController: 手动刷新状态")
        wifiMonitor?.forceRefreshStatus()
        forceRefresh()
    }
    
    /// 重试连接
    @objc private func retryConnection() {
        print("StatusBarController: 手动重试连接")
        wifiMonitor?.retryConnection()
    }
    
    /// 显示偏好设置
    @objc private func showPreferences() {
        print("StatusBarController: 显示偏好设置")
        preferencesWindowController.showPreferences()
    }
    
    /// 显示测试界面（仅在调试模式下）
    #if DEBUG
    @objc private func showTestInterface() {
        print("StatusBarController: 显示测试界面")
        testLauncher.showTestInterface()
    }
    #endif
    
    /// 退出应用
    @objc private func quitApplication() {
        print("StatusBarController: 退出应用")
        NSApplication.shared.terminate(nil)
    }
    
    /// 显示警告对话框
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    // MARK: - Preferences Handling
    
    /// 加载偏好设置
    private func loadPreferences() {
        let preferences = PreferencesManager.shared.getCurrentPreferences()
        displayFormat = preferences.displayFormat
        print("StatusBarController: 加载偏好设置 - 显示格式: \(displayFormat.displayName)")
    }
    
    /// 偏好设置变更处理
    @objc private func preferencesDidChange(_ notification: Notification) {
        guard let preferences = notification.userInfo?["preferences"] as? AppPreferences else {
            return
        }
        
        print("StatusBarController: 偏好设置已变更")
        
        // 更新显示格式
        if preferences.displayFormat != displayFormat {
            displayFormat = preferences.displayFormat
            print("StatusBarController: 显示格式已更新为 \(displayFormat.displayName)")
        }
        
        // 立即更新显示
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplay()
        }
    }
    
    /// 图标主题变更处理
    @objc private func iconThemeChanged(_ notification: Notification) {
        print("StatusBarController: 图标主题已变更")
        
        // 强制更新图标
        DispatchQueue.main.async { [weak self] in
            if let currentStatus = self?.wifiMonitor?.status {
                self?.updateStatusBarIcon(for: currentStatus)
            }
        }
    }
    
    /// 图标动画帧变更处理
    @objc private func iconAnimationFrameChanged(_ notification: Notification) {
        // 更新动画图标
        DispatchQueue.main.async { [weak self] in
            if let currentStatus = self?.wifiMonitor?.status {
                self?.updateStatusBarIcon(for: currentStatus)
            }
        }
    }
}

// MARK: - WiFiMonitorDelegate Implementation

extension StatusBarController {
    /// WiFi连接到新网络时调用
    /// - Parameter network: 连接的网络信息
    func wifiDidConnect(to network: WiFiNetwork) {
        print("StatusBarController: WiFi已连接到 \(network.ssid)")
        
        // 立即更新显示
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplay(with: .connected(network))
        }
        
        // 记录连接事件
        logConnectionEvent("已连接到网络: \(network.ssid)")
    }
    
    /// WiFi断开连接时调用
    func wifiDidDisconnect() {
        print("StatusBarController: WiFi连接已断开")
        
        // 立即更新显示
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplay(with: .disconnected)
        }
        
        // 记录断开事件
        logConnectionEvent("WiFi连接已断开")
    }
    
    /// WiFi状态发生变化时调用
    /// - Parameter status: 新的WiFi状态
    func wifiStatusDidChange(_ status: WiFiStatus) {
        print("StatusBarController: WiFi状态变化为 \(status.shortDescription)")
        
        // 立即更新显示
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplay(with: status)
        }
        
        // 根据状态类型执行特定操作
        handleStatusChange(status)
        
        // 记录状态变化事件
        logConnectionEvent("状态变化: \(status.displayText)")
    }
    
    /// 处理状态变化的特定操作
    /// - Parameter status: 新的WiFi状态
    private func handleStatusChange(_ status: WiFiStatus) {
        switch status {
        case .connected(let network):
            // 连接成功时的处理
            handleSuccessfulConnection(network)
            
        case .error(let error):
            // 错误状态的处理
            handleConnectionError(error)
            
        case .disconnected:
            // 断开连接时的处理
            handleDisconnection()
            
        case .connecting(let networkName):
            // 连接中状态的处理
            handleConnecting(networkName)
            
        case .disabled:
            // WiFi禁用状态的处理
            handleWiFiDisabled()
            
        default:
            // 其他状态的通用处理
            break
        }
    }
    
    /// 处理成功连接
    /// - Parameter network: 连接的网络
    private func handleSuccessfulConnection(_ network: WiFiNetwork) {
        // 更新工具提示为详细信息
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.toolTip = self?.createToolTip(for: .connected(network))
            }
        }
        
        // 如果信号强度较弱，可以考虑显示警告
        if let strength = network.signalStrength, strength < -70 {
            print("StatusBarController: 警告 - 信号强度较弱: \(strength)dBm")
        }
    }
    
    /// 处理连接错误
    /// - Parameter error: 错误信息
    private func handleConnectionError(_ error: WiFiMonitorError) {
        print("StatusBarController: 处理连接错误: \(error.localizedDescription)")
        
        // 更新工具提示显示错误信息
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.toolTip = "WiFi错误: \(error.localizedDescription)"
            }
        }
        
        // 如果需要用户干预，可以考虑显示通知
        if error.requiresUserIntervention {
            print("StatusBarController: 错误需要用户干预: \(error.recoverySuggestion ?? "无建议")")
        }
    }
    
    /// 处理断开连接
    private func handleDisconnection() {
        // 更新工具提示
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.toolTip = "未连接到WiFi网络"
            }
        }
    }
    
    /// 处理连接中状态
    /// - Parameter networkName: 正在连接的网络名称
    private func handleConnecting(_ networkName: String) {
        // 更新工具提示显示连接进度
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.toolTip = "正在连接到: \(networkName)"
            }
        }
    }
    
    /// 处理WiFi禁用状态
    private func handleWiFiDisabled() {
        // 更新工具提示
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.toolTip = "WiFi已关闭，请在系统设置中启用"
            }
        }
    }
    
    /// 记录连接事件
    /// - Parameter message: 事件消息
    private func logConnectionEvent(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), 
                                                     dateStyle: .none, 
                                                     timeStyle: .medium)
        print("StatusBarController [\(timestamp)]: \(message)")
    }
}

// MARK: - StatusBarController Extensions

extension StatusBarController {
    /// 检查是否在状态栏中显示
    var isVisibleInStatusBar: Bool {
        return isVisible
    }
    
    /// 获取菜单项数量
    var menuItemCount: Int {
        return menu?.items.count ?? 0
    }
    
    /// 获取状态栏按钮标题
    var statusBarTitle: String? {
        return statusItem?.button?.title
    }
    
    /// 获取工具提示
    var toolTip: String? {
        return statusItem?.button?.toolTip
    }
}