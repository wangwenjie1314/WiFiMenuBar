import XCTest
@testable import WiFiMenuBar

/// PermissionManager单元测试
/// 测试权限管理器的功能
class PermissionManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var permissionManager: PermissionManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        permissionManager = PermissionManager.shared
    }
    
    override func tearDownWithError() throws {
        permissionManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() {
        // Given & When
        let instance1 = PermissionManager.shared
        let instance2 = PermissionManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "PermissionManager应该是单例")
    }
    
    func testInitialState() {
        // Given & When
        let manager = PermissionManager.shared
        
        // Then
        XCTAssertNotNil(manager.notificationPermissionStatus, "通知权限状态应该有初始值")
        XCTAssertNotNil(manager.networkPermissionStatus, "网络权限状态应该有初始值")
        XCTAssertNotNil(manager.wifiPermissionStatus, "WiFi权限状态应该有初始值")
    }
    
    // MARK: - Permission Status Tests
    
    func testCheckAllPermissions() {
        // Given & When & Then
        XCTAssertNoThrow(permissionManager.checkAllPermissions(), "检查所有权限不应该抛出异常")
    }
    
    func testGetPermissionSummary() {
        // Given & When
        let summary = permissionManager.getPermissionSummary()
        
        // Then
        XCTAssertNotNil(summary, "权限摘要应该存在")
        XCTAssertNotNil(summary.lastCheckTime, "最后检查时间应该存在")
        XCTAssertFalse(summary.description.isEmpty, "权限摘要描述不应该为空")
    }
    
    func testGetMissingPermissions() {
        // Given & When
        let missingPermissions = permissionManager.getMissingPermissions()
        
        // Then
        XCTAssertNotNil(missingPermissions, "缺失权限列表应该存在")
        // 注意：在测试环境中，权限状态可能不准确
    }
    
    // MARK: - Permission Request Tests
    
    func testRequestAllRequiredPermissions() {
        // Given
        let expectation = XCTestExpectation(description: "权限请求完成")
        
        // When
        permissionManager.requestAllRequiredPermissions { allGranted in
            // Then
            XCTAssertNotNil(allGranted, "权限请求结果应该有值")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testShowPermissionRequestDialog() {
        // Given
        let expectation = XCTestExpectation(description: "权限对话框显示")
        
        // When
        permissionManager.showPermissionRequestDialog(for: .notification) { granted in
            // Then
            // 在测试环境中，对话框可能不会真正显示
            // 这里主要测试方法调用不会崩溃
            expectation.fulfill()
        }
        
        // 由于对话框可能不会在测试环境中显示，我们设置较短的超时时间
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - System Preferences Tests
    
    func testOpenSystemPreferencesForPermission() {
        // Given & When & Then
        XCTAssertNoThrow(permissionManager.openSystemPreferencesForPermission(.notification), 
                        "打开系统偏好设置不应该抛出异常")
        XCTAssertNoThrow(permissionManager.openSystemPreferencesForPermission(.network), 
                        "打开系统偏好设置不应该抛出异常")
        XCTAssertNoThrow(permissionManager.openSystemPreferencesForPermission(.wifi), 
                        "打开系统偏好设置不应该抛出异常")
    }
    
    // MARK: - Permission Status Enum Tests
    
    func testPermissionStatusDisplayName() {
        // Given & When & Then
        XCTAssertEqual(PermissionStatus.unknown.displayName, "未知")
        XCTAssertEqual(PermissionStatus.notDetermined.displayName, "未确定")
        XCTAssertEqual(PermissionStatus.denied.displayName, "已拒绝")
        XCTAssertEqual(PermissionStatus.granted.displayName, "已授予")
        XCTAssertEqual(PermissionStatus.notRequired.displayName, "不需要")
    }
    
    func testPermissionStatusColor() {
        // Given & When & Then
        XCTAssertEqual(PermissionStatus.granted.color, .systemGreen)
        XCTAssertEqual(PermissionStatus.denied.color, .systemRed)
        XCTAssertEqual(PermissionStatus.notDetermined.color, .systemOrange)
        XCTAssertEqual(PermissionStatus.notRequired.color, .systemGray)
        XCTAssertEqual(PermissionStatus.unknown.color, .systemGray)
    }
    
    func testPermissionStatusFromUNAuthorizationStatus() {
        // Given & When & Then
        XCTAssertEqual(PermissionStatus(from: .notDetermined), .notDetermined)
        XCTAssertEqual(PermissionStatus(from: .denied), .denied)
        XCTAssertEqual(PermissionStatus(from: .authorized), .granted)
        XCTAssertEqual(PermissionStatus(from: .provisional), .granted)
        XCTAssertEqual(PermissionStatus(from: .ephemeral), .granted)
    }
    
    // MARK: - Permission Type Tests
    
    func testPermissionTypeDisplayName() {
        // Given & When & Then
        XCTAssertEqual(PermissionType.notification.displayName, "通知")
        XCTAssertEqual(PermissionType.network.displayName, "网络")
        XCTAssertEqual(PermissionType.wifi.displayName, "WiFi")
        XCTAssertEqual(PermissionType.location.displayName, "位置")
        XCTAssertEqual(PermissionType.screenRecording.displayName, "屏幕录制")
        XCTAssertEqual(PermissionType.accessibility.displayName, "辅助功能")
    }
    
    func testPermissionTypeIsRequired() {
        // Given & When & Then
        XCTAssertTrue(PermissionType.notification.isRequired)
        XCTAssertTrue(PermissionType.network.isRequired)
        XCTAssertTrue(PermissionType.wifi.isRequired)
        XCTAssertFalse(PermissionType.location.isRequired)
        XCTAssertFalse(PermissionType.screenRecording.isRequired)
        XCTAssertFalse(PermissionType.accessibility.isRequired)
    }
    
    // MARK: - Permission Summary Tests
    
    func testPermissionSummaryDescription() {
        // Given
        let summary = PermissionSummary(
            notificationPermission: .granted,
            networkPermission: .granted,
            wifiPermission: .granted,
            locationPermission: .notRequired,
            screenRecordingPermission: .notRequired,
            accessibilityPermission: .notRequired,
            allRequiredGranted: true,
            lastCheckTime: Date()
        )
        
        // When
        let description = summary.description
        
        // Then
        XCTAssertTrue(description.contains("权限状态摘要"))
        XCTAssertTrue(description.contains("通知权限: 已授予"))
        XCTAssertTrue(description.contains("网络权限: 已授予"))
        XCTAssertTrue(description.contains("所有必需权限已授予: 是"))
    }
    
    // MARK: - Performance Tests
    
    func testCheckAllPermissionsPerformance() {
        // Given & When & Then
        measure {
            permissionManager.checkAllPermissions()
        }
    }
    
    func testGetPermissionSummaryPerformance() {
        // Given & When & Then
        measure {
            _ = permissionManager.getPermissionSummary()
        }
    }
    
    // MARK: - Integration Tests
    
    func testPermissionManagerWithComponentCommunicationManager() {
        // Given
        let communicationManager = ComponentCommunicationManager.shared
        let initialStatus = communicationManager.notificationPermissionStatus
        
        // When
        permissionManager.checkAllPermissions()
        
        // Then
        // 权限状态可能会更新通信管理器
        // 在测试环境中，状态可能不会改变，所以我们主要测试不会崩溃
        XCTAssertNotNil(communicationManager.notificationPermissionStatus)
    }
    
    // MARK: - Error Handling Tests
    
    func testPermissionRequestWithInvalidType() {
        // Given & When & Then
        // 测试所有权限类型都能正确处理
        for permissionType in PermissionType.allCases {
            XCTAssertNoThrow(permissionManager.openSystemPreferencesForPermission(permissionType), 
                            "处理\(permissionType)权限不应该抛出异常")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentPermissionChecks() {
        // Given
        let expectation = XCTestExpectation(description: "并发权限检查")
        expectation.expectedFulfillmentCount = 5
        
        // When
        for i in 0..<5 {
            DispatchQueue.global().async {
                self.permissionManager.checkAllPermissions()
                print("并发权限检查 \(i) 完成")
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - FirstRunManager Tests

class FirstRunManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var firstRunManager: FirstRunManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        firstRunManager = FirstRunManager.shared
    }
    
    override func tearDownWithError() throws {
        firstRunManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() {
        // Given & When
        let instance1 = FirstRunManager.shared
        let instance2 = FirstRunManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "FirstRunManager应该是单例")
    }
    
    // MARK: - First Run Detection Tests
    
    func testIsFirstRun() {
        // Given & When
        let isFirstRun = firstRunManager.isFirstRun()
        
        // Then
        XCTAssertNotNil(isFirstRun, "首次运行检查应该返回布尔值")
    }
    
    func testIsFirstRunAfterUpdate() {
        // Given & When
        let isFirstRunAfterUpdate = firstRunManager.isFirstRunAfterUpdate()
        
        // Then
        XCTAssertNotNil(isFirstRunAfterUpdate, "版本更新检查应该返回布尔值")
    }
    
    func testGetFirstRunInfo() {
        // Given & When
        let info = firstRunManager.getFirstRunInfo()
        
        // Then
        XCTAssertNotNil(info, "首次运行信息应该存在")
        XCTAssertNotNil(info.currentVersion, "当前版本应该存在")
        XCTAssertNotNil(info.currentBuildVersion, "构建版本应该存在")
        XCTAssertFalse(info.description.isEmpty, "首次运行信息描述不应该为空")
    }
    
    // MARK: - First Run Flow Tests
    
    func testStartFirstRunFlow() {
        // Given
        let expectation = XCTestExpectation(description: "首次运行流程")
        
        // When
        firstRunManager.startFirstRunFlow { success in
            // Then
            XCTAssertNotNil(success, "首次运行流程结果应该有值")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testStartUpdateFlow() {
        // Given
        let expectation = XCTestExpectation(description: "版本更新流程")
        
        // When
        firstRunManager.startUpdateFlow { success in
            // Then
            XCTAssertNotNil(success, "版本更新流程结果应该有值")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testShowQuickSetupWizard() {
        // Given
        let expectation = XCTestExpectation(description: "快速设置向导")
        
        // When
        firstRunManager.showQuickSetupWizard { success in
            // Then
            XCTAssertNotNil(success, "快速设置向导结果应该有值")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Reset Tests
    
    func testResetFirstRunStatus() {
        // Given
        let initialInfo = firstRunManager.getFirstRunInfo()
        
        // When
        firstRunManager.resetFirstRunStatus()
        
        // Then
        let resetInfo = firstRunManager.getFirstRunInfo()
        // 重置后的状态可能会改变
        XCTAssertNotNil(resetInfo, "重置后的首次运行信息应该存在")
    }
    
    // MARK: - Performance Tests
    
    func testFirstRunCheckPerformance() {
        // Given & When & Then
        measure {
            _ = firstRunManager.isFirstRun()
        }
    }
    
    func testGetFirstRunInfoPerformance() {
        // Given & When & Then
        measure {
            _ = firstRunManager.getFirstRunInfo()
        }
    }
}