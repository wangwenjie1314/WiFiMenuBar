import Cocoa
import Foundation

/// 测试启动器
/// 提供在应用中启动和管理测试的功能
class TestLauncher: NSObject {
    
    // MARK: - Properties
    
    /// 测试运行器
    private let testRunner = TestRunner()
    
    /// 测试窗口控制器
    private var testWindowController: NSWindowController?
    
    /// 是否正在运行测试
    private var isRunningTests = false
    
    // MARK: - Public Methods
    
    /// 显示测试界面
    func showTestInterface() {
        if testWindowController == nil {
            createTestWindow()
        }
        
        testWindowController?.showWindow(nil)
        testWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    /// 运行快速测试
    /// - Parameter completion: 完成回调
    func runQuickTest(completion: @escaping (QuickTestReport) -> Void) {
        guard !isRunningTests else {
            print("TestLauncher: 测试正在运行中")
            return
        }
        
        isRunningTests = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let report = self.testRunner.runQuickTests()
            
            DispatchQueue.main.async {
                self.isRunningTests = false
                completion(report)
            }
        }
    }
    
    /// 运行完整测试
    /// - Parameter completion: 完成回调
    func runCompleteTest(completion: @escaping (ComprehensiveTestReport) -> Void) {
        guard !isRunningTests else {
            print("TestLauncher: 测试正在运行中")
            return
        }
        
        isRunningTests = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let report = self.testRunner.runAllTests()
            
            DispatchQueue.main.async {
                self.isRunningTests = false
                completion(report)
            }
        }
    }
    
    /// 运行特定测试
    /// - Parameters:
    ///   - testType: 测试类型
    ///   - completion: 完成回调
    func runSpecificTest(_ testType: TestType, completion: @escaping (Any) -> Void) {
        guard !isRunningTests else {
            print("TestLauncher: 测试正在运行中")
            return
        }
        
        isRunningTests = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.testRunner.runSpecificTest(testType)
            
            DispatchQueue.main.async {
                self.isRunningTests = false
                completion(result)
            }
        }
    }
    
    /// 显示测试报告
    /// - Parameter report: 测试报告
    func showTestReport(_ report: String) {
        let alert = NSAlert()
        alert.messageText = "测试报告"
        alert.informativeText = "测试已完成，是否查看详细报告？"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "查看报告")
        alert.addButton(withTitle: "保存到文件")
        alert.addButton(withTitle: "关闭")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            showReportWindow(report)
        case .alertSecondButtonReturn:
            saveReportToFile(report)
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建测试窗口
    private func createTestWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "WiFi菜单栏 - 测试控制台"
        window.center()
        
        let contentView = createTestContentView()
        window.contentView = contentView
        
        testWindowController = NSWindowController(window: window)
    }
    
    /// 创建测试内容视图
    private func createTestContentView() -> NSView {
        let contentView = NSView()
        
        // 创建按钮
        let quickTestButton = NSButton(title: "快速测试", target: self, action: #selector(quickTestButtonClicked))
        let completeTestButton = NSButton(title: "完整测试", target: self, action: #selector(completeTestButtonClicked))
        let integrationTestButton = NSButton(title: "集成测试", target: self, action: #selector(integrationTestButtonClicked))
        let uxTestButton = NSButton(title: "用户体验验证", target: self, action: #selector(uxTestButtonClicked))
        let iconTestButton = NSButton(title: "图标测试", target: self, action: #selector(iconTestButtonClicked))
        let stabilityTestButton = NSButton(title: "稳定性诊断", target: self, action: #selector(stabilityTestButtonClicked))
        
        // 设置按钮样式
        let buttons = [quickTestButton, completeTestButton, integrationTestButton, uxTestButton, iconTestButton, stabilityTestButton]
        for button in buttons {
            button.bezelStyle = .rounded
            button.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(button)
        }
        
        // 创建状态标签
        let statusLabel = NSTextField(labelWithString: "准备运行测试")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            quickTestButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            quickTestButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            completeTestButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            completeTestButton.leadingAnchor.constraint(equalTo: quickTestButton.trailingAnchor, constant: 10),
            completeTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            integrationTestButton.topAnchor.constraint(equalTo: quickTestButton.bottomAnchor, constant: 10),
            integrationTestButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            integrationTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            uxTestButton.topAnchor.constraint(equalTo: quickTestButton.bottomAnchor, constant: 10),
            uxTestButton.leadingAnchor.constraint(equalTo: integrationTestButton.trailingAnchor, constant: 10),
            uxTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            iconTestButton.topAnchor.constraint(equalTo: integrationTestButton.bottomAnchor, constant: 10),
            iconTestButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            stabilityTestButton.topAnchor.constraint(equalTo: integrationTestButton.bottomAnchor, constant: 10),
            stabilityTestButton.leadingAnchor.constraint(equalTo: iconTestButton.trailingAnchor, constant: 10),
            stabilityTestButton.widthAnchor.constraint(equalToConstant: 120),
            
            statusLabel.topAnchor.constraint(equalTo: iconTestButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        return contentView
    }
    
    /// 显示报告窗口
    private func showReportWindow(_ report: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "测试报告"
        window.center()
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        
        let textView = NSTextView()
        textView.string = report
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        scrollView.documentView = textView
        window.contentView = scrollView
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
    }
    
    /// 保存报告到文件
    private func saveReportToFile(_ report: String) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "WiFiMenuBar_TestReport_\(Date().timeIntervalSince1970).txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try report.write(to: url, atomically: true, encoding: .utf8)
                    
                    let alert = NSAlert()
                    alert.messageText = "保存成功"
                    alert.informativeText = "测试报告已保存到 \(url.path)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "保存失败"
                    alert.informativeText = "无法保存测试报告: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func quickTestButtonClicked() {
        runQuickTest { [weak self] report in
            let reportText = "快速测试完成\n\n集成测试通过率: \(String(format: "%.1f", Double(report.integrationResult.passedTests) / Double(report.integrationResult.totalTests) * 100))%"
            self?.showTestReport(reportText)
        }
    }
    
    @objc private func completeTestButtonClicked() {
        runCompleteTest { [weak self] report in
            let reportText = self?.testRunner.generateCompleteReport(report) ?? "无法生成报告"
            self?.showTestReport(reportText)
        }
    }
    
    @objc private func integrationTestButtonClicked() {
        runSpecificTest(.integration) { [weak self] result in
            if let integrationResult = result as? IntegrationTestSuiteResult {
                let reportText = "集成测试结果\n\n通过: \(integrationResult.passedTests)/\(integrationResult.totalTests)"
                self?.showTestReport(reportText)
            }
        }
    }
    
    @objc private func uxTestButtonClicked() {
        runSpecificTest(.userExperience) { [weak self] result in
            if let uxResult = result as? UXValidationSuiteResult {
                let reportText = "用户体验验证结果\n\n成功率: \(String(format: "%.1f", uxResult.successRate * 100))%"
                self?.showTestReport(reportText)
            }
        }
    }
    
    @objc private func iconTestButtonClicked() {
        runSpecificTest(.icon) { [weak self] result in
            if let iconResult = result as? IconTestResult {
                let reportText = "图标测试结果\n\n通过: \(iconResult.passedTests)/\(iconResult.totalTests)"
                self?.showTestReport(reportText)
            }
        }
    }
    
    @objc private func stabilityTestButtonClicked() {
        runSpecificTest(.stability) { [weak self] result in
            if let stabilityResult = result as? ComprehensiveDiagnosisResult {
                let reportText = "稳定性诊断结果\n\n稳定性分数: \(String(format: "%.1f", stabilityResult.stabilityAnalysis.stabilityScore))"
                self?.showTestReport(reportText)
            }
        }
    }
}