import SwiftUI
import UserNotifications

/// 通知偏好设置视图
/// 管理应用的通知设置和权限
struct NotificationPreferencesView: View {
    
    // MARK: - Properties
    
    /// 偏好设置管理器
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    
    /// 通知权限状态
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    /// 当前偏好设置
    private var preferences: AppPreferences {
        preferencesManager.getCurrentPreferences()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("通知设置")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 通知权限状态
            notificationPermissionSection
            
            Divider()
            
            // 通知选项
            notificationOptionsSection
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            checkNotificationPermission()
        }
    }
    
    // MARK: - Subviews
    
    private var notificationPermissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知权限")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: notificationPermissionIcon)
                    .foregroundColor(notificationPermissionColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notificationPermissionTitle)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(notificationPermissionDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if notificationPermissionStatus == .notDetermined || notificationPermissionStatus == .denied {
                    Button("请求权限") {
                        requestNotificationPermission()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var notificationOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知选项")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("启用通知", isOn: Binding(
                    get: { preferences.enableNotifications },
                    set: { preferencesManager.setNotificationsEnabled($0) }
                ))
                .help("启用或禁用所有通知")
                .disabled(notificationPermissionStatus != .authorized)
                
                Group {
                    Toggle("WiFi连接通知", isOn: Binding(
                        get: { preferences.enableNotifications },
                        set: { _ in /* TODO: 实现具体的通知类型设置 */ }
                    ))
                    .help("当连接到新的WiFi网络时显示通知")
                    
                    Toggle("WiFi断开通知", isOn: Binding(
                        get: { preferences.enableNotifications },
                        set: { _ in /* TODO: 实现具体的通知类型设置 */ }
                    ))
                    .help("当WiFi连接断开时显示通知")
                    
                    Toggle("网络切换通知", isOn: Binding(
                        get: { preferences.enableNotifications },
                        set: { _ in /* TODO: 实现具体的通知类型设置 */ }
                    ))
                    .help("当切换到不同的WiFi网络时显示通知")
                    
                    Toggle("信号强度警告", isOn: Binding(
                        get: { preferences.enableNotifications },
                        set: { _ in /* TODO: 实现具体的通知类型设置 */ }
                    ))
                    .help("当WiFi信号强度过低时显示警告")
                }
                .disabled(!preferences.enableNotifications || notificationPermissionStatus != .authorized)
                .padding(.leading, 20)
            }
            
            if notificationPermissionStatus != .authorized {
                Text("需要通知权限才能使用通知功能。请点击上方的"请求权限"按钮或在系统偏好设置中手动启用。")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var notificationPermissionIcon: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .provisional:
            return "clock.circle.fill"
        case .ephemeral:
            return "timer.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private var notificationPermissionColor: Color {
        switch notificationPermissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional:
            return .blue
        case .ephemeral:
            return .blue
        @unknown default:
            return .gray
        }
    }
    
    private var notificationPermissionTitle: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "通知权限已授予"
        case .denied:
            return "通知权限被拒绝"
        case .notDetermined:
            return "通知权限未确定"
        case .provisional:
            return "临时通知权限"
        case .ephemeral:
            return "临时通知权限"
        @unknown default:
            return "未知权限状态"
        }
    }
    
    private var notificationPermissionDescription: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "应用可以发送通知"
        case .denied:
            return "请在系统偏好设置中启用通知权限"
        case .notDetermined:
            return "需要请求通知权限"
        case .provisional:
            return "可以发送静默通知"
        case .ephemeral:
            return "临时通知权限"
        @unknown default:
            return "无法确定权限状态"
        }
    }
    
    // MARK: - Methods
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationPermissionStatus = .authorized
                } else {
                    self.notificationPermissionStatus = .denied
                }
                
                if let error = error {
                    print("通知权限请求失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreferencesView()
            .frame(width: 400, height: 500)
    }
}