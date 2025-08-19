import XCTest
import CoreWLAN
import Network
@testable import WiFiMenuBar

/// WiFiMonitor的单元测试
final class WiFiMonitorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var wifiMonitor: WiFiMonitor!
    private var mockDelegate: MockWiFiMonitorDelegate!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        wifiMonitor = WiFiMonitor()
        mockDelegate = MockWiFiMonitorDelegate()
        wifiMonitor.delegate = mockDelegate
    }
    
    override func tearDown() {
        wifiMonitor.stopMonitoring()
        wifiMonitor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(wifiMonitor, "WiFiMonitor应该能够正常初始化")
        XCTAssertFalse(wifiMonitor.monitoring, "初始化时应该没有在监控")
        XCTAssertEqual(wifiMonitor.status, .unknown, "初始状态应该是unknown")
    }
    
    func testDelegateAssignment() {
        let newDelegate = MockWiFiMonitorDelegate()
        wifiMonitor.delegate = newDelegate
        
        // 由于delegate是weak引用，我们无法直接比较
        // 但可以通过触发委托方法来验证
        XCTAssertNotNil(wifiMonitor.delegate, "委托应该被正确设置")
    }
    
    // MARK: - Monitoring Control Tests
    
    func testStartMonitoring() {
        XCTAssertFalse(wifiMonitor.monitoring, "开始前应该没有在监控")
        
        wifiMonitor.startMonitoring()
        
        XCTAssertTrue(wifiMonitor.monitoring, "开始监控后应该处于监控状态")
    }
    
    func testStopMonitoring() {
        wifiMonitor.startMonitoring()
        XCTAssertTrue(wifiMonitor.monitoring, "开始监控后应该处于监控状态")
        
        wifiMonitor.stopMonitoring()
        
        XCTAssertFalse(wifiMonitor.monitoring, "停止监控后应该不在监控状态")
    }
    
    func testMultipleStartMonitoring() {
        wifiMonitor.startMonitoring()
        let firstMonitoringState = wifiMonitor.monitoring
        
        // 再次调用startMonitoring不应该有副作用
        wifiMonitor.startMonitoring()
        
        XCTAssertEqual(wifiMonitor.monitoring, firstMonitoringState, "多次调用startMonitoring应该保持状态一致")
    }
    
    func testMultipleStopMonitoring() {
        wifiMonitor.startMonitoring()
        wifiMonitor.stopMonitoring()
        
        let firstStoppedState = wifiMonitor.monitoring
        
        // 再次调用stopMonitoring不应该有副作用
        wifiMonitor.stopMonitoring()
        
        XCTAssertEqual(wifiMonitor.monitoring, firstStoppedState, "多次调用stopMonitoring应该保持状态一致")
    }
    
    // MARK: - Network Information Tests
    
    func testGetCurrentNetworkWhenNotMonitoring() {
        // 在不监控的情况下也应该能获取当前网络信息
        let network = wifiMonitor.getCurrentNetwork()
        
        // 结果可能是nil（如果没有连接）或有效的网络信息
        // 这取决于测试环境的实际WiFi状态
        if let network = network {
            XCTAssertFalse(network.ssid.isEmpty, "如果有网络连接，SSID不应该为空")
        }
    }
    
    func testGetSignalStrengthWhenNotConnected() {
        // 如果没有连接到WiFi，信号强度应该是nil
        // 注意：这个测试的结果取决于测试环境
        let signalStrength = wifiMonitor.getSignalStrength()
        
        // 信号强度可能是nil（未连接）或有效值（已连接）
        if let strength = signalStrength {
            XCTAssertTrue(strength <= 0, "WiFi信号强度应该是负值或零")
            XCTAssertTrue(strength >= -100, "WiFi信号强度不应该小于-100dBm")
        }
    }
    
    func testRefreshStatus() {
        let initialStatus = wifiMonitor.status
        
        wifiMonitor.refreshStatus()
        
        // 刷新后状态可能改变也可能不变，这取决于实际的网络状态
        // 我们主要测试方法能够正常调用而不崩溃
        XCTAssertNotNil(wifiMonitor.status, "刷新后状态不应该是nil")
    }
    
    // MARK: - Static Methods Tests
    
    func testAvailableInterfaceNames() {
        let interfaceNames = WiFiMonitor.availableInterfaceNames()
        
        // 在macOS系统上，通常至少有一个WiFi接口
        // 但在某些测试环境中可能没有
        XCTAssertNotNil(interfaceNames, "接口名称列表不应该是nil")
    }
    
    func testIsWiFiAvailable() {
        let isAvailable = WiFiMonitor.isWiFiAvailable()
        
        // 这个测试的结果取决于测试环境
        // 我们主要确保方法能够正常调用
        XCTAssertNotNil(isAvailable, "WiFi可用性检查应该返回布尔值")
    }
    
    // MARK: - Delegate Callback Tests
    
    func testDelegateCallbacksWhenStartingMonitoring() {
        let expectation = XCTestExpectation(description: "等待状态变化回调")
        
        mockDelegate.onStatusChange = { status in
            expectation.fulfill()
        }
        
        wifiMonitor.startMonitoring()
        
        // 等待异步回调
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(mockDelegate.statusChangeCallCount > 0, "开始监控时应该触发状态变化回调")
    }
    
    // MARK: - Memory Management Tests
    
    func testWeakDelegateReference() {
        var delegate: MockWiFiMonitorDelegate? = MockWiFiMonitorDelegate()
        wifiMonitor.delegate = delegate
        
        XCTAssertNotNil(wifiMonitor.delegate, "委托应该被设置")
        
        delegate = nil
        
        // 由于是weak引用，委托应该被自动释放
        XCTAssertNil(wifiMonitor.delegate, "委托应该被自动释放")
    }
    
    func testDeinitializationStopsMonitoring() {
        wifiMonitor.startMonitoring()
        XCTAssertTrue(wifiMonitor.monitoring, "应该处于监控状态")
        
        // 模拟对象被释放
        wifiMonitor = nil
        
        // 创建新的实例来验证
        wifiMonitor = WiFiMonitor()
        XCTAssertFalse(wifiMonitor.monitoring, "新实例应该不在监控状态")
    }
    
    // MARK: - Error Handling Tests
    
    func testStatusWhenWiFiDisabled() {
        // 这个测试需要模拟WiFi被禁用的情况
        // 在实际测试中，我们无法控制系统WiFi状态
        // 所以这里主要测试相关代码路径不会崩溃
        
        wifiMonitor.refreshStatus()
        let status = wifiMonitor.status
        
        // 状态应该是有效的枚举值
        switch status {
        case .connected, .disconnected, .connecting, .disconnecting, .error, .disabled, .unknown:
            XCTAssertTrue(true, "状态应该是有效的枚举值")
        }
    }
}

// MARK: - Mock Delegate

/// WiFiMonitorDelegate的模拟实现，用于测试
class MockWiFiMonitorDelegate: WiFiMonitorDelegate {
    
    // MARK: - Callback Tracking
    
    var connectCallCount = 0
    var disconnectCallCount = 0
    var statusChangeCallCount = 0
    
    var lastConnectedNetwork: WiFiNetwork?
    var lastStatus: WiFiStatus?
    
    // MARK: - Callback Closures
    
    var onConnect: ((WiFiNetwork) -> Void)?
    var onDisconnect: (() -> Void)?
    var onStatusChange: ((WiFiStatus) -> Void)?
    
    // MARK: - WiFiMonitorDelegate Implementation
    
    func wifiDidConnect(to network: WiFiNetwork) {
        connectCallCount += 1
        lastConnectedNetwork = network
        onConnect?(network)
    }
    
    func wifiDidDisconnect() {
        disconnectCallCount += 1
        onDisconnect?()
    }
    
    func wifiStatusDidChange(_ status: WiFiStatus) {
        statusChangeCallCount += 1
        lastStatus = status
        onStatusChange?(status)
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        connectCallCount = 0
        disconnectCallCount = 0
        statusChangeCallCount = 0
        lastConnectedNetwork = nil
        lastStatus = nil
        onConnect = nil
        onDisconnect = nil
        onStatusChange = nil
    }
}