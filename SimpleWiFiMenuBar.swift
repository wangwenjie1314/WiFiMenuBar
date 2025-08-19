#!/usr/bin/env swift

import Cocoa
import CoreWLAN
import Network

/// 简化版WiFi状态栏应用
class SimpleWiFiMenuBar: NSObject, NSApplicationDelegate {
    
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
    
    /// 网速监控相关属性
    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var lastUpdateTime: Date = Date()
    private var currentUploadSpeed: Double = 0.0
    private var currentDownloadSpeed: Double = 0.0
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 设置状态栏
        setupStatusBar()
        
        // 初始化WiFi监控
        setupWiFiMonitoring()
        
        // 开始监控WiFi状态
        startMonitoring()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // 停止监控
        stopMonitoring()
        
        // 清理资源
        cleanup()
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
    
    /// 初始化WiFi监控
    private func setupWiFiMonitoring() {
        // 初始化CoreWLAN客户端
        wifiClient = CWWiFiClient.shared()
        
        // 获取默认WiFi接口
        guard let client = wifiClient,
              let interfaceNames = CWWiFiClient.interfaceNames(),
              let interfaceName = interfaceNames.first else {
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
    }
    
    /// 开始监控WiFi状态
    private func startMonitoring() {
        // 启动网络路径监控
        pathMonitor?.start(queue: monitorQueue)
        
        // 设置定时器定期更新状态（更频繁更新以获取准确网速）
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWiFiStatus()
        }
        
        // 立即更新一次状态
        updateWiFiStatus()
    }
    
    /// 停止监控
    private func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        pathMonitor?.cancel()
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
        updateNetworkSpeed()
        
        let uploadSpeedStr = formatSpeed(currentUploadSpeed)
        let downloadSpeedStr = formatSpeed(currentDownloadSpeed)
        
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.title = "WiFi: \(wifiName) | ↑\(uploadSpeedStr) ↓\(downloadSpeedStr)"
        }
    }
    
    /// 更新网络速度
    private func updateNetworkSpeed() {
        guard let interfaceName = getActiveNetworkInterface() else {
            currentUploadSpeed = 0.0
            currentDownloadSpeed = 0.0
            return
        }
        
        let (bytesIn, bytesOut) = getNetworkBytes(for: interfaceName)
        let currentTime = Date()
        let timeDiff = currentTime.timeIntervalSince(lastUpdateTime)
        
        if timeDiff > 0 && lastUpdateTime != Date(timeIntervalSince1970: 0) {
            let bytesDiffIn = bytesIn > lastBytesIn ? bytesIn - lastBytesIn : 0
            let bytesDiffOut = bytesOut > lastBytesOut ? bytesOut - lastBytesOut : 0
            
            currentDownloadSpeed = Double(bytesDiffIn) / timeDiff
            currentUploadSpeed = Double(bytesDiffOut) / timeDiff
        } else {
            // 首次运行时设置为0
            currentDownloadSpeed = 0.0
            currentUploadSpeed = 0.0
        }
        
        lastBytesIn = bytesIn
        lastBytesOut = bytesOut
        lastUpdateTime = currentTime
    }
    
    /// 获取活动网络接口名称
    private func getActiveNetworkInterface() -> String? {
        // 优先使用WiFi接口
        if let wifiInterface = wifiInterface,
           let interfaceName = wifiInterface.interfaceName,
           wifiInterface.ssid() != nil {
            return interfaceName
        }
        
        // 如果WiFi未连接，尝试使用以太网接口
        let commonInterfaces = ["en0", "en1", "en2", "en3"]
        for interface in commonInterfaces {
            let (bytesIn, _) = getNetworkBytes(for: interface)
            if bytesIn > 0 {
                return interface
            }
        }
        
        return nil
    }
    
    /// 获取指定网络接口的字节数
    private func getNetworkBytes(for interfaceName: String) -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        
        guard getifaddrs(&ifaddrs) == 0 else {
            return (0, 0)
        }
        
        var ptr = ifaddrs
        while ptr != nil {
            let interface = ptr!.pointee
            let name = String(cString: interface.ifa_name)
            
            if name == interfaceName && interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let data = unsafeBitCast(interface.ifa_data, to: UnsafeMutablePointer<if_data>.self)
                bytesIn = UInt64(data.pointee.ifi_ibytes)
                bytesOut = UInt64(data.pointee.ifi_obytes)
                break
            }
            
            ptr = interface.ifa_next
        }
        
        freeifaddrs(ifaddrs)
        return (bytesIn, bytesOut)
    }
    
    /// 格式化速度显示
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0fB/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1fKB/s", bytesPerSecond / 1024)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.1fMB/s", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.1fGB/s", bytesPerSecond / (1024 * 1024 * 1024))
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
        
        // 重置网速监控数据
        lastBytesIn = 0
        lastBytesOut = 0
        currentUploadSpeed = 0.0
        currentDownloadSpeed = 0.0
    }
}

// MARK: - Main Entry Point

/// 应用入口点
func main() {
    let app = NSApplication.shared
    let delegate = SimpleWiFiMenuBar()
    app.delegate = delegate
    app.run()
}

// 启动应用
main()