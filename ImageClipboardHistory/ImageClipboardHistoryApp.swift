import SwiftUI
import AppKit
import Carbon

@main
struct ImageClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // インターフェースを AppDelegate 側で管理するため、空の設定にする
        Settings {
            Text("Settings")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var history = ClipboardImageHistory()
    
    // グローバルショートカット用 (Shift + Cmd + X)
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        // ドックに表示しない (アクセサリ設定)
        NSApp.setActivationPolicy(.accessory)

        // ポップオーバー（メニューの中身）の設定
        let contentView = ContentView()
            .environmentObject(history)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 600)
        popover.behavior = .transient
        popover.animates = false // アニメーションをオフにして高速化
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // メニューバーアイテムの設定
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Image History")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // グローバルショートカット登録: Shift + Cmd + X
        setupGlobalShortcut()
    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // アプリを確実にアクティブにする
            NSApp.activate(ignoringOtherApps: true)
            
            // ポップオーバーを表示
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // 表示されたポップオーバーのウィンドウを捕まえて、最前面に持ってくる
            if let window = popover.contentViewController?.view.window {
                window.level = .statusBar // メニューバーと同じレベルに
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    private func setupGlobalShortcut() {
        // Carbon の定数。直接数値で指定するのが確実です。
        // cmdKey = 0x0100, shiftKey = 0x0200
        let modifierFlags = UInt32(0x0100 | 0x0200) 
        let keyCode = UInt32(0x07) // 'X' キーのキーコード
        
        var hotKeyID = EventHotKeyID()
        // 'ImgH' を OSType に変換 (73, 109, 103, 72)
        hotKeyID.signature = OSType(1231972168) 
        hotKeyID.id = 1
        
        let eventHandler: EventHandlerUPP = { (_, _, _) -> OSStatus in
            DispatchQueue.main.async {
                if let appDelegate = AppDelegate.shared {
                    appDelegate.togglePopover()
                }
            }
            return noErr
        }
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)
        
        InstallEventHandler(GetApplicationEventTarget(), eventHandler, 1, &eventType, nil, nil)
        RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
