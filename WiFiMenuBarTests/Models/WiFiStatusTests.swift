import XCTest
@testable import WiFiMenuBar

/// WiFiStatus枚举的单元测试
final class WiFiStatusTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func createTestNetwork() -> WiFiNetwork {
        return WiFiNetwork(
            ssid: "TestNetwork",
            bssid: "00:11:22:33:44:55",
            signalStrength: -50,
            isSecure: true,
            frequency: 2437.0,
            channel: 6,
            standard: "802.11n",
            connectedAt: Date()
        )
    }
    
    private func createTestError() -> WiFiMonitorError {
        return .networkUnavailable
    }
    
    // MARK: - Display Text Tests
    
    func testDisplayText() {
        let network = createTestNetwork()
        let error = createTestError()
        
        let testCases: [(WiFiStatus, String)] = [
            (.connected(network), "TestNetwork"),
            (.disconnected, "未连接"),
            (.connecting("TestNetwork"), "连接中: TestNetwork"),
            (.disconnecting, "断开中"),
            (.error(error), "错误: 网络服务不可用"),
            (.disabled, "WiFi已关闭"),
            (.unknown, "状态未知")
        ]
        
        for (status, expectedText) in testCases {
            XCTAssertEqual(status.displayText, expectedText,
                          "状态 \(status) 的显示文本应该是 \(expectedText)")
        }
    }
    
    func testShortDescription() {
        let network = createTestNetwork()
        
        let testCases: [(WiFiStatus, String)] = [
            (.connected(network), "TestNetwork"),
            (.disconnected, "未连接"),
            (.connecting("TestNetwork"), "连接中"),
            (.disconnecting, "断开中"),
            (.error(createTestError()), "错误"),
            (.disabled, "已关闭"),
            (.unknown, "未知")
        ]
        
        for (status, expectedText) in testCases {
            XCTAssertEqual(status.shortDescription, expectedText,
                          "状态 \(status) 的简短描述应该是 \(expectedText)")
        }
    }
    
    func testDetailedDescription() {
        let network = createTestNetwork()
        let connectedStatus = WiFiStatus.connected(network)
        let detailedDescription = connectedStatus.detailedDescription
        
        XCTAssertTrue(detailedDescription.contains("已连接到: TestNetwork"))
        XCTAssertTrue(detailedDescription.contains("信号强度: -50dBm"))
        XCTAssertTrue(detailedDescription.contains("频段: 2.4GHz"))
        XCTAssertTrue(detailedDescription.contains("安全性: 安全"))
        XCTAssertTrue(detailedDescription.contains("连接时间:"))
        
        let disconnectedStatus = WiFiStatus.disconnected
        XCTAssertEqual(disconnectedStatus.detailedDescription, "当前未连接到任何WiFi网络")
        
        let errorStatus = WiFiStatus.error(createTestError())
        XCTAssertTrue(errorStatus.detailedDescription.contains("WiFi连接出现错误"))
    }
    
    // MARK: - Status Property Tests
    
    func testIsConnected() {
        let network = createTestNetwork()
        
        XCTAssertTrue(WiFiStatus.connected(network).isConnected)
        XCTAssertFalse(WiFiStatus.disconnected.isConnected)
        XCTAssertFalse(WiFiStatus.connecting("Test").isConnected)
        XCTAssertFalse(WiFiStatus.error(createTestError()).isConnected)
    }
    
    func testIsError() {
        let error = createTestError()
        
        XCTAssertTrue(WiFiStatus.error(error).isError)
        XCTAssertFalse(WiFiStatus.connected(createTestNetwork()).isError)
        XCTAssertFalse(WiFiStatus.disconnected.isError)
        XCTAssertFalse(WiFiStatus.connecting("Test").isError)
    }
    
    func testIsTransitioning() {
        XCTAssertTrue(WiFiStatus.connecting("Test").isTransitioning)
        XCTAssertTrue(WiFiStatus.disconnecting.isTransitioning)
        XCTAssertFalse(WiFiStatus.connected(createTestNetwork()).isTransitioning)
        XCTAssertFalse(WiFiStatus.disconnected.isTransitioning)
        XCTAssertFalse(WiFiStatus.error(createTestError()).isTransitioning)
    }
    
    func testConnectedNetwork() {
        let network = createTestNetwork()
        let connectedStatus = WiFiStatus.connected(network)
        
        XCTAssertEqual(connectedStatus.connectedNetwork, network)
        XCTAssertNil(WiFiStatus.disconnected.connectedNetwork)
        XCTAssertNil(WiFiStatus.connecting("Test").connectedNetwork)
        XCTAssertNil(WiFiStatus.error(createTestError()).connectedNetwork)
    }
    
    // MARK: - Equatable Tests
    
    func testEquality() {
        let network1 = createTestNetwork()
        let network2 = WiFiNetwork(
            ssid: "TestNetwork",
            bssid: "00:11:22:33:44:55",
            signalStrength: -60, // 不同的信号强度
            isSecure: true,
            frequency: 2437.0,
            channel: 6,
            standard: "802.11n",
            connectedAt: Date()
        )
        let network3 = WiFiNetwork(
            ssid: "DifferentNetwork",
            bssid: "00:11:22:33:44:55",
            signalStrength: -50,
            isSecure: true,
            frequency: 2437.0,
            channel: 6,
            standard: "802.11n",
            connectedAt: Date()
        )
        
        // 测试connected状态的相等性
        XCTAssertEqual(WiFiStatus.connected(network1), WiFiStatus.connected(network2),
                      "相同网络的connected状态应该相等")
        XCTAssertNotEqual(WiFiStatus.connected(network1), WiFiStatus.connected(network3),
                         "不同网络的connected状态应该不相等")
        
        // 测试其他状态的相等性
        XCTAssertEqual(WiFiStatus.disconnected, WiFiStatus.disconnected)
        XCTAssertEqual(WiFiStatus.connecting("Test"), WiFiStatus.connecting("Test"))
        XCTAssertNotEqual(WiFiStatus.connecting("Test1"), WiFiStatus.connecting("Test2"))
        XCTAssertEqual(WiFiStatus.disconnecting, WiFiStatus.disconnecting)
        XCTAssertEqual(WiFiStatus.disabled, WiFiStatus.disabled)
        XCTAssertEqual(WiFiStatus.unknown, WiFiStatus.unknown)
        
        // 测试不同状态之间的不相等性
        XCTAssertNotEqual(WiFiStatus.connected(network1), WiFiStatus.disconnected)
        XCTAssertNotEqual(WiFiStatus.disconnected, WiFiStatus.connecting("Test"))
    }
    
    // MARK: - Description Tests
    
    func testDescription() {
        let network = createTestNetwork()
        let status = WiFiStatus.connected(network)
        
        XCTAssertEqual(status.description, "TestNetwork")
        XCTAssertEqual(WiFiStatus.disconnected.description, "未连接")
        XCTAssertEqual(WiFiStatus.connecting("TestNetwork").description, "连接中: TestNetwork")
    }
    
    // MARK: - Edge Cases
    
    func testStatusWithEmptyNetworkName() {
        let emptyNameStatus = WiFiStatus.connecting("")
        XCTAssertEqual(emptyNameStatus.displayText, "连接中: ")
        XCTAssertEqual(emptyNameStatus.shortDescription, "连接中")
    }
    
    func testStatusWithLongNetworkName() {
        let longName = "VeryLongNetworkNameThatExceedsNormalLength"
        let longNameStatus = WiFiStatus.connecting(longName)
        XCTAssertEqual(longNameStatus.displayText, "连接中: \(longName)")
    }
}