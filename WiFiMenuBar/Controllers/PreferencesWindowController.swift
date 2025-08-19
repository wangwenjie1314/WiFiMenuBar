import Cocoa
import SwiftUI

/// 偏好设置窗口控制器
/// 负责管理偏好设置窗口的显示和生命周期
class PreferencesWindowController: NSWindowController {
    
    // MARK: - Properties
    
    /// 偏好设置管理器
    private let preferencesManager = PreferencesManager.shared
    
    /// SwiftUI视图的宿主视图控制器
    private var hostingController: NSHostingController<PreferencesView>?
    
    // MARK: - Initialization
    
    convenience init() {
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        setupWindow()
        setupContent()
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // 窗口基本设置
        window.title = "WiFi菜单栏 - 偏好设置"
        window.isReleasedWhenClosed = false
        window.center()
        
        // 设置窗口大小限制
        window.minSize = NSSize(width: 450, height: 350)
        window.maxSize = NSSize(width: 600, height: 500)
        
        // 设置窗口样式
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        
        // 设置窗口级别
        window.level = .floating
        
        print("PreferencesWindowController: 窗口设置完成")
    }
    
    private func setupContent() {
        guard let window = window else { return }
        
        // 创建SwiftUI视图
        let preferencesView = PreferencesView()
        
        // 创建宿主视图控制器
        hostingController = NSHostingController(rootView: preferencesView)
        
        // 设置内容视图
        window.contentViewController = hostingController
        
        print("PreferencesWindowController: 内容设置完成")
    }
    
    // MARK: - Public Methods
    
    /// 显示偏好设置窗口
    func showPreferences() {
        guard let window = window else { return }
        
        // 如果窗口已经可见，则将其置于前台
        if window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // 显示窗口
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        print("PreferencesWindowController: 显示偏好设置窗口")
    }
    
    /// 隐藏偏好设置窗口
    func hidePreferences() {
        window?.orderOut(nil)
        print("PreferencesWindowController: 隐藏偏好设置窗口")
    }
    
    /// 切换偏好设置窗口显示状态
    func togglePreferences() {
        guard let window = window else { return }
        
        if window.isVisible {
            hidePreferences()
        } else {
            showPreferences()
        }
    }
}

// MARK: - NSWindowDelegate

extension PreferencesWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("PreferencesWindowController: 窗口即将关闭")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("PreferencesWindowController: 窗口成为主窗口")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        print("PreferencesWindowController: 窗口失去焦点")
    }
}