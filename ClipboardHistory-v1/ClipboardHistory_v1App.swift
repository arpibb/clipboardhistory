//
//  ClipboardHistoryApp.swift
//  ClipboardHistory
//
//  Created by Arpad Bencze on 13.03.25.
//

import SwiftUI

@main
struct ClipboardHistoryApp: App {
    @StateObject private var clipboardManager = ClipboardManager.shared
    
    init() {
        // Request clipboard permission by attempting to access it
        UIPasteboard.general.string = UIPasteboard.general.string
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
        }
    }
}
