import Cocoa
import CoreWLAN
import Network

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    /// 状态栏项目
    private var statusItem: NSStatusItem?
    
    /// WiFi客户端
    private var wifiClient: CWWiFiClient?
    
    /// 当前WiFi接口
    private var wifiInterface: CWInterface?
    
    /// 网络监控器
    private var pathMonitor: NWPathMonitor?
    
    /// 监控队列
    private let monitorQueue = DispatchQueue(label: "wifi.monitor", qos: .utility)
    
    /// 更新定时器
    private var updateTimer: Timer?
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("WiFiMenuBar: 应用启动")
        
        // 设置状态栏
        setupStatusBar()
        
        // 初始化WiFi监控
        setupWiFiMonitoring()
        
        // 开始监控WiFi状态
        startMonitoring()
        
        print("WiFiMenuBar: 应用启动完成")
    }
    
    /// 初始化WiFi监控
    private func setupWiFiMonitoring() {
        print("WiFiMenuBar: 初始化WiFi监控")
        
        // 初始化CoreWLAN客户端
        wifiClient = CWWiFiClient.shared()
        
        // 获取默认WiFi接口
        guard let client = wifiClient,
              let interfaceNames = CWWiFiClient.interfaceNames(),
              let interfaceName = interfaceNames.first as? String else {
            print("WiFiMenuBar: 无法获取WiFi接口")
            return
        }
        
        wifiInterface = client.interface(withName: interfaceName)
        
        // 初始化网络路径监控
        pathMonitor = NWPathMonitor()
        
        // 设置网络状态变化回调
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateWiFiStatus()
            }
        }
        
        print("WiFiMenuBar: WiFi监控初始化完成")
    }
    
    /// 开始监控WiFi状态
    private func startMonitoring() {
        print("WiFiMenuBar: 开始监控WiFi状态")
        
        // 启动网络路径监控
        pathMonitor?.start(queue: monitorQueue)
        
        // 设置定时器定期更新状态
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateWiFiStatus()
        }
        
        // 立即更新一次状态
        updateWiFiStatus()
        
        print("WiFiMenuBar: WiFi状态监控已启动")
    }
    
    /// 停止监控
    private func stopMonitoring() {
        print("WiFiMenuBar: 停止监控")
        
        updateTimer?.invalidate()
        updateTimer = nil
        
        pathMonitor?.cancel()
        
        print("WiFiMenuBar: 监控已停止")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("WiFiMenuBar: 应用即将退出")
        
        // 停止监控
        stopMonitoring()
        
        // 清理资源
        cleanup()
        
        print("WiFiMenuBar: 应用退出完成")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Core Methods
    
    /// 设置状态栏
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "WiFi: 获取中..."
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // 设置应用为后台应用（不显示在Dock中）
        NSApp.setActivationPolicy(.accessory)
    }
    
    /// 状态栏按钮点击事件
    @objc private func statusBarButtonClicked() {
        // 简单的菜单
        let menu = NSMenu()
        
        let currentWiFi = getCurrentWiFiName()
        let wifiMenuItem = NSMenuItem(title: "当前WiFi: \(currentWiFi)", action: nil, keyEquivalent: "")
        wifiMenuItem.isEnabled = false
        menu.addItem(wifiMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let refreshItem = NSMenuItem(title: "刷新", action: #selector(refreshWiFiStatus), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    /// 刷新WiFi状态
    @objc private func refreshWiFiStatus() {
        updateWiFiStatus()
    }
    
    /// 退出应用
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    /// 获取当前WiFi名称
    private func getCurrentWiFiName() -> String {
        guard let interface = wifiInterface else {
            return "未连接"
        }
        
        return interface.ssid() ?? "未连接"
    }
    
    /// 更新WiFi状态
    private func updateWiFiStatus() {
        let wifiName = getCurrentWiFiName()
        
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.title = "WiFi: \(wifiName)"
        }
    }
    
    /// 清理资源
    private func cleanup() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        pathMonitor?.cancel()
        pathMonitor = nil
        
        statusItem = nil
        wifiClient = nil
        wifiInterface = nil
    }
}