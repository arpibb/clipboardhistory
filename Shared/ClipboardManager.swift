//
//  ClipboradManager.swift
//  ClipboardHistory
//
//  Created by Arpad Bencze on 13.03.25.
//


import SwiftUI
import UIKit

public class ClipboardManager: ObservableObject {
    @Published public var clipboardItems: [ClipboardItem] = []
    private let maxItems = 50
    private var lastContent: ClipboardContent?
    
    public init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Set up a timer to check clipboard periodically
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        let clipboard = UIPasteboard.general
        
        let newContent: ClipboardContent?
        
        if let text = clipboard.string {
            newContent = .text(text)
        } else if let image = clipboard.image {
            newContent = .image(image)
        } else {
            newContent = nil
        }
        
        // Only add if content is different from last check
        if let content = newContent, content != lastContent {
            lastContent = content
            addItem(ClipboardItem(content: content))
        }
    }
    
    private func addItem(_ item: ClipboardItem) {
        // Check if item already exists to avoid duplicates
        guard !clipboardItems.contains(where: { $0.id == item.id }) else { return }
        
        DispatchQueue.main.async {
            self.clipboardItems.insert(item, at: 0)
            if self.clipboardItems.count > self.maxItems {
                self.clipboardItems.removeLast()
            }
        }
    }
    
    public func copyToClipboard(_ item: ClipboardItem) {
        let clipboard = UIPasteboard.general
        
        switch item.content {
        case .text(let text):
            clipboard.string = text
        case .image(let image):
            clipboard.image = image
        }
    }
}

public struct ClipboardItem: Identifiable {
    public let id = UUID()
    public let content: ClipboardContent
    public let timestamp = Date()
}

public enum ClipboardContent: Equatable {
    case text(String)
    case image(UIImage)
    
    public var text: String? {
        if case .text(let value) = self { return value }
        return nil
    }
    
    public var image: UIImage? {
        if case .image(let value) = self { return value }
        return nil
    }
    
    public static func == (lhs: ClipboardContent, rhs: ClipboardContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let lText), .text(let rText)):
            return lText == rText
        case (.image(let lImage), .image(let rImage)):
            // Compare image data for equality
            return lImage.pngData() == rImage.pngData()
        default:
            return false
        }
    }
}
