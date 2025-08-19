import SwiftUI
import Charts

/// 性能监控视图
/// 显示应用的内存和CPU使用情况，以及性能优化控制
struct PerformanceMonitorView: View {
    
    // MARK: - Properties
    
    /// 性能管理器
    @ObservedObject private var performanceManager = PerformanceManager.shared
    
    /// 是否显示详细信息
    @State private var showDetails = false
    
    /// 是否显示历史图表
    @State private var showChart = false
    
    /// 自动刷新定时器
    @State private var refreshTimer: Timer?
    
    /// 性能报告
    @State private var performanceReport: PerformanceReport?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 当前性能状态
                    currentPerformanceSection
                    
                    Divider()
                    
                    // 性能图表
                    if showChart {
                        performanceChartSection
                        
                        Divider()
                    }
                    
                    // 详细信息
                    if showDetails {
                        detailedInfoSection
                        
                        Divider()
                    }
                    
                    // 优化控制
                    optimizationControlSection
                    
                    Divider()
                    
                    // 性能报告
                    if let report = performanceReport {
                        performanceReportSection(report)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 底部控制栏
            controlBar
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            startAutoRefresh()
            refreshPerformanceReport()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Subviews
    
    private var titleBar: some View {
        HStack {
            Text("性能监控")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("实时监控应用的内存和CPU使用情况")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var currentPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("当前性能状态")
                .font(.headline)
            
            HStack(spacing: 30) {
                // 内存使用
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(.blue)
                        Text("内存使用")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("\(String(format: "%.1f", performanceManager.currentMemoryUsage)) MB")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(memoryUsageColor)
                    
                    ProgressView(value: performanceManager.currentMemoryUsage, total: 200.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: memoryUsageColor))
                }
                
                // CPU使用
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.orange)
                        Text("CPU使用")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("\(String(format: "%.1f", performanceManager.currentCPUUsage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(cpuUsageColor)
                    
                    ProgressView(value: performanceManager.currentCPUUsage, total: 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: cpuUsageColor))
                }
                
                // 性能状态
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "gauge")
                            .foregroundColor(.green)
                        Text("性能状态")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Circle()
                            .fill(performanceManager.performanceStatus.color)
                            .frame(width: 12, height: 12)
                        
                        Text(performanceManager.performanceStatus.description)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Text(performanceStatusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能历史图表")
                .font(.headline)
            
            // 这里可以添加图表组件
            // 由于Charts框架可能不可用，我们使用简单的文本显示
            VStack(alignment: .leading, spacing: 8) {
                Text("内存使用趋势")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    ForEach(0..<10, id: \.self) { index in
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 20, height: CGFloat.random(in: 20...80))
                    }
                }
                
                Text("CPU使用趋势")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)
                
                HStack {
                    ForEach(0..<10, id: \.self) { index in
                        Rectangle()
                            .fill(Color.orange.opacity(0.6))
                            .frame(width: 20, height: CGFloat.random(in: 10...60))
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var detailedInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                let memoryDetails = performanceManager.getMemoryUsageDetails()
                let cpuDetails = performanceManager.getCPUUsageDetails()
                
                InfoRow(label: "常驻内存", value: "\(String(format: "%.1f", memoryDetails.residentSize)) MB")
                InfoRow(label: "虚拟内存", value: "\(String(format: "%.1f", memoryDetails.virtualSize)) MB")
                InfoRow(label: "用户态时间", value: "\(String(format: "%.2f", cpuDetails.userTime)) 秒")
                InfoRow(label: "系统态时间", value: "\(String(format: "%.2f", cpuDetails.systemTime)) 秒")
                InfoRow(label: "监控状态", value: performanceManager.isMonitoringEnabled ? "启用" : "禁用")
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var optimizationControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能优化控制")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle("启用性能监控", isOn: $performanceManager.isMonitoringEnabled)
                        .onChange(of: performanceManager.isMonitoringEnabled) { enabled in
                            if enabled {
                                performanceManager.startPerformanceMonitoring()
                            } else {
                                performanceManager.stopPerformanceMonitoring()
                            }
                        }
                    
                    Spacer()
                }
                
                HStack {
                    Button("执行优化") {
                        performanceManager.performOptimization()
                        refreshPerformanceReport()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    
                    Button("清理历史") {
                        performanceManager.clearPerformanceHistory()
                        refreshPerformanceReport()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("导出数据") {
                        exportPerformanceData()
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
    
    private func performanceReportSection(_ report: PerformanceReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能报告")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "平均内存使用", value: "\(String(format: "%.1f", report.averageMemoryUsage)) MB")
                InfoRow(label: "平均CPU使用", value: "\(String(format: "%.1f", report.averageCPUUsage))%")
                InfoRow(label: "峰值内存使用", value: "\(String(format: "%.1f", report.peakMemoryUsage)) MB")
                InfoRow(label: "峰值CPU使用", value: "\(String(format: "%.1f", report.peakCPUUsage))%")
                InfoRow(label: "监控时长", value: "\(String(format: "%.0f", report.monitoringDuration)) 秒")
                
                if !report.optimizationSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("优化建议:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ForEach(report.optimizationSuggestions, id: \.self) { suggestion in
                            Text("• \(suggestion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
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
            
            Toggle("显示图表", isOn: $showChart)
            
            Spacer()
            
            Button("刷新") {
                refreshPerformanceReport()
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
    
    private var memoryUsageColor: Color {
        if performanceManager.currentMemoryUsage > 100 {
            return .red
        } else if performanceManager.currentMemoryUsage > 50 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var cpuUsageColor: Color {
        if performanceManager.currentCPUUsage > 50 {
            return .red
        } else if performanceManager.currentCPUUsage > 25 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var performanceStatusDescription: String {
        switch performanceManager.performanceStatus {
        case .normal:
            return "性能正常"
        case .warning:
            return "性能警告"
        case .critical:
            return "性能严重"
        }
    }
    
    // MARK: - Methods
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // 性能管理器会自动更新，这里只需要刷新报告
            if performanceReport != nil {
                refreshPerformanceReport()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshPerformanceReport() {
        performanceReport = performanceManager.getPerformanceReport()
    }
    
    private func exportPerformanceData() {
        let savePanel = NSSavePanel()
        savePanel.title = "导出性能数据"
        savePanel.nameFieldStringValue = "Performance-\(Date().timeIntervalSince1970).json"
        savePanel.allowedContentTypes = [.json]
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            if let jsonString = performanceManager.exportPerformanceData() {
                do {
                    try jsonString.write(to: url, atomically: true, encoding: .utf8)
                    showAlert(title: "导出成功", message: "性能数据已导出到 \(url.lastPathComponent)")
                } catch {
                    showAlert(title: "导出失败", message: "无法导出性能数据：\(error.localizedDescription)")
                }
            } else {
                showAlert(title: "导出失败", message: "无法生成性能数据")
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

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct PerformanceMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceMonitorView()
            .frame(width: 600, height: 500)
    }
}