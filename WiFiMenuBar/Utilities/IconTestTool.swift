import Cocoa
import Foundation

/// 图标测试工具
/// 用于测试和验证图标功能
class IconTestTool {
    
    // MARK: - Properties
    
    /// 图标管理器
    private let iconManager = IconManager.shared
    
    /// 资源加载器
    private let resourceLoader = IconResourceLoader.shared
    
    // MARK: - Public Methods
    
    /// 执行完整的图标测试
    /// - Returns: 测试结果
    func performCompleteIconTest() -> IconTestResult {
        print("IconTestTool: 开始完整图标测试")
        
        let testStartTime = Date()
        var testResults: [IconTestCase] = []
        
        // 1. 测试资源完整性
        testResults.append(testResourceIntegrity())
        
        // 2. 测试图标生成
        testResults.append(testIconGeneration())
        
        // 3. 测试图标缓存
        testResults.append(testIconCaching())
        
        // 4. 测试主题切换
        testResults.append(testThemeSwitching())
        
        // 5. 测试动画功能
        testResults.append(testAnimationFunctionality())
        
        // 6. 测试性能
        testResults.append(testPerformance())
        
        let testDuration = Date().timeIntervalSince(testStartTime)
        let passedTests = testResults.filter { $0.passed }.count
        let totalTests = testResults.count
        
        let result = IconTestResult(
            testDuration: testDuration,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: totalTests - passedTests,
            testCases: testResults
        )
        
        print("IconTestTool: 图标测试完成 - 通过: \(passedTests)/\(totalTests)")
        
        return result
    }
    
    /// 执行快速图标测试
    /// - Returns: 测试结果
    func performQuickIconTest() -> IconTestResult {
        print("IconTestTool: 开始快速图标测试")
        
        let testStartTime = Date()
        var testResults: [IconTestCase] = []
        
        // 快速测试：只测试基本功能
        testResults.append(testResourceIntegrity())
        testResults.append(testBasicIconGeneration())
        
        let testDuration = Date().timeIntervalSince(testStartTime)
        let passedTests = testResults.filter { $0.passed }.count
        let totalTests = testResults.count
        
        return IconTestResult(
            testDuration: testDuration,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: totalTests - passedTests,
            testCases: testResults
        )
    }
    
    /// 测试特定图标状态
    /// - Parameter status: 图标状态
    /// - Returns: 测试结果
    func testIconStatus(_ status: IconStatus) -> IconTestCase {
        let testName = "测试图标状态: \(status.description)"
        
        do {
            // 测试图标生成
            let icon = iconManager.getStatusBarIcon(for: convertIconStatusToWiFiStatus(status))
            
            if icon != nil {
                return IconTestCase(
                    name: testName,
                    passed: true,
                    message: "图标生成成功",
                    details: ["状态": status.description, "图标": "已生成"]
                )
            } else {
                return IconTestCase(
                    name: testName,
                    passed: false,
                    message: "图标生成失败",
                    details: ["状态": status.description, "错误": "返回nil"]
                )
            }
        } catch {
            return IconTestCase(
                name: testName,
                passed: false,
                message: "图标测试异常: \(error.localizedDescription)",
                details: ["状态": status.description, "异常": error.localizedDescription]
            )
        }
    }
    
    /// 生成测试报告
    /// - Parameter testResult: 测试结果
    /// - Returns: 测试报告
    func generateTestReport(_ testResult: IconTestResult) -> String {
        var report = """
        图标测试报告
        ============
        
        测试时间: \(Date())
        测试耗时: \(String(format: "%.3f", testResult.testDuration)) 秒
        总测试数: \(testResult.totalTests)
        通过测试: \(testResult.passedTests)
        失败测试: \(testResult.failedTests)
        成功率: \(String(format: "%.1f", Double(testResult.passedTests) / Double(testResult.totalTests) * 100))%
        
        详细结果:
        --------
        
        """
        
        for (index, testCase) in testResult.testCases.enumerated() {
            let status = testCase.passed ? "✅ 通过" : "❌ 失败"
            report += "\(index + 1). \(testCase.name) - \(status)\n"
            report += "   消息: \(testCase.message)\n"
            
            if !testCase.details.isEmpty {
                report += "   详情:\n"
                for (key, value) in testCase.details {
                    report += "     - \(key): \(value)\n"
                }
            }
            report += "\n"
        }
        
        // 添加建议
        if testResult.failedTests > 0 {
            report += "建议:\n"
            report += "-----\n"
            
            let failedTests = testResult.testCases.filter { !$0.passed }
            for testCase in failedTests {
                report += "- \(testCase.name): \(generateRecommendation(for: testCase))\n"
            }
        }
        
        return report
    }
    
    // MARK: - Private Test Methods
    
    /// 测试资源完整性
    private func testResourceIntegrity() -> IconTestCase {
        let testName = "资源完整性测试"
        
        let integrityResult = resourceLoader.checkIconResourceIntegrity()
        
        if integrityResult.isComplete {
            return IconTestCase(
                name: testName,
                passed: true,
                message: "所有图标资源完整",
                details: [
                    "可用资源": "\(integrityResult.availableResources.count)",
                    "资源列表": integrityResult.availableResources.joined(separator: ", ")
                ]
            )
        } else {
            return IconTestCase(
                name: testName,
                passed: false,
                message: "图标资源不完整",
                details: [
                    "可用资源": "\(integrityResult.availableResources.count)",
                    "缺失资源": "\(integrityResult.missingResources.count)",
                    "缺失列表": integrityResult.missingResources.joined(separator: ", ")
                ]
            )
        }
    }
    
    /// 测试图标生成
    private func testIconGeneration() -> IconTestCase {
        let testName = "图标生成测试"
        
        var generatedCount = 0
        var failedCount = 0
        var details: [String: String] = [:]
        
        for status in IconStatus.allCases {
            let wifiStatus = convertIconStatusToWiFiStatus(status)
            if let icon = iconManager.getStatusBarIcon(for: wifiStatus) {
                generatedCount += 1
                details[status.description] = "成功"
            } else {
                failedCount += 1
                details[status.description] = "失败"
            }
        }
        
        let passed = failedCount == 0
        let message = passed ? "所有图标生成成功" : "部分图标生成失败"
        
        details["成功数量"] = "\(generatedCount)"
        details["失败数量"] = "\(failedCount)"
        
        return IconTestCase(
            name: testName,
            passed: passed,
            message: message,
            details: details
        )
    }
    
    /// 测试基本图标生成
    private func testBasicIconGeneration() -> IconTestCase {
        let testName = "基本图标生成测试"
        
        // 只测试连接和断开状态
        let testStatuses: [IconStatus] = [.connected, .disconnected]
        var allPassed = true
        var details: [String: String] = [:]
        
        for status in testStatuses {
            let wifiStatus = convertIconStatusToWiFiStatus(status)
            if let icon = iconManager.getStatusBarIcon(for: wifiStatus) {
                details[status.description] = "成功"
            } else {
                details[status.description] = "失败"
                allPassed = false
            }
        }
        
        return IconTestCase(
            name: testName,
            passed: allPassed,
            message: allPassed ? "基本图标生成成功" : "基本图标生成失败",
            details: details
        )
    }
    
    /// 测试图标缓存
    private func testIconCaching() -> IconTestCase {
        let testName = "图标缓存测试"
        
        // 清除缓存
        iconManager.clearIconCache()
        
        // 生成图标（应该创建缓存）
        let status = IconStatus.connected
        let wifiStatus = convertIconStatusToWiFiStatus(status)
        let icon1 = iconManager.getStatusBarIcon(for: wifiStatus)
        
        // 再次获取图标（应该从缓存获取）
        let icon2 = iconManager.getStatusBarIcon(for: wifiStatus)
        
        let iconInfo = iconManager.getIconInfo()
        let cacheWorking = icon1 != nil && icon2 != nil && iconInfo.cacheSize > 0
        
        return IconTestCase(
            name: testName,
            passed: cacheWorking,
            message: cacheWorking ? "图标缓存正常工作" : "图标缓存异常",
            details: [
                "缓存大小": "\(iconInfo.cacheSize)",
                "图标1": icon1 != nil ? "成功" : "失败",
                "图标2": icon2 != nil ? "成功" : "失败"
            ]
        )
    }
    
    /// 测试主题切换
    private func testThemeSwitching() -> IconTestCase {
        let testName = "主题切换测试"
        
        let originalTheme = iconManager.currentTheme
        var switchResults: [String: String] = [:]
        
        // 测试切换到不同主题
        let testThemes: [IconTheme] = [.light, .dark, .auto]
        
        for theme in testThemes {
            iconManager.setTheme(theme)
            
            // 生成图标测试主题是否生效
            let wifiStatus = convertIconStatusToWiFiStatus(.connected)
            let icon = iconManager.getStatusBarIcon(for: wifiStatus)
            
            switchResults[theme.description] = icon != nil ? "成功" : "失败"
        }
        
        // 恢复原始主题
        iconManager.setTheme(originalTheme)
        
        let allPassed = !switchResults.values.contains("失败")
        
        return IconTestCase(
            name: testName,
            passed: allPassed,
            message: allPassed ? "主题切换正常" : "主题切换异常",
            details: switchResults
        )
    }
    
    /// 测试动画功能
    private func testAnimationFunctionality() -> IconTestCase {
        let testName = "动画功能测试"
        
        let originalDynamicEnabled = iconManager.isDynamicIconEnabled
        
        // 启用动画
        iconManager.setDynamicIconEnabled(true)
        
        // 设置连接中状态（应该触发动画）
        iconManager.updateIconStatus(.connecting("TestNetwork"))
        
        let iconInfo = iconManager.getIconInfo()
        let animationWorking = iconInfo.isDynamicEnabled && iconInfo.currentStatus == .connecting
        
        // 恢复原始设置
        iconManager.setDynamicIconEnabled(originalDynamicEnabled)
        
        return IconTestCase(
            name: testName,
            passed: animationWorking,
            message: animationWorking ? "动画功能正常" : "动画功能异常",
            details: [
                "动态图标启用": "\(iconInfo.isDynamicEnabled)",
                "当前状态": iconInfo.currentStatus.description,
                "动画状态": "\(iconInfo.isAnimating)"
            ]
        )
    }
    
    /// 测试性能
    private func testPerformance() -> IconTestCase {
        let testName = "性能测试"
        
        let testCount = 100
        let startTime = Date()
        
        // 执行多次图标生成测试性能
        for _ in 0..<testCount {
            let randomStatus = IconStatus.allCases.randomElement() ?? .connected
            let wifiStatus = convertIconStatusToWiFiStatus(randomStatus)
            _ = iconManager.getStatusBarIcon(for: wifiStatus)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let averageTime = duration / Double(testCount)
        
        // 性能标准：平均每次生成应该在10ms以内
        let performanceGood = averageTime < 0.01
        
        return IconTestCase(
            name: testName,
            passed: performanceGood,
            message: performanceGood ? "性能良好" : "性能需要优化",
            details: [
                "测试次数": "\(testCount)",
                "总耗时": "\(String(format: "%.3f", duration))秒",
                "平均耗时": "\(String(format: "%.3f", averageTime * 1000))毫秒"
            ]
        )
    }
    
    /// 转换图标状态到WiFi状态
    private func convertIconStatusToWiFiStatus(_ iconStatus: IconStatus) -> WiFiStatus {
        switch iconStatus {
        case .connected:
            return .connected(WiFiNetwork(ssid: "TestNetwork", bssid: nil, signalStrength: -50, isSecure: true, frequency: 2.4, channel: 6, standard: "802.11n", connectedAt: Date()))
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting("TestNetwork")
        case .error:
            return .error(WiFiMonitorError.networkUnavailable)
        case .disabled:
            return .disabled
        case .unknown:
            return .unknown
        }
    }
    
    /// 生成建议
    private func generateRecommendation(for testCase: IconTestCase) -> String {
        switch testCase.name {
        case let name where name.contains("资源完整性"):
            return "检查Assets.xcassets中的图标资源是否完整，运行图标生成脚本"
        case let name where name.contains("图标生成"):
            return "检查图标生成逻辑，确保所有状态都有对应的图标"
        case let name where name.contains("缓存"):
            return "检查图标缓存机制，确保缓存正常工作"
        case let name where name.contains("主题"):
            return "检查主题切换逻辑，确保不同主题下图标正确显示"
        case let name where name.contains("动画"):
            return "检查动画功能实现，确保连接中状态能正确触发动画"
        case let name where name.contains("性能"):
            return "优化图标生成和缓存机制，提高性能"
        default:
            return "检查相关功能实现"
        }
    }
}

// MARK: - Supporting Types

/// 图标测试结果
struct IconTestResult {
    let testDuration: TimeInterval
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let testCases: [IconTestCase]
    
    var successRate: Double {
        return totalTests > 0 ? Double(passedTests) / Double(totalTests) : 0.0
    }
    
    var description: String {
        return """
        图标测试结果:
        - 测试耗时: \(String(format: "%.3f", testDuration)) 秒
        - 总测试数: \(totalTests)
        - 通过测试: \(passedTests)
        - 失败测试: \(failedTests)
        - 成功率: \(String(format: "%.1f", successRate * 100))%
        """
    }
}

/// 图标测试用例
struct IconTestCase {
    let name: String
    let passed: Bool
    let message: String
    let details: [String: String]
    
    var description: String {
        let status = passed ? "✅ 通过" : "❌ 失败"
        return "\(name) - \(status): \(message)"
    }
}