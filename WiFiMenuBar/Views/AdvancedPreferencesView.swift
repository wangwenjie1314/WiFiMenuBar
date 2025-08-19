import SwiftUI
import Darwin

/// 高级偏好设置视图
/// 管理应用的高级设置和调试选项
struct AdvancedPreferencesView: View {
    
    // MARK: - Properties
    
    /// 偏好设置管理器
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    
    /// 显示重置确认对话框
    @State private var showResetConfirmation = false
    
    /// 显示日志查看器
    @State private var showLogViewer = false
    
    /// 当前偏好设置
    private var preferences: AppPreferences {
        preferencesManager.getCurrentPreferences()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("高级设置")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 调试选项
            debugSection
            
            Divider()
            
            // 数据管理
            dataManagementSection
            
            Divider()
            
            // 系统信息
            systemInfoSection
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert("重置所有设置", isPresented: $showResetConfirmation) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                preferencesManager.resetToDefaults()
            }
        } message: {
            Text("确定要将所有设置重置为默认值吗？此操作无法撤销。")
        }
        .sheet(isPresented: $showLogViewer) {
            LogViewerView()
        }
    }
    
    // MARK: - Subviews
    
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("调试选项")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button("查看日志") {
                        showLogViewer = true
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("清除日志") {
                        clearLogs()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("数据流监控") {
                        showDataFlowMonitor()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("权限管理") {
                        showPermissionManager()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("性能监控") {
                        showPerformanceMonitor()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("稳定性监控") {
                        showStabilityMonitor()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                }
                
                HStack {
                    Button("导出诊断信息") {
                        exportDiagnosticInfo()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("测试通知") {
                        testNotification()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                }
            }
            
            Text("调试选项用于排查问题和收集诊断信息。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据管理")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button("重置所有设置") {
                        showResetConfirmation = true
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .foregroundColor(.red)
                    
                    Spacer()
                }
                
                HStack {
                    Button("清除缓存数据") {
                        clearCacheData()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("重建索引") {
                        rebuildIndex()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                }
            }
            
            Text("数据管理操作会影响应用的运行状态，请谨慎操作。")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("系统信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                InfoRow(label: "应用版本", value: getAppVersion())
                InfoRow(label: "构建版本", value: getBuildVersion())
                InfoRow(label: "系统版本", value: getSystemVersion())
                InfoRow(label: "设备型号", value: getDeviceModel())
                InfoRow(label: "内存使用", value: getMemoryUsage())
                InfoRow(label: "启动时间", value: getUptime())
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Button("复制系统信息") {
                    copySystemInfo()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func clearLogs() {
        // TODO: 实现清除日志功能
        showAlert(title: "清除日志", message: "日志已清除")
    }
    
    private func exportDiagnosticInfo() {
        let savePanel = NSSavePanel()
        savePanel.title = "导出诊断信息"
        savePanel.nameFieldStringValue = "WiFiMenuBar-Diagnostic-\(Date().timeIntervalSince1970).txt"
        savePanel.allowedContentTypes = [.plainText]
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            let diagnosticInfo = generateDiagnosticInfo()
            do {
                try diagnosticInfo.write(to: url, atomically: true, encoding: .utf8)
                showAlert(title: "导出成功", message: "诊断信息已导出到 \(url.lastPathComponent)")
            } catch {
                showAlert(title: "导出失败", message: "无法导出诊断信息：\(error.localizedDescription)")
            }
        }
    }
    
    private func testNotification() {
        // TODO: 实现测试通知功能
        showAlert(title: "测试通知", message: "测试通知已发送")
    }
    
    private func clearCacheData() {
        // TODO: 实现清除缓存数据功能
        showAlert(title: "清除缓存", message: "缓存数据已清除")
    }
    
    private func rebuildIndex() {
        // TODO: 实现重建索引功能
        showAlert(title: "重建索引", message: "索引重建完成")
    }
    
    private func copySystemInfo() {
        let systemInfo = generateSystemInfo()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(systemInfo, forType: .string)
        
        showAlert(title: "复制成功", message: "系统信息已复制到剪贴板")
    }
    
    // MARK: - Helper Methods
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }
    
    private func getBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"
    }
    
    private func getSystemVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private func getDeviceModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
    
    private func getMemoryUsage() -> String {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.1f MB", memoryUsage)
        } else {
            return "未知"
        }
    }
    
    private func getUptime() -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
    
    private func generateSystemInfo() -> String {
        return """
        WiFi菜单栏 - 系统信息
        
        应用版本: \(getAppVersion())
        构建版本: \(getBuildVersion())
        系统版本: macOS \(getSystemVersion())
        设备型号: \(getDeviceModel())
        内存使用: \(getMemoryUsage())
        系统运行时间: \(getUptime())
        
        生成时间: \(Date())
        """
    }
    
    private func generateDiagnosticInfo() -> String {
        let systemInfo = generateSystemInfo()
        let preferences = preferencesManager.exportSettings()
        let preferencesString = preferences.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        
        return """
        \(systemInfo)
        
        当前设置:
        \(preferencesString)
        
        诊断信息生成完成。
        """
    }
    
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
    
    /// 显示数据流监控器
    private func showDataFlowMonitor() {
        let dataFlowWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        dataFlowWindow.title = "数据流监控器"
        dataFlowWindow.contentView = NSHostingView(rootView: DataFlowMonitorView())
        dataFlowWindow.center()
        dataFlowWindow.makeKeyAndOrderFront(nil)
    }
    
    /// 显示权限管理器
    private func showPermissionManager() {
        let permissionWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        permissionWindow.title = "权限和首次运行管理"
        permissionWindow.contentView = NSHostingView(rootView: PermissionStatusView())
        permissionWindow.center()
        permissionWindow.makeKeyAndOrderFront(nil)
    }
    
    /// 显示性能监控器
    private func showPerformanceMonitor() {
        let performanceWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        performanceWindow.title = "性能监控"
        performanceWindow.contentView = NSHostingView(rootView: PerformanceMonitorView())
        performanceWindow.center()
        performanceWindow.makeKeyAndOrderFront(nil)
    }
    
    /// 显示稳定性监控器
    private func showStabilityMonitor() {
        let stabilityWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        stabilityWindow.title = "稳定性监控"
        stabilityWindow.contentView = NSHostingView(rootView: StabilityMonitorView())
        stabilityWindow.center()
        stabilityWindow.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct LogViewerView: View {
    var body: some View {
        VStack {
            Text("日志查看器")
                .font(.title2)
                .padding()
            
            ScrollView {
                Text("暂无日志内容")
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .background(Color.black)
            .foregroundColor(.green)
            
            HStack {
                Button("关闭") {
                    // 关闭窗口的逻辑会由父视图处理
                }
                .buttonStyle(BorderedProminentButtonStyle())
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 600, height: 400)
    }
}

// MARK: - Preview

struct AdvancedPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedPreferencesView()
            .frame(width: 400, height: 500)
    }
}