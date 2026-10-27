import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var model: AppModel!
    private var item: NSStatusItem!
    private var window: NSWindow?
    private var subscriptions = Set<AnyCancellable>()
    private let statusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model = AppModel()
        model.closeSettings = { [weak self] in self?.window?.close() }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Lookout")
        let menu = NSMenu()
        menu.addItem(statusItem)
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "设置与校准…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self; menu.addItem(settings)
        toggleItem.target = self; menu.addItem(toggleItem)
        let emergency = NSMenuItem(title: "立即解除遮挡并暂停", action: #selector(pause), keyEquivalent: "")
        emergency.target = self; menu.addItem(emergency)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 Lookout", action: #selector(quit), keyEquivalent: "q")
        quit.target = self; menu.addItem(quit)
        item.menu = menu
        model.$status.combineLatest(model.$enabled, model.$covered).receive(on: DispatchQueue.main)
            .sink { [weak self] status, enabled, covered in
                guard let self else { return }
                self.statusItem.title = status
                self.toggleItem.title = enabled ? "暂停保护" : "开始保护"
                self.item.button?.image = NSImage(systemSymbolName: covered ? "eye.slash" : "eye", accessibilityDescription: status)
                self.item.button?.toolTip = "Lookout · \(status)"
            }.store(in: &subscriptions)
        NSApp.mainMenu = makeMainMenu()
        showSettings()
    }

    @objc func showSettings() {
        if let window, window.isVisible {
            NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil); return
        }
        model.beginEditing()
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let host = NSHostingController(rootView: SettingsView(model: model))
            let w = NSWindow(contentViewController: host)
            w.title = "Lookout — 设置与校准"
            w.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            w.setContentSize(NSSize(width: 890, height: 730))
            w.minSize = NSSize(width: 880, height: 700)
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        model.endEditing()
        NSApp.setActivationPolicy(.accessory)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings(); return true
    }
    @objc func toggle() {
        if !model.settings.calibrated { showSettings() } else { model.toggleProtection() }
    }
    @objc func pause() { model.pause() }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { model.shutdown() }

    private func makeMainMenu() -> NSMenu {
        let menu = NSMenu()
        let app = NSMenuItem(); menu.addItem(app)
        let submenu = NSMenu()
        submenu.addItem(withTitle: "关于 Lookout", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        let settings = submenu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        submenu.addItem(.separator())
        submenu.addItem(withTitle: "退出 Lookout", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        app.submenu = submenu
        let edit = NSMenuItem(); menu.addItem(edit)
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        edit.submenu = editMenu
        let win = NSMenuItem(); menu.addItem(win)
        let winMenu = NSMenu(title: "窗口")
        winMenu.addItem(withTitle: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        win.submenu = winMenu
        return menu
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
