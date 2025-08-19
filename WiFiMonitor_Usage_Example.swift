import Foundation

/// WiFiMonitor使用示例
/// 这个文件展示了如何使用WiFiMonitor类
class WiFiMonitorUsageExample: WiFiMonitorDelegate {
    
    private let wifiMonitor = WiFiMonitor()
    
    init() {
        setupWiFiMonitor()
    }
    
    private func setupWiFiMonitor() {
        // 设置委托
        wifiMonitor.delegate = self
        
        // 开始监控
        wifiMonitor.startMonitoring()
        
        // 获取当前网络信息
        if let currentNetwork = wifiMonitor.getCurrentNetwork() {
            print("当前连接的网络: \(currentNetwork.ssid)")
            print("信号强度: \(currentNetwork.signalStrengthDescription)")
            print("频段: \(currentNetwork.frequencyBand)")
            print("安全性: \(currentNetwork.securityDescription)")
        } else {
            print("当前未连接到任何WiFi网络")
        }
        
        // 检查WiFi可用性
        if WiFiMonitor.isWiFiAvailable() {
            print("WiFi功能可用")
            let interfaces = WiFiMonitor.availableInterfaceNames()
            print("可用接口: \(interfaces)")
        } else {
            print("WiFi功能不可用")
        }
    }
    
    // MARK: - WiFiMonitorDelegate
    
    func wifiDidConnect(to network: WiFiNetwork) {
        print("✅ 已连接到网络: \(network.ssid)")
        
        if let strength = network.signalStrength {
            print("   信号强度: \(strength)dBm (\(network.signalStrengthPercentage)%)")
        }
        
        if let frequency = network.frequency {
            print("   频段: \(network.frequencyBand)")
        }
        
        print("   安全性: \(network.securityDescription)")
    }
    
    func wifiDidDisconnect() {
        print("❌ WiFi连接已断开")
    }
    
    func wifiStatusDidChange(_ status: WiFiStatus) {
        print("📡 WiFi状态变化: \(status.displayText)")
        
        switch status {
        case .connected(let network):
            print("   详细信息: \(network.description)")
            
        case .disconnected:
            print("   当前未连接到任何网络")
            
        case .connecting(let networkName):
            print("   正在连接到: \(networkName)")
            
        case .disconnecting:
            print("   正在断开连接")
            
        case .error(let error):
            print("   错误: \(error.localizedDescription)")
            if error.isRetryable {
                print("   这是一个可重试的错误")
            }
            if error.requiresUserIntervention {
                print("   需要用户干预: \(error.recoverySuggestion ?? "无建议")")
            }
            
        case .disabled:
            print("   WiFi功能已被禁用")
            
        case .unknown:
            print("   WiFi状态未知")
        }
    }
    
    deinit {
        // 停止监控
        wifiMonitor.stopMonitoring()
    }
}

// MARK: - 使用示例

/*
// 在AppDelegate或其他地方使用：

class AppDelegate: NSObject, NSApplicationDelegate {
    private var wifiExample: WiFiMonitorUsageExample?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 创建WiFi监控示例
        wifiExample = WiFiMonitorUsageExample()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // 清理资源
        wifiExample = nil
    }
}
*/