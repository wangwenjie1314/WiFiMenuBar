import SwiftUI

/// 偏好设置主视图
/// 使用SwiftUI构建的现代化设置界面
struct PreferencesView: View {
    
    // MARK: - Properties
    
    /// 偏好设置管理器
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    
    /// 当前选中的标签页
    @State private var selectedTab: PreferencesTab = .display
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签页选择器
            tabSelector
            
            Divider()
            
            // 内容区域
            TabView(selection: $selectedTab) {
                DisplayPreferencesView()
                    .tabItem {
                        Image(systemName: "display")
                        Text("显示")
                    }
                    .tag(PreferencesTab.display)
                
                BehaviorPreferencesView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("行为")
                    }
                    .tag(PreferencesTab.behavior)
                
                NotificationPreferencesView()
                    .tabItem {
                        Image(systemName: "bell")
                        Text("通知")
                    }
                    .tag(PreferencesTab.notifications)
                
                AdvancedPreferencesView()
                    .tabItem {
                        Image(systemName: "wrench.and.screwdriver")
                        Text("高级")
                    }
                    .tag(PreferencesTab.advanced)
            }
            .tabViewStyle(DefaultTabViewStyle())
            
            Divider()
            
            // 底部按钮区域
            bottomButtons
        }
        .frame(minWidth: 450, minHeight: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Subviews
    
    private var tabSelector: some View {
        HStack {
            Text("WiFi菜单栏偏好设置")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("重置为默认") {
                resetToDefaults()
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var bottomButtons: some View {
        HStack {
            Button("导出设置") {
                exportSettings()
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button("导入设置") {
                importSettings()
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            Button("关闭") {
                closeWindow()
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .keyboardShortcut(.cancelAction)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "重置设置"
        alert.informativeText = "确定要将所有设置重置为默认值吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            preferencesManager.resetToDefaults()
        }
    }
    
    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.title = "导出设置"
        savePanel.nameFieldStringValue = "WiFiMenuBar-Settings.json"
        savePanel.allowedContentTypes = [.json]
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                let settings = preferencesManager.exportSettings()
                let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                try data.write(to: url)
                
                showAlert(title: "导出成功", message: "设置已成功导出到 \(url.lastPathComponent)")
            } catch {
                showAlert(title: "导出失败", message: "无法导出设置：\(error.localizedDescription)")
            }
        }
    }
    
    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.title = "导入设置"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        let response = openPanel.runModal()
        if response == .OK, let url = openPanel.urls.first {
            do {
                let data = try Data(contentsOf: url)
                let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                
                let success = preferencesManager.importSettings(from: settings)
                if success {
                    showAlert(title: "导入成功", message: "设置已成功从 \(url.lastPathComponent) 导入")
                } else {
                    showAlert(title: "导入失败", message: "设置文件格式无效或包含无效数据")
                }
            } catch {
                showAlert(title: "导入失败", message: "无法读取设置文件：\(error.localizedDescription)")
            }
        }
    }
    
    private func closeWindow() {
        if let window = NSApp.keyWindow {
            window.close()
        }
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
}

// MARK: - Supporting Types

/// 偏好设置标签页枚举
enum PreferencesTab: String, CaseIterable {
    case display = "display"
    case behavior = "behavior"
    case notifications = "notifications"
    case advanced = "advanced"
    
    var title: String {
        switch self {
        case .display: return "显示"
        case .behavior: return "行为"
        case .notifications: return "通知"
        case .advanced: return "高级"
        }
    }
    
    var icon: String {
        switch self {
        case .display: return "display"
        case .behavior: return "gear"
        case .notifications: return "bell"
        case .advanced: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Preview

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .frame(width: 500, height: 400)
    }
}