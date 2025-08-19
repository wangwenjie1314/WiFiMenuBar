import Foundation

/// WiFi连接状态枚举
/// 表示当前WiFi的连接状态和相关信息
enum WiFiStatus {
    /// 已连接到指定网络
    case connected(WiFiNetwork)
    
    /// 未连接到任何网络
    case disconnected
    
    /// 正在连接中
    case connecting(String) // 参数为正在连接的网络名称
    
    /// 正在断开连接
    case disconnecting
    
    /// 发生错误
    case error(WiFiMonitorError)
    
    /// WiFi硬件已禁用
    case disabled
    
    /// 未知状态
    case unknown
}

// MARK: - WiFiStatus Extensions

extension WiFiStatus {
    /// 获取状态的显示文本
    var displayText: String {
        switch self {
        case .connected(let network):
            return network.ssid
        case .disconnected:
            return "未连接"
        case .connecting(let networkName):
            return "连接中: \(networkName)"
        case .disconnecting:
            return "断开中"
        case .error(let error):
            return "错误: \(error.localizedDescription)"
        case .disabled:
            return "WiFi已关闭"
        case .unknown:
            return "状态未知"
        }
    }
    
    /// 获取状态的简短描述
    var shortDescription: String {
        switch self {
        case .connected(let network):
            return network.ssid
        case .disconnected:
            return "未连接"
        case .connecting:
            return "连接中"
        case .disconnecting:
            return "断开中"
        case .error:
            return "错误"
        case .disabled:
            return "已关闭"
        case .unknown:
            return "未知"
        }
    }
    
    /// 获取详细的状态信息
    var detailedDescription: String {
        switch self {
        case .connected(let network):
            var details = ["已连接到: \(network.ssid)"]
            
            if let strength = network.signalStrength {
                details.append("信号强度: \(strength)dBm (\(network.signalStrengthDescription))")
            }
            
            if let freq = network.frequency {
                details.append("频段: \(network.frequencyBand)")
            }
            
            details.append("安全性: \(network.securityDescription)")
            
            if let connectedAt = network.connectedAt {
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
                details.append("连接时间: \(formatter.string(from: connectedAt))")
            }
            
            return details.joined(separator="\n")
            
        case .disconnected:
            return "当前未连接到任何WiFi网络"
            
        case .connecting(let networkName):
            return "正在连接到网络: \(networkName)"
            
        case .disconnecting:
            return "正在断开当前网络连接"
            
        case .error(let error):
            return "WiFi连接出现错误:\n\(error.localizedDescription)"
            
        case .disabled:
            return "WiFi功能已关闭，请在系统设置中启用"
            
        case .unknown:
            return "无法确定当前WiFi状态"
        }
    }
    
    /// 判断是否为连接状态
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    /// 判断是否为错误状态
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    /// 判断是否为过渡状态（连接中或断开中）
    var isTransitioning: Bool {
        switch self {
        case .connecting, .disconnecting:
            return true
        default:
            return false
        }
    }
    
    /// 获取当前连接的网络（如果已连接）
    var connectedNetwork: WiFiNetwork? {
        if case .connected(let network) = self {
            return network
        }
        return nil
    }
}

// MARK: - Equatable

extension WiFiStatus: Equatable {
    static func == (lhs: WiFiStatus, rhs: WiFiStatus) -> Bool {
        switch (lhs, rhs) {
        case (.connected(let network1), .connected(let network2)):
            return network1 == network2
        case (.disconnected, .disconnected):
            return true
        case (.connecting(let name1), .connecting(let name2)):
            return name1 == name2
        case (.disconnecting, .disconnecting):
            return true
        case (.error(let error1), .error(let error2)):
            return error1.localizedDescription == error2.localizedDescription
        case (.disabled, .disabled):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension WiFiStatus: CustomStringConvertible {
    var description: String {
        return displayText
    }
}