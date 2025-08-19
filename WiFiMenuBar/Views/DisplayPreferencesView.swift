import SwiftUI

/// 显示偏好设置视图
/// 管理WiFi信息在菜单栏中的显示格式和样式设置
struct DisplayPreferencesView: View {
    
    // MARK: - Properties
    
    /// 偏好设置管理器
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    
    /// 当前偏好设置
    private var preferences: AppPreferences {
        preferencesManager.getCurrentPreferences()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("显示设置")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 显示格式选择
            displayFormatSection
            
            Divider()
            
            // 显示长度设置
            displayLengthSection
            
            Divider()
            
            // 其他显示选项
            additionalOptionsSection
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Subviews
    
    private var displayFormatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("显示格式")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("选择WiFi信息在菜单栏中的显示方式")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(DisplayFormat.allCases, id: \.self) { format in
                    HStack {
                        Button(action: {
                            preferencesManager.setDisplayFormat(format)
                        }) {
                            HStack {
                                Image(systemName: preferences.displayFormat == format ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(preferences.displayFormat == format ? .accentColor : .secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.leading, 8)
        }
    }
    
    private var displayLengthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("显示长度")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("设置WiFi名称在菜单栏中的最大显示长度")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("短")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(preferences.maxDisplayLength) },
                        set: { preferencesManager.setMaxDisplayLength(Int($0)) }
                    ),
                    in: 5...50,
                    step: 1
                )
                
                Text("长")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(preferences.maxDisplayLength)")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(width: 30)
            }
            
            // 预览示例
            HStack {
                Text("预览:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(previewText)
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
            }
        }
    }
    
    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他选项")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("显示信号强度", isOn: Binding(
                    get: { preferences.showSignalStrength },
                    set: { enabled in
                        var newPreferences = preferences
                        newPreferences.showSignalStrength = enabled
                        preferencesManager.updatePreferences(newPreferences)
                    }
                ))
                .help("在菜单栏显示中包含信号强度信息")
                
                Toggle("显示网络图标", isOn: Binding(
                    get: { preferences.showNetworkIcon },
                    set: { enabled in
                        var newPreferences = preferences
                        newPreferences.showNetworkIcon = enabled
                        preferencesManager.updatePreferences(newPreferences)
                    }
                ))
                .help("在菜单栏显示中包含WiFi状态图标")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var previewText: String {
        let sampleNetworkName = "MyWiFiNetwork-5G"
        let truncated = sampleNetworkName.count > preferences.maxDisplayLength
            ? String(sampleNetworkName.prefix(preferences.maxDisplayLength - 1)) + "…"
            : sampleNetworkName
        
        return truncated
    }
}

// MARK: - Preview

struct DisplayPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        DisplayPreferencesView()
            .frame(width: 400, height: 500)
    }
}