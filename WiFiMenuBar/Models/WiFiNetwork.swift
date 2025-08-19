import Foundation

/// WiFi网络信息模型
/// 包含网络的基本信息，如SSID、信号强度、安全性等
struct WiFiNetwork {
    /// 网络名称 (Service Set Identifier)
    let ssid: String
    
    /// 基站标识符 (Basic Service Set Identifier)
    let bssid: String?
    
    /// 信号强度 (RSSI值，通常为负数，越接近0信号越强)
    let signalStrength: Int?
    
    /// 是否为安全网络（需要密码）
    let isSecure: Bool
    
    /// 网络频率 (2.4GHz 或 5GHz)
    let frequency: Double?
    
    /// 网络信道
    let channel: Int?
    
    /// 网络标准 (802.11a/b/g/n/ac/ax)
    let standard: String?
    
    /// 连接时间戳（如果已连接）
    let connectedAt: Date?
}

// MARK: - WiFiNetwork Extensions

extension WiFiNetwork {
    /// 获取信号强度的描述性文本
    var signalStrengthDescription: String {
        guard let strength = signalStrength else { return "未知" }
        
        switch strength {
        case -30...0:
            return "极强"
        case -50...(-31):
            return "很强"
        case -60...(-51):
            return "良好"
        case -70...(-61):
            return "一般"
        default:
            return "较弱"
        }
    }
    
    /// 获取信号强度的百分比 (0-100)
    var signalStrengthPercentage: Int {
        guard let strength = signalStrength else { return 0 }
        
        // 将RSSI值转换为百分比
        // 通常RSSI范围是-100到-30dBm
        let minRSSI = -100
        let maxRSSI = -30
        let clampedStrength = max(minRSSI, min(maxRSSI, strength))
        let percentage = Int(((Double(clampedStrength - minRSSI) / Double(maxRSSI - minRSSI)) * 100))
        
        return percentage
    }
    
    /// 获取频段描述
    var frequencyBand: String {
        guard let freq = frequency else { return "未知" }
        
        if freq >= 2400 && freq <= 2500 {
            return "2.4GHz"
        } else if freq >= 5000 && freq <= 6000 {
            return "5GHz"
        } else if freq >= 6000 && freq <= 7000 {
            return "6GHz"
        } else {
            return "其他"
        }
    }
    
    /// 获取安全性描述
    var securityDescription: String {
        return isSecure ? "安全" : "开放"
    }
}

// MARK: - Equatable

extension WiFiNetwork: Equatable {
    static func == (lhs: WiFiNetwork, rhs: WiFiNetwork) -> Bool {
        return lhs.ssid == rhs.ssid && lhs.bssid == rhs.bssid
    }
}

// MARK: - Hashable

extension WiFiNetwork: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ssid)
        hasher.combine(bssid)
    }
}

// MARK: - CustomStringConvertible

extension WiFiNetwork: CustomStringConvertible {
    var description: String {
        var components = ["SSID: \(ssid)"]
        
        if let bssid = bssid {
            components.append("BSSID: \(bssid)")
        }
        
        if let strength = signalStrength {
            components.append("信号: \(strength)dBm (\(signalStrengthDescription))")
        }
        
        components.append("安全性: \(securityDescription)")
        
        if let freq = frequency {
            components.append("频段: \(frequencyBand)")
        }
        
        return components.joined(separator=", ")
    }
}