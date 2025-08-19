import Foundation

/// 菜单栏显示格式枚举
/// 定义WiFi信息在菜单栏中的显示方式
enum DisplayFormat: String, CaseIterable {
    /// 仅显示网络名称
    case nameOnly = "name_only"
    
    /// 显示网络名称和信号强度
    case nameWithSignal = "name_with_signal"
    
    /// 显示网络名称和WiFi图标
    case nameWithIcon = "name_with_icon"
    
    /// 显示网络名称、信号强度和图标
    case nameWithSignalAndIcon = "name_with_signal_and_icon"
    
    /// 仅显示图标（适合空间有限的情况）
    case iconOnly = "icon_only"
}

// MARK: - DisplayFormat Extensions

extension DisplayFormat {
    /// 获取显示格式的中文名称
    var displayName: String {
        switch self {
        case .nameOnly:
            return "仅显示名称"
        case .nameWithSignal:
            return "名称 + 信号强度"
        case .nameWithIcon:
            return "名称 + 图标"
        case .nameWithSignalAndIcon:
            return "名称 + 信号强度 + 图标"
        case .iconOnly:
            return "仅显示图标"
        }
    }
    
    /// 获取显示格式的描述
    var description: String {
        switch self {
        case .nameOnly:
            return "在菜单栏中只显示WiFi网络名称"
        case .nameWithSignal:
            return "显示网络名称和信号强度百分比"
        case .nameWithIcon:
            return "显示网络名称和WiFi状态图标"
        case .nameWithSignalAndIcon:
            return "显示网络名称、信号强度和状态图标"
        case .iconOnly:
            return "只显示WiFi状态图标，节省菜单栏空间"
        }
    }
    
    /// 判断是否显示网络名称
    var showsNetworkName: Bool {
        switch self {
        case .nameOnly, .nameWithSignal, .nameWithIcon, .nameWithSignalAndIcon:
            return true
        case .iconOnly:
            return false
        }
    }
    
    /// 判断是否显示信号强度
    var showsSignalStrength: Bool {
        switch self {
        case .nameWithSignal, .nameWithSignalAndIcon:
            return true
        case .nameOnly, .nameWithIcon, .iconOnly:
            return false
        }
    }
    
    /// 判断是否显示图标
    var showsIcon: Bool {
        switch self {
        case .nameWithIcon, .nameWithSignalAndIcon, .iconOnly:
            return true
        case .nameOnly, .nameWithSignal:
            return false
        }
    }
    
    /// 格式化WiFi状态为菜单栏显示文本
    /// - Parameter status: WiFi状态
    /// - Parameter maxLength: 最大显示长度
    /// - Returns: 格式化后的显示文本
    func formatStatus(_ status: WiFiStatus, maxLength: Int = 20) -> String {
        switch status {
        case .connected(let network):
            return formatConnectedNetwork(network, maxLength: maxLength)
        case .disconnected:
            return formatDisconnectedStatus()
        case .connecting(let networkName):
            return formatConnectingStatus(networkName, maxLength: maxLength)
        case .disconnecting:
            return formatDisconnectingStatus()
        case .error:
            return formatErrorStatus()
        case .disabled:
            return formatDisabledStatus()
        case .unknown:
            return formatUnknownStatus()
        }
    }
    
    /// 格式化已连接网络的显示
    private func formatConnectedNetwork(_ network: WiFiNetwork, maxLength: Int) -> String {
        var components: [String] = []
        
        // 添加图标（如果需要）
        if showsIcon {
            components.append("📶")
        }
        
        // 添加网络名称（如果需要）
        if showsNetworkName {
            let networkName = truncateText(network.ssid, maxLength: maxLength - (showsSignalStrength ? 8 : 0))
            components.append(networkName)
        }
        
        // 添加信号强度（如果需要）
        if showsSignalStrength, let strength = network.signalStrength {
            let percentage = network.signalStrengthPercentage
            components.append("(\(percentage)%)")
        }
        
        return components.joined(separator: " ")
    }
    
    /// 格式化未连接状态的显示
    private func formatDisconnectedStatus() -> String {
        if showsIcon && !showsNetworkName {
            return "📶"
        } else if showsIcon {
            return "📶 未连接"
        } else {
            return "未连接"
        }
    }
    
    /// 格式化连接中状态的显示
    private func formatConnectingStatus(_ networkName: String, maxLength: Int) -> String {
        if showsIcon && !showsNetworkName {
            return "🔄"
        } else if showsIcon {
            let name = truncateText(networkName, maxLength: maxLength - 6)
            return "🔄 \(name)"
        } else {
            let name = truncateText(networkName, maxLength: maxLength - 4)
            return "连接 \(name)"
        }
    }
    
    /// 格式化断开中状态的显示
    private func formatDisconnectingStatus() -> String {
        if showsIcon && !showsNetworkName {
            return "⏸"
        } else if showsIcon {
            return "⏸ 断开中"
        } else {
            return "断开中"
        }
    }
    
    /// 格式化错误状态的显示
    private func formatErrorStatus() -> String {
        if showsIcon && !showsNetworkName {
            return "❌"
        } else if showsIcon {
            return "❌ 错误"
        } else {
            return "错误"
        }
    }
    
    /// 格式化WiFi禁用状态的显示
    private func formatDisabledStatus() -> String {
        if showsIcon && !showsNetworkName {
            return "📵"
        } else if showsIcon {
            return "📵 已关闭"
        } else {
            return "WiFi已关闭"
        }
    }
    
    /// 格式化未知状态的显示
    private func formatUnknownStatus() -> String {
        if showsIcon && !showsNetworkName {
            return "❓"
        } else if showsIcon {
            return "❓ 未知"
        } else {
            return "状态未知"
        }
    }
    
    /// 截断文本到指定长度
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        } else {
            let truncated = String(text.prefix(maxLength - 1))
            return truncated + "…"
        }
    }
}

// MARK: - Codable

extension DisplayFormat: Codable {
    // 自动实现Codable，因为是String枚举
}

// MARK: - CustomStringConvertible

extension DisplayFormat: CustomStringConvertible {
    var description: String {
        return displayName
    }
}