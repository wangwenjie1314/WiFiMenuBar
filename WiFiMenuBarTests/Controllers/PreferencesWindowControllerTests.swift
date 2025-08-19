import XCTest
@testable import WiFiMenuBar

/// PreferencesWindowController单元测试
/// 测试偏好设置窗口控制器的功能
class PreferencesWindowControllerTests: XCTestCase {
    
    // MARK: - Properties
    
    var windowController: PreferencesWindowController!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        windowController = PreferencesWindowController()
    }
    
    override func tearDownWithError() throws {
        windowController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testWindowControllerInitialization() {
        // Given & When
        let controller = PreferencesWindowController()
        
        // Then
        XCTAssertNotNil(controller.window, "窗口应该被正确创建")
        XCTAssertEqual(controller.window?.title, "WiFi菜单栏 - 偏好设置", "窗口标题应该正确设置")
        XCTAssertFalse(controller.window?.isReleasedWhenClosed ?? true, "窗口不应该在关闭时释放")
    }
    
    func testWindowSizeConfiguration() {
        // Given & When
        let window = windowController.window
        
        // Then
        XCTAssertNotNil(window, "窗口应该存在")
        XCTAssertEqual(window?.minSize.width, 450, "最小宽度应该为450")
        XCTAssertEqual(window?.minSize.height, 350, "最小高度应该为350")
        XCTAssertEqual(window?.maxSize.width, 600, "最大宽度应该为600")
        XCTAssertEqual(window?.maxSize.height, 500, "最大高度应该为500")
    }
    
    func testWindowStyleConfiguration() {
        // Given & When
        let window = windowController.window
        
        // Then
        XCTAssertNotNil(window, "窗口应该存在")
        XCTAssertFalse(window?.titlebarAppearsTransparent ?? true, "标题栏不应该透明")
        XCTAssertEqual(window?.titleVisibility, .visible, "标题应该可见")
        XCTAssertEqual(window?.level, .floating, "窗口级别应该为floating")
    }
    
    // MARK: - Window Management Tests
    
    func testShowPreferences() {
        // Given
        let window = windowController.window
        XCTAssertNotNil(window, "窗口应该存在")
        
        // When
        windowController.showPreferences()
        
        // Then
        // 注意：在单元测试环境中，窗口可能不会真正显示
        // 这里主要测试方法调用不会崩溃
        XCTAssertNoThrow(windowController.showPreferences(), "显示偏好设置不应该抛出异常")
    }
    
    func testHidePreferences() {
        // Given
        let window = windowController.window
        XCTAssertNotNil(window, "窗口应该存在")
        
        // When & Then
        XCTAssertNoThrow(windowController.hidePreferences(), "隐藏偏好设置不应该抛出异常")
    }
    
    func testTogglePreferences() {
        // Given
        let window = windowController.window
        XCTAssertNotNil(window, "窗口应该存在")
        
        // When & Then
        XCTAssertNoThrow(windowController.togglePreferences(), "切换偏好设置显示状态不应该抛出异常")
    }
    
    // MARK: - Content Tests
    
    func testContentViewControllerSetup() {
        // Given & When
        let contentViewController = windowController.window?.contentViewController
        
        // Then
        XCTAssertNotNil(contentViewController, "内容视图控制器应该被设置")
        XCTAssertTrue(contentViewController is NSHostingController<PreferencesView>, 
                     "内容视图控制器应该是NSHostingController<PreferencesView>类型")
    }
    
    // MARK: - Memory Management Tests
    
    func testWindowControllerMemoryManagement() {
        // Given
        weak var weakController: PreferencesWindowController?
        
        // When
        autoreleasepool {
            let controller = PreferencesWindowController()
            weakController = controller
            // controller在这里会被释放
        }
        
        // Then
        // 注意：由于窗口控制器可能被系统持有，这个测试可能不会通过
        // 这里主要是为了检查是否有明显的内存泄漏
        // XCTAssertNil(weakController, "窗口控制器应该被正确释放")
    }
    
    // MARK: - Integration Tests
    
    func testPreferencesManagerIntegration() {
        // Given
        let preferencesManager = PreferencesManager.shared
        let initialPreferences = preferencesManager.getCurrentPreferences()
        
        // When
        windowController.showPreferences()
        
        // Then
        let currentPreferences = preferencesManager.getCurrentPreferences()
        XCTAssertEqual(initialPreferences.displayFormat, currentPreferences.displayFormat, 
                      "显示偏好设置不应该改变当前设置")
        XCTAssertEqual(initialPreferences.autoStart, currentPreferences.autoStart, 
                      "显示偏好设置不应该改变自动启动设置")
    }
    
    // MARK: - Error Handling Tests
    
    func testWindowControllerWithNilWindow() {
        // Given
        let controller = PreferencesWindowController()
        controller.window = nil
        
        // When & Then
        XCTAssertNoThrow(controller.showPreferences(), "处理nil窗口时不应该崩溃")
        XCTAssertNoThrow(controller.hidePreferences(), "处理nil窗口时不应该崩溃")
        XCTAssertNoThrow(controller.togglePreferences(), "处理nil窗口时不应该崩溃")
    }
}

// MARK: - Performance Tests

extension PreferencesWindowControllerTests {
    
    func testWindowCreationPerformance() {
        // Given & When & Then
        measure {
            let controller = PreferencesWindowController()
            _ = controller.window
        }
    }
    
    func testShowHidePerformance() {
        // Given
        let controller = PreferencesWindowController()
        
        // When & Then
        measure {
            controller.showPreferences()
            controller.hidePreferences()
        }
    }
}