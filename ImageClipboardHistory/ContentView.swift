import SwiftUI
import AppKit

struct ContentView: View {

    @EnvironmentObject var history: ClipboardImageHistory
    @Environment(\.dismiss) var dismiss
    @State private var isTrashHovered = false
    @State private var isQuitHovered = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー: アプリ名とゴミ箱ボタン（高さ最小限）
            HStack {
                Text("ImageClipboardHistory")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                Spacer()
                Button {
                    history.clearAll()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .padding(6)
                        .background(isTrashHovered ? Color.red.opacity(0.1) : Color.clear)
                        .foregroundColor(isTrashHovered ? .red : .secondary)
                        .cornerRadius(6)
                }
                .buttonStyle(.borderless)
                .help("履歴をすべて削除")
                .onHover { hovering in
                    isTrashHovered = hovering
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            
            Divider()

            if history.items.isEmpty {
                VStack(spacing: 16) {
                    Text("まだ画像がコピーされていません")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("画像をコピーするとここに履歴が表示されます")
                        .font(.headline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(history.items) { item in
                            ThumbnailView(item: item)
                                .onTapGesture {
                                    history.copyToPasteboard(item: item)
                                    dismiss()
                                    NSApp.sendAction(#selector(NSWindow.orderOut(_:)), to: nil, from: nil)
                                }
                        }
                    }
                    .padding(12)
                }
            }
            
            Divider()
            
            // フッター: 終了ボタンのみ（高さ最小限）
            HStack {
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("終了")
                        .font(.system(size: 13))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isQuitHovered ? Color.secondary.opacity(0.2) : Color.clear)
                        .foregroundColor(isQuitHovered ? .primary : .secondary)
                        .cornerRadius(6)
                }
                .buttonStyle(.borderless)
                .onHover { hovering in
                    isQuitHovered = hovering
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
        .frame(width: 320, height: 600)
        .onAppear {
            // キーボード入力（Enter）を監視
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 36 { // 36 は Return (Enter) キー
                    if let firstItem = history.items.first {
                        history.copyToPasteboard(item: firstItem)
                        dismiss()
                        NSApp.sendAction(#selector(NSWindow.orderOut(_:)), to: nil, from: nil)
                        return nil // イベントを消費
                    }
                }
                return event
            }
        }
    }
}

struct ThumbnailView: View {
    let item: ClipboardImageItem
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .frame(height: 140) // 高さを固定して揃える
                .clipped()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isHovered ? 2 : 1)
                )

            Text(dateLabel(date: item.date))
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(isHovered ? .primary : .secondary)
        }
        .padding(8)
        .background(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .contentShape(Rectangle()) // 判定領域をしっかり定義
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP") // 日本語の曜日を表示
        formatter.dateFormat = "M/d (EEE) HH:mm"
        return formatter
    }()

    private func dateLabel(date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }
}
