import XCTest
import Combine
@testable import WiFiMenuBar

/// ComponentCommunicationManager单元测试
/// 测试组件间通信管理器的功能
class ComponentCommunicationManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var communicationManager: ComponentCommunicationManager!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        communicationManager = ComponentCommunicationManager.shared
        cancellables = Set<AnyCancellable>()
        
        // 重置状态以确保测试的独立性
        communicationManager.resetAllStates()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        communicationManager.resetAllStates()
        communicationManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() {
        // Given & When
        let instance1 = ComponentCommunicationManager.shared
        let instance2 = ComponentCommunicationManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "ComponentCommunicationManager应该是单例")
    }
    
    func testInitialState() {
        // Given & When
        let manager = ComponentCommunicationManager.shared
        
        // Then
        XCTAssertEqual(manager.currentWiFiStatus, .unknown, "初始WiFi状态应该是unknown")
        XCTAssertFalse(manager.isNetworkConnected, "初始网络连接状态应该是false")
        XCTAssertNil(manager.currentNetwork, "初始当前网络应该是nil")
        XCTAssertNil(manager.lastError, "初始错误状态应该是nil")
    }
    
    // MARK: - WiFi Status Tests
    
    func testUpdateWiFiStatus() {
        // Given
        let expectation = XCTestExpectation(description: "WiFi状态更新")
        let testNetwork = createTestNetwork()
        let newStatus = WiFiStatus.connected(testNetwork)
        
        // When
        communicationManager.$currentWiFiStatus
            .dropFirst() // 跳过初始值
            .sink { status in
                XCTAssertEqual(status, newStatus, "WiFi状态应该被正确更新")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        communicationManager.updateWiFiStatus(newStatus)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(communicationManager.currentWiFiStatus, newStatus)
        XCTAssertTrue(communicationManager.isNetworkConnected, "网络连接状态应该更新为true")
        XCTAssertEqual(communicationManager.currentNetwork?.ssid, testNetwork.ssid)
    }
    
    func testWiFiStatusChangeNotification() {
        // Given
        let expectation = XCTestExpectation(description: "WiFi状态变化通知")
        let testNetwork = createTestNetwork()
        let newStatus = WiFiStatus.connected(testNetwork)
        
        NotificationCenter.default.addObserver(
            forName: .wifiStatusDidChange,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["oldStatus"])
            XCTAssertNotNil(notification.userInfo?["newStatus"])
            expectation.fulfill()
        }
        
        // When
        communicationManager.updateWiFiStatus(newStatus)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWiFiStatusNoChangeIgnored() {
        // Given
        let testNetwork = createTestNetwork()
        let status = WiFiStatus.connected(testNetwork)
        communicationManager.updateWiFiStatus(status)
        
        let initialEventCount = communicationManager.getCommunicationStats().totalEventCount
        
        // When
        communicationManager.updateWiFiStatus(status) // 相同状态
        
        // Then
        let finalEventCount = communicationManager.getCommunicationStats().totalEventCount
        XCTAssertEqual(initialEventCount, finalEventCount, "相同状态更新应该被忽略")
    }
    
    // MARK: - Preferences Tests
    
    func testUpdatePreferences() {
        // Given
        let expectation = XCTestExpectation(description: "偏好设置更新")
        var newPreferences = AppPreferences()
        newPreferences.displayFormat = .nameWithSignal
        newPreferences.autoStart = false
        
        // When
        communicationManager.$currentPreferences
            .dropFirst() // 跳过初始值
            .sink { preferences in
                XCTAssertEqual(preferences.displayFormat, .nameWithSignal)
                XCTAssertFalse(preferences.autoStart)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        communicationManager.updatePreferences(newPreferences)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(communicationManager.currentPreferences.displayFormat, .nameWithSignal)
    }
    
    func testPreferencesChangeNotification() {
        // Given
        let expectation = XCTestExpectation(description: "偏好设置变化通知")
        var newPreferences = AppPreferences()
        newPreferences.displayFormat = .nameWithIcon
        
        NotificationCenter.default.addObserver(
            forName: .preferencesDidChange,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["oldPreferences"])
            XCTAssertNotNil(notification.userInfo?["newPreferences"])
            expectation.fulfill()
        }
        
        // When
        communicationManager.updatePreferences(newPreferences)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - App State Tests
    
    func testUpdateAppState() {
        // Given
        let expectation = XCTestExpectation(description: "应用状态更新")
        let newState = AppState.running
        
        // When
        communicationManager.$appState
            .dropFirst() // 跳过初始值
            .sink { state in
                XCTAssertEqual(state, newState)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        communicationManager.updateAppState(newState)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(communicationManager.appState, newState)
    }
    
    // MARK: - Error Handling Tests
    
    func testUpdateError() {
        // Given
        let expectation = XCTestExpectation(description: "错误状态更新")
        let testError = WiFiMonitorError.permissionDenied
        
        NotificationCenter.default.addObserver(
            forName: .wifiErrorOccurred,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["error"])
            expectation.fulfill()
        }
        
        // When
        communicationManager.updateError(testError)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(communicationManager.lastError, testError)
    }
    
    // MARK: - Data Flow History Tests
    
    func testDataFlowHistory() {
        // Given
        let testNetwork = createTestNetwork()
        let wifiStatus = WiFiStatus.connected(testNetwork)
        var preferences = AppPreferences()
        preferences.displayFormat = .nameWithSignal
        
        // When
        communicationManager.updateWiFiStatus(wifiStatus)
        communicationManager.updatePreferences(preferences)
        communicationManager.updateAppState(.running)
        
        // Then
        let history = communicationManager.getDataFlowHistory()
        XCTAssertGreaterThan(history.count, 0, "应该有数据流历史记录")
        
        // 检查是否包含预期的事件类型
        let eventDescriptions = history.map { $0.description }
        XCTAssertTrue(eventDescriptions.contains { $0.contains("WiFi状态变化") })
        XCTAssertTrue(eventDescriptions.contains { $0.contains("偏好设置变化") })
        XCTAssertTrue(eventDescriptions.contains { $0.contains("应用状态变化") })
    }
    
    func testClearHistory() {
        // Given
        let testNetwork = createTestNetwork()
        communicationManager.updateWiFiStatus(.connected(testNetwork))
        
        let initialHistoryCount = communicationManager.getDataFlowHistory().count
        XCTAssertGreaterThan(initialHistoryCount, 0, "应该有历史记录")
        
        // When
        communicationManager.clearHistory()
        
        // Then
        let finalHistoryCount = communicationManager.getDataFlowHistory().count
        XCTAssertEqual(finalHistoryCount, 0, "历史记录应该被清除")
        
        let stats = communicationManager.getCommunicationStats()
        XCTAssertEqual(stats.totalEventCount, 0, "统计数据应该被重置")
    }
    
    // MARK: - Communication Stats Tests
    
    func testCommunicationStats() {
        // Given
        let testNetwork = createTestNetwork()
        var preferences = AppPreferences()
        preferences.displayFormat = .nameWithIcon
        
        // When
        communicationManager.updateWiFiStatus(.connected(testNetwork))
        communicationManager.updateWiFiStatus(.disconnected)
        communicationManager.updatePreferences(preferences)
        communicationManager.updateAppState(.running)
        communicationManager.updateError(WiFiMonitorError.permissionDenied)
        
        // Then
        let stats = communicationManager.getCommunicationStats()
        XCTAssertGreaterThan(stats.totalEventCount, 0, "应该有事件统计")
        XCTAssertGreaterThan(stats.wifiStatusUpdateCount, 0, "应该有WiFi状态更新统计")
        XCTAssertGreaterThan(stats.preferencesUpdateCount, 0, "应该有偏好设置更新统计")
        XCTAssertGreaterThan(stats.appStateUpdateCount, 0, "应该有应用状态更新统计")
        XCTAssertNotNil(stats.lastEventTime, "应该有最后事件时间")
    }
    
    // MARK: - Network Connection Tests
    
    func testNetworkConnectionStatusUpdate() {
        // Given
        let testNetwork = createTestNetwork()
        
        // When - 连接到网络
        communicationManager.updateWiFiStatus(.connected(testNetwork))
        
        // Then
        XCTAssertTrue(communicationManager.isNetworkConnected, "网络连接状态应该为true")
        XCTAssertEqual(communicationManager.currentNetwork?.ssid, testNetwork.ssid)
        
        // When - 断开网络
        communicationManager.updateWiFiStatus(.disconnected)
        
        // Then
        XCTAssertFalse(communicationManager.isNetworkConnected, "网络连接状态应该为false")
        XCTAssertNil(communicationManager.currentNetwork, "当前网络应该为nil")
    }
    
    // MARK: - Reset Tests
    
    func testResetAllStates() {
        // Given
        let testNetwork = createTestNetwork()
        var preferences = AppPreferences()
        preferences.displayFormat = .nameWithSignal
        
        communicationManager.updateWiFiStatus(.connected(testNetwork))
        communicationManager.updatePreferences(preferences)
        communicationManager.updateAppState(.running)
        communicationManager.updateError(WiFiMonitorError.permissionDenied)
        
        // When
        communicationManager.resetAllStates()
        
        // Then
        XCTAssertEqual(communicationManager.currentWiFiStatus, .unknown)
        XCTAssertFalse(communicationManager.isNetworkConnected)
        XCTAssertNil(communicationManager.currentNetwork)
        XCTAssertNil(communicationManager.lastError)
        XCTAssertEqual(communicationManager.getDataFlowHistory().count, 0)
        XCTAssertEqual(communicationManager.getCommunicationStats().totalEventCount, 0)
    }
    
    // MARK: - Performance Tests
    
    func testUpdatePerformance() {
        // Given
        let testNetwork = createTestNetwork()
        
        // When & Then
        measure {
            for _ in 0..<100 {
                communicationManager.updateWiFiStatus(.connected(testNetwork))
                communicationManager.updateWiFiStatus(.disconnected)
            }
        }
    }
    
    func testHistoryPerformance() {
        // Given
        let testNetwork = createTestNetwork()
        
        // 生成大量历史记录
        for i in 0..<1000 {
            if i % 2 == 0 {
                communicationManager.updateWiFiStatus(.connected(testNetwork))
            } else {
                communicationManager.updateWiFiStatus(.disconnected)
            }
        }
        
        // When & Then
        measure {
            _ = communicationManager.getDataFlowHistory()
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "并发更新测试")
        expectation.expectedFulfillmentCount = 10
        
        let testNetwork = createTestNetwork()
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                if i % 2 == 0 {
                    self.communicationManager.updateWiFiStatus(.connected(testNetwork))
                } else {
                    self.communicationManager.updateWiFiStatus(.disconnected)
                }
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        // 验证状态一致性
        let finalStatus = communicationManager.currentWiFiStatus
        XCTAssertTrue(finalStatus == .connected(testNetwork) || finalStatus == .disconnected)
    }
    
    // MARK: - Helper Methods
    
    private func createTestNetwork() -> WiFiNetwork {
        return WiFiNetwork(
            ssid: "TestNetwork",
            bssid: "00:11:22:33:44:55",
            signalStrength: -50,
            isSecure: true,
            frequency: 2.4
        )
    }
}

// MARK: - Mock Tests

extension ComponentCommunicationManagerTests {
    
    func testDataFlowEventDescription() {
        // Given
        let testNetwork = createTestNetwork()
        let oldStatus = WiFiStatus.disconnected
        let newStatus = WiFiStatus.connected(testNetwork)
        
        // When
        let event = DataFlowEvent.wifiStatusChanged(from: oldStatus, to: newStatus)
        
        // Then
        XCTAssertTrue(event.description.contains("WiFi状态变化"))
        XCTAssertNotNil(event.timestamp)
    }
    
    func testCommunicationStatsDescription() {
        // Given
        var stats = CommunicationStats()
        stats.totalEventCount = 10
        stats.wifiStatusUpdateCount = 5
        stats.preferencesUpdateCount = 3
        stats.appStateUpdateCount = 2
        
        // When
        let description = stats.description
        
        // Then
        XCTAssertTrue(description.contains("总事件数: 10"))
        XCTAssertTrue(description.contains("WiFi状态更新: 5"))
        XCTAssertTrue(description.contains("偏好设置更新: 3"))
        XCTAssertTrue(description.contains("应用状态更新: 2"))
    }
    
    func testNotificationPermissionStatus() {
        // Given & When & Then
        XCTAssertEqual(NotificationPermissionStatus(from: .notDetermined), .notDetermined)
        XCTAssertEqual(NotificationPermissionStatus(from: .denied), .denied)
        XCTAssertEqual(NotificationPermissionStatus(from: .authorized), .authorized)
        XCTAssertEqual(NotificationPermissionStatus(from: .provisional), .provisional)
        XCTAssertEqual(NotificationPermissionStatus(from: .ephemeral), .ephemeral)
    }
}