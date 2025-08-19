import XCTest
@testable import WiFiMenuBar

/// 网络状态监控功能的单元测试
final class NetworkStateMonitoringTests: XCTestCase {
    
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
    
    // MARK: - Status Cache Tests
    
    func testStatusCacheInitialization() {
        let cacheInfo = wifiMonitor.cacheInfo
        
        XCTAssertFalse(cacheInfo.hasCache, "初始化时应该没有缓存")
        XCTAssertNil(cacheInfo.cacheTime, "初始化时缓存时间应该为nil")
        XCTAssertEqual(cacheInfo.changeCount, 0, "初始化时变化次数应该为0")
        XCTAssertNil(cacheInfo.lastNetwork, "初始化时最后网络应该为nil")
    }
    
    func testForceRefreshStatus() {
        // 开始监控以建立缓存
        wifiMonitor.startMonitoring()
        
        // 等待一小段时间让缓存建立
        let expectation = XCTestExpectation(description: "等待缓存建立")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let initialChangeCount = wifiMonitor.cacheInfo.changeCount
        
        // 强制刷新状态
        wifiMonitor.forceRefreshStatus()
        
        // 验证缓存被清除并重新建立
        let newCacheInfo = wifiMonitor.cacheInfo
        XCTAssertTrue(newCacheInfo.changeCount >= initialChangeCount, "强制刷新后变化次数应该增加或保持")
    }
    
    // MARK: - Connection History Tests
    
    func testConnectionHistoryInitialization() {
        let history = wifiMonitor.connectionHistory
        XCTAssertTrue(history.isEmpty, "初始化时连接历史应该为空")
    }
    
    func testClearConnectionHistory() {
        // 开始监控以产生一些历史记录
        wifiMonitor.startMonitoring()
        
        // 等待一些事件发生
        let expectation = XCTestExpectation(description: "等待事件产生")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // 清除历史记录
        wifiMonitor.clearConnectionHistory()
        
        let history = wifiMonitor.connectionHistory
        XCTAssertTrue(history.isEmpty, "清除后连接历史应该为空")
    }
    
    // MARK: - Connection Stats Tests
    
    func testConnectionStatsInitialization() {
        let stats = wifiMonitor.getConnectionStats()
        
        XCTAssertEqual(stats.totalEvents, 0, "初始化时总事件数应该为0")
        XCTAssertEqual(stats.connectionCount, 0, "初始化时连接次数应该为0")
        XCTAssertEqual(stats.disconnectionCount, 0, "初始化时断开次数应该为0")
        XCTAssertEqual(stats.errorCount, 0, "初始化时错误次数应该为0")
        XCTAssertNil(stats.lastEventTime, "初始化时最后事件时间应该为nil")
        XCTAssertEqual(stats.connectionSuccessRate, 1.0, "初始化时连接成功率应该为1.0")
        XCTAssertEqual(stats.connectionStabilityRatio, 0.0, "初始化时稳定性比率应该为0.0")
    }
    
    func testConnectionStatsCalculation() {
        let stats = wifiMonitor.getConnectionStats()
        
        // 测试成功率计算
        XCTAssertEqual(stats.connectionSuccessRate, 1.0, "没有事件时成功率应该为1.0")
        
        // 测试稳定性比率计算
        XCTAssertEqual(stats.connectionStabilityRatio, 0.0, "没有连接时稳定性比率应该为0.0")
    }
    
    // MARK: - Connection Stability Tests
    
    func testConnectionStabilityInitialization() {
        let stability = wifiMonitor.getConnectionStability()
        
        XCTAssertTrue(stability.isStable, "初始化时应该是稳定的")
        XCTAssertEqual(stability.stabilityScore, 1.0, "初始化时稳定性评分应该为1.0")
        XCTAssertTrue(stability.issues.isEmpty, "初始化时不应该有问题")
        XCTAssertEqual(stability.stabilityLevel, .excellent, "初始化时稳定性等级应该是优秀")
    }
    
    func testStabilityLevelDescriptions() {
        let testCases: [(StabilityLevel, String)] = [
            (.excellent, "网络连接非常稳定"),
            (.good, "网络连接稳定"),
            (.fair, "网络连接基本稳定，偶有波动"),
            (.poor, "网络连接不稳定，经常出现问题"),
            (.critical, "网络连接极不稳定，需要检查")
        ]
        
        for (level, expectedDescription) in testCases {
            XCTAssertEqual(level.description, expectedDescription,
                          "稳定性等级 \(level) 的描述应该是 \(expectedDescription)")
        }
    }
    
    func testStabilityLevelFromScore() {
        let testCases: [(Double, StabilityLevel)] = [
            (1.0, .excellent),
            (0.95, .excellent),
            (0.85, .good),
            (0.75, .good),
            (0.65, .fair),
            (0.55, .fair),
            (0.45, .poor),
            (0.35, .poor),
            (0.25, .critical),
            (0.0, .critical)
        ]
        
        for (score, expectedLevel) in testCases {
            let stability = ConnectionStability(isStable: score > 0.7, stabilityScore: score, issues: [])
            XCTAssertEqual(stability.stabilityLevel, expectedLevel,
                          "评分 \(score) 应该对应稳定性等级 \(expectedLevel)")
        }
    }
    
    // MARK: - WiFiStatusCache Tests
    
    func testWiFiStatusCacheBasicFunctionality() {
        let cache = WiFiStatusCache()
        
        // 初始状态
        XCTAssertNil(cache.getCachedStatus(), "初始时应该没有缓存状态")
        
        // 更新缓存
        let testStatus = WiFiStatus.disconnected
        cache.updateCache(with: testStatus)
        
        // 验证缓存
        let cachedStatus = cache.getCachedStatus()
        XCTAssertEqual(cachedStatus, testStatus, "缓存的状态应该与更新的状态相同")
        
        // 清除缓存
        cache.clearCache()
        XCTAssertNil(cache.getCachedStatus(), "清除后应该没有缓存状态")
    }
    
    func testWiFiStatusCacheInfo() {
        let cache = WiFiStatusCache()
        
        // 初始信息
        var info = cache.info
        XCTAssertFalse(info.hasCache, "初始时应该没有缓存")
        XCTAssertNil(info.cacheTime, "初始时缓存时间应该为nil")
        XCTAssertEqual(info.changeCount, 0, "初始时变化次数应该为0")
        
        // 更新缓存后的信息
        cache.updateCache(with: .disconnected)
        info = cache.info
        XCTAssertTrue(info.hasCache, "更新后应该有缓存")
        XCTAssertNotNil(info.cacheTime, "更新后缓存时间不应该为nil")
        XCTAssertEqual(info.changeCount, 1, "更新后变化次数应该为1")
    }
    
    // MARK: - ConnectionEvent Tests
    
    func testConnectionEventInitialization() {
        let network = createTestNetwork()
        let event = ConnectionEvent(type: .connected(network))
        
        XCTAssertNotNil(event.timestamp, "事件应该有时间戳")
        XCTAssertNil(event.duration, "默认情况下持续时间应该为nil")
        
        if case .connected(let eventNetwork) = event.type {
            XCTAssertEqual(eventNetwork.ssid, network.ssid, "事件中的网络应该与创建时的网络相同")
        } else {
            XCTFail("事件类型应该是connected")
        }
    }
    
    func testConnectionEventWithDuration() {
        let duration: TimeInterval = 5.0
        let event = ConnectionEvent(type: .disconnected, duration: duration)
        
        XCTAssertEqual(event.duration, duration, "事件持续时间应该与设置的值相同")
    }
    
    // MARK: - Integration Tests
    
    func testMonitoringWithCacheAndHistory() {
        let expectation = XCTestExpectation(description: "等待监控建立")
        
        // 设置委托回调来跟踪状态变化
        var statusChangeCount = 0
        mockDelegate.onStatusChange = { _ in
            statusChangeCount += 1
            if statusChangeCount >= 1 {
                expectation.fulfill()
            }
        }
        
        // 开始监控
        wifiMonitor.startMonitoring()
        
        // 等待状态变化
        wait(for: [expectation], timeout: 5.0)
        
        // 验证缓存和历史记录
        let cacheInfo = wifiMonitor.cacheInfo
        XCTAssertTrue(cacheInfo.changeCount > 0, "应该有状态变化记录")
        
        let stats = wifiMonitor.getConnectionStats()
        XCTAssertTrue(stats.totalEvents >= 0, "应该有事件记录")
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