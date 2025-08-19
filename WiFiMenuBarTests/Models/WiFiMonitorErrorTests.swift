import XCTest
@testable import WiFiMenuBar

/// WiFiMonitorError错误类型的单元测试
final class WiFiMonitorErrorTests: XCTestCase {
    
    // MARK: - Error Description Tests
    
    func testErrorDescriptions() {
        let testCases: [(WiFiMonitorError, String)] = [
            (.permissionDenied, "需要网络访问权限"),
            (.networkUnavailable, "网络服务不可用"),
            (.hardwareError, "WiFi硬件错误"),
            (.coreWLANError(123), "CoreWLAN错误 (代码: 123)"),
            (.timeout, "获取WiFi信息超时"),
            (.invalidConfiguration, "无效的网络配置"),
            (.unsupportedSystem, "系统版本不支持此功能"),
            (.unknownError("测试错误"), "未知错误: 测试错误")
        ]
        
        for (error, expectedDescription) in testCases {
            XCTAssertEqual(error.localizedDescription, expectedDescription,
                          "错误 \(error) 的描述应该是 \(expectedDescription)")
        }
    }
    
    func testNetworkFrameworkError() {
        let underlyingError = NSError(domain: "TestDomain", code: 999, userInfo: [
            NSLocalizedDescriptionKey: "测试底层错误"
        ])
        let wifiError = WiFiMonitorError.networkFrameworkError(underlyingError)
        
        XCTAssertEqual(wifiError.localizedDescription, "网络框架错误: 测试底层错误")
    }
    
    // MARK: - Failure Reason Tests
    
    func testFailureReasons() {
        let testCases: [(WiFiMonitorError, String)] = [
            (.permissionDenied, "应用没有获得访问网络信息的权限"),
            (.networkUnavailable, "系统网络服务当前不可用或已关闭"),
            (.hardwareError, "WiFi硬件可能已损坏或被禁用"),
            (.coreWLANError(123), "CoreWLAN框架内部发生错误"),
            (.timeout, "网络信息获取操作超时"),
            (.invalidConfiguration, "网络配置参数无效或不完整"),
            (.unsupportedSystem, "当前macOS版本不支持所需的网络API"),
            (.unknownError("测试"), "发生了未预期的错误")
        ]
        
        for (error, expectedReason) in testCases {
            XCTAssertEqual(error.failureReason, expectedReason,
                          "错误 \(error) 的失败原因应该是 \(expectedReason)")
        }
    }
    
    // MARK: - Recovery Suggestion Tests
    
    func testRecoverySuggestions() {
        let permissionError = WiFiMonitorError.permissionDenied
        XCTAssertTrue(permissionError.recoverySuggestion?.contains("系统偏好设置") == true)
        
        let networkError = WiFiMonitorError.networkUnavailable
        XCTAssertTrue(networkError.recoverySuggestion?.contains("检查网络设置") == true)
        
        let hardwareError = WiFiMonitorError.hardwareError
        XCTAssertTrue(hardwareError.recoverySuggestion?.contains("重启WiFi") == true)
        
        let systemError = WiFiMonitorError.unsupportedSystem
        XCTAssertTrue(systemError.recoverySuggestion?.contains("升级到macOS") == true)
    }
    
    // MARK: - Error Code Tests
    
    func testErrorCodes() {
        let testCases: [(WiFiMonitorError, Int)] = [
            (.permissionDenied, 1001),
            (.networkUnavailable, 1002),
            (.hardwareError, 1003),
            (.coreWLANError(123), 2123), // 2000 + 123
            (.networkFrameworkError(NSError(domain: "test", code: 0)), 3001),
            (.timeout, 4001),
            (.invalidConfiguration, 5001),
            (.unsupportedSystem, 6001),
            (.unknownError("test"), 9999)
        ]
        
        for (error, expectedCode) in testCases {
            XCTAssertEqual(error.errorCode, expectedCode,
                          "错误 \(error) 的错误代码应该是 \(expectedCode)")
        }
    }
    
    // MARK: - Error Domain Test
    
    func testErrorDomain() {
        let error = WiFiMonitorError.permissionDenied
        XCTAssertEqual(WiFiMonitorError.errorDomain, "com.wifimenubar.WiFiMonitorError")
    }
    
    // MARK: - Error UserInfo Tests
    
    func testErrorUserInfo() {
        let error = WiFiMonitorError.permissionDenied
        let userInfo = error.errorUserInfo
        
        XCTAssertEqual(userInfo[NSLocalizedDescriptionKey] as? String, "需要网络访问权限")
        XCTAssertEqual(userInfo[NSLocalizedFailureReasonErrorKey] as? String, 
                      "应用没有获得访问网络信息的权限")
        XCTAssertNotNil(userInfo[NSLocalizedRecoverySuggestionErrorKey])
    }
    
    // MARK: - Convenience Methods Tests
    
    func testIsRetryable() {
        // 可重试的错误
        let retryableErrors: [WiFiMonitorError] = [
            .networkUnavailable,
            .timeout,
            .coreWLANError(123),
            .networkFrameworkError(NSError(domain: "test", code: 0)),
            .unknownError("test")
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "错误 \(error) 应该是可重试的")
        }
        
        // 不可重试的错误
        let nonRetryableErrors: [WiFiMonitorError] = [
            .permissionDenied,
            .hardwareError,
            .unsupportedSystem,
            .invalidConfiguration
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "错误 \(error) 应该是不可重试的")
        }
    }
    
    func testRequiresUserIntervention() {
        // 需要用户干预的错误
        let userInterventionErrors: [WiFiMonitorError] = [
            .permissionDenied,
            .hardwareError,
            .unsupportedSystem
        ]
        
        for error in userInterventionErrors {
            XCTAssertTrue(error.requiresUserIntervention, 
                         "错误 \(error) 应该需要用户干预")
        }
        
        // 不需要用户干预的错误
        let noUserInterventionErrors: [WiFiMonitorError] = [
            .networkUnavailable,
            .coreWLANError(123),
            .networkFrameworkError(NSError(domain: "test", code: 0)),
            .timeout,
            .invalidConfiguration,
            .unknownError("test")
        ]
        
        for error in noUserInterventionErrors {
            XCTAssertFalse(error.requiresUserIntervention, 
                          "错误 \(error) 应该不需要用户干预")
        }
    }
    
    func testSeverity() {
        let testCases: [(WiFiMonitorError, ErrorSeverity)] = [
            (.permissionDenied, .critical),
            (.unsupportedSystem, .critical),
            (.hardwareError, .high),
            (.networkUnavailable, .high),
            (.coreWLANError(123), .medium),
            (.networkFrameworkError(NSError(domain: "test", code: 0)), .medium),
            (.invalidConfiguration, .medium),
            (.timeout, .low),
            (.unknownError("test"), .low)
        ]
        
        for (error, expectedSeverity) in testCases {
            XCTAssertEqual(error.severity, expectedSeverity,
                          "错误 \(error) 的严重程度应该是 \(expectedSeverity)")
        }
    }
    
    // MARK: - ErrorSeverity Tests
    
    func testErrorSeverityDescription() {
        let testCases: [(ErrorSeverity, String)] = [
            (.low, "轻微"),
            (.medium, "中等"),
            (.high, "严重"),
            (.critical, "致命")
        ]
        
        for (severity, expectedDescription) in testCases {
            XCTAssertEqual(severity.description, expectedDescription,
                          "严重程度 \(severity) 的描述应该是 \(expectedDescription)")
        }
    }
    
    func testErrorSeverityRawValue() {
        XCTAssertEqual(ErrorSeverity.low.rawValue, 1)
        XCTAssertEqual(ErrorSeverity.medium.rawValue, 2)
        XCTAssertEqual(ErrorSeverity.high.rawValue, 3)
        XCTAssertEqual(ErrorSeverity.critical.rawValue, 4)
    }
    
    func testErrorSeverityAllCases() {
        let allCases = ErrorSeverity.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.critical))
    }
}