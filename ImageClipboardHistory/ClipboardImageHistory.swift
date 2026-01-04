import Foundation
import AppKit
import SwiftUI
import Combine

struct ClipboardImageItem: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let image: NSImage
}

final class ClipboardImageHistory: ObservableObject {

    @Published private(set) var items: [ClipboardImageItem] = []

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let maxItems: Int = 100

    init() {
        startWatching()
    }

    // 監視開始（アプリ起動時に自動で呼ばれる）
    func startWatching() {
        stopWatching()

        timer = Timer.scheduledTimer(withTimeInterval: 0.4,
                                     repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // 画像として読めるものだけ拾う
        if let image = NSImage(pasteboard: pasteboard) {
            appendImage(image)
            return
        }

        // ファイルURL経由（画像ファイルをコピーした場合）も拾う
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self],
                                             options: nil) as? [URL] {
            for url in urls where isImageFile(url: url) {
                if let image = NSImage(contentsOf: url) {
                    appendImage(image)
                }
            }
        }
    }

    private func isImageFile(url: URL) -> Bool {
        let ex = url.pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "heic", "webp"].contains(ex)
    }

    private func appendImage(_ image: NSImage) {
        let item = ClipboardImageItem(date: Date(), image: image)

        DispatchQueue.main.async {
            self.items.insert(item, at: 0)
            if self.items.count > self.maxItems {
                self.items.removeLast(self.items.count - self.maxItems)
            }
        }
    }

    func copyToPasteboard(item: ClipboardImageItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([item.image])
    }

    func clearAll() {
        items.removeAll()
    }
}
