# ClipboardHistory

A modern iOS app that keeps track of your clipboard history, supporting both text and images.

## Features

- Automatically monitors clipboard changes
- Supports both text and image content
- Shows relative timestamps for each copied item
- Maintains history of up to 50 recent items
- Clean, modern SwiftUI interface
- Easy one-tap to copy items back to clipboard

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `ClipboardHistory-v1.xcodeproj` in Xcode
3. Build and run the project

## Usage

Simply copy text or images as you normally would. The app will automatically track your clipboard history. Tap any item in the history to copy it back to your clipboard.

## Architecture

- Built with SwiftUI and modern iOS design patterns
- Uses MVVM architecture with `ClipboardManager` as the main view model
- Shared code architecture for potential app extensions
