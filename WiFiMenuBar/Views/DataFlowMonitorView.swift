import SwiftUI
import Combine

/// 数据流监控视图
/// 用于可视化和监控应用内组件间的数据流和通信
struct DataFlowMonitorView: View {
    
    // MARK: - Properties
    
    /// 通信管理器
    @ObservedObject private var communicationManager = ComponentCommunicationManager.shared
    
    /// 数据流历史
    @State private var dataFlowHistory: [DataFlowEvent] = []
    
    /// 通信统计
    @State private var communicationStats = CommunicationStats()
    
    /// 自动刷新定时器
    @State private var refreshTimer: Timer?
    
    /// 是否自动刷新
    @State private var autoRefresh = true
    
    /// 选中的事件
    @State private var selectedEvent: DataFlowEvent?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // 主内容区域
            HSplitView {
                // 左侧：数据流历史
                dataFlowHistoryView
                
                // 右侧：统计和详情
                VStack {
                    // 统计信息
                    statisticsView
                    
                    Divider()
                    
                    // 当前状态
                    currentStatusView
                    
                    Divider()
                    
                    // 事件详情
                    eventDetailsView
                }
                .frame(minWidth: 300)
            }
            
            Divider()
            
            // 底部控制栏
            controlBar
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            refreshData()
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Subviews
    
    private var titleBar: some View {
        HStack {
            Text("数据流监控器")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("实时监控应用内组件间的数据流和通信")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var dataFlowHistoryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("数据流历史")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                Text("\(dataFlowHistory.count) 个事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(dataFlowHistory.enumerated().reversed()), id: \.offset) { index, event in
                        DataFlowEventRow(
                            event: event,
                            index: dataFlowHistory.count - index,
                            isSelected: selectedEvent?.description == event.description
                        ) {
                            selectedEvent = event
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(minWidth: 400)
    }
    
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通信统计")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("总事件数:")
                        .foregroundColor(.secondary)
                    Text("\(communicationStats.totalEventCount)")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("WiFi状态更新:")
                        .foregroundColor(.secondary)
                    Text("\(communicationStats.wifiStatusUpdateCount)")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("偏好设置更新:")
                        .foregroundColor(.secondary)
                    Text("\(communicationStats.preferencesUpdateCount)")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("应用状态更新:")
                        .foregroundColor(.secondary)
                    Text("\(communicationStats.appStateUpdateCount)")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("错误数量:")
                        .foregroundColor(.secondary)
                    Text("\(communicationStats.errorCount)")
                        .fontWeight(.medium)
                        .foregroundColor(communicationStats.errorCount > 0 ? .red : .primary)
                }
                
                if let lastEventTime = communicationStats.lastEventTime {
                    GridRow {
                        Text("最后事件:")
                            .foregroundColor(.secondary)
                        Text(lastEventTime, style: .relative)
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    private var currentStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(
                    label: "WiFi状态",
                    value: communicationManager.currentWiFiStatus.shortDescription,
                    color: statusColor(for: communicationManager.currentWiFiStatus)
                )
                
                StatusRow(
                    label: "网络连接",
                    value: communicationManager.isNetworkConnected ? "已连接" : "未连接",
                    color: communicationManager.isNetworkConnected ? .green : .red
                )
                
                StatusRow(
                    label: "应用状态",
                    value: communicationManager.appState.description,
                    color: .blue
                )
                
                if let network = communicationManager.currentNetwork {
                    StatusRow(
                        label: "当前网络",
                        value: network.ssid,
                        color: .green
                    )
                }
                
                if let error = communicationManager.lastError {
                    StatusRow(
                        label: "最后错误",
                        value: error.localizedDescription,
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    private var eventDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("事件详情")
                .font(.headline)
            
            if let selectedEvent = selectedEvent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("事件类型:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedEvent.description)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("时间戳:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedEvent.timestamp, style: .complete)
                        .font(.caption)
                        .fontFamily(.monospaced)
                }
            } else {
                Text("选择一个事件查看详情")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    private var controlBar: some View {
        HStack {
            Toggle("自动刷新", isOn: $autoRefresh)
                .onChange(of: autoRefresh) { enabled in
                    if enabled {
                        startAutoRefresh()
                    } else {
                        stopAutoRefresh()
                    }
                }
            
            Spacer()
            
            Button("刷新数据") {
                refreshData()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("清除历史") {
                clearHistory()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("导出数据") {
                exportData()
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(for status: WiFiStatus) -> Color {
        switch status {
        case .connected:
            return .green
        case .disconnected:
            return .orange
        case .error:
            return .red
        case .disabled:
            return .gray
        default:
            return .blue
        }
    }
    
    private func refreshData() {
        dataFlowHistory = communicationManager.getDataFlowHistory()
        communicationStats = communicationManager.getCommunicationStats()
    }
    
    private func startAutoRefresh() {
        guard autoRefresh else { return }
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshData()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func clearHistory() {
        communicationManager.clearHistory()
        refreshData()
        selectedEvent = nil
    }
    
    private func exportData() {
        let savePanel = NSSavePanel()
        savePanel.title = "导出数据流数据"
        savePanel.nameFieldStringValue = "DataFlow-\(Date().timeIntervalSince1970).json"
        savePanel.allowedContentTypes = [.json]
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                let exportData = DataFlowExportData(
                    history: dataFlowHistory,
                    statistics: communicationStats,
                    currentStatus: DataFlowCurrentStatus(
                        wifiStatus: communicationManager.currentWiFiStatus.shortDescription,
                        isNetworkConnected: communicationManager.isNetworkConnected,
                        appState: communicationManager.appState.description,
                        currentNetwork: communicationManager.currentNetwork?.ssid,
                        lastError: communicationManager.lastError?.localizedDescription
                    ),
                    exportTime: Date()
                )
                
                let jsonData = try JSONEncoder().encode(exportData)
                try jsonData.write(to: url)
                
                showAlert(title: "导出成功", message: "数据流数据已导出到 \(url.lastPathComponent)")
            } catch {
                showAlert(title: "导出失败", message: "无法导出数据：\(error.localizedDescription)")
            }
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

struct DataFlowEventRow: View {
    let event: DataFlowEvent
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text("#\(index)")
                .font(.caption)
                .fontFamily(.monospaced)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.description)
                    .font(.caption)
                    .lineLimit(2)
                
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            onTap()
        }
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Export Data Types

struct DataFlowExportData: Codable {
    let history: [DataFlowEventExport]
    let statistics: CommunicationStatsExport
    let currentStatus: DataFlowCurrentStatus
    let exportTime: Date
    
    init(history: [DataFlowEvent], statistics: CommunicationStats, currentStatus: DataFlowCurrentStatus, exportTime: Date) {
        self.history = history.map { DataFlowEventExport(event: $0) }
        self.statistics = CommunicationStatsExport(stats: statistics)
        self.currentStatus = currentStatus
        self.exportTime = exportTime
    }
}

struct DataFlowEventExport: Codable {
    let description: String
    let timestamp: Date
    
    init(event: DataFlowEvent) {
        self.description = event.description
        self.timestamp = event.timestamp
    }
}

struct CommunicationStatsExport: Codable {
    let totalEventCount: Int
    let wifiStatusUpdateCount: Int
    let preferencesUpdateCount: Int
    let appStateUpdateCount: Int
    let errorCount: Int
    let lastEventTime: Date?
    
    init(stats: CommunicationStats) {
        self.totalEventCount = stats.totalEventCount
        self.wifiStatusUpdateCount = stats.wifiStatusUpdateCount
        self.preferencesUpdateCount = stats.preferencesUpdateCount
        self.appStateUpdateCount = stats.appStateUpdateCount
        self.errorCount = stats.errorCount
        self.lastEventTime = stats.lastEventTime
    }
}

struct DataFlowCurrentStatus: Codable {
    let wifiStatus: String
    let isNetworkConnected: Bool
    let appState: String
    let currentNetwork: String?
    let lastError: String?
}

// MARK: - Preview

struct DataFlowMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        DataFlowMonitorView()
            .frame(width: 800, height: 600)
    }
}