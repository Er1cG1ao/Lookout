import AppKit

/// This optional, private WindowServer API follows HeadOrbit's documented approach.
/// Absence or failure always falls back to an opaque cover, never dim-only protection.
enum BackdropBlur {
    typealias Connection = @convention(c) () -> Int32
    typealias SetRadius = @convention(c) (Int32, Int32, Int32) -> Int32
    private static let functions: (Connection, SetRadius)? = {
        guard let handle = dlopen("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices", RTLD_NOW),
              let connection = dlsym(handle, "CGSDefaultConnectionForThread"),
              let radius = dlsym(handle, "CGSSetWindowBackgroundBlurRadius") else { return nil }
        return (unsafeBitCast(connection, to: Connection.self), unsafeBitCast(radius, to: SetRadius.self))
    }()
    static func apply(_ window: NSWindow, radius: Int) -> Bool {
        guard let (connection, set) = functions else { return false }
        return set(connection(), Int32(window.windowNumber), Int32(radius)) == 0
    }
}

final class ScreenCover {
    private var windows: [NSWindow] = []
    private(set) var shown = false
    private(set) var blurAvailable = true
    private var settings = ProtectionSettings()
    private var screenObserver: NSObjectProtocol?

    init() {
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in
                guard let self, self.shown else { return }
                self.rebuild()
            }
    }

    func setCovered(_ covered: Bool, settings: ProtectionSettings) {
        let changed = self.settings.blurRadius != settings.blurRadius || self.settings.dimming != settings.dimming
        self.settings = settings
        if !covered {
            windows.forEach { $0.orderOut(nil) }
            shown = false
        } else if !shown || changed {
            shown = true
            rebuild()
        }
    }

    private func rebuild() {
        let old = windows
        blurAvailable = true
        windows = NSScreen.screens.map { screen in
            let window = CoverWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.setFrame(screen.frame, display: false)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = true
            window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 2)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.black.cgColor
            window.contentView = view
            window.orderFrontRegardless()
            let success = BackdropBlur.apply(window, radius: Int(settings.blurRadius))
            if success {
                view.layer?.backgroundColor = NSColor.black.withAlphaComponent(max(0.08, settings.dimming)).cgColor
            } else { blurAvailable = false }
            return window
        }
        old.forEach { $0.orderOut(nil) }
    }
    deinit { if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) } }
}

private final class CoverWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
