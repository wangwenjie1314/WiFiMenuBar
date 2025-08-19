import SwiftUI

/// 稳定性监控视图
/// 显示应用的稳定性状态和崩溃恢复信息
struct StabilityMonitorView: View {
    
    // MARK: - Properties
    
    /// 稳定性管理器
    @ObservedObject private var stabilityManager = StabilityManager.shared
    
    /// 是否显示详细信息
    @State private var showDetails = false
    
    /// 是否显示崩溃历史
    @State private var showCrashHistory = false
    
    /// 是否显示异常历史
    @State private var showExceptionHistory = false
    
    /// 稳定性报告
    @State private var stabilityReport: StabilityReport?
    
    /// 自动刷新定时器
    @State private var refreshTimer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 健康状态概览
                    healthStatusSection
                    
                    Divider()
                    
                    // 崩溃恢复状态
                    crashRecoverySection
                    
                    Divider()
                    
                    // 稳定性报告
                    if let report = stabilityReport {
                        stabilityReportSection(report)
                        
                        Divider()
                    }
                    
                    // 历史记录
                    if showCrashHistory || showExceptionHistory {
                        historySection
                        
                        Divider()
                    }
                    
                    // 详细信息
                    if showDetails {
                        detailedInfoSection
                        
                        Divider()
                    }
                    
                    // 恢复控制
                    recoveryControlSection
                }
                .padding()
            }
            
            Divider()
            
            // 底部控制栏
            controlBar
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            startAutoRefresh()
            refreshStabilityReport()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Subviews
    
    private var titleBar: some View {
        HStack {
            Text("稳定性监控")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("监控应用稳定性和崩溃恢复状态")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var healthStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("健康状态")
                .font(.headline)
            
            HStack(spacing: 30) {
                // 健康状态指示器
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(stabilityManager.healthStatus.color)
                            .frame(width: 16, height: 16)
                        
                        Text("整体健康")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(stabilityManager.healthStatus.description)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stabilityManager.healthStatus.color)
                    
                    Text(healthStatusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 稳定性分数
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                        Text("稳定性分数")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("\(String(format: "%.0f", stabilityReport?.stabilityScore ?? 0))/100")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stabilityScoreColor)
                    
                    ProgressView(value: (stabilityReport?.stabilityScore ?? 0) / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: stabilityScoreColor))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var crashRecoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("崩溃恢复状态")
                .font(.headline)
            
            HStack {
                Image(systemName: crashRecoveryIcon)
                    .foregroundColor(crashRecoveryColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stabilityManager.crashRecoveryStatus.description)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(crashRecoveryDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if stabilityManager.crashRecoveryStatus == .needsRecovery {
                    Button("执行恢复") {
                        stabilityManager.performApplicationRecovery()
                        refreshStabilityReport()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private func stabilityReportSection(_ report: StabilityReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("稳定性报告")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("运行时间:")
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.0f", report.uptime)) 秒")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("崩溃次数:")
                        .foregroundColor(.secondary)
                    Text("\(report.crashCount)")
                        .fontWeight(.medium)
                        .foregroundColor(report.crashCount > 0 ? .red : .primary)
                }
                
                GridRow {
                    Text("异常次数:")
                        .foregroundColor(.secondary)
                    Text("\(report.exceptionCount)")
                        .fontWeight(.medium)
                        .foregroundColor(report.exceptionCount > 0 ? .orange : .primary)
                }
                
                GridRow {
                    Text("连续检查失败:")
                        .foregroundColor(.secondary)
                    Text("\(report.consecutiveHealthCheckFailures)")
                        .fontWeight(.medium)
                        .foregroundColor(report.consecutiveHealthCheckFailures > 0 ? .red : .primary)
                }
                
                if let lastCrashTime = report.lastCrashTime {
                    GridRow {
                        Text("最后崩溃:")
                            .foregroundColor(.secondary)
                        Text(lastCrashTime, style: .relative)
                            .fontWeight(.medium)
                    }
                }
                
                if let lastExceptionTime = report.lastExceptionTime {
                    GridRow {
                        Text("最后异常:")
                            .foregroundColor(.secondary)
                        Text(lastExceptionTime, style: .relative)
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.caption)
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)
            
            if showCrashHistory {
                VStack(alignment: .leading, spacing: 8) {
                    Text("崩溃历史")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let crashHistory = stabilityManager.getCrashHistory()
                    if crashHistory.isEmpty {
                        Text("无崩溃记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(crashHistory.suffix(5).enumerated()), id: \.offset) { index, crash in
                            CrashHistoryRow(crash: crash, index: index + 1)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            if showExceptionHistory {
                VStack(alignment: .leading, spacing: 8) {
                    Text("异常历史")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let exceptionHistory = stabilityManager.getExceptionHistory()
                    if exceptionHistory.isEmpty {
                        Text("无异常记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(exceptionHistory.suffix(5).enumerated()), id: \.offset) { index, exception in
                            ExceptionHistoryRow(exception: exception, index: index + 1)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var detailedInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                let healthResult = stabilityManager.performHealthCheck()
                
                InfoRow(label: "健康检查时间", value: healthResult.checkTime.formatted(date: .omitted, time: .standard))
                InfoRow(label: "健康组件数", value: "\(healthResult.healthyComponents.count)")
                InfoRow(label: "警告数量", value: "\(healthResult.warnings.count)")
                InfoRow(label: "严重问题数量", value: "\(healthResult.criticalIssues.count)")
                
                if !healthResult.healthyComponents.isEmpty {
                    InfoRow(label: "健康组件", value: healthResult.healthyComponents.joined(separator: ", "))
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var recoveryControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("恢复控制")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle("启用稳定性监控", isOn: $stabilityManager.isStabilityMonitoringEnabled)
                        .onChange(of: stabilityManager.isStabilityMonitoringEnabled) { enabled in
                            if enabled {
                                stabilityManager.startStabilityMonitoring()
                            } else {
                                stabilityManager.stopStabilityMonitoring()
                            }
                        }
                    
                    Spacer()
                }
                
                HStack {
                    Button("执行健康检查") {
                        _ = stabilityManager.performHealthCheck()
                        refreshStabilityReport()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("执行应用恢复") {
                        stabilityManager.performApplicationRecovery()
                        refreshStabilityReport()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("清除历史记录") {
                        stabilityManager.clearHistory()
                        refreshStabilityReport()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var controlBar: some View {
        HStack {
            Toggle("显示详细信息", isOn: $showDetails)
            
            Toggle("显示崩溃历史", isOn: $showCrashHistory)
            
            Toggle("显示异常历史", isOn: $showExceptionHistory)
            
            Spacer()
            
            Button("导出数据") {
                exportStabilityData()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("刷新") {
                refreshStabilityReport()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("关闭") {
                closeWindow()
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var healthStatusDescription: String {
        switch stabilityManager.healthStatus {
        case .healthy:
            return "应用运行正常，所有组件工作良好"
        case .warning:
            return "检测到一些警告，但不影响核心功能"
        case .critical:
            return "检测到严重问题，可能影响应用稳定性"
        case .unknown:
            return "健康状态未知，正在检查中"
        }
    }
    
    private var crashRecoveryIcon: String {
        switch stabilityManager.crashRecoveryStatus {
        case .none:
            return "checkmark.circle.fill"
        case .needsRecovery:
            return "exclamationmark.triangle.fill"
        case .recovering:
            return "arrow.clockwise.circle.fill"
        case .recovered:
            return "checkmark.circle.fill"
        }
    }
    
    private var crashRecoveryColor: Color {
        switch stabilityManager.crashRecoveryStatus {
        case .none, .recovered:
            return .green
        case .needsRecovery:
            return .orange
        case .recovering:
            return .blue
        }
    }
    
    private var crashRecoveryDescription: String {
        switch stabilityManager.crashRecoveryStatus {
        case .none:
            return "无需恢复，应用运行正常"
        case .needsRecovery:
            return "检测到之前的崩溃，建议执行恢复"
        case .recovering:
            return "正在执行恢复操作"
        case .recovered:
            return "恢复操作已完成"
        }
    }
    
    private var stabilityScoreColor: Color {
        guard let score = stabilityReport?.stabilityScore else { return .gray }
        
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Methods
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refreshStabilityReport()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshStabilityReport() {
        stabilityReport = stabilityManager.getStabilityReport()
    }
    
    private func exportStabilityData() {
        let savePanel = NSSavePanel()
        savePanel.title = "导出稳定性数据"
        savePanel.nameFieldStringValue = "Stability-\(Date().timeIntervalSince1970).json"
        savePanel.allowedContentTypes = [.json]
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            if let jsonString = stabilityManager.exportStabilityData() {
                do {
                    try jsonString.write(to: url, atomically: true, encoding: .utf8)
                    showAlert(title: "导出成功", message: "稳定性数据已导出到 \(url.lastPathComponent)")
                } catch {
                    showAlert(title: "导出失败", message: "无法导出稳定性数据：\(error.localizedDescription)")
                }
            } else {
                showAlert(title: "导出失败", message: "无法生成稳定性数据")
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

// MARK: - Supporting Views

struct CrashHistoryRow: View {
    let crash: CrashRecord
    let index: Int
    
    var body: some View {
        HStack {
            Text("#\(index)")
                .font(.caption)
                .fontFamily(.monospaced)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(crash.crashInfo.type.description)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(crash.timestamp, style: .complete)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("版本: \(crash.appVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ExceptionHistoryRow: View {
    let exception: ExceptionRecord
    let index: Int
    
    var body: some View {
        HStack {
            Text("#\(index)")
                .font(.caption)
                .fontFamily(.monospaced)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exception.exceptionName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let reason = exception.reason {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(exception.timestamp, style: .complete)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct StabilityMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        StabilityMonitorView()
            .frame(width: 700, height: 600)
    }
}