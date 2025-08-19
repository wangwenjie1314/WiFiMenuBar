import SwiftUI

/// 行为偏好设置视图
/// 管理应用的启动、更新和运行行为设置
struct BehaviorPreferencesView: View {
    
    // MARK: - Properties
    
    /// 偏好设置管理器
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    
    /// 登录启动状态
    @State private var launchAtLoginStatus: LaunchAtLoginStatus?
    
    /// 当前偏好设置
    private var preferences: AppPreferences {
        preferencesManager.getCurrentPreferences()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("行为设置")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 启动设置
            startupSection
            
            Divider()
            
            // 更新设置
            updateSection
            
            Divider()
            
            // 刷新设置
            refreshSection
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            refreshLaunchAtLoginStatus()
        }
    }
    
    // MARK: - Subviews
    
    private var startupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("启动设置")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("开机自动启动", isOn: Binding(
                    get: { preferences.autoStart },
                    set: { preferencesManager.setAutoStart($0) }
                ))
                .help("系统启动时自动启动WiFi菜单栏应用")
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("登录时启动", isOn: Binding(
                        get: { preferences.launchAtLogin },
                        set: { enabled in
                            preferencesManager.setLaunchAtLogin(enabled)
                            refreshLaunchAtLoginStatus()
                        }
                    ))
                    .help("用户登录时自动启动应用")
                    
                    if let status = launchAtLoginStatus {
                        HStack {
                            Image(systemName: status.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(status.isEnabled ? .green : .red)
                                .font(.caption)
                            
                            Text(status.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !status.canModify {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .help("权限不足，可能需要管理员权限")
                            }
                            
                            Spacer()
                            
                            Button("刷新状态") {
                                refreshLaunchAtLoginStatus()
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .font(.caption)
                        }
                    }
                }
                
                Toggle("最小化到托盘", isOn: Binding(
                    get: { preferences.minimizeToTray },
                    set: { enabled in
                        var newPreferences = preferences
                        newPreferences.minimizeToTray = enabled
                        preferencesManager.updatePreferences(newPreferences)
                    }
                ))
                .help("关闭窗口时最小化到系统托盘而不是退出应用")
            }
            
            Text("注意：开机自动启动需要系统权限，首次启用时可能需要在系统偏好设置中确认。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("更新设置")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("自动检查更新", isOn: Binding(
                    get: { preferences.checkForUpdates },
                    set: { enabled in
                        var newPreferences = preferences
                        newPreferences.checkForUpdates = enabled
                        preferencesManager.updatePreferences(newPreferences)
                    }
                ))
                .help("定期检查应用更新")
                
                HStack {
                    Button("立即检查更新") {
                        checkForUpdatesNow()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .disabled(!preferences.checkForUpdates)
                    
                    Spacer()
                }
            }
            
            Text("应用会在后台定期检查更新，发现新版本时会通知您。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    private var refreshSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("刷新设置")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("设置WiFi状态的检查频率")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("刷新间隔:")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", preferences.refreshInterval))秒")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { preferences.refreshInterval },
                        set: { preferencesManager.setRefreshInterval($0) }
                    ),
                    in: 1.0...60.0,
                    step: 0.5
                ) {
                    Text("刷新间隔")
                } minimumValueLabel: {
                    Text("1s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("60s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 刷新间隔说明
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(refreshIntervalDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var refreshIntervalDescription: String {
        let interval = preferences.refreshInterval
        
        if interval <= 2.0 {
            return "高频率刷新，实时性好但可能增加系统负担"
        } else if interval <= 10.0 {
            return "平衡的刷新频率，推荐设置"
        } else {
            return "低频率刷新，节省系统资源但可能延迟更新"
        }
    }
    
    // MARK: - Actions
    
    private func checkForUpdatesNow() {
        // TODO: 实现立即检查更新功能
        let alert = NSAlert()
        alert.messageText = "检查更新"
        alert.informativeText = "当前版本已是最新版本。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    /// 刷新登录启动状态
    private func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = LaunchAtLoginManager.shared.getLaunchAtLoginStatus()
        
        // 同步偏好设置状态
        preferencesManager.syncLaunchAtLoginStatus()
    }
}

// MARK: - Preview

struct BehaviorPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        BehaviorPreferencesView()
            .frame(width: 400, height: 500)
    }
}