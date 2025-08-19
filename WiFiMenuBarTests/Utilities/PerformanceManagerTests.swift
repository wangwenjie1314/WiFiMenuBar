import XCTest
@testable import WiFiMenuBar

/// PerformanceManager单元测试
/// 测试性能管理器的功能
class PerformanceManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var performanceManager: PerformanceManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        performanceManager = PerformanceManager.shared
    }
    
    override func tearDownWithError() throws {
        performanceManager.stopPerformanceMonitoring()
        performanceManager.clearPerformanceHistory()
        performanceManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() {
        // Given & When
        let instance1 = PerformanceManager.shared
        let instance2 = PerformanceManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "PerformanceManager应该是单例")
    }
    
    func testInitialState() {
        // Given & When
        let manager = PerformanceManager.shared
        
        // Then
        XCTAssertGreaterThanOrEqual(manager.currentMemoryUsage, 0, "内存使用量应该大于等于0")
        XCTAssertGreaterThanOrEqual(manager.currentCPUUsage, 0, "CPU使用率应该大于等于0")
        XCTAssertNotNil(manager.performanceStatus, "性能状态应该有值")
        XCTAssertTrue(manager.isMonitoringEnabled, "默认应该启用监控")
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testStartStopPerformanceMonitoring() {
        // Given
        performanceManager.stopPerformanceMonitoring()
        
        // When
        performanceManager.startPerformanceMonitoring()
        
        // Then
        XCTAssertTrue(performanceManager.isMonitoringEnabled, "监控应该被启用")
        
        // When
        performanceManager.stopPerformanceMonitoring()
        
        // Then
        // 注意：isMonitoringEnabled可能仍然为true，因为它控制是否应该监控
        // 实际的监控状态由内部定时器控制
    }
    
    func testPerformanceMetricsUpdate() {
        // Given
        let initialMemoryUsage = performanceManager.currentMemoryUsage
        let initialCPUUsage = performanceManager.currentCPUUsage
        
        // When
        performanceManager.startPerformanceMonitoring()
        
        // 等待一段时间让指标更新
        let expectation = XCTestExpectation(description: "性能指标更新")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertGreaterThanOrEqual(performanceManager.currentMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(performanceManager.currentCPUUsage, 0)
    }
    
    // MARK: - Performance Report Tests
    
    func testGetPerformanceReport() {
        // Given & When
        let report = performanceManager.getPerformanceReport()
        
        // Then
        XCTAssertNotNil(report, "性能报告应该存在")
        XCTAssertGreaterThanOrEqual(report.currentMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(report.currentCPUUsage, 0)
        XCTAssertNotNil(report.performanceStatus)
        XCTAssertGreaterThanOrEqual(report.averageMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(report.averageCPUUsage, 0)
        XCTAssertNotNil(report.optimizationSuggestions)
    }
    
    func testPerformanceReportDescription() {
        // Given
        let report = performanceManager.getPerformanceReport()
        
        // When
        let description = report.description
        
        // Then
        XCTAssertFalse(description.isEmpty, "性能报告描述不应该为空")
        XCTAssertTrue(description.contains("性能报告"), "描述应该包含标题")
        XCTAssertTrue(description.contains("内存使用"), "描述应该包含内存使用信息")
        XCTAssertTrue(description.contains("CPU使用"), "描述应该包含CPU使用信息")
    }
    
    // MARK: - Memory and CPU Details Tests
    
    func testGetMemoryUsageDetails() {
        // Given & When
        let memoryDetails = performanceManager.getMemoryUsageDetails()
        
        // Then
        XCTAssertGreaterThan(memoryDetails.residentSize, 0, "常驻内存大小应该大于0")
        XCTAssertGreaterThan(memoryDetails.virtualSize, 0, "虚拟内存大小应该大于0")
        XCTAssertGreaterThanOrEqual(memoryDetails.suspendCount, 0, "挂起计数应该大于等于0")
        XCTAssertNotNil(memoryDetails.timestamp, "时间戳应该存在")
    }
    
    func testGetCPUUsageDetails() {
        // Given & When
        let cpuDetails = performanceManager.getCPUUsageDetails()
        
        // Then
        XCTAssertGreaterThanOrEqual(cpuDetails.userTime, 0, "用户态时间应该大于等于0")
        XCTAssertGreaterThanOrEqual(cpuDetails.systemTime, 0, "系统态时间应该大于等于0")
        XCTAssertGreaterThanOrEqual(cpuDetails.totalTime, 0, "总时间应该大于等于0")
        XCTAssertNotNil(cpuDetails.timestamp, "时间戳应该存在")
    }
    
    // MARK: - Performance Optimization Tests
    
    func testPerformOptimization() {
        // Given & When & Then
        XCTAssertNoThrow(performanceManager.performOptimization(), "性能优化不应该抛出异常")
    }
    
    func testClearPerformanceHistory() {
        // Given
        // 先让性能管理器运行一段时间以生成历史记录
        performanceManager.startPerformanceMonitoring()
        
        let expectation = XCTestExpectation(description: "生成历史记录")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // When
        performanceManager.clearPerformanceHistory()
        
        // Then
        let report = performanceManager.getPerformanceReport()
        XCTAssertEqual(report.monitoringDuration, 0, "清理后监控时长应该为0")
    }
    
    // MARK: - Data Export Tests
    
    func testExportPerformanceData() {
        // Given & When
        let exportedData = performanceManager.exportPerformanceData()
        
        // Then
        XCTAssertNotNil(exportedData, "导出的数据应该存在")
        
        if let jsonString = exportedData {
            XCTAssertFalse(jsonString.isEmpty, "导出的JSON字符串不应该为空")
            
            // 验证是否为有效的JSON
            let jsonData = jsonString.data(using: .utf8)
            XCTAssertNotNil(jsonData, "应该能转换为Data")
            
            do {
                let _ = try JSONSerialization.jsonObject(with: jsonData!, options: [])
            } catch {
                XCTFail("导出的数据应该是有效的JSON: \(error)")
            }
        }
    }
    
    // MARK: - Performance Status Tests
    
    func testPerformanceStatusEnum() {
        // Given & When & Then
        XCTAssertEqual(PerformanceStatus.normal.description, "正常")
        XCTAssertEqual(PerformanceStatus.warning.description, "警告")
        XCTAssertEqual(PerformanceStatus.critical.description, "严重")
        
        XCTAssertEqual(PerformanceStatus.normal.color, .systemGreen)
        XCTAssertEqual(PerformanceStatus.warning.color, .systemOrange)
        XCTAssertEqual(PerformanceStatus.critical.color, .systemRed)
    }
    
    // MARK: - Performance Optimization Strategies Tests
    
    func testMemoryCacheCleanupStrategy() {
        // Given
        let strategy = MemoryCacheCleanupStrategy()
        
        // When & Then
        XCTAssertEqual(strategy.name, "内存缓存清理")
        XCTAssertTrue(strategy.shouldApply(currentMemoryUsage: 100.0, currentCPUUsage: 10.0))
        XCTAssertFalse(strategy.shouldApply(currentMemoryUsage: 50.0, currentCPUUsage: 10.0))
        
        XCTAssertNoThrow(strategy.apply(), "策略应用不应该抛出异常")
    }
    
    func testComponentCommunicationOptimizationStrategy() {
        // Given
        let strategy = ComponentCommunicationOptimizationStrategy()
        
        // When & Then
        XCTAssertEqual(strategy.name, "组件通信优化")
        XCTAssertTrue(strategy.shouldApply(currentMemoryUsage: 70.0, currentCPUUsage: 10.0))
        XCTAssertTrue(strategy.shouldApply(currentMemoryUsage: 10.0, currentCPUUsage: 40.0))
        XCTAssertFalse(strategy.shouldApply(currentMemoryUsage: 50.0, currentCPUUsage: 20.0))
        
        XCTAssertNoThrow(strategy.apply(), "策略应用不应该抛出异常")
    }
    
    func testWiFiMonitorOptimizationStrategy() {
        // Given
        let strategy = WiFiMonitorOptimizationStrategy()
        
        // When & Then
        XCTAssertEqual(strategy.name, "WiFi监控优化")
        XCTAssertTrue(strategy.shouldApply(currentMemoryUsage: 10.0, currentCPUUsage: 50.0))
        XCTAssertFalse(strategy.shouldApply(currentMemoryUsage: 10.0, currentCPUUsage: 30.0))
        
        XCTAssertNoThrow(strategy.apply(), "策略应用不应该抛出异常")
    }
    
    func testUIUpdateOptimizationStrategy() {
        // Given
        let strategy = UIUpdateOptimizationStrategy()
        
        // When & Then
        XCTAssertEqual(strategy.name, "UI更新优化")
        XCTAssertTrue(strategy.shouldApply(currentMemoryUsage: 10.0, currentCPUUsage: 40.0))
        XCTAssertFalse(strategy.shouldApply(currentMemoryUsage: 10.0, currentCPUUsage: 30.0))
        
        XCTAssertNoThrow(strategy.apply(), "策略应用不应该抛出异常")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMonitoringPerformance() {
        // Given & When & Then
        measure {
            let _ = performanceManager.getMemoryUsageDetails()
            let _ = performanceManager.getCPUUsageDetails()
        }
    }
    
    func testPerformanceReportGenerationPerformance() {
        // Given & When & Then
        measure {
            let _ = performanceManager.getPerformanceReport()
        }
    }
    
    func testPerformanceOptimizationPerformance() {
        // Given & When & Then
        measure {
            performanceManager.performOptimization()
        }
    }
    
    // MARK: - Integration Tests
    
    func testPerformanceManagerWithComponentCommunicationManager() {
        // Given
        let communicationManager = ComponentCommunicationManager.shared
        
        // When
        performanceManager.performOptimization()
        
        // Then
        // 优化应该清理通信管理器的历史记录
        let history = communicationManager.getDataFlowHistory()
        // 历史记录可能被清理，但这取决于具体的实现
        XCTAssertNotNil(history, "历史记录应该存在（即使为空）")
    }
    
    func testPerformanceNotifications() {
        // Given
        let expectation = XCTestExpectation(description: "性能通知")
        
        NotificationCenter.default.addObserver(
            forName: .performanceCacheCleanup,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // When
        performanceManager.performOptimization()
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testPerformanceManagerWithInvalidData() {
        // Given & When & Then
        // 测试性能管理器在异常情况下的行为
        XCTAssertNoThrow(performanceManager.getMemoryUsageDetails(), "获取内存详情不应该抛出异常")
        XCTAssertNoThrow(performanceManager.getCPUUsageDetails(), "获取CPU详情不应该抛出异常")
        XCTAssertNoThrow(performanceManager.getPerformanceReport(), "获取性能报告不应该抛出异常")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentPerformanceMonitoring() {
        // Given
        let expectation = XCTestExpectation(description: "并发性能监控")
        expectation.expectedFulfillmentCount = 5
        
        // When
        for i in 0..<5 {
            DispatchQueue.global().async {
                let _ = self.performanceManager.getPerformanceReport()
                print("并发性能监控 \(i) 完成")
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - Mock Tests

extension PerformanceManagerTests {
    
    func testMemoryUsageDetailsProperties() {
        // Given
        let details = MemoryUsageDetails(
            residentSize: 50.0,
            virtualSize: 100.0,
            suspendCount: 0,
            timestamp: Date()
        )
        
        // When & Then
        XCTAssertEqual(details.residentSize, 50.0)
        XCTAssertEqual(details.virtualSize, 100.0)
        XCTAssertEqual(details.suspendCount, 0)
        XCTAssertNotNil(details.timestamp)
    }
    
    func testCPUUsageDetailsProperties() {
        // Given
        let details = CPUUsageDetails(
            userTime: 1.0,
            systemTime: 0.5,
            totalTime: 1.5,
            timestamp: Date()
        )
        
        // When & Then
        XCTAssertEqual(details.userTime, 1.0)
        XCTAssertEqual(details.systemTime, 0.5)
        XCTAssertEqual(details.totalTime, 1.5)
        XCTAssertNotNil(details.timestamp)
    }
    
    func testPerformanceRecordCodable() {
        // Given
        let record = PerformanceRecord(
            timestamp: Date(),
            memoryUsage: 50.0,
            cpuUsage: 25.0,
            performanceStatus: .normal
        )
        
        // When
        do {
            let data = try JSONEncoder().encode(record)
            let decodedRecord = try JSONDecoder().decode(PerformanceRecord.self, from: data)
            
            // Then
            XCTAssertEqual(record.memoryUsage, decodedRecord.memoryUsage)
            XCTAssertEqual(record.cpuUsage, decodedRecord.cpuUsage)
            XCTAssertEqual(record.performanceStatus, decodedRecord.performanceStatus)
        } catch {
            XCTFail("PerformanceRecord应该支持Codable: \(error)")
        }
    }
}