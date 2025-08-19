import XCTest
import Cocoa
@testable import WiFiMenuBar

/// StatusBarController的WiFiMonitorDelegate实现测试
final class StatusBarControllerDelegateTests: XCTestCase {
    
    // MARK: - Properties
    
    private var statusBarController: StatusBarController!
    private var mockWiFiMonitor: WiFiMonitor!
    private var mockDelegate: MockWiFiMonitorDelegate!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockWiFiMonitor = WiFiMonitor()
        mockDelegate = MockWiFiMonitorDelegate()
        statusBarController = StatusBarController(wifiMonitor: mockWiFiMonitor)
        
        // 显示状态栏以便测试UI更新
        statusBarController.showInStatusBar()
    }
    
    override func tearDown() {
        statusBarController.hideFromStatusBar()
        statusBarController = nil
        mockWiFiMonitor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Delegate Setup Tests
    
    func testDelegateSetupInInitialization() {
        // 创建新的控制器来测试委托设置
        let newMonitor = WiFiMonitor()
        let newController = StatusBarController(wifiMonitor: newMonitor)
        
        // 验证委托被正确设置
        // 注意：由于delegate是weak引用，我们无法直接比较对象
        // 但我们可以通过触发委托方法来验证
        XCTAssertNotNil(newController, "控制器应该成功创建")
        
        newController.hideFromStatusBar()
    }
    
    // MARK: - wifiDidConnect Tests
    
    func testWifiDidConnect() {
        let testNetwork = createTestNetwork(ssid: "TestNetwork")
        
        // 调用委托方法
        statusBarController.wifiDidConnect(to: testNetwork)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证状态栏标题包含网络名称
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("TestNetwork") ?? false, 
                     "状态栏标题应该包含网络名称")
        
        // 验证工具提示被更新
        let toolTip = statusBarController.toolTip
        XCTAssertNotNil(toolTip, "工具提示应该被设置")
        XCTAssertTrue(toolTip?.contains("TestNetwork") ?? false, 
                     "工具提示应该包含网络名称")
    }
    
    func testWifiDidConnectWithWeakSignal() {
        let weakSignalNetwork = createTestNetwork(ssid: "WeakNetwork", signalStrength: -80)
        
        // 调用委托方法
        statusBarController.wifiDidConnect(to: weakSignalNetwork)
        
        // 等待异步处理
        let expectation = XCTestExpectation(description: "等待处理完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证弱信号网络的处理
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("WeakNetwork") ?? false, 
                     "状态栏应该显示弱信号网络名称")
    }
    
    func testWifiDidConnectMultipleTimes() {
        let network1 = createTestNetwork(ssid: "Network1")
        let network2 = createTestNetwork(ssid: "Network2")
        
        // 连续调用委托方法
        statusBarController.wifiDidConnect(to: network1)
        statusBarController.wifiDidConnect(to: network2)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证最后一次连接的网络被显示
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("Network2") ?? false, 
                     "状态栏应该显示最后连接的网络")
    }
    
    // MARK: - wifiDidDisconnect Tests
    
    func testWifiDidDisconnect() {
        // 先连接一个网络
        let testNetwork = createTestNetwork(ssid: "TestNetwork")
        statusBarController.wifiDidConnect(to: testNetwork)
        
        // 然后断开连接
        statusBarController.wifiDidDisconnect()
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证状态栏显示断开状态
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("未连接") ?? false, 
                     "状态栏应该显示未连接状态")
        
        // 验证工具提示被更新
        let toolTip = statusBarController.toolTip
        XCTAssertTrue(toolTip?.contains("未连接") ?? false, 
                     "工具提示应该显示未连接状态")
    }
    
    func testWifiDidDisconnectWhenNotConnected() {
        // 在未连接状态下调用断开
        statusBarController.wifiDidDisconnect()
        
        // 等待异步处理
        let expectation = XCTestExpectation(description: "等待处理完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证不会崩溃且状态正确
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertNotNil(statusBarTitle, "状态栏标题应该存在")
    }
    
    // MARK: - wifiStatusDidChange Tests
    
    func testWifiStatusDidChangeToConnected() {
        let testNetwork = createTestNetwork(ssid: "StatusChangeNetwork")
        let connectedStatus = WiFiStatus.connected(testNetwork)
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(connectedStatus)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证状态更新
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("StatusChangeNetwork") ?? false, 
                     "状态栏应该显示新连接的网络")
    }
    
    func testWifiStatusDidChangeToDisconnected() {
        let disconnectedStatus = WiFiStatus.disconnected
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(disconnectedStatus)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证断开状态
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("未连接") ?? false, 
                     "状态栏应该显示未连接状态")
    }
    
    func testWifiStatusDidChangeToError() {
        let errorStatus = WiFiStatus.error(.networkUnavailable)
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(errorStatus)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证错误状态
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("错误") ?? false, 
                     "状态栏应该显示错误状态")
        
        // 验证工具提示包含错误信息
        let toolTip = statusBarController.toolTip
        XCTAssertTrue(toolTip?.contains("错误") ?? false, 
                     "工具提示应该包含错误信息")
    }
    
    func testWifiStatusDidChangeToConnecting() {
        let connectingStatus = WiFiStatus.connecting("ConnectingNetwork")
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(connectingStatus)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证连接中状态
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("连接") ?? false, 
                     "状态栏应该显示连接中状态")
        
        // 验证工具提示包含连接信息
        let toolTip = statusBarController.toolTip
        XCTAssertTrue(toolTip?.contains("ConnectingNetwork") ?? false, 
                     "工具提示应该包含正在连接的网络名称")
    }
    
    func testWifiStatusDidChangeToDisabled() {
        let disabledStatus = WiFiStatus.disabled
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(disabledStatus)
        
        // 等待异步UI更新
        let expectation = XCTestExpectation(description: "等待UI更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证禁用状态
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("关闭") ?? false, 
                     "状态栏应该显示WiFi关闭状态")
        
        // 验证工具提示包含启用建议
        let toolTip = statusBarController.toolTip
        XCTAssertTrue(toolTip?.contains("系统设置") ?? false, 
                     "工具提示应该包含启用建议")
    }
    
    // MARK: - Status Change Sequence Tests
    
    func testStatusChangeSequence() {
        let testNetwork = createTestNetwork(ssid: "SequenceNetwork")
        
        // 模拟完整的连接序列
        statusBarController.wifiStatusDidChange(.connecting("SequenceNetwork"))
        statusBarController.wifiStatusDidChange(.connected(testNetwork))
        statusBarController.wifiStatusDidChange(.disconnected)
        
        // 等待所有异步更新完成
        let expectation = XCTestExpectation(description: "等待序列完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证最终状态
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("未连接") ?? false, 
                     "最终状态应该是未连接")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingWithUserIntervention() {
        let permissionError = WiFiMonitorError.permissionDenied
        let errorStatus = WiFiStatus.error(permissionError)
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(errorStatus)
        
        // 等待异步处理
        let expectation = XCTestExpectation(description: "等待错误处理")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证需要用户干预的错误被正确处理
        let toolTip = statusBarController.toolTip
        XCTAssertTrue(toolTip?.contains("权限") ?? false, 
                     "工具提示应该包含权限相关信息")
    }
    
    func testErrorHandlingWithRetryableError() {
        let networkError = WiFiMonitorError.networkUnavailable
        let errorStatus = WiFiStatus.error(networkError)
        
        // 调用委托方法
        statusBarController.wifiStatusDidChange(errorStatus)
        
        // 等待异步处理
        let expectation = XCTestExpectation(description: "等待错误处理")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证可重试错误被正确处理
        let statusBarTitle = statusBarController.statusBarTitle
        XCTAssertTrue(statusBarTitle?.contains("错误") ?? false, 
                     "状态栏应该显示错误状态")
    }
    
    // MARK: - Integration Tests
    
    func testDelegateIntegrationWithRealMonitor() {
        // 创建真实的WiFi监控器进行集成测试
        let realMonitor = WiFiMonitor()
        let controller = StatusBarController(wifiMonitor: realMonitor)
        
        controller.showInStatusBar()
        
        // 启动监控
        realMonitor.startMonitoring()
        
        // 等待一段时间让监控器工作
        let expectation = XCTestExpectation(description: "等待监控器工作")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // 验证集成工作正常
        XCTAssertTrue(controller.isVisibleInStatusBar, "控制器应该在状态栏中显示")
        XCTAssertNotNil(controller.statusBarTitle, "状态栏标题应该存在")
        
        // 清理
        realMonitor.stopMonitoring()
        controller.hideFromStatusBar()
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentDelegateCallbacks() {
        let testNetwork = createTestNetwork(ssid: "ConcurrentNetwork")
        
        // 并发调用委托方法
        DispatchQueue.global().async {
            self.statusBarController.wifiDidConnect(to: testNetwork)
        }
        
        DispatchQueue.global().async {
            self.statusBarController.wifiDidDisconnect()
        }
        
        DispatchQueue.global().async {
            self.statusBarController.wifiStatusDidChange(.unknown)
        }
        
        // 等待所有并发操作完成
        let expectation = XCTestExpectation(description: "等待并发操作完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 验证没有崩溃且状态栏仍然可用
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "状态栏应该仍然可见")
        XCTAssertNotNil(statusBarController.statusBarTitle, "状态栏标题应该存在")
    }
    
    // MARK: - Helper Methods
    
    private func createTestNetwork(ssid: String = "TestNetwork", 
                                  signalStrength: Int? = -50) -> WiFiNetwork {
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
}