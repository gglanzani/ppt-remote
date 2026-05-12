import AppKit
import Darwin

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let port: UInt16 = 8080
    private let token: String = {
        let chars = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        return String((0..<8).map { _ in chars[Int.random(in: 0..<chars.count)] })
    }()
    private var statusItem: NSStatusItem!
    private var server: HTTPServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccessibilityIfNeeded()
        setupMenuBar()
        startServer()
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = "Accessibility permission required"
            alert.informativeText = "PPT Remote needs Accessibility access to send the laser-pointer keystroke.\n\nGrant access in System Settings → Privacy & Security → Accessibility, then relaunch the app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let cfg = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let icon = NSImage(systemSymbolName: "cursorarrow.rays",
                               accessibilityDescription: "PPT Remote")?
                .withSymbolConfiguration(cfg)
            icon?.isTemplate = true
            button.image = icon
            button.toolTip = "PPT Remote"
        }

        let menu = NSMenu()
        let qrView = QRMenuView()
        let qrItem = NSMenuItem()
        qrItem.view = qrView
        qrItem.tag = 100
        menu.addItem(qrItem)
        menu.addItem(NSMenuItem.separator())
        let copyItem = NSMenuItem(title: "Copy URL", action: #selector(copyURL), keyEquivalent: "c")
        copyItem.target = self
        menu.addItem(copyItem)
        let refreshItem = NSMenuItem(title: "Refresh URL", action: #selector(refreshURL), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
    }

    private func startServer() {
        let scripts = AppleScriptRunner()
        let mover = CursorMover()
        let router = Router(scripts: scripts, mover: mover, token: token)
        do {
            let server = try HTTPServer(port: port, handler: router.handle)
            server.wsHandler = router.handleWS
            try server.start()
            self.server = server
            updateMenuURL()
        } catch {
            let alert = NSAlert()
            alert.messageText = "PPT Remote could not start"
            alert.informativeText = "\(error)"
            alert.alertStyle = .critical
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    private func currentURL() -> String {
        let host = localIP() ?? "localhost"
        return "http://\(host):\(port)/\(token)"
    }

    private func updateMenuURL() {
        if let item = statusItem.menu?.item(withTag: 100) {
            if let view = item.view as? QRMenuView {
                view.update(url: currentURL())
            }
        }
    }

    @objc private func refreshURL() {
        updateMenuURL()
    }

    @objc private func copyURL() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(currentURL(), forType: .string)
    }
}

func localIP() -> String? {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
    defer { freeifaddrs(ifaddr) }

    var fallback: String?
    var ptr: UnsafeMutablePointer<ifaddrs>? = first
    while let p = ptr {
        let i = p.pointee
        let name = String(cString: i.ifa_name)
        let isLoopback = (i.ifa_flags & UInt32(IFF_LOOPBACK)) != 0
        if !isLoopback, let sa = i.ifa_addr, sa.pointee.sa_family == sa_family_t(AF_INET) {
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(sa, socklen_t(sa.pointee.sa_len),
                        &host, socklen_t(host.count),
                        nil, 0, NI_NUMERICHOST)
            let address = String(cString: host)
            if !address.hasPrefix("169.254") {
                if name == "en0" || name == "en1" { return address }
                fallback = fallback ?? address
            }
        }
        ptr = i.ifa_next
    }
    return fallback
}
