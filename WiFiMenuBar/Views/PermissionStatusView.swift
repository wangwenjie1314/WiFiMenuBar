import SwiftUI

/// 权限状态视图
/// 显示应用各种权限的状态和管理界面
struct PermissionStatusView: View {
    
    // MARK: - Properties
    
    /// 权限管理器
    @ObservedObject private var permissionManager = PermissionManager.shared
    
    /// 首次运行管理器
    private let firstRunManager = FirstRunManager.shared
    
    /// 是否显示详细信息
    @State private var showDetails = false
    
    /// 是否显示首次运行信息
    @State private var showFirstRunInfo = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("权限和首次运行管理")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 权限状态概览
            permissionOverviewSection
            
            Divider()
            
            // 详细权限状态
            if showDetails {
                detailedPermissionSection
                
                Divider()
            }
            
            // 首次运行信息
            firstRunSection
            
            Divider()
            
            // 操作按钮
            actionButtonsSection
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
    
    // MARK: - Subviews
    
    private var permissionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("权限状态概览")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: permissionManager.areAllRequiredPermissionsGranted() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(permissionManager.areAllRequiredPermissionsGranted() ? .green : .orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(permissionManager.areAllRequiredPermissionsGranted() ? "所有必需权限已授予" : "部分权限需要授予")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(permissionStatusSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(showDetails ? "隐藏详情" : "显示详情") {
                    showDetails.toggle()
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var detailedPermissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细权限状态")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                PermissionRow(
                    type: .notification,
                    status: permissionManager.notificationPermissionStatus,
                    isRequired: true
                ) {
                    requestPermission(.notification)
                }
                
                PermissionRow(
                    type: .network,
                    status: permissionManager.networkPermissionStatus,
                    isRequired: true
                ) {
                    requestPermission(.network)
                }
                
                PermissionRow(
                    type: .wifi,
                    status: permissionManager.wifiPermissionStatus,
                    isRequired: true
                ) {
                    requestPermission(.wifi)
                }
                
                PermissionRow(
                    type: .location,
                    status: permissionManager.locationPermissionStatus,
                    isRequired: false
                ) {
                    requestPermission(.location)
                }
            }
        }
    }
    
    private var firstRunSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("首次运行信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(firstRunStatusText)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(firstRunDetailsText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(showFirstRunInfo ? "隐藏详情" : "显示详情") {
                    showFirstRunInfo.toggle()
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            if showFirstRunInfo {
                FirstRunInfoView()
                    .padding(.top, 8)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("操作")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Button("刷新权限状态") {
                    refreshPermissions()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button("请求所有权限") {
                    requestAllPermissions()
                }
                .buttonStyle(BorderedButtonStyle())
                .disabled(permissionManager.areAllRequiredPermissionsGranted())
                
                Button("重新运行首次设置") {
                    rerunFirstTimeSetup()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
            }
            
            HStack {
                Button("打开系统偏好设置") {
                    openSystemPreferences()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button("重置首次运行状态") {
                    resetFirstRunStatus()
                }
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.red)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var permissionStatusSummary: String {
        let missingPermissions = permissionManager.getMissingPermissions()
        if missingPermissions.isEmpty {
            return "应用具有所有必需的权限"
        } else {
            let missingNames = missingPermissions.map { $0.displayName }.joined(separator: "、")
            return "缺少权限：\(missingNames)"
        }
    }
    
    private var firstRunStatusText: String {
        let info = firstRunManager.getFirstRunInfo()
        if info.isFirstRun {
            return "这是首次运行"
        } else if info.isFirstRunAfterUpdate {
            return "版本更新后首次运行"
        } else {
            return "正常运行状态"
        }
    }
    
    private var firstRunDetailsText: String {
        let info = firstRunManager.getFirstRunInfo()
        return "当前版本：\(info.currentVersion)，首次运行已完成：\(info.firstRunCompleted ? "是" : "否")"
    }
    
    // MARK: - Actions
    
    private func requestPermission(_ type: PermissionType) {
        permissionManager.showPermissionRequestDialog(for: type) { granted in
            if granted {
                print("PermissionStatusView: \(type.displayName)权限已授予")
            } else {
                print("PermissionStatusView: \(type.displayName)权限被拒绝")
            }
        }
    }
    
    private func refreshPermissions() {
        permissionManager.checkAllPermissions()
    }
    
    private func requestAllPermissions() {
        permissionManager.requestAllRequiredPermissions { allGranted in
            DispatchQueue.main.async {
                let message = allGranted ? "所有权限已授予" : "部分权限未授予，请在系统偏好设置中手动授予"
                showAlert(title: "权限请求结果", message: message)
            }
        }
    }
    
    private func rerunFirstTimeSetup() {
        firstRunManager.showQuickSetupWizard { completed in
            DispatchQueue.main.async {
                let message = completed ? "首次设置已完成" : "首次设置被取消"
                showAlert(title: "首次设置", message: message)
            }
        }
    }
    
    private func openSystemPreferences() {
        permissionManager.openSystemPreferencesForPermission(.notification)
    }
    
    private func resetFirstRunStatus() {
        let alert = NSAlert()
        alert.messageText = "重置首次运行状态"
        alert.informativeText = "确定要重置首次运行状态吗？这将使应用在下次启动时重新显示首次运行流程。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            firstRunManager.resetFirstRunStatus()
            showAlert(title: "重置完成", message: "首次运行状态已重置，下次启动时将显示首次运行流程。")
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

// MARK: - Supporting Views

struct PermissionRow: View {
    let type: PermissionType
    let status: PermissionStatus
    let isRequired: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(type.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if isRequired {
                        Text("(必需)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if status != .granted && status != .notRequired {
                Button("请求权限") {
                    onRequest()
                }
                .buttonStyle(BorderlessButtonStyle())
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FirstRunInfoView: View {
    private let firstRunManager = FirstRunManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let info = firstRunManager.getFirstRunInfo()
            
            InfoRow(label: "是否首次运行", value: info.isFirstRun ? "是" : "否")
            InfoRow(label: "版本更新后首次运行", value: info.isFirstRunAfterUpdate ? "是" : "否")
            InfoRow(label: "当前版本", value: info.currentVersion)
            InfoRow(label: "构建版本", value: info.currentBuildVersion)
            InfoRow(label: "上次版本", value: info.lastVersion ?? "无")
            InfoRow(label: "首次运行已完成", value: info.firstRunCompleted ? "是" : "否")
            
            if let installationDate = info.installationDate {
                InfoRow(label: "安装日期", value: DateFormatter.localizedString(from: installationDate, dateStyle: .medium, timeStyle: .short))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct PermissionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionStatusView()
            .frame(width: 500, height: 600)
    }
}