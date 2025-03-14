//
//  ClipboradManager.swift
//  ClipboardHistory
//
//  Created by Arpad Bencze on 13.03.25.
//


import SwiftUI
import UIKit

public class ClipboardManager: ObservableObject {
    // Notification name for clipboard changes
    public static let clipboardChangedNotification = Notification.Name("com.arpadbencze.clipboardhistory.clipboardChanged")
    
    // Shared instance for non-SwiftUI contexts (like keyboard extension)
    private static var _shared: ClipboardManager?
    public static var shared: ClipboardManager {
        if _shared == nil {
            _shared = ClipboardManager()
        }
        return _shared!
    }
    @Published public var clipboardItems: [ClipboardItem] = []
    private static let maxItems = 50 // Make this static
    private var lastContent: ClipboardContent?
    private let defaults: UserDefaults
    private var notificationObserver: Any?
    private var timer: Timer?
    
    public init() {
        // Initialize with app group UserDefaults
        if let groupDefaults = UserDefaults(suiteName: "group.com.arpadbencze.clipboardhistory") {
            self.defaults = groupDefaults
        } else {
            self.defaults = UserDefaults.standard
            print("⚠️ Warning: Could not access app group defaults, using standard defaults")
        }
        
        // // Reset any stale data
        defaults.synchronize()
        
        // Load saved items
        loadSavedItems()
        startMonitoring()
        
        // Start listening for changes
        setupNotifications()
    }
    
    public func loadSavedItems() {
        // Reset local items
        clipboardItems.removeAll()
        
        // Load items from UserDefaults
        if let savedItems = defaults.array(forKey: "clipboardItems") as? [[String: Any]] {
            // Enforce item limit
            let limitedItems = savedItems.prefix(ClipboardManager.maxItems)
            // Sort items by timestamp (newest first)
            let sortedItems = Array(limitedItems).sorted { 
                ($0["timestamp"] as? Date ?? Date.distantPast) > ($1["timestamp"] as? Date ?? Date.distantPast)
            }
            clipboardItems = sortedItems.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let timestamp = dict["timestamp"] as? Date,
                      let uuid = UUID(uuidString: id) else { return nil }
                
                if let text = dict["text"] as? String {
                    return ClipboardItem(id: uuid, content: .text(text), timestamp: timestamp)
                } else if let imageData = dict["imageData"] as? Data,
                          let image = UIImage(data: imageData) {
                    return ClipboardItem(id: uuid, content: .image(image), timestamp: timestamp)
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
        
        // Save items in a single operation
        defaults.set(itemDicts, forKey: "clipboardItems")
        defaults.synchronize()
        
        // Notify other instances about the change
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(
                name: ClipboardManager.clipboardChangedNotification,
                object: self,
                userInfo: ["itemCount": self.clipboardItems.count]
            )
        }
    }
    
    private func stopMonitoring() {
        // Stop the timer
        timer?.invalidate()
        timer = nil
        lastContent = nil
    }
    
    func startMonitoring() {
        // Request clipboard permission explicitly
        requestClipboardPermission { [weak self] in
            guard let self = self else { return }
            
            // Stop any existing timer
            self.timer?.invalidate()
            
            // Set up a timer to check clipboard periodically
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkClipboard()
            }
        }
    }
    
    private func requestClipboardPermission(completion: @escaping () -> Void) {
        // Trigger the clipboard permission dialog by attempting to access it
        DispatchQueue.main.async {
            // This will trigger the permission prompt
            let _ = UIPasteboard.general.string
            completion()
        }
    }
    
    private func checkClipboard() {
        // Ensure we're on the main thread when accessing clipboard
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
            if let content = newContent, content != self.lastContent {
                self.lastContent = content
                let newItem = ClipboardItem(content: content)
                self.addItem(newItem)
            }
        }
    }
    
    private func addItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // Remove any existing items with the same content
            self.clipboardItems.removeAll(where: { $0.content == item.content })
            
            // Add new item at the beginning
            self.clipboardItems.insert(item, at: 0)
            
            // Enforce item limit
            if self.clipboardItems.count > ClipboardManager.maxItems {
                self.clipboardItems = Array(self.clipboardItems.prefix(ClipboardManager.maxItems))
            }

            // Save and notify
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
            // Remove item from local array
            self.clipboardItems.removeAll { $0.id == item.id }
            
            // Clear existing items from UserDefaults
            self.defaults.removeObject(forKey: "clipboardItems")
            self.defaults.synchronize()
            
            // Save updated items
            let itemDicts = self.clipboardItems.map { item -> [String: Any] in
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
            
            // Save and sync
            self.defaults.set(itemDicts, forKey: "clipboardItems")
            self.defaults.synchronize()
            
            // Notify all instances
            NotificationCenter.default.post(
                name: ClipboardManager.clipboardChangedNotification,
                object: self,
                userInfo: ["itemCount": self.clipboardItems.count]
            )
        }
    }
    
    public func deleteAllItems() {
        DispatchQueue.main.async {
            // Stop monitoring temporarily
            self.stopMonitoring()
            
            // Clear local items
            self.clipboardItems.removeAll()
            
            // Clear UserDefaults
            self.defaults.removeObject(forKey: "clipboardItems")
            self.defaults.synchronize()
            
            // Notify all instances
            NotificationCenter.default.post(
                name: ClipboardManager.clipboardChangedNotification,
                object: self,
                userInfo: ["itemCount": 0]
            )
            
            // Resume monitoring after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startMonitoring()
            }
        }
    }
    
    private func setupNotifications() {
        // Remove any existing observer
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Add new observer for clipboard changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: ClipboardManager.clipboardChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadSavedItems()
            // Notify SwiftUI views to update
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
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
