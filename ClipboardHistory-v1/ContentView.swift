//
//  ContentView.swift
//  ClipboardHistory
//
//  Created by Arpad Bencze on 13.03.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var showingCopiedAlert = false
    @State private var lastCopiedItem: ClipboardItem?
    
    var body: some View {
        NavigationView {
            Group {
                if clipboardManager.clipboardItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Items Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Copy some text or images to see them here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(clipboardManager.clipboardItems) { item in
                            ClipboardItemView(item: item)
                                .onTapGesture {
                                    clipboardManager.copyToClipboard(item)
                                    lastCopiedItem = item
                                    showingCopiedAlert = true
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Clipboard History")
            .alert("Copied!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let item = lastCopiedItem {
                    switch item.content {
                    case .text(let text):
                        Text(text.prefix(50) + (text.count > 50 ? "..." : ""))
                    case .image:
                        Text("Image copied to clipboard")
                    }
                }
            }
        }
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.content {
            case .text(let text):
                Text(text)
                    .lineLimit(3)
                    .font(.body)
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            }
            
            Text(item.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}

