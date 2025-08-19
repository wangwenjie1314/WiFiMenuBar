import XCTest
@testable import WiFiMenuBar

/// DisplayFormat枚举的单元测试
final class DisplayFormatTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func createTestNetwork(
        ssid: String = "TestNetwork",
        signalStrength: Int? = -50
    ) -> WiFiNetwork {
        return WiFiNetwork(
            ssid: ssid,
            bssid: "00:11:22:33:44:55",
            signalStrength: signalStrength,
            isSecure: true,
            frequency: 2437.0,
            channel: 6,
            standard: "802.11n",
            connectedAt: Date()
        )
    }
    
    // MARK: - Basic Properties Tests
    
    func testDisplayNames() {
        let testCases: [(DisplayFormat, String)] = [
            (.nameOnly, "仅显示名称"),
            (.nameWithSignal, "名称 + 信号强度"),
            (.nameWithIcon, "名称 + 图标"),
            (.nameWithSignalAndIcon, "名称 + 信号强度 + 图标"),
            (.iconOnly, "仅显示图标")
        ]
        
        for (format, expectedName) in testCases {
            XCTAssertEqual(format.displayName, expectedName,
                          "格式 \(format) 的显示名称应该是 \(expectedName)")
        }
    }
    
    func testDescriptions() {
        XCTAssertEqual(DisplayFormat.nameOnly.description, "在菜单栏中只显示WiFi网络名称")
        XCTAssertEqual(DisplayFormat.nameWithSignal.description, "显示网络名称和信号强度百分比")
        XCTAssertEqual(DisplayFormat.nameWithIcon.description, "显示网络名称和WiFi状态图标")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.description, "显示网络名称、信号强度和状态图标")
        XCTAssertEqual(DisplayFormat.iconOnly.description, "只显示WiFi状态图标，节省菜单栏空间")
    }
    
    // MARK: - Display Options Tests
    
    func testShowsNetworkName() {
        XCTAssertTrue(DisplayFormat.nameOnly.showsNetworkName)
        XCTAssertTrue(DisplayFormat.nameWithSignal.showsNetworkName)
        XCTAssertTrue(DisplayFormat.nameWithIcon.showsNetworkName)
        XCTAssertTrue(DisplayFormat.nameWithSignalAndIcon.showsNetworkName)
        XCTAssertFalse(DisplayFormat.iconOnly.showsNetworkName)
    }
    
    func testShowsSignalStrength() {
        XCTAssertFalse(DisplayFormat.nameOnly.showsSignalStrength)
        XCTAssertTrue(DisplayFormat.nameWithSignal.showsSignalStrength)
        XCTAssertFalse(DisplayFormat.nameWithIcon.showsSignalStrength)
        XCTAssertTrue(DisplayFormat.nameWithSignalAndIcon.showsSignalStrength)
        XCTAssertFalse(DisplayFormat.iconOnly.showsSignalStrength)
    }
    
    func testShowsIcon() {
        XCTAssertFalse(DisplayFormat.nameOnly.showsIcon)
        XCTAssertFalse(DisplayFormat.nameWithSignal.showsIcon)
        XCTAssertTrue(DisplayFormat.nameWithIcon.showsIcon)
        XCTAssertTrue(DisplayFormat.nameWithSignalAndIcon.showsIcon)
        XCTAssertTrue(DisplayFormat.iconOnly.showsIcon)
    }
    
    // MARK: - Format Status Tests
    
    func testFormatConnectedStatus() {
        let network = createTestNetwork(ssid: "MyWiFi", signalStrength: -50)
        let connectedStatus = WiFiStatus.connected(network)
        
        // 测试不同格式的输出
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(connectedStatus), "MyWiFi")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(connectedStatus), "MyWiFi (71%)")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(connectedStatus), "📶 MyWiFi")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(connectedStatus), "📶 MyWiFi (71%)")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(connectedStatus), "📶")
    }
    
    func testFormatDisconnectedStatus() {
        let disconnectedStatus = WiFiStatus.disconnected
        
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(disconnectedStatus), "未连接")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(disconnectedStatus), "未连接")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(disconnectedStatus), "📶 未连接")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(disconnectedStatus), "📶 未连接")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(disconnectedStatus), "📶")
    }
    
    func testFormatConnectingStatus() {
        let connectingStatus = WiFiStatus.connecting("TestNetwork")
        
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(connectingStatus), "连接 TestNetwork")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(connectingStatus), "连接 TestNetwork")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(connectingStatus), "🔄 TestNetwork")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(connectingStatus), "🔄 TestNetwork")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(connectingStatus), "🔄")
    }
    
    func testFormatDisconnectingStatus() {
        let disconnectingStatus = WiFiStatus.disconnecting
        
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(disconnectingStatus), "断开中")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(disconnectingStatus), "断开中")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(disconnectingStatus), "⏸ 断开中")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(disconnectingStatus), "⏸ 断开中")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(disconnectingStatus), "⏸")
    }
    
    func testFormatErrorStatus() {
        let errorStatus = WiFiStatus.error(.networkUnavailable)
        
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(errorStatus), "错误")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(errorStatus), "错误")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(errorStatus), "❌ 错误")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(errorStatus), "❌ 错误")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(errorStatus), "❌")
    }
    
    func testFormatDisabledStatus() {
        let disabledStatus = WiFiStatus.disabled
        
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(disabledStatus), "WiFi已关闭")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(disabledStatus), "WiFi已关闭")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(disabledStatus), "📵 已关闭")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(disabledStatus), "📵 已关闭")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(disabledStatus), "📵")
    }
    
    func testFormatUnknownStatus() {
        let unknownStatus = WiFiStatus.unknown
        
        XCTAssertEqual(DisplayFormat.nameOnly.formatStatus(unknownStatus), "状态未知")
        XCTAssertEqual(DisplayFormat.nameWithSignal.formatStatus(unknownStatus), "状态未知")
        XCTAssertEqual(DisplayFormat.nameWithIcon.formatStatus(unknownStatus), "❓ 未知")
        XCTAssertEqual(DisplayFormat.nameWithSignalAndIcon.formatStatus(unknownStatus), "❓ 未知")
        XCTAssertEqual(DisplayFormat.iconOnly.formatStatus(unknownStatus), "❓")
    }
    
    // MARK: - Text Truncation Tests
    
    func testTextTruncation() {
        let longNetworkName = "VeryLongNetworkNameThatExceedsMaxLength"
        let network = createTestNetwork(ssid: longNetworkName, signalStrength: -50)
        let connectedStatus = WiFiStatus.connected(network)
        
        // 测试名称截断（最大长度为20）
        let result = DisplayFormat.nameOnly.formatStatus(connectedStatus, maxLength: 20)
        XCTAssertTrue(result.count <= 20, "结果长度应该不超过20个字符")
        XCTAssertTrue(result.hasSuffix("…"), "长文本应该以省略号结尾")
    }
    
    func testTextTruncationWithSignal() {
        let longNetworkName = "VeryLongNetworkName"
        let network = createTestNetwork(ssid: longNetworkName, signalStrength: -50)
        let connectedStatus = WiFiStatus.connected(network)
        
        // 测试带信号强度的名称截断
        let result = DisplayFormat.nameWithSignal.formatStatus(connectedStatus, maxLength: 20)
        XCTAssertTrue(result.count <= 20, "结果长度应该不超过20个字符")
        XCTAssertTrue(result.contains("(71%)"), "应该包含信号强度百分比")
    }
    
    func testNoTruncationForShortNames() {
        let shortNetworkName = "WiFi"
        let network = createTestNetwork(ssid: shortNetworkName, signalStrength: -50)
        let connectedStatus = WiFiStatus.connected(network)
        
        let result = DisplayFormat.nameOnly.formatStatus(connectedStatus, maxLength: 20)
        XCTAssertEqual(result, "WiFi", "短名称不应该被截断")
    }
    
    // MARK: - Signal Strength Formatting Tests
    
    func testSignalStrengthFormatting() {
        let testCases: [(Int, String)] = [
            (-30, "(100%)"),
            (-50, "(71%)"),
            (-70, "(43%)"),
            (-100, "(0%)")
        ]
        
        for (strength, expectedPercentage) in testCases {
            let network = createTestNetwork(signalStrength: strength)
            let connectedStatus = WiFiStatus.connected(network)
            let result = DisplayFormat.nameWithSignal.formatStatus(connectedStatus)
            
            XCTAssertTrue(result.contains(expectedPercentage),
                         "信号强度 \(strength) 应该显示为 \(expectedPercentage)")
        }
    }
    
    func testSignalStrengthFormattingWithNilValue() {
        let network = createTestNetwork(signalStrength: nil)
        let connectedStatus = WiFiStatus.connected(network)
        let result = DisplayFormat.nameWithSignal.formatStatus(connectedStatus)
        
        // 没有信号强度时不应该显示百分比
        XCTAssertFalse(result.contains("("), "没有信号强度时不应该显示百分比")
        XCTAssertEqual(result, "TestNetwork", "应该只显示网络名称")
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let originalFormat = DisplayFormat.nameWithSignalAndIcon
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalFormat)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedFormat = try decoder.decode(DisplayFormat.self, from: data)
        
        XCTAssertEqual(originalFormat, decodedFormat, "编码解码后的格式应该相同")
    }
    
    func testAllCasesCodable() throws {
        for format in DisplayFormat.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(format)
            
            let decoder = JSONDecoder()
            let decodedFormat = try decoder.decode(DisplayFormat.self, from: data)
            
            XCTAssertEqual(format, decodedFormat, "格式 \(format) 编码解码后应该相同")
        }
    }
    
    // MARK: - CustomStringConvertible Tests
    
    func testCustomStringConvertible() {
        for format in DisplayFormat.allCases {
            XCTAssertEqual(format.description, format.displayName,
                          "description应该返回displayName")
        }
    }
    
    // MARK: - CaseIterable Tests
    
    func testAllCases() {
        let allCases = DisplayFormat.allCases
        XCTAssertEqual(allCases.count, 5, "应该有5种显示格式")
        
        XCTAssertTrue(allCases.contains(.nameOnly))
        XCTAssertTrue(allCases.contains(.nameWithSignal))
        XCTAssertTrue(allCases.contains(.nameWithIcon))
        XCTAssertTrue(allCases.contains(.nameWithSignalAndIcon))
        XCTAssertTrue(allCases.contains(.iconOnly))
    }
}