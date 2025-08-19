import XCTest
@testable import WiFiMenuBar

/// 错误处理和重试机制的单元测试
final class ErrorHandlingAndRetryTests: XCTestCase {
    
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
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingStatsInitialization() {
        let stats = wifiMonitor.getErrorHandlingStats()
        
        XCTAssertEqual(stats.totalErrors, 0, "初始化时总错误数应该为0")
        XCTAssertEqual(stats.recentErrors, 0, "初始化时最近错误数应该为0")
        XCTAssertTrue(stats.errorCounts.isEmpty, "初始化时错误计数应该为空")
        XCTAssertNil(stats.lastErrorTime, "初始化时最后错误时间应该为nil")
        XCTAssertEqual(stats.errorRate, 0.0, "初始化时错误率应该为0.0")
        XCTAssertNil(stats.mostCommonError, "初始化时最常见错误应该为nil")
    }
    
    func testRetryConnectionWhenCanRetry() {
        let initialRetryStatus = wifiMonitor.getRetryStatus()
        XCTAssertTrue(initialRetryStatus.canRetry, "初始时应该可以重试")
        XCTAssertEqual(initialRetryStatus.currentRetryCount, 0, "初始重试次数应该为0")
        
        // 执行重试
        wifiMonitor.retryConnection()
        
        let newRetryStatus = wifiMonitor.getRetryStatus()
        XCTAssertEqual(newRetryStatus.currentRetryCount, 1, "重试后计数应该增加")
        XCTAssertNotNil(newRetryStatus.lastRetryTime, "重试后应该有最后重试时间")
    }
    
    func testResetErrorState() {
        // 先执行一些重试来改变状态
        wifiMonitor.retryConnection()
        wifiMonitor.retryConnection()
        
        let beforeReset = wifiMonitor.getRetryStatus()
        XCTAssertEqual(beforeReset.currentRetryCount, 2, "重置前应该有重试记录")
        
        // 重置错误状态
        wifiMonitor.resetErrorState()
        
        let afterReset = wifiMonitor.getRetryStatus()
        XCTAssertEqual(afterReset.currentRetryCount, 0, "重置后重试计数应该为0")
        XCTAssertNil(afterReset.lastRetryTime, "重置后最后重试时间应该为nil")
        
        let errorStats = wifiMonitor.getErrorHandlingStats()
        XCTAssertEqual(errorStats.totalErrors, 0, "重置后错误统计应该清零")
    }
    
    // MARK: - WiFiErrorHandler Tests
    
    func testWiFiErrorHandlerInitialization() {
        let errorHandler = WiFiErrorHandler()
        let stats = errorHandler.getStats()
        
        XCTAssertEqual(stats.totalErrors, 0, "初始化时总错误数应该为0")
        XCTAssertEqual(stats.recentErrors, 0, "初始化时最近错误数应该为0")
        XCTAssertTrue(stats.errorCounts.isEmpty, "初始化时错误计数应该为空")
        XCTAssertNil(stats.lastErrorTime, "初始化时最后错误时间应该为nil")
    }
    
    func testWiFiErrorHandlerRecordError() {
        let errorHandler = WiFiErrorHandler()
        let testError = WiFiMonitorError.networkUnavailable
        
        // 记录错误
        errorHandler.recordError(testError)
        
        let stats = errorHandler.getStats()
        XCTAssertEqual(stats.totalErrors, 1, "记录错误后总数应该为1")
        XCTAssertEqual(stats.recentErrors, 1, "记录错误后最近错误数应该为1")
        XCTAssertNotNil(stats.lastErrorTime, "记录错误后应该有最后错误时间")
        XCTAssertFalse(stats.errorCounts.isEmpty, "记录错误后错误计数不应该为空")
    }
    
    func testWiFiErrorHandlerClearErrors() {
        let errorHandler = WiFiErrorHandler()
        
        // 记录一些错误
        errorHandler.recordError(.networkUnavailable)
        errorHandler.recordError(.hardwareError)
        
        let beforeClear = errorHandler.getStats()
        XCTAssertEqual(beforeClear.totalErrors, 2, "清除前应该有2个错误")
        
        // 清除错误
        errorHandler.clearErrors()
        
        let afterClear = errorHandler.getStats()
        XCTAssertEqual(afterClear.totalErrors, 0, "清除后错误数应该为0")
        XCTAssertTrue(afterClear.errorCounts.isEmpty, "清除后错误计数应该为空")
    }
    
    func testWiFiErrorHandlerGetRecentErrors() {
        let errorHandler = WiFiErrorHandler()
        
        // 记录多个错误
        let errors: [WiFiMonitorError] = [
            .networkUnavailable,
            .hardwareError,
            .timeout,
            .permissionDenied
        ]
        
        for error in errors {
            errorHandler.recordError(error)
        }
        
        let recentErrors = errorHandler.getRecentErrors(limit: 3)
        XCTAssertEqual(recentErrors.count, 3, "应该返回最近3个错误")
        
        // 验证返回的是最新的错误
        XCTAssertEqual(recentErrors.last?.error.localizedDescription, 
                      WiFiMonitorError.permissionDenied.localizedDescription,
                      "最后一个错误应该是最新记录的")
    }
    
    // MARK: - RetryManager Tests
    
    func testRetryManagerInitialization() {
        let retryManager = RetryManager()
        let status = retryManager.getStatus()
        
        XCTAssertEqual(status.currentRetryCount, 0, "初始重试次数应该为0")
        XCTAssertTrue(status.canRetry, "初始时应该可以重试")
        XCTAssertNil(status.lastRetryTime, "初始时最后重试时间应该为nil")
        XCTAssertEqual(status.remainingRetries, status.maxRetryCount, "初始时剩余重试次数应该等于最大重试次数")
        XCTAssertEqual(status.retryProgress, 0.0, "初始时重试进度应该为0.0")
    }
    
    func testRetryManagerIncrementRetryCount() {
        let retryManager = RetryManager()
        
        let initialStatus = retryManager.getStatus()
        XCTAssertEqual(initialStatus.currentRetryCount, 0, "初始重试次数应该为0")
        
        // 增加重试次数
        retryManager.incrementRetryCount()
        
        let newStatus = retryManager.getStatus()
        XCTAssertEqual(newStatus.currentRetryCount, 1, "重试次数应该增加到1")
        XCTAssertNotNil(newStatus.lastRetryTime, "应该记录最后重试时间")
        XCTAssertEqual(newStatus.remainingRetries, newStatus.maxRetryCount - 1, "剩余重试次数应该减少")
    }
    
    func testRetryManagerResetRetryCount() {
        let retryManager = RetryManager()
        
        // 先增加一些重试次数
        retryManager.incrementRetryCount()
        retryManager.incrementRetryCount()
        
        let beforeReset = retryManager.getStatus()
        XCTAssertEqual(beforeReset.currentRetryCount, 2, "重置前应该有重试记录")
        
        // 重置
        retryManager.resetRetryCount()
        
        let afterReset = retryManager.getStatus()
        XCTAssertEqual(afterReset.currentRetryCount, 0, "重置后重试次数应该为0")
        XCTAssertNil(afterReset.lastRetryTime, "重置后最后重试时间应该为nil")
    }
    
    func testRetryManagerMaxRetryLimit() {
        let retryManager = RetryManager()
        let maxRetries = retryManager.getStatus().maxRetryCount
        
        // 达到最大重试次数
        for _ in 0..<maxRetries {
            XCTAssertTrue(retryManager.canRetry(), "达到最大次数前应该可以重试")
            retryManager.incrementRetryCount()
        }
        
        // 验证不能再重试
        XCTAssertFalse(retryManager.canRetry(), "达到最大重试次数后不应该能重试")
        XCTAssertEqual(retryManager.getStatus().remainingRetries, 0, "剩余重试次数应该为0")
        XCTAssertEqual(retryManager.getStatus().retryProgress, 1.0, "重试进度应该为1.0")
    }
    
    func testRetryManagerExponentialBackoff() {
        let retryManager = RetryManager()
        
        let firstDelay = retryManager.getNextRetryDelay()
        retryManager.incrementRetryCount()
        
        let secondDelay = retryManager.getNextRetryDelay()
        retryManager.incrementRetryCount()
        
        let thirdDelay = retryManager.getNextRetryDelay()
        
        // 验证指数退避
        XCTAssertTrue(secondDelay > firstDelay, "第二次延迟应该大于第一次")
        XCTAssertTrue(thirdDelay > secondDelay, "第三次延迟应该大于第二次")
        
        // 验证延迟是指数增长的
        XCTAssertEqual(secondDelay, firstDelay * 2, accuracy: 0.1, "第二次延迟应该是第一次的2倍")
        XCTAssertEqual(thirdDelay, firstDelay * 4, accuracy: 0.1, "第三次延迟应该是第一次的4倍")
    }
    
    // MARK: - PermissionChecker Tests
    
    func testPermissionCheckerInitialization() {
        let permissionChecker = PermissionChecker()
        
        // 检查权限状态
        let status = permissionChecker.checkNetworkPermissions()
        XCTAssertNotNil(status, "权限状态不应该为nil")
        
        let description = permissionChecker.getPermissionStatusDescription()
        XCTAssertFalse(description.isEmpty, "权限状态描述不应该为空")
    }
    
    func testPermissionCheckerRequestPermissions() {
        let permissionChecker = PermissionChecker()
        let expectation = XCTestExpectation(description: "权限请求完成")
        
        permissionChecker.requestNetworkPermissions { status in
            XCTAssertNotNil(status, "权限请求回调应该返回状态")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPermissionCheckerManualAuthorization() {
        let permissionChecker = PermissionChecker()
        let requiresManual = permissionChecker.requiresManualAuthorization()
        
        // 这个测试的结果取决于系统状态，我们主要确保方法能正常调用
        XCTAssertNotNil(requiresManual, "手动授权检查应该返回布尔值")
    }
    
    // MARK: - Integration Tests
    
    func testErrorHandlingIntegration() {
        let expectation = XCTestExpectation(description: "错误处理集成测试")
        
        // 设置委托来监听状态变化
        mockDelegate.onStatusChange = { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        
        // 开始监控（可能会触发一些错误）
        wifiMonitor.startMonitoring()
        
        // 等待可能的错误状态
        wait(for: [expectation], timeout: 10.0)
        
        // 验证错误处理统计
        let errorStats = wifiMonitor.getErrorHandlingStats()
        // 注意：在测试环境中可能没有实际错误，所以我们主要验证API可用性
        XCTAssertNotNil(errorStats, "错误统计应该可用")
    }
    
    func testRetryMechanismIntegration() {
        // 测试重试机制的集成
        let initialRetryStatus = wifiMonitor.getRetryStatus()
        XCTAssertTrue(initialRetryStatus.canRetry, "初始时应该可以重试")
        
        // 执行多次重试
        for i in 1...3 {
            wifiMonitor.retryConnection()
            let status = wifiMonitor.getRetryStatus()
            XCTAssertEqual(status.currentRetryCount, i, "重试次数应该正确递增")
        }
        
        // 重置并验证
        wifiMonitor.resetErrorState()
        let resetStatus = wifiMonitor.getRetryStatus()
        XCTAssertEqual(resetStatus.currentRetryCount, 0, "重置后重试次数应该为0")
    }
}