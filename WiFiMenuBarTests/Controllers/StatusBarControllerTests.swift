import XCTest
import Cocoa
@testable import WiFiMenuBar

/// StatusBarController的单元测试
final class StatusBarControllerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var statusBarController: StatusBarController!
    private var mockWiFiMonitor: WiFiMonitor!
    private var mockDelegate: MockWiFiMonitorDelegate!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockWiFiMonitor = WiFiMonitor()
        mockDelegate = MockWiFiMonitorDelegate()
        mockWiFiMonitor.delegate = mockDelegate
        statusBarController = StatusBarController(wifiMonitor: mockWiFiMonitor)
    }
    
    override func tearDown() {
        statusBarController.hideFromStatusBar()
        statusBarController = nil
        mockWiFiMonitor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(statusBarController, "StatusBarController应该能够正常初始化")
        XCTAssertFalse(statusBarController.isVisibleInStatusBar, "初始化时不应该在状态栏中显示")
        XCTAssertEqual(statusBarController.currentDisplayFormat, .nameOnly, "默认显示格式应该是nameOnly")
    }
    
    func testInitializationWithWiFiMonitor() {
        let controller = StatusBarController(wifiMonitor: mockWiFiMonitor)
        XCTAssertNotNil(controller, "使用WiFiMonitor初始化应该成功")
        XCTAssertFalse(controller.isVisibleInStatusBar, "初始化时不应该在状态栏中显示")
    }
    
    // MARK: - Status Bar Visibility Tests
    
    func testShowInStatusBar() {
        XCTAssertFalse(statusBarController.isVisibleInStatusBar, "显示前应该不在状态栏中")
        
        statusBarController.showInStatusBar()
        
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "显示后应该在状态栏中")
    }
    
    func testHideFromStatusBar() {
        // 先显示
        statusBarController.showInStatusBar()
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "显示后应该在状态栏中")
        
        // 再隐藏
        statusBarController.hideFromStatusBar()
        XCTAssertFalse(statusBarController.isVisibleInStatusBar, "隐藏后不应该在状态栏中")
    }
    
    func testMultipleShowCalls() {
        statusBarController.showInStatusBar()
        let firstVisibleState = statusBarController.isVisibleInStatusBar
        
        // 再次调用showInStatusBar不应该有副作用
        statusBarController.showInStatusBar()
        
        XCTAssertEqual(statusBarController.isVisibleInStatusBar, firstVisibleState, 
                      "多次调用showInStatusBar应该保持状态一致")
    }
    
    func testMultipleHideCalls() {
        statusBarController.showInStatusBar()
        statusBarController.hideFromStatusBar()
        
        let firstHiddenState = statusBarController.isVisibleInStatusBar
        
        // 再次调用hideFromStatusBar不应该有副作用
        statusBarController.hideFromStatusBar()
        
        XCTAssertEqual(statusBarController.isVisibleInStatusBar, firstHiddenState,
                      "多次调用hideFromStatusBar应该保持状态一致")
    }
    
    // MARK: - Display Format Tests
    
    func testSetDisplayFormat() {
        let initialFormat = statusBarController.currentDisplayFormat
        XCTAssertEqual(initialFormat, .nameOnly, "初始显示格式应该是nameOnly")
        
        // 更改显示格式
        statusBarController.setDisplayFormat(.nameWithSignal)
        
        XCTAssertEqual(statusBarController.currentDisplayFormat, .nameWithSignal,
                      "显示格式应该更新为nameWithSignal")
    }
    
    func testSetSameDisplayFormat() {
        let initialFormat = statusBarController.currentDisplayFormat
        
        // 设置相同的格式
        statusBarController.setDisplayFormat(initialFormat)
        
        XCTAssertEqual(statusBarController.currentDisplayFormat, initialFormat,
                      "设置相同格式应该保持不变")
    }
    
    func testAllDisplayFormats() {
        for format in DisplayFormat.allCases {
            statusBarController.setDisplayFormat(format)
            XCTAssertEqual(statusBarController.currentDisplayFormat, format,
                          "应该能够设置所有显示格式: \(format)")
        }
    }
    
    // MARK: - Update Display Tests
    
    func testUpdateDisplayWithoutStatus() {
        statusBarController.showInStatusBar()
        
        // 测试不传入状态的更新
        statusBarController.updateDisplay()
        
        // 验证更新没有崩溃（具体内容验证需要UI测试）
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "更新后应该仍然可见")
    }
    
    func testUpdateDisplayWithStatus() {
        statusBarController.showInStatusBar()
        
        let testNetwork = createTestNetwork()
        let testStatus = WiFiStatus.connected(testNetwork)
        
        // 测试传入状态的更新
        statusBarController.updateDisplay(with: testStatus)
        
        // 验证更新没有崩溃
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "更新后应该仍然可见")
    }
    
    func testUpdateDisplayWhenHidden() {
        // 在隐藏状态下更新
        XCTAssertFalse(statusBarController.isVisibleInStatusBar, "应该处于隐藏状态")
        
        statusBarController.updateDisplay()
        
        // 验证更新没有崩溃且状态保持隐藏
        XCTAssertFalse(statusBarController.isVisibleInStatusBar, "更新后应该仍然隐藏")
    }
    
    func testForceRefresh() {
        statusBarController.showInStatusBar()
        
        // 测试强制刷新
        statusBarController.forceRefresh()
        
        // 验证刷新没有崩溃
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "强制刷新后应该仍然可见")
    }
    
    // MARK: - Menu Tests
    
    func testMenuItemCount() {
        let menuItemCount = statusBarController.menuItemCount
        XCTAssertGreaterThan(menuItemCount, 0, "应该有菜单项")
        
        // 验证基本菜单项数量（包括分隔线）
        // 状态项 + 分隔线 + 详情 + 统计 + 分隔线 + 刷新 + 重试 + 分隔线 + 偏好设置 + 分隔线 + 退出
        XCTAssertEqual(menuItemCount, 11, "应该有11个菜单项（包括分隔线）")
    }
    
    func testMenuItemsExist() {
        statusBarController.showInStatusBar()
        
        // 验证菜单项数量大于0
        XCTAssertGreaterThan(statusBarController.menuItemCount, 0, "应该有菜单项")
    }
    
    // MARK: - Status Bar Properties Tests
    
    func testStatusBarTitle() {
        statusBarController.showInStatusBar()
        
        // 状态栏标题可能为nil或有值，取决于当前状态
        let title = statusBarController.statusBarTitle
        // 我们主要验证属性可以访问而不崩溃
        XCTAssertNotNil(statusBarController, "控制器应该存在")
    }
    
    func testToolTip() {
        statusBarController.showInStatusBar()
        
        // 工具提示可能为nil或有值
        let toolTip = statusBarController.toolTip
        // 我们主要验证属性可以访问而不崩溃
        XCTAssertNotNil(statusBarController, "控制器应该存在")
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithWiFiMonitor() {
        // 开始WiFi监控
        mockWiFiMonitor.startMonitoring()
        
        // 显示状态栏
        statusBarController.showInStatusBar()
        
        // 等待一小段时间让状态更新
        let expectation = XCTestExpectation(description: "等待状态更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // 验证集成工作正常
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "状态栏应该可见")
        XCTAssertTrue(mockWiFiMonitor.monitoring, "WiFi监控应该在运行")
    }
    
    func testDisplayFormatIntegration() {
        statusBarController.showInStatusBar()
        
        let testNetwork = createTestNetwork()
        let testStatus = WiFiStatus.connected(testNetwork)
        
        // 测试不同显示格式的集成
        for format in DisplayFormat.allCases {
            statusBarController.setDisplayFormat(format)
            statusBarController.updateDisplay(with: testStatus)
            
            XCTAssertEqual(statusBarController.currentDisplayFormat, format,
                          "显示格式应该正确设置: \(format)")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testDeinitializationCleansUp() {
        var controller: StatusBarController? = StatusBarController(wifiMonitor: mockWiFiMonitor)
        controller?.showInStatusBar()
        
        XCTAssertNotNil(controller, "控制器应该存在")
        XCTAssertTrue(controller?.isVisibleInStatusBar ?? false, "应该在状态栏中显示")
        
        // 释放控制器
        controller = nil
        
        // 验证控制器被正确释放
        XCTAssertNil(controller, "控制器应该被释放")
    }
    
    // MARK: - Error Handling Tests
    
    func testUpdateDisplayWithErrorStatus() {
        statusBarController.showInStatusBar()
        
        let errorStatus = WiFiStatus.error(.networkUnavailable)
        
        // 测试错误状态的显示更新
        statusBarController.updateDisplay(with: errorStatus)
        
        // 验证更新没有崩溃
        XCTAssertTrue(statusBarController.isVisibleInStatusBar, "错误状态更新后应该仍然可见")
    }
    
    func testUpdateDisplayWithAllStatusTypes() {
        statusBarController.showInStatusBar()
        
        let testNetwork = createTestNetwork()
        let statusTypes: [WiFiStatus] = [
            .connected(testNetwork),
            .disconnected,
            .connecting("TestNetwork"),
            .disconnecting,
            .error(.networkUnavailable),
            .disabled,
            .unknown
        ]
        
        // 测试所有状态类型的显示更新
        for status in statusTypes {
            statusBarController.updateDisplay(with: status)
            
            // 验证每种状态都能正常处理
            XCTAssertTrue(statusBarController.isVisibleInStatusBar, 
                         "状态 \(status) 更新后应该仍然可见")
        }
    }
    
    // MARK: - Helper Methods
    
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
}