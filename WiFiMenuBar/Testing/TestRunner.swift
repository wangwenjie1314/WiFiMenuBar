import Cocoa
import Foundation

/// 测试运行器
/// 统一管理和执行所有类型的测试
class TestRunner {
    
    // MARK: - Properties
    
    /// 集成测试套件
    private let integrationTestSuite = IntegrationTestSuite()
    
    /// 用户体验验证器
    private let uxValidator = UserExperienceValidator()
    
    /// 图标测试工具
    private let iconTestTool = IconTestTool()
    
    /// 稳定性诊断工具
    private let stabilityDiagnosticTool = StabilityDiagnosticTool()
    
    // MARK: - Public Methods
    
    /// 运行所有测试
    /// - Returns: 完整测试报告
    func runAllTests() -> ComprehensiveTestReport {
        print("TestRunner: 开始运行所有测试")
        
        let overallStartTime = Date()
        
        // 1. 运行集成测试
        print("TestRunner: 运行集成测试...")
        let integrationResult = integrationTestSuite.runCompleteIntegrationTest()
        
        // 2. 运行用户体验验证
        print("TestRunner: 运行用户体验验证...")
        let uxResult = uxValidator.performCompleteUXValidation()
        
        // 3. 运行图标测试
        print("TestRunner: 运行图标测试...")
        let iconResult = iconTestTool.performCompleteIconTest()
        
        // 4. 运行稳定性诊断
        print("TestRunner: 运行稳定性诊断...")
        let stabilityResult = stabilityDiagnosticTool.performComprehensiveDiagnosis()
        
        let overallDuration = Date().timeIntervalSince(overallStartTime)
        
        let report = ComprehensiveTestReport(
            testDate: Date(),
            overallDuration: overallDuration,
            integrationTestResult: integrationResult,
            uxValidationResult: uxResult,
            iconTestResult: iconResult,
            stabilityDiagnosisResult: stabilityResult
        )
        
        print("TestRunner: 所有测试完成")
        
        return report
    }
    
    /// 运行快速测试
    /// - Returns: 快速测试报告
    func runQuickTests() -> QuickTestReport {
        print("TestRunner: 开始运行快速测试")
        
        let startTime = Date()
        
        // 运行关键功能的快速测试
        let integrationResult = integrationTestSuite.runUserWorkflowTest()
        let iconResult = iconTestTool.performQuickIconTest()
        let stabilityResult = stabilityDiagnosticTool.performQuickDiagnosis()
        
        let duration = Date().timeIntervalSince(startTime)
        
        return QuickTestReport(
            testDate: Date(),
            duration: duration,
            integrationResult: integrationResult,
            iconResult: iconResult,
            stabilityResult: stabilityResult
        )
    }
    
    /// 运行特定类型的测试
    /// - Parameter testType: 测试类型
    /// - Returns: 测试结果
    func runSpecificTest(_ testType: TestType) -> Any {
        print("TestRunner: 运行 \(testType.description) 测试")
        
        switch testType {
        case .integration:
            return integrationTestSuite.runCompleteIntegrationTest()
        case .userExperience:
            return uxValidator.performCompleteUXValidation()
        case .icon:
            return iconTestTool.performCompleteIconTest()
        case .stability:
            return stabilityDiagnosticTool.performComprehensiveDiagnosis()
        case .performance:
            return runPerformanceTest()
        case .network:
            return integrationTestSuite.runNetworkEnvironmentTest()
        }
    }
    
    /// 生成完整测试报告
    /// - Parameter report: 综合测试报告
    /// - Returns: 格式化的报告文本
    func generateCompleteReport(_ report: ComprehensiveTestReport) -> String {
        var reportText = """
        WiFi菜单栏应用 - 完整测试报告
        ==============================
        
        测试日期: \(report.testDate)
        总耗时: \(String(format: "%.2f", report.overallDuration)) 秒
        
        """
        
        // 添加执行摘要
        reportText += generateExecutiveSummary(report)
        
        // 添加集成测试结果
        reportText += "\n\n集成测试结果:\n"
        reportText += "============\n"
        reportText += integrationTestSuite.generateTestReport(report.integrationTestResult)
        
        // 添加用户体验验证结果
        reportText += "\n\n用户体验验证结果:\n"
        reportText += "================\n"
        reportText += generateUXValidationReport(report.uxValidationResult)
        
        // 添加图标测试结果
        reportText += "\n\n图标测试结果:\n"
        reportText += "============\n"
        reportText += iconTestTool.generateTestReport(report.iconTestResult)
        
        // 添加稳定性诊断结果
        reportText += "\n\n稳定性诊断结果:\n"
        reportText += "==============\n"
        reportText += generateStabilityDiagnosisReport(report.stabilityDiagnosisResult)
        
        // 添加总结和建议
        reportText += "\n\n总结和建议:\n"
        reportText += "==========\n"
        reportText += generateOverallRecommendations(report)
        
        return reportText
    }
    
    /// 保存测试报告到文件
    /// - Parameters:
    ///   - report: 测试报告内容
    ///   - filename: 文件名
    /// - Returns: 是否保存成功
    func saveReportToFile(_ report: String, filename: String) -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            print("TestRunner: 测试报告已保存到 \(fileURL.path)")
            return true
        } catch {
            print("TestRunner: 保存测试报告失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// 运行性能测试
    private func runPerformanceTest() -> PerformanceTestResult {
        let startTime = Date()
        
        let performanceManager = PerformanceManager.shared
        let memoryUsage = performanceManager.currentMemoryUsage
        let cpuUsage = performanceManager.currentCPUUsage
        
        let duration = Date().timeIntervalSince(startTime)
        
        return PerformanceTestResult(
            duration: duration,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            passed: memoryUsage < 100.0 && cpuUsage < 10.0
        )
    }
    
    /// 生成执行摘要
    private func generateExecutiveSummary(_ report: ComprehensiveTestReport) -> String {
        let integrationSuccess = Double(report.integrationTestResult.passedTests) / Double(report.integrationTestResult.totalTests)
        let uxSuccess = report.uxValidationResult.successRate
        let iconSuccess = Double(report.iconTestResult.passedTests) / Double(report.iconTestResult.totalTests)
        
        let overallSuccess = (integrationSuccess + uxSuccess + iconSuccess) / 3.0
        
        var summary = "执行摘要:\n"
        summary += "========\n\n"
        
        if overallSuccess >= 0.9 {
            summary += "🎉 应用质量优秀！所有主要功能都正常工作，可以发布。\n"
        } else if overallSuccess >= 0.7 {
            summary += "✅ 应用质量良好，建议修复少量问题后发布。\n"
        } else if overallSuccess >= 0.5 {
            summary += "⚠️ 应用存在一些问题，需要修复后再考虑发布。\n"
        } else {
            summary += "❌ 应用存在严重问题，不建议发布。\n"
        }
        
        summary += "\n关键指标:\n"
        summary += "- 集成测试通过率: \(String(format: "%.1f", integrationSuccess * 100))%\n"
        summary += "- 用户体验评分: \(String(format: "%.1f", uxSuccess * 100))%\n"
        summary += "- 图标功能完整性: \(String(format: "%.1f", iconSuccess * 100))%\n"
        summary += "- 整体质量评分: \(String(format: "%.1f", overallSuccess * 100))%\n"
        
        return summary
    }
    
    /// 生成用户体验验证报告
    private func generateUXValidationReport(_ result: UXValidationSuiteResult) -> String {
        var report = """
        用户体验验证耗时: \(String(format: "%.2f", result.duration)) 秒
        总验证项: \(result.totalValidations)
        通过验证: \(result.passedValidations)
        失败验证: \(result.failedValidations)
        成功率: \(String(format: "%.1f", result.successRate * 100))%
        
        详细结果:
        --------
        
        """
        
        for validationResult in result.validationResults {
            let status = validationResult.passed ? "✅ 通过" : "❌ 失败"
            report += "\(validationResult.validationName) - \(status)\n"
            
            if !validationResult.details.isEmpty {
                report += "  详情:\n"
                for (key, value) in validationResult.details {
                    report += "    - \(key): \(value)\n"
                }
            }
            
            if !validationResult.issues.isEmpty {
                report += "  问题:\n"
                for issue in validationResult.issues {
                    report += "    - \(issue)\n"
                }
            }
            
            report += "\n"
        }
        
        return report
    }
    
    /// 生成稳定性诊断报告
    private func generateStabilityDiagnosisReport(_ result: ComprehensiveDiagnosisResult) -> String {
        var report = """
        稳定性诊断耗时: \(String(format: "%.2f", result.duration)) 秒
        
        健康检查:
        --------
        状态: \(result.healthCheck.healthStatus.description)
        平均分数: \(String(format: "%.1f", result.healthCheck.averageScore))
        趋势: \(result.healthCheck.trend.description)
        
        稳定性分析:
        ----------
        稳定性分数: \(String(format: "%.1f", result.stabilityAnalysis.stabilityScore))
        崩溃次数: \(result.stabilityAnalysis.crashCount)
        异常次数: \(result.stabilityAnalysis.exceptionCount)
        运行时间: \(String(format: "%.0f", result.stabilityAnalysis.uptime)) 秒
        
        性能分析:
        --------
        内存使用: \(String(format: "%.1f", result.performanceAnalysis.memoryUsage)) MB
        CPU使用: \(String(format: "%.1f", result.performanceAnalysis.cpuUsage))%
        性能状态: \(result.performanceAnalysis.performanceStatus.description)
        
        风险评估:
        --------
        风险等级: \(result.riskAssessment.riskLevel.description)
        风险分数: \(String(format: "%.1f", result.riskAssessment.riskScore))
        风险因素数量: \(result.riskAssessment.riskFactors.count)
        
        """
        
        if !result.recommendations.isEmpty {
            report += "建议:\n"
            report += "----\n"
            for recommendation in result.recommendations {
                report += "- [\(recommendation.priority.description)] \(recommendation.title): \(recommendation.description)\n"
            }
        }
        
        return report
    }
    
    /// 生成整体建议
    private func generateOverallRecommendations(_ report: ComprehensiveTestReport) -> String {
        var recommendations = ""
        
        // 基于测试结果生成建议
        if report.integrationTestResult.failedTests > 0 {
            recommendations += "- 修复集成测试中发现的问题\n"
        }
        
        if report.uxValidationResult.failedValidations > 0 {
            recommendations += "- 改进用户体验相关的问题\n"
        }
        
        if report.iconTestResult.failedTests > 0 {
            recommendations += "- 完善图标系统的实现\n"
        }
        
        // 添加通用建议
        recommendations += "- 定期运行测试以确保质量\n"
        recommendations += "- 关注用户反馈并持续改进\n"
        recommendations += "- 保持代码质量和文档更新\n"
        
        return recommendations
    }
}

// MARK: - Supporting Types

/// 测试类型
enum TestType {
    case integration
    case userExperience
    case icon
    case stability
    case performance
    case network
    
    var description: String {
        switch self {
        case .integration: return "集成测试"
        case .userExperience: return "用户体验验证"
        case .icon: return "图标测试"
        case .stability: return "稳定性诊断"
        case .performance: return "性能测试"
        case .network: return "网络环境测试"
        }
    }
}

/// 综合测试报告
struct ComprehensiveTestReport {
    let testDate: Date
    let overallDuration: TimeInterval
    let integrationTestResult: IntegrationTestSuiteResult
    let uxValidationResult: UXValidationSuiteResult
    let iconTestResult: IconTestResult
    let stabilityDiagnosisResult: ComprehensiveDiagnosisResult
}

/// 快速测试报告
struct QuickTestReport {
    let testDate: Date
    let duration: TimeInterval
    let integrationResult: IntegrationTestSuiteResult
    let iconResult: IconTestResult
    let stabilityResult: QuickDiagnosisResult
}

/// 性能测试结果
struct PerformanceTestResult {
    let duration: TimeInterval
    let memoryUsage: Double
    let cpuUsage: Double
    let passed: Bool
}