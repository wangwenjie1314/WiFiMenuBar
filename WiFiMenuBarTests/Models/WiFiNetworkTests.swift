import XCTest
@testable import WiFiMenuBar

/// WiFiNetwork模型的单元测试
final class WiFiNetworkTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func createTestNetwork(
        ssid: String = "TestNetwork",
        bssid: String? = "00:11:22:33:44:55",
        signalStrength: Int? = -50,
        isSecure: Bool = true,
        frequency: Double? = 2437.0,
        channel: Int? = 6,
        standard: String? = "802.11n",
        connectedAt: Date? = nil
    ) -> WiFiNetwork {
        return WiFiNetwork(
            ssid: ssid,
            bssid: bssid,
            signalStrength: signalStrength,
            isSecure: isSecure,
            frequency: frequency,
            channel: channel,
            standard: standard,
            connectedAt: connectedAt
        )
    }
    
    // MARK: - Basic Properties Tests
    
    func testWiFiNetworkInitialization() {
        let network = createTestNetwork()
        
        XCTAssertEqual(network.ssid, "TestNetwork")
        XCTAssertEqual(network.bssid, "00:11:22:33:44:55")
        XCTAssertEqual(network.signalStrength, -50)
        XCTAssertTrue(network.isSecure)
        XCTAssertEqual(network.frequency, 2437.0)
        XCTAssertEqual(network.channel, 6)
        XCTAssertEqual(network.standard, "802.11n")
        XCTAssertNil(network.connectedAt)
    }
    
    func testWiFiNetworkWithNilValues() {
        let network = WiFiNetwork(
            ssid: "MinimalNetwork",
            bssid: nil,
            signalStrength: nil,
            isSecure: false,
            frequency: nil,
            channel: nil,
            standard: nil,
            connectedAt: nil
        )
        
        XCTAssertEqual(network.ssid, "MinimalNetwork")
        XCTAssertNil(network.bssid)
        XCTAssertNil(network.signalStrength)
        XCTAssertFalse(network.isSecure)
        XCTAssertNil(network.frequency)
        XCTAssertNil(network.channel)
        XCTAssertNil(network.standard)
        XCTAssertNil(network.connectedAt)
    }
    
    // MARK: - Signal Strength Tests
    
    func testSignalStrengthDescription() {
        // 测试不同信号强度的描述
        let testCases: [(Int, String)] = [
            (-25, "极强"),
            (-40, "很强"),
            (-55, "良好"),
            (-65, "一般"),
            (-80, "较弱")
        ]
        
        for (strength, expectedDescription) in testCases {
            let network = createTestNetwork(signalStrength: strength)
            XCTAssertEqual(network.signalStrengthDescription, expectedDescription,
                          "信号强度 \(strength) 应该显示为 \(expectedDescription)")
        }
    }
    
    func testSignalStrengthDescriptionWithNilValue() {
        let network = createTestNetwork(signalStrength: nil)
        XCTAssertEqual(network.signalStrengthDescription, "未知")
    }
    
    func testSignalStrengthPercentage() {
        // 测试信号强度百分比计算
        let testCases: [(Int, Int)] = [
            (-30, 100),  // 最强信号
            (-50, 71),   // 良好信号
            (-70, 43),   // 一般信号
            (-100, 0)    // 最弱信号
        ]
        
        for (strength, expectedPercentage) in testCases {
            let network = createTestNetwork(signalStrength: strength)
            XCTAssertEqual(network.signalStrengthPercentage, expectedPercentage,
                          "信号强度 \(strength) 应该转换为 \(expectedPercentage)%")
        }
    }
    
    func testSignalStrengthPercentageWithNilValue() {
        let network = createTestNetwork(signalStrength: nil)
        XCTAssertEqual(network.signalStrengthPercentage, 0)
    }
    
    // MARK: - Frequency Band Tests
    
    func testFrequencyBand() {
        let testCases: [(Double, String)] = [
            (2437.0, "2.4GHz"),
            (5180.0, "5GHz"),
            (6000.0, "6GHz"),
            (1000.0, "其他")
        ]
        
        for (frequency, expectedBand) in testCases {
            let network = createTestNetwork(frequency: frequency)
            XCTAssertEqual(network.frequencyBand, expectedBand,
                          "频率 \(frequency) 应该识别为 \(expectedBand)")
        }
    }
    
    func testFrequencyBandWithNilValue() {
        let network = createTestNetwork(frequency: nil)
        XCTAssertEqual(network.frequencyBand, "未知")
    }
    
    // MARK: - Security Tests
    
    func testSecurityDescription() {
        let secureNetwork = createTestNetwork(isSecure: true)
        XCTAssertEqual(secureNetwork.securityDescription, "安全")
        
        let openNetwork = createTestNetwork(isSecure: false)
        XCTAssertEqual(openNetwork.securityDescription, "开放")
    }
    
    // MARK: - Equatable Tests
    
    func testEquality() {
        let network1 = createTestNetwork(ssid: "Network1", bssid: "00:11:22:33:44:55")
        let network2 = createTestNetwork(ssid: "Network1", bssid: "00:11:22:33:44:55")
        let network3 = createTestNetwork(ssid: "Network2", bssid: "00:11:22:33:44:55")
        let network4 = createTestNetwork(ssid: "Network1", bssid: "00:11:22:33:44:66")
        
        XCTAssertEqual(network1, network2, "相同SSID和BSSID的网络应该相等")
        XCTAssertNotEqual(network1, network3, "不同SSID的网络应该不相等")
        XCTAssertNotEqual(network1, network4, "不同BSSID的网络应该不相等")
    }
    
    func testEqualityWithNilBSSID() {
        let network1 = createTestNetwork(ssid: "Network1", bssid: nil)
        let network2 = createTestNetwork(ssid: "Network1", bssid: nil)
        let network3 = createTestNetwork(ssid: "Network1", bssid: "00:11:22:33:44:55")
        
        XCTAssertEqual(network1, network2, "相同SSID且都没有BSSID的网络应该相等")
        XCTAssertNotEqual(network1, network3, "一个有BSSID一个没有的网络应该不相等")
    }
    
    // MARK: - Hashable Tests
    
    func testHashable() {
        let network1 = createTestNetwork(ssid: "Network1", bssid: "00:11:22:33:44:55")
        let network2 = createTestNetwork(ssid: "Network1", bssid: "00:11:22:33:44:55")
        let network3 = createTestNetwork(ssid: "Network2", bssid: "00:11:22:33:44:55")
        
        var networkSet = Set<WiFiNetwork>()
        networkSet.insert(network1)
        networkSet.insert(network2)
        networkSet.insert(network3)
        
        XCTAssertEqual(networkSet.count, 2, "Set应该包含2个不同的网络")
        XCTAssertTrue(networkSet.contains(network1))
        XCTAssertTrue(networkSet.contains(network3))
    }
    
    // MARK: - Description Tests
    
    func testDescription() {
        let network = createTestNetwork(
            ssid: "TestNetwork",
            bssid: "00:11:22:33:44:55",
            signalStrength: -50,
            isSecure: true,
            frequency: 2437.0
        )
        
        let description = network.description
        
        XCTAssertTrue(description.contains("SSID: TestNetwork"))
        XCTAssertTrue(description.contains("BSSID: 00:11:22:33:44:55"))
        XCTAssertTrue(description.contains("信号: -50dBm"))
        XCTAssertTrue(description.contains("安全性: 安全"))
        XCTAssertTrue(description.contains("频段: 2.4GHz"))
    }
    
    func testDescriptionWithNilValues() {
        let network = createTestNetwork(
            ssid: "MinimalNetwork",
            bssid: nil,
            signalStrength: nil,
            isSecure: false,
            frequency: nil
        )
        
        let description = network.description
        
        XCTAssertTrue(description.contains("SSID: MinimalNetwork"))
        XCTAssertFalse(description.contains("BSSID:"))
        XCTAssertFalse(description.contains("信号:"))
        XCTAssertTrue(description.contains("安全性: 开放"))
        XCTAssertFalse(description.contains("频段:"))
    }
}