import XCTest
@testable import WiFiMenuBar

/// PreferencesManager的单元测试
final class PreferencesManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var preferencesManager: PreferencesManager!
    private var testUserDefaults: UserDefaults!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // 使用测试专用的UserDefaults
        testUserDefaults = UserDefaults(suiteName: "PreferencesManagerTests")
        testUserDefaults.removePersistentDomain(forName: "PreferencesManagerTests")
        
        // 注意：由于PreferencesManager是单例，我们需要小心测试
        preferencesManager = PreferencesManager.shared
    }
    
    override func tearDown() {
        // 清理测试数据
        testUserDefaults.removePersistentDomain(forName: "PreferencesManagerTests")
        testUserDefaults = nil
        preferencesManager = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() {
        let instance1 = PreferencesManager.shared
        let instance2 = PreferencesManager.shared
        
        XCTAssertTrue(instance1 === instance2, "PreferencesManager应该是单例")
    }
    
    // MARK: - Default Preferences Tests
    
    func testDefaultPreferences() {
        let defaultPreferences = AppPreferences()
        
        XCTAssertEqual(defaultPreferences.displayFormat, .nameOnly, "默认显示格式应该是nameOnly")
        XCTAssertTrue(defaultPreferences.autoStart, "默认应该启用自动启动")
        XCTAssertEqual(defaultPreferences.maxDisplayLength, 20, "默认最大显示长度应该是20")
        XCTAssertEqual(defaultPreferences.refreshInterval, 5.0, "默认刷新间隔应该是5秒")
        XCTAssertFalse(defaultPreferences.showSignalStrength, "默认不显示信号强度")
        XCTAssertFalse(defaultPreferences.showNetworkIcon, "默认不显示网络图标")
        XCTAssertTrue(defaultPreferences.enableNotifications, "默认启用通知")
        XCTAssertTrue(defaultPreferences.minimizeToTray, "默认最小化到托盘")
        XCTAssertFalse(defaultPreferences.launchAtLogin, "默认不在登录时启动")
        XCTAssertTrue(defaultPreferences.checkForUpdates, "默认检查更新")
    }
    
    func testAppPreferencesEquality() {
        let preferences1 = AppPreferences()
        let preferences2 = AppPreferences()
        
        XCTAssertEqual(preferences1, preferences2, "相同的默认设置应该相等")
        
        var preferences3 = AppPreferences()
        preferences3.displayFormat = .nameWithSignal
        
        XCTAssertNotEqual(preferences1, preferences3, "不同的设置应该不相等")
    }
    
    func testAppPreferencesCodable() throws {
        let originalPreferences = AppPreferences(
            displayFormat: .nameWithSignal,
            autoStart: false,
            maxDisplayLength: 15,
            refreshInterval: 3.0
        )
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPreferences)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedPreferences = try decoder.decode(AppPreferences.self, from: data)
        
        XCTAssertEqual(originalPreferences, decodedPreferences, "编码解码后的设置应该相同")
    }
    
    // MARK: - Preferences Management Tests
    
    func testGetCurrentPreferences() {
        let currentPreferences = preferencesManager.getCurrentPreferences()
        XCTAssertNotNil(currentPreferences, "应该能够获取当前偏好设置")
    }
    
    func testUpdatePreferences() {
        let originalPreferences = preferencesManager.getCurrentPreferences()
        
        var newPreferences = originalPreferences
        newPreferences.displayFormat = .nameWithSignal
        newPreferences.maxDisplayLength = 15
        
        preferencesManager.updatePreferences(newPreferences)
        
        let updatedPreferences = preferencesManager.getCurrentPreferences()
        XCTAssertEqual(updatedPreferences.displayFormat, .nameWithSignal, "显示格式应该被更新")
        XCTAssertEqual(updatedPreferences.maxDisplayLength, 15, "最大显示长度应该被更新")
    }
    
    func testUpdateSamePreferences() {
        let originalPreferences = preferencesManager.getCurrentPreferences()
        
        // 更新相同的设置
        preferencesManager.updatePreferences(originalPreferences)
        
        let updatedPreferences = preferencesManager.getCurrentPreferences()
        XCTAssertEqual(originalPreferences, updatedPreferences, "更新相同设置后应该保持不变")
    }
    
    func testResetToDefaults() {
        // 先修改设置
        var modifiedPreferences = preferencesManager.getCurrentPreferences()
        modifiedPreferences.displayFormat = .nameWithSignal
        modifiedPreferences.autoStart = false
        preferencesManager.updatePreferences(modifiedPreferences)
        
        // 重置为默认值
        preferencesManager.resetToDefaults()
        
        let resetPreferences = preferencesManager.getCurrentPreferences()
        let defaultPreferences = AppPreferences()
        
        XCTAssertEqual(resetPreferences, defaultPreferences, "重置后应该恢复默认设置")
    }
    
    // MARK: - Convenience Methods Tests
    
    func testSetDisplayFormat() {
        let originalFormat = preferencesManager.getCurrentPreferences().displayFormat
        let newFormat: DisplayFormat = (originalFormat == .nameOnly) ? .nameWithSignal : .nameOnly
        
        preferencesManager.setDisplayFormat(newFormat)
        
        let updatedFormat = preferencesManager.getCurrentPreferences().displayFormat
        XCTAssertEqual(updatedFormat, newFormat, "显示格式应该被更新")
    }
    
    func testSetAutoStart() {
        let originalAutoStart = preferencesManager.getCurrentPreferences().autoStart
        let newAutoStart = !originalAutoStart
        
        preferencesManager.setAutoStart(newAutoStart)
        
        let updatedAutoStart = preferencesManager.getCurrentPreferences().autoStart
        XCTAssertEqual(updatedAutoStart, newAutoStart, "自动启动设置应该被更新")
    }
    
    func testSetMaxDisplayLength() {
        preferencesManager.setMaxDisplayLength(25)
        
        let updatedLength = preferencesManager.getCurrentPreferences().maxDisplayLength
        XCTAssertEqual(updatedLength, 25, "最大显示长度应该被更新")
    }
    
    func testSetMaxDisplayLengthInvalid() {
        let originalLength = preferencesManager.getCurrentPreferences().maxDisplayLength
        
        // 测试无效值
        preferencesManager.setMaxDisplayLength(3) // 太小
        XCTAssertEqual(preferencesManager.getCurrentPreferences().maxDisplayLength, originalLength, 
                      "无效的长度不应该被设置")
        
        preferencesManager.setMaxDisplayLength(100) // 太大
        XCTAssertEqual(preferencesManager.getCurrentPreferences().maxDisplayLength, originalLength, 
                      "无效的长度不应该被设置")
    }
    
    func testSetRefreshInterval() {
        preferencesManager.setRefreshInterval(10.0)
        
        let updatedInterval = preferencesManager.getCurrentPreferences().refreshInterval
        XCTAssertEqual(updatedInterval, 10.0, "刷新间隔应该被更新")
    }
    
    func testSetRefreshIntervalInvalid() {
        let originalInterval = preferencesManager.getCurrentPreferences().refreshInterval
        
        // 测试无效值
        preferencesManager.setRefreshInterval(0.5) // 太小
        XCTAssertEqual(preferencesManager.getCurrentPreferences().refreshInterval, originalInterval, 
                      "无效的间隔不应该被设置")
        
        preferencesManager.setRefreshInterval(120.0) // 太大
        XCTAssertEqual(preferencesManager.getCurrentPreferences().refreshInterval, originalInterval, 
                      "无效的间隔不应该被设置")
    }
    
    func testSetNotificationsEnabled() {
        let originalEnabled = preferencesManager.getCurrentPreferences().enableNotifications
        let newEnabled = !originalEnabled
        
        preferencesManager.setNotificationsEnabled(newEnabled)
        
        let updatedEnabled = preferencesManager.getCurrentPreferences().enableNotifications
        XCTAssertEqual(updatedEnabled, newEnabled, "通知设置应该被更新")
    }
    
    func testSetLaunchAtLogin() {
        let originalLaunch = preferencesManager.getCurrentPreferences().launchAtLogin
        let newLaunch = !originalLaunch
        
        preferencesManager.setLaunchAtLogin(newLaunch)
        
        let updatedLaunch = preferencesManager.getCurrentPreferences().launchAtLogin
        XCTAssertEqual(updatedLaunch, newLaunch, "登录启动设置应该被更新")
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidPreferences() {
        let validPreferences = AppPreferences()
        let result = preferencesManager.validatePreferences(validPreferences)
        
        XCTAssertTrue(result.isValid, "默认设置应该是有效的")
        XCTAssertTrue(result.errors.isEmpty, "有效设置不应该有错误")
    }
    
    func testValidateInvalidMaxDisplayLength() {
        var invalidPreferences = AppPreferences()
        invalidPreferences.maxDisplayLength = 3 // 太小
        
        let result = preferencesManager.validatePreferences(invalidPreferences)
        
        XCTAssertFalse(result.isValid, "无效的最大显示长度应该验证失败")
        XCTAssertTrue(result.errors.contains { $0.contains("最大显示长度") }, "应该包含最大显示长度错误")
    }
    
    func testValidateInvalidRefreshInterval() {
        var invalidPreferences = AppPreferences()
        invalidPreferences.refreshInterval = 0.5 // 太小
        
        let result = preferencesManager.validatePreferences(invalidPreferences)
        
        XCTAssertFalse(result.isValid, "无效的刷新间隔应该验证失败")
        XCTAssertTrue(result.errors.contains { $0.contains("刷新间隔") }, "应该包含刷新间隔错误")
    }
    
    func testValidateMultipleErrors() {
        var invalidPreferences = AppPreferences()
        invalidPreferences.maxDisplayLength = 100 // 太大
        invalidPreferences.refreshInterval = 120.0 // 太大
        
        let result = preferencesManager.validatePreferences(invalidPreferences)
        
        XCTAssertFalse(result.isValid, "多个无效设置应该验证失败")
        XCTAssertEqual(result.errors.count, 2, "应该有2个错误")
    }
    
    // MARK: - Export/Import Tests
    
    func testExportSettings() {
        let preferences = AppPreferences(
            displayFormat: .nameWithSignal,
            autoStart: false,
            maxDisplayLength: 15
        )
        preferencesManager.updatePreferences(preferences)
        
        let exportedSettings = preferencesManager.exportSettings()
        
        XCTAssertEqual(exportedSettings["displayFormat"] as? String, "name_with_signal", 
                      "导出的显示格式应该正确")
        XCTAssertEqual(exportedSettings["autoStart"] as? Bool, false, 
                      "导出的自动启动设置应该正确")
        XCTAssertEqual(exportedSettings["maxDisplayLength"] as? Int, 15, 
                      "导出的最大显示长度应该正确")
    }
    
    func testImportValidSettings() {
        let settingsToImport: [String: Any] = [
            "displayFormat": "name_with_signal",
            "autoStart": false,
            "maxDisplayLength": 25,
            "refreshInterval": 8.0,
            "showSignalStrength": true
        ]
        
        let success = preferencesManager.importSettings(from: settingsToImport)
        
        XCTAssertTrue(success, "导入有效设置应该成功")
        
        let importedPreferences = preferencesManager.getCurrentPreferences()
        XCTAssertEqual(importedPreferences.displayFormat, .nameWithSignal, "显示格式应该被导入")
        XCTAssertFalse(importedPreferences.autoStart, "自动启动设置应该被导入")
        XCTAssertEqual(importedPreferences.maxDisplayLength, 25, "最大显示长度应该被导入")
        XCTAssertEqual(importedPreferences.refreshInterval, 8.0, "刷新间隔应该被导入")
        XCTAssertTrue(importedPreferences.showSignalStrength, "信号强度显示应该被导入")
    }
    
    func testImportInvalidSettings() {
        let invalidSettings: [String: Any] = [
            "displayFormat": "invalid_format",
            "autoStart": "not_a_boolean",
            "maxDisplayLength": 100
        ]
        
        let success = preferencesManager.importSettings(from: invalidSettings)
        
        XCTAssertFalse(success, "导入无效设置应该失败")
    }
    
    func testImportPartialSettings() {
        let originalPreferences = preferencesManager.getCurrentPreferences()
        
        let partialSettings: [String: Any] = [
            "displayFormat": "name_with_icon",
            "autoStart": false
            // 缺少其他必需字段
        ]
        
        let success = preferencesManager.importSettings(from: partialSettings)
        
        XCTAssertFalse(success, "导入不完整设置应该失败")
        
        // 验证原设置未被修改
        let currentPreferences = preferencesManager.getCurrentPreferences()
        XCTAssertEqual(currentPreferences, originalPreferences, "导入失败时原设置应该保持不变")
    }
    
    // MARK: - Notification Tests
    
    func testPreferencesChangeNotification() {
        let expectation = XCTestExpectation(description: "等待偏好设置变更通知")
        
        let observer = NotificationCenter.default.addObserver(
            forName: PreferencesManager.preferencesDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["preferences"], "通知应该包含偏好设置")
            expectation.fulfill()
        }
        
        // 修改设置触发通知
        var newPreferences = preferencesManager.getCurrentPreferences()
        newPreferences.displayFormat = .nameWithSignal
        preferencesManager.updatePreferences(newPreferences)
        
        wait(for: [expectation], timeout: 1.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testNoNotificationForSamePreferences() {
        let expectation = XCTestExpectation(description: "不应该收到通知")
        expectation.isInverted = true
        
        let observer = NotificationCenter.default.addObserver(
            forName: PreferencesManager.preferencesDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // 设置相同的偏好设置
        let currentPreferences = preferencesManager.getCurrentPreferences()
        preferencesManager.updatePreferences(currentPreferences)
        
        wait(for: [expectation], timeout: 0.5)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Error Handling Tests
    
    func testPreferencesErrorDescriptions() {
        let errors: [PreferencesError] = [
            .invalidDisplayFormat,
            .invalidAutoStart,
            .invalidMaxDisplayLength,
            .invalidRefreshInterval,
            .saveFailed,
            .loadFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "错误 \(error) 应该有描述")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "错误描述不应该为空")
        }
    }
    
    // MARK: - ValidationResult Tests
    
    func testValidationResultValid() {
        let result = ValidationResult(isValid: true)
        
        XCTAssertTrue(result.isValid, "验证结果应该是有效的")
        XCTAssertTrue(result.errors.isEmpty, "有效结果不应该有错误")
    }
    
    func testValidationResultInvalid() {
        let errors = ["错误1", "错误2"]
        let result = ValidationResult(isValid: false, errors: errors)
        
        XCTAssertFalse(result.isValid, "验证结果应该是无效的")
        XCTAssertEqual(result.errors, errors, "错误列表应该匹配")
    }
}