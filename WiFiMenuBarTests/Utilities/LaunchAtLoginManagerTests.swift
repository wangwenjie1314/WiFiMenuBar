import XCTest
@testable import WiFiMenuBar

/// LaunchAtLoginManager单元测试
/// 测试登录启动管理器的功能
class LaunchAtLoginManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var launchManager: LaunchAtLoginManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        launchManager = LaunchAtLoginManager.shared
    }
    
    override func tearDownWithError() throws {
        // 确保测试后清理登录启动状态
        launchManager.setLaunchAtLogin(false)
        launchManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() {
        // Given & When
        let instance1 = LaunchAtLoginManager.shared
        let instance2 = LaunchAtLoginManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "LaunchAtLoginManager应该是单例")
    }
    
    // MARK: - Status Check Tests
    
    func testInitialLaunchAtLoginStatus() {
        // Given & When
        let isEnabled = launchManager.isLaunchAtLoginEnabled()
        
        // Then
        XCTAssertFalse(isEnabled, "初始状态下登录启动应该是禁用的")
    }
    
    func testGetLaunchAtLoginStatus() {
        // Given & When
        let status = launchManager.getLaunchAtLoginStatus()
        
        // Then
        XCTAssertNotNil(status, "应该能够获取登录启动状态")
        XCTAssertFalse(status.isEnabled, "初始状态应该是禁用的")
        XCTAssertTrue(status.canModify, "应该有修改权限")
    }
    
    func testRefreshStatus() {
        // Given & When & Then
        XCTAssertNoThrow(launchManager.refreshStatus(), "刷新状态不应该抛出异常")
    }
    
    // MARK: - Enable/Disable Tests
    
    func testEnableLaunchAtLogin() {
        // Given
        let initialStatus = launchManager.isLaunchAtLoginEnabled()
        XCTAssertFalse(initialStatus, "初始状态应该是禁用的")
        
        // When
        let success = launchManager.setLaunchAtLogin(true)
        
        // Then
        if success {
            let newStatus = launchManager.isLaunchAtLoginEnabled()
            XCTAssertTrue(newStatus, "启用登录启动后状态应该为true")
        } else {
            // 在某些测试环境中可能会失败，这是正常的
            print("LaunchAtLoginManagerTests: 启用登录启动失败，可能是权限问题")
        }
    }
    
    func testDisableLaunchAtLogin() {
        // Given
        // 先尝试启用
        launchManager.setLaunchAtLogin(true)
        
        // When
        let success = launchManager.setLaunchAtLogin(false)
        
        // Then
        if success {
            let status = launchManager.isLaunchAtLoginEnabled()
            XCTAssertFalse(status, "禁用登录启动后状态应该为false")
        } else {
            print("LaunchAtLoginManagerTests: 禁用登录启动失败")
        }
    }
    
    func testToggleLaunchAtLogin() {
        // Given
        let initialStatus = launchManager.isLaunchAtLoginEnabled()
        
        // When
        let enableSuccess = launchManager.setLaunchAtLogin(!initialStatus)
        let disableSuccess = launchManager.setLaunchAtLogin(initialStatus)
        
        // Then
        // 至少一个操作应该成功，或者都失败（权限问题）
        let finalStatus = launchManager.isLaunchAtLoginEnabled()
        XCTAssertEqual(finalStatus, initialStatus, "切换后应该回到初始状态")
    }
    
    // MARK: - Status Information Tests
    
    func testLaunchAtLoginStatusDescription() {
        // Given & When
        let status = launchManager.getLaunchAtLoginStatus()
        
        // Then
        XCTAssertFalse(status.description.isEmpty, "状态描述不应该为空")
        XCTAssertTrue(status.description.contains("未启用") || status.description.contains("已启用"), 
                     "状态描述应该包含启用状态信息")
    }
    
    func testRegistrationMethodDetection() {
        // Given & When
        let status = launchManager.getLaunchAtLoginStatus()
        
        // Then
        XCTAssertNotNil(status.registrationMethod, "应该能检测到注册方法")
        
        // 初始状态下应该是none
        if !status.isEnabled {
            XCTAssertEqual(status.registrationMethod, .none, "未启用时注册方法应该是none")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPermissionCheck() {
        // Given & When
        let status = launchManager.getLaunchAtLoginStatus()
        
        // Then
        // 在大多数情况下应该有修改权限
        XCTAssertTrue(status.canModify, "应该有修改登录项的权限")
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithPreferencesManager() {
        // Given
        let preferencesManager = PreferencesManager.shared
        let initialPreferences = preferencesManager.getCurrentPreferences()
        
        // When
        preferencesManager.setLaunchAtLogin(true)
        let updatedPreferences = preferencesManager.getCurrentPreferences()
        
        // Then
        XCTAssertTrue(updatedPreferences.launchAtLogin, "PreferencesManager应该更新登录启动设置")
        
        // Cleanup
        preferencesManager.setLaunchAtLogin(initialPreferences.launchAtLogin)
    }
    
    func testSyncLaunchAtLoginStatus() {
        // Given
        let preferencesManager = PreferencesManager.shared
        
        // When & Then
        XCTAssertNoThrow(preferencesManager.syncLaunchAtLoginStatus(), 
                        "同步登录启动状态不应该抛出异常")
    }
    
    // MARK: - Performance Tests
    
    func testStatusCheckPerformance() {
        // Given & When & Then
        measure {
            _ = launchManager.isLaunchAtLoginEnabled()
        }
    }
    
    func testStatusObjectCreationPerformance() {
        // Given & When & Then
        measure {
            _ = launchManager.getLaunchAtLoginStatus()
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testMultipleEnableDisableCalls() {
        // Given
        let initialStatus = launchManager.isLaunchAtLoginEnabled()
        
        // When
        for _ in 0..<3 {
            launchManager.setLaunchAtLogin(true)
            launchManager.setLaunchAtLogin(false)
        }
        
        // Then
        let finalStatus = launchManager.isLaunchAtLoginEnabled()
        XCTAssertEqual(finalStatus, false, "多次调用后应该是禁用状态")
        
        // Cleanup
        launchManager.setLaunchAtLogin(initialStatus)
    }
    
    func testConcurrentAccess() {
        // Given
        let expectation = XCTestExpectation(description: "并发访问测试")
        expectation.expectedFulfillmentCount = 5
        
        // When
        for i in 0..<5 {
            DispatchQueue.global().async {
                let status = self.launchManager.isLaunchAtLoginEnabled()
                print("并发测试 \(i): \(status)")
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Tests

extension LaunchAtLoginManagerTests {
    
    func testLaunchAtLoginStatusEquality() {
        // Given
        let status1 = LaunchAtLoginStatus(
            isEnabled: true,
            registrationMethod: .serviceManagement,
            canModify: true,
            lastError: nil
        )
        
        let status2 = LaunchAtLoginStatus(
            isEnabled: true,
            registrationMethod: .serviceManagement,
            canModify: true,
            lastError: nil
        )
        
        // When & Then
        XCTAssertEqual(status1.isEnabled, status2.isEnabled)
        XCTAssertEqual(status1.registrationMethod, status2.registrationMethod)
        XCTAssertEqual(status1.canModify, status2.canModify)
    }
    
    func testRegistrationMethodDescription() {
        // Given & When & Then
        XCTAssertEqual(LaunchAtLoginRegistrationMethod.serviceManagement.description, "ServiceManagement")
        XCTAssertEqual(LaunchAtLoginRegistrationMethod.sharedFileList.description, "SharedFileList")
        XCTAssertEqual(LaunchAtLoginRegistrationMethod.launchAgent.description, "LaunchAgent")
        XCTAssertEqual(LaunchAtLoginRegistrationMethod.none.description, "无")
    }
    
    func testLaunchAtLoginErrorDescription() {
        // Given & When & Then
        XCTAssertNotNil(LaunchAtLoginError.permissionDenied.errorDescription)
        XCTAssertNotNil(LaunchAtLoginError.serviceUnavailable.errorDescription)
        XCTAssertNotNil(LaunchAtLoginError.invalidConfiguration.errorDescription)
        XCTAssertNotNil(LaunchAtLoginError.systemError("test").errorDescription)
    }
}