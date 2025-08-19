import Foundation
import ServiceManagement

/// 登录启动管理器
/// 负责管理应用的开机自启动和登录启动功能
class LaunchAtLoginManager {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = LaunchAtLoginManager()
    
    // MARK: - Properties
    
    /// 登录项标识符
    private let loginItemIdentifier = "com.wifimenubar.LaunchHelper"
    
    /// 应用Bundle标识符
    private var appBundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.wifimenubar.WiFiMenuBar"
    }
    
    // MARK: - Initialization
    
    private init() {
        print("LaunchAtLoginManager: 初始化登录启动管理器")
    }
    
    // MARK: - Public Methods
    
    /// 检查是否启用了登录启动
    /// - Returns: 是否启用登录启动
    func isLaunchAtLoginEnabled() -> Bool {
        // 方法1: 使用SMCopyAllJobDictionaries (已弃用但仍可用)
        if let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]] {
            for job in jobs {
                if let label = job["Label"] as? String,
                   label == appBundleIdentifier || label == loginItemIdentifier {
                    return job["OnDemand"] as? Bool ?? false
                }
            }
        }
        
        // 方法2: 检查登录项目录
        return checkLoginItemsDirectory()
    }
    
    /// 设置登录启动状态
    /// - Parameter enabled: 是否启用登录启动
    /// - Returns: 操作是否成功
    @discardableResult
    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        print("LaunchAtLoginManager: 设置登录启动为 \(enabled)")
        
        if enabled {
            return enableLaunchAtLogin()
        } else {
            return disableLaunchAtLogin()
        }
    }
    
    /// 获取登录启动状态的详细信息
    /// - Returns: 登录启动状态信息
    func getLaunchAtLoginStatus() -> LaunchAtLoginStatus {
        let isEnabled = isLaunchAtLoginEnabled()
        let method = detectRegistrationMethod()
        let canModify = checkModificationPermission()
        
        return LaunchAtLoginStatus(
            isEnabled: isEnabled,
            registrationMethod: method,
            canModify: canModify,
            lastError: nil
        )
    }
    
    /// 强制刷新登录启动状态
    func refreshStatus() {
        print("LaunchAtLoginManager: 刷新登录启动状态")
        // 重新检查状态并通知相关组件
        let status = getLaunchAtLoginStatus()
        print("LaunchAtLoginManager: 当前状态 - 启用: \(status.isEnabled), 方法: \(status.registrationMethod)")
    }
    
    // MARK: - Private Methods
    
    /// 启用登录启动
    /// - Returns: 操作是否成功
    private func enableLaunchAtLogin() -> Bool {
        // 方法1: 尝试使用SMLoginItemSetEnabled (推荐方法)
        if SMLoginItemSetEnabled(loginItemIdentifier as CFString, true) {
            print("LaunchAtLoginManager: 使用SMLoginItemSetEnabled成功启用登录启动")
            return true
        }
        
        // 方法2: 尝试使用LSSharedFileList (备用方法)
        if enableLaunchAtLoginUsingLSSharedFileList() {
            print("LaunchAtLoginManager: 使用LSSharedFileList成功启用登录启动")
            return true
        }
        
        // 方法3: 创建登录项plist文件 (最后的备用方法)
        if createLoginItemPlist() {
            print("LaunchAtLoginManager: 使用plist文件成功启用登录启动")
            return true
        }
        
        print("LaunchAtLoginManager: 启用登录启动失败")
        return false
    }
    
    /// 禁用登录启动
    /// - Returns: 操作是否成功
    private func disableLaunchAtLogin() -> Bool {
        var success = false
        
        // 方法1: 使用SMLoginItemSetEnabled
        if SMLoginItemSetEnabled(loginItemIdentifier as CFString, false) {
            print("LaunchAtLoginManager: 使用SMLoginItemSetEnabled成功禁用登录启动")
            success = true
        }
        
        // 方法2: 使用LSSharedFileList清理
        if disableLaunchAtLoginUsingLSSharedFileList() {
            print("LaunchAtLoginManager: 使用LSSharedFileList成功禁用登录启动")
            success = true
        }
        
        // 方法3: 删除plist文件
        if removeLoginItemPlist() {
            print("LaunchAtLoginManager: 删除plist文件成功")
            success = true
        }
        
        return success
    }
    
    /// 使用LSSharedFileList启用登录启动
    /// - Returns: 操作是否成功
    private func enableLaunchAtLoginUsingLSSharedFileList() -> Bool {
        guard let appURL = Bundle.main.bundleURL else {
            print("LaunchAtLoginManager: 无法获取应用Bundle URL")
            return false
        }
        
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil)
        if let loginItems = loginItems?.takeRetainedValue() {
            let loginItemRef = LSSharedFileListInsertItemURL(
                loginItems,
                kLSSharedFileListItemBeforeFirst,
                nil,
                nil,
                appURL as CFURL,
                nil,
                nil
            )
            
            if loginItemRef != nil {
                return true
            }
        }
        
        return false
    }
    
    /// 使用LSSharedFileList禁用登录启动
    /// - Returns: 操作是否成功
    private func disableLaunchAtLoginUsingLSSharedFileList() -> Bool {
        guard let appURL = Bundle.main.bundleURL else { return false }
        
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil)
        if let loginItems = loginItems?.takeRetainedValue() {
            let loginItemsArray = LSSharedFileListCopySnapshot(loginItems, nil)
            if let loginItemsArray = loginItemsArray?.takeRetainedValue() as? [LSSharedFileListItem] {
                for item in loginItemsArray {
                    var itemURL: Unmanaged<CFURL>?
                    let result = LSSharedFileListItemResolve(item, 0, &itemURL, nil)
                    
                    if result == noErr, let itemURL = itemURL?.takeRetainedValue() as URL? {
                        if itemURL == appURL {
                            LSSharedFileListItemRemove(loginItems, item)
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    /// 创建登录项plist文件
    /// - Returns: 操作是否成功
    private func createLoginItemPlist() -> Bool {
        guard let homeDirectory = NSHomeDirectory() as NSString? else { return false }
        
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        let plistPath = (launchAgentsPath as NSString).appendingPathComponent("\(loginItemIdentifier).plist")
        
        // 确保目录存在
        do {
            try FileManager.default.createDirectory(atPath: launchAgentsPath, 
                                                  withIntermediateDirectories: true, 
                                                  attributes: nil)
        } catch {
            print("LaunchAtLoginManager: 创建LaunchAgents目录失败: \(error)")
            return false
        }
        
        // 创建plist内容
        let plistContent: [String: Any] = [
            "Label": loginItemIdentifier,
            "ProgramArguments": [Bundle.main.executablePath ?? ""],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        
        // 写入plist文件
        do {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: plistContent,
                format: .xml,
                options: 0
            )
            try plistData.write(to: URL(fileURLWithPath: plistPath))
            
            // 加载plist到launchd
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["load", plistPath]
            task.launch()
            task.waitUntilExit()
            
            return task.terminationStatus == 0
        } catch {
            print("LaunchAtLoginManager: 创建plist文件失败: \(error)")
            return false
        }
    }
    
    /// 删除登录项plist文件
    /// - Returns: 操作是否成功
    private func removeLoginItemPlist() -> Bool {
        guard let homeDirectory = NSHomeDirectory() as NSString? else { return false }
        
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        let plistPath = (launchAgentsPath as NSString).appendingPathComponent("\(loginItemIdentifier).plist")
        
        // 先从launchd卸载
        let unloadTask = Process()
        unloadTask.launchPath = "/bin/launchctl"
        unloadTask.arguments = ["unload", plistPath]
        unloadTask.launch()
        unloadTask.waitUntilExit()
        
        // 删除plist文件
        do {
            try FileManager.default.removeItem(atPath: plistPath)
            return true
        } catch {
            print("LaunchAtLoginManager: 删除plist文件失败: \(error)")
            return false
        }
    }
    
    /// 检查登录项目录
    /// - Returns: 是否在登录项中
    private func checkLoginItemsDirectory() -> Bool {
        guard let appURL = Bundle.main.bundleURL else { return false }
        
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil)
        if let loginItems = loginItems?.takeRetainedValue() {
            let loginItemsArray = LSSharedFileListCopySnapshot(loginItems, nil)
            if let loginItemsArray = loginItemsArray?.takeRetainedValue() as? [LSSharedFileListItem] {
                for item in loginItemsArray {
                    var itemURL: Unmanaged<CFURL>?
                    let result = LSSharedFileListItemResolve(item, 0, &itemURL, nil)
                    
                    if result == noErr, let itemURL = itemURL?.takeRetainedValue() as URL? {
                        if itemURL == appURL {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    /// 检测注册方法
    /// - Returns: 使用的注册方法
    private func detectRegistrationMethod() -> LaunchAtLoginRegistrationMethod {
        // 检查SMLoginItem
        if let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]] {
            for job in jobs {
                if let label = job["Label"] as? String,
                   label == appBundleIdentifier || label == loginItemIdentifier {
                    return .serviceManagement
                }
            }
        }
        
        // 检查LSSharedFileList
        if checkLoginItemsDirectory() {
            return .sharedFileList
        }
        
        // 检查plist文件
        guard let homeDirectory = NSHomeDirectory() as NSString? else { return .none }
        let plistPath = homeDirectory.appendingPathComponent("Library/LaunchAgents/\(loginItemIdentifier).plist")
        if FileManager.default.fileExists(atPath: plistPath) {
            return .launchAgent
        }
        
        return .none
    }
    
    /// 检查修改权限
    /// - Returns: 是否有修改权限
    private func checkModificationPermission() -> Bool {
        // 检查是否有写入权限
        guard let homeDirectory = NSHomeDirectory() as NSString? else { return false }
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        
        return FileManager.default.isWritableFile(atPath: launchAgentsPath)
    }
}

// MARK: - Supporting Types

/// 登录启动状态信息
struct LaunchAtLoginStatus {
    /// 是否启用
    let isEnabled: Bool
    
    /// 注册方法
    let registrationMethod: LaunchAtLoginRegistrationMethod
    
    /// 是否可以修改
    let canModify: Bool
    
    /// 最后的错误
    let lastError: Error?
    
    /// 状态描述
    var description: String {
        if isEnabled {
            return "已启用 (使用\(registrationMethod.description))"
        } else {
            return "未启用"
        }
    }
}

/// 登录启动注册方法
enum LaunchAtLoginRegistrationMethod {
    case serviceManagement  // 使用ServiceManagement框架
    case sharedFileList    // 使用LSSharedFileList
    case launchAgent       // 使用LaunchAgent plist
    case none              // 未注册
    
    var description: String {
        switch self {
        case .serviceManagement:
            return "ServiceManagement"
        case .sharedFileList:
            return "SharedFileList"
        case .launchAgent:
            return "LaunchAgent"
        case .none:
            return "无"
        }
    }
}

/// 登录启动错误类型
enum LaunchAtLoginError: Error, LocalizedError {
    case permissionDenied
    case serviceUnavailable
    case invalidConfiguration
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "权限被拒绝，无法修改登录项"
        case .serviceUnavailable:
            return "系统服务不可用"
        case .invalidConfiguration:
            return "配置无效"
        case .systemError(let message):
            return "系统错误: \(message)"
        }
    }
}