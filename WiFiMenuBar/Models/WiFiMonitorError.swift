import Foundation

/// WiFi监控过程中可能出现的错误类型
enum WiFiMonitorError: Error {
    /// 权限被拒绝，无法访问WiFi信息
    case permissionDenied
    
    /// 网络服务不可用
    case networkUnavailable
    
    /// WiFi硬件错误或不可用
    case hardwareError
    
    /// CoreWLAN框架相关错误
    case coreWLANError(Int) // 错误代码
    
    /// 网络框架相关错误
    case networkFrameworkError(Error)
    
    /// 获取WiFi信息超时
    case timeout
    
    /// 无效的网络配置
    case invalidConfiguration
    
    /// 系统版本不支持
    case unsupportedSystem
    
    /// 未知错误
    case unknownError(String)
}

// MARK: - LocalizedError

extension WiFiMonitorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "需要网络访问权限"
            
        case .networkUnavailable:
            return "网络服务不可用"
            
        case .hardwareError:
            return "WiFi硬件错误"
            
        case .coreWLANError(let code):
            return "CoreWLAN错误 (代码: \(code))"
            
        case .networkFrameworkError(let error):
            return "网络框架错误: \(error.localizedDescription)"
            
        case .timeout:
            return "获取WiFi信息超时"
            
        case .invalidConfiguration:
            return "无效的网络配置"
            
        case .unsupportedSystem:
            return "系统版本不支持此功能"
            
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .permissionDenied:
            return "应用没有获得访问网络信息的权限"
            
        case .networkUnavailable:
            return "系统网络服务当前不可用或已关闭"
            
        case .hardwareError:
            return "WiFi硬件可能已损坏或被禁用"
            
        case .coreWLANError:
            return "CoreWLAN框架内部发生错误"
            
        case .networkFrameworkError:
            return "Network框架调用失败"
            
        case .timeout:
            return "网络信息获取操作超时"
            
        case .invalidConfiguration:
            return "网络配置参数无效或不完整"
            
        case .unsupportedSystem:
            return "当前macOS版本不支持所需的网络API"
            
        case .unknownError:
            return "发生了未预期的错误"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "请在系统偏好设置 > 安全性与隐私 > 隐私 > 网络中允许此应用访问网络信息"
            
        case .networkUnavailable:
            return "请检查网络设置，确保WiFi功能已启用"
            
        case .hardwareError:
            return "请尝试重启WiFi或重启系统，如问题持续请联系技术支持"
            
        case .coreWLANError:
            return "请尝试重启应用，如问题持续请重启系统"
            
        case .networkFrameworkError:
            return "请检查网络连接状态，必要时重启网络服务"
            
        case .timeout:
            return "请稍后重试，或检查网络连接是否稳定"
            
        case .invalidConfiguration:
            return "请检查网络配置设置，确保所有参数正确"
            
        case .unsupportedSystem:
            return "请升级到macOS 10.15或更高版本"
            
        case .unknownError:
            return "请尝试重启应用，如问题持续请联系技术支持"
        }
    }
}

// MARK: - CustomNSError

extension WiFiMonitorError: CustomNSError {
    static var errorDomain: String {
        return "com.wifimenubar.WiFiMonitorError"
    }
    
    var errorCode: Int {
        switch self {
        case .permissionDenied:
            return 1001
        case .networkUnavailable:
            return 1002
        case .hardwareError:
            return 1003
        case .coreWLANError(let code):
            return 2000 + code
        case .networkFrameworkError:
            return 3001
        case .timeout:
            return 4001
        case .invalidConfiguration:
            return 5001
        case .unsupportedSystem:
            return 6001
        case .unknownError:
            return 9999
        }
    }
    
    var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [:]
        
        if let description = errorDescription {
            userInfo[NSLocalizedDescriptionKey] = description
        }
        
        if let failureReason = failureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        }
        
        if let recoverySuggestion = recoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
        }
        
        return userInfo
    }
}

// MARK: - Convenience Methods

extension WiFiMonitorError {
    /// 判断错误是否可以重试
    var isRetryable: Bool {
        switch self {
        case .permissionDenied, .hardwareError, .unsupportedSystem, .invalidConfiguration:
            return false
        case .networkUnavailable, .timeout, .coreWLANError, .networkFrameworkError, .unknownError:
            return true
        }
    }
    
    /// 判断错误是否需要用户干预
    var requiresUserIntervention: Bool {
        switch self {
        case .permissionDenied, .hardwareError, .unsupportedSystem:
            return true
        case .networkUnavailable, .coreWLANError, .networkFrameworkError, .timeout, .invalidConfiguration, .unknownError:
            return false
        }
    }
    
    /// 获取错误的严重程度
    var severity: ErrorSeverity {
        switch self {
        case .permissionDenied, .unsupportedSystem:
            return .critical
        case .hardwareError, .networkUnavailable:
            return .high
        case .coreWLANError, .networkFrameworkError, .invalidConfiguration:
            return .medium
        case .timeout, .unknownError:
            return .low
        }
    }
}

/// 错误严重程度
enum ErrorSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low:
            return "轻微"
        case .medium:
            return "中等"
        case .high:
            return "严重"
        case .critical:
            return "致命"
        }
    }
}