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
    private let defaults: UserDefaults
    private var notificationObserver: Any?
    
    public init() {
        // Initialize with app group UserDefaults
        if let groupDefaults = UserDefaults(suiteName: "group.com.arpadbencze.clipboardhistory") {
            self.defaults = groupDefaults
        } else {
            self.defaults = UserDefaults.standard
        }
        
        // Load saved items
        loadSavedItems()
        startMonitoring()
        
        // Start listening for changes
        setupNotifications()
    }
    
    private func loadSavedItems() {
        if let savedItems = defaults.array(forKey: "clipboardItems") as? [[String: Any]] {
            clipboardItems = savedItems.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let timestamp = dict["timestamp"] as? Date else { return nil }
                
                if let text = dict["text"] as? String {
                    return ClipboardItem(id: UUID(uuidString: id)!, content: .text(text), timestamp: timestamp)
                } else if let imageData = dict["imageData"] as? Data,
                          let image = UIImage(data: imageData) {
                    return ClipboardItem(id: UUID(uuidString: id)!, content: .image(image), timestamp: timestamp)
                }
                return nil
            }
        }
    }
    
    private func saveItems() {
        let itemDicts = clipboardItems.map { item -> [String: Any] in
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "timestamp": item.timestamp
            ]
            
            switch item.content {
            case .text(let text):
                dict["text"] = text
            case .image(let image):
                if let imageData = image.pngData() {
                    dict["imageData"] = imageData
                }
            }
            
            return dict
        }
        
        defaults.set(itemDicts, forKey: "clipboardItems")
        
        // Notify other instances about the change
        NotificationCenter.default.post(
            name: Notification.Name("ClipboardHistoryDidChange"),
            object: nil,
            userInfo: nil
        )
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
        
        if let text = clipboard.string?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            newContent = .text(text)
        } else if let image = clipboard.image {
            newContent = .image(image)
        } else {
            newContent = nil
        }
        
        // Only add if content is different from last check and not empty
        if let content = newContent, content != lastContent {
            lastContent = content
            addItem(ClipboardItem(content: content))
        }
    }
    
    private func addItem(_ item: ClipboardItem) {
        // Check if content already exists to avoid duplicates
        guard !clipboardItems.contains(where: { $0.content == item.content }) else { return }
        
        DispatchQueue.main.async {
            self.clipboardItems.insert(item, at: 0)
            if self.clipboardItems.count > self.maxItems {
                self.clipboardItems.removeLast()
            }
            self.saveItems()
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
    
    public func deleteItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.clipboardItems.removeAll { $0.id == item.id }
            self.saveItems()
        }
    }
    
    public func deleteAllItems() {
        DispatchQueue.main.async {
            self.clipboardItems.removeAll()
            self.saveItems()
        }
    }
    
    private func setupNotifications() {
        // Remove any existing observer
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Add new observer for clipboard changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("ClipboardHistoryDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadSavedItems()
        }
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

public struct ClipboardItem: Identifiable {
    public let id: UUID
    public let content: ClipboardContent
    public let timestamp: Date
    
    public init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
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
