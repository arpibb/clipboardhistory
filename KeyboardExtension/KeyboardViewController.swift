//
//  KeyboardViewController.swift
//  KeyboardExtension
//
//  Created by Arpad Bencze on 13.03.25.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    private var clipboardManager: ClipboardManager!
    private var collectionView: UICollectionView!
    private var nextKeyboardButton: UIButton!
    private var emojiButton: UIButton!
    private var keyboardView: UIView!
    
    // Track if emoji picker is visible
    private var isEmojiPickerVisible = false
    
    // Track current interface style
    private var isDarkMode: Bool {
        if #available(iOSApplicationExtension 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
    
    private let clipboardHistoryHeight: CGFloat = 56 // Fixed height for clipboard items
    
    private var collectionViewHeightConstraint: NSLayoutConstraint!

    private var keyboardTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupClipboardManager()
        
        // Initial appearance update
        updateAppearance()
        
        // Note: We detect dark/light mode changes using traitCollectionDidChange method
        // which is already implemented below
        
        // Make sure everything is visible
        collectionView.isHidden = false
        

    }
    
    private func setupClipboardManager() {
        // Use the shared clipboard manager from the app group
        if clipboardManager == nil {
            clipboardManager = ClipboardManager.shared
            clipboardManager.loadSavedItems()
            print("⌨️ Keyboard setup - initialized clipboard manager")
        } else {
            // Just refresh the items if manager already exists
            clipboardManager.loadSavedItems()
            print("⌨️ Keyboard setup - refreshed clipboard items")
        }
        
        // Remove any existing observers
        NotificationCenter.default.removeObserver(self)
        
        // Listen for clipboard changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClipboardChange(_:)),
            name: ClipboardManager.clipboardChangedNotification,
            object: nil
        )
        
        // Listen for keyboard becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        // Listen for keyboard being deactivated
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
    }
    
    private func cleanup() {
        // Clean up when keyboard is dismissed
        NotificationCenter.default.removeObserver(self)
        print("⌨️ Keyboard cleanup - removing observers")
    }
    
    @objc private func handleClipboardChange(_ notification: Notification) {
        // Force reload the items from UserDefaults
        clipboardManager.loadSavedItems()
        collectionView.reloadData()
        
        // Log item count for debugging
        if let userInfo = notification.userInfo,
           let itemCount = userInfo[ClipboardManager.itemCountKey] as? Int {
            print("📋 Clipboard items updated: \(itemCount) items")
        }
    }
    
    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        // Reset clipboard manager when keyboard appears
        setupClipboardManager()
        collectionView.reloadData()
        
        // Update appearance for dark/light mode
        updateAppearance()
        
        // Log for debugging
        print("⌨️ Keyboard shown - reloading clipboard items")
    }
    
    @objc private func updateAppearance() {
        // Define iOS keyboard colors based on mode
        let keyboardBackgroundColor = isDarkMode ? 
            UIColor(red: 36/255, green: 36/255, blue: 38/255, alpha: 1.0) : 
            UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        
        // Regular key colors
        let regularKeyBgColor = isDarkMode ? 
            UIColor(red: 52/255, green: 52/255, blue: 54/255, alpha: 1.0) : 
            UIColor.white
        let regularKeyTextColor = isDarkMode ? UIColor.white : UIColor.black
        
        // Special key colors (shift, backspace, etc.)
        let specialKeyBgColor = isDarkMode ? 
            UIColor(red: 66/255, green: 66/255, blue: 68/255, alpha: 1.0) : 
            UIColor(red: 172/255, green: 180/255, blue: 190/255, alpha: 1.0)
        let specialKeyTextColor = isDarkMode ? UIColor.white : UIColor.black
        
        // Action key colors (return, 123, etc.)
        let actionKeyBgColor = isDarkMode ? 
            UIColor(red: 66/255, green: 66/255, blue: 68/255, alpha: 1.0) : 
            UIColor(red: 172/255, green: 180/255, blue: 190/255, alpha: 1.0)
        let actionKeyTextColor = isDarkMode ? UIColor.white : UIColor.black
        
        // Space bar colors
        let spaceBarBgColor = regularKeyBgColor
        
        // Clipboard item colors
        let clipboardItemBgColor = isDarkMode ? 
            UIColor(red: 52/255, green: 52/255, blue: 54/255, alpha: 1.0) : 
            UIColor.white
        let clipboardItemTextColor = isDarkMode ? UIColor.white : UIColor.black
        
        // Update main view background color
        view.backgroundColor = keyboardBackgroundColor
        
        // Update keyboard background color
        keyboardView.backgroundColor = keyboardBackgroundColor
        
        // Update collection view background
        collectionView.backgroundColor = keyboardBackgroundColor
        
        // Store the colors for cells to use
        ClipboardItemCell.cellBackgroundColor = clipboardItemBgColor
        ClipboardItemCell.cellTextColor = clipboardItemTextColor
        
        // Update collection view cells
        collectionView.reloadData()
        
        // Update keyboard buttons
        for subview in keyboardView.subviews {
            if let stackView = subview as? UIStackView {
                for rowStack in stackView.arrangedSubviews {
                    if let rowStackView = rowStack as? UIStackView {
                        for case let button as UIButton in rowStackView.arrangedSubviews {
                            // Get the button title to determine its type
                            let title = button.title(for: .normal) ?? ""
                            
                            // Apply appropriate styling based on key type
                            switch title {
                            case "⌫", "⇧":
                                button.backgroundColor = specialKeyBgColor
                                button.setTitleColor(specialKeyTextColor, for: .normal)
                            case "123", "go", "return":
                                button.backgroundColor = actionKeyBgColor
                                button.setTitleColor(actionKeyTextColor, for: .normal)
                            case " ": // Space bar
                                button.backgroundColor = spaceBarBgColor
                            case "": // Emoji button or other image-based buttons
                                if button.accessibilityIdentifier == "emojiButton" {
                                    button.backgroundColor = specialKeyBgColor
                                    button.tintColor = specialKeyTextColor
                                } else {
                                    button.backgroundColor = regularKeyBgColor
                                    button.setTitleColor(regularKeyTextColor, for: .normal)
                                }
                            default: // Regular letter keys
                                button.backgroundColor = regularKeyBgColor
                                button.setTitleColor(regularKeyTextColor, for: .normal)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Check if the user interface style (dark/light mode) changed
        if #available(iOSApplicationExtension 13.0, *) {
            if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
                updateAppearance()
            }
        }
    }
    
    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        cleanup()
    }
    
    private func setupUI() {
        // Background color will be set in updateAppearance()
        

        
        // No title label - removed for cleaner UI
        
        // Setup collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 40)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 8)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        // Collection view background will be set in updateAppearance()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ClipboardItemCell.self, forCellWithReuseIdentifier: "ClipboardItemCell")
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isHidden = true
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup keyboard view
        keyboardView = createKeyboardView()
        view.addSubview(keyboardView)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Store constraints that we'll need to modify
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: clipboardHistoryHeight)
        keyboardTopConstraint = keyboardView.topAnchor.constraint(equalTo: collectionView.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // Collection view at the top with more left padding
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionViewHeightConstraint,
            
            keyboardTopConstraint,
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup keyboard switcher button
        nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 20)
        nextKeyboardButton.addTarget(self, action: #selector(advanceToNextInputMode), for: .touchUpInside)
        
        view.addSubview(nextKeyboardButton)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        // We'll add the emoji button to the keyboard view later
        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 30),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 30),
            

        ])
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
        // Make sure the collection view is visible
        collectionView.isHidden = false
    }
    
    @objc private func showEmojiPicker() {
        // Toggle emoji picker visibility
        isEmojiPickerVisible = !isEmojiPickerVisible
        print("loading emojis: \(isEmojiPickerVisible)")  
        
        // Remove any existing emoji views first
        for subview in keyboardView.subviews {
            if subview.tag == 999 { // Tag for emoji views
                subview.removeFromSuperview()
                print("removing emojis")  
            }
        }
        
        // If we're toggling off, just return after removing
        if !isEmojiPickerVisible {
            print("returning simply")  
            return
        }
        
        // Create a simple emoji grid
        let commonEmojis = ["😀", "😂", "😍", "👍", "👋", "🙏", "❤️", "🔥", "✅", "⭐"]
        
        // Create emoji grid with proper theming
        let emojiContainer = UIView()
        emojiContainer.tag = 999
        
        // Use the same background color as the keyboard for the emoji container
        let keyboardBgColor = isDarkMode ? 
            UIColor(red: 36/255, green: 36/255, blue: 38/255, alpha: 1.0) : 
            UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        emojiContainer.backgroundColor = keyboardBgColor
        
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.addSubview(emojiContainer)
        
        // Position the emoji container to cover the keyboard area
        NSLayoutConstraint.activate([
            emojiContainer.topAnchor.constraint(equalTo: keyboardView.topAnchor),
            emojiContainer.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor),
            emojiContainer.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor),
            emojiContainer.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add emoji buttons
        let buttonSize: CGFloat = 32
        let spacing: CGFloat = 8
        
        // Create a scroll view for emojis
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: emojiContainer.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: emojiContainer.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: emojiContainer.bottomAnchor, constant: -8)
        ])
        
        // Content view for the scroll view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Set up the content view constraints
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // Calculate total width needed
        let totalWidth = CGFloat(commonEmojis.count) * (buttonSize + spacing) - spacing
        contentView.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true
        
        for (index, emoji) in commonEmojis.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 24)
            
            // Use transparent background for emoji buttons
            button.backgroundColor = .clear
            button.tag = index
            
            // Add action to insert emoji
            button.addTarget(self, action: #selector(insertEmoji(_:)), for: .touchUpInside)
            
            contentView.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat(index) * (buttonSize + spacing)),
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize)
            ])
        }
    }
    
    @objc private func insertEmoji(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        
        // Insert the emoji into the text document
        textDocumentProxy.insertText(emoji)
    }
    
    private func createKeyboardView() -> UIView {
        // Create the emoji button first
        emojiButton = UIButton(type: .system)
        emojiButton.addTarget(self, action: #selector(showEmojiPicker), for: .touchUpInside)
        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        let keyboardView = UIView()
        // Background color will be set in updateAppearance()
        
        // Add the emoji button to the keyboard view
        keyboardView.addSubview(emojiButton)
        
        // Define key layouts
        let layout = [
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
            [ "123", "emoji", "space", "go"]
        ]
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.distribution = .fillEqually
        
        for row in layout {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 4
            rowStack.distribution = .fillEqually
            
            for key in row {
                let button = UIButton(type: .system)
                button.setTitle(key, for: .normal)
                // Button background will be set in updateAppearance()
                
                // If this is the emoji button, use our existing emojiButton
                // if key == "emoji" {
                //     // Skip adding a new button, we'll position our emojiButton here later
                //     continue
                // }
                button.layer.cornerRadius = 5
                button.titleLabel?.font = .systemFont(ofSize: 18)
                button.tintColor = .black // iOS keyboard text color
                
                if key == "space" {
                    button.setTitle(" ", for: .normal)
                } else if key == "emoji" {
                    // Use system image for emoji button without any title
                    button.setTitle("", for: .normal) // Empty string instead of nil
                    button.accessibilityIdentifier = "emojiButton" // For identification
                    
                    if #available(iOSApplicationExtension 13.0, *) {
                        button.setImage(UIImage(systemName: "face.smiling"), for: .normal)
                    }
                    
                    // Add direct action to emoji button
                    button.addTarget(self, action: #selector(showEmojiPicker), for: .touchUpInside)
                } else {
                    // Only add the keyPressed action to non-emoji buttons
                    button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
                }
                rowStack.addArrangedSubview(button)
            }
            
            stackView.addArrangedSubview(rowStack)
        }
        
        keyboardView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -8)
        ])
        
        // We're using the built-in keyboard layout for the emoji button now
        
        return keyboardView
    }
    
    @objc private func keyPressed(_ sender: UIButton) {
        // Get the button's title or use a tag-based approach for image-only buttons
        guard let key = sender.title(for: .normal) else { return }
        
        switch key {
        case "⌫":
            textDocumentProxy.deleteBackward()
        case "⇧":
            // TODO: Implement shift functionality
            break
        case "123":
            // TODO: Implement number pad
            break
        case "🌐":
            // Use the advanceToNextInputMode method instead
            advanceToNextInputMode()
        case "return":
            textDocumentProxy.insertText("\n")
        case "space":
            textDocumentProxy.insertText(" ")
        case "emoji", "":
            showEmojiPicker()
        default:
            textDocumentProxy.insertText(key)
        }
    }
    
    override func textWillChange(_ textInput: UITextInput?) {}
    
    override func textDidChange(_ textInput: UITextInput?) {}
    
    deinit {
        cleanup()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension KeyboardViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return clipboardManager.clipboardItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClipboardItemCell", for: indexPath) as! ClipboardItemCell
        let item = clipboardManager.clipboardItems[indexPath.item]
        if case .text(let text) = item.content {
            cell.configure(with: text)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipboardItemCell else { return }
        UIView.animate(withDuration: 0.1) {
            cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            let highlightColor = self.isDarkMode ? UIColor.black.withAlphaComponent(0.6) : UIColor.white.withAlphaComponent(0.6)
            cell.backgroundColor = highlightColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipboardItemCell else { return }
        UIView.animate(withDuration: 0.1) {
            cell.transform = .identity
            let normalColor = self.isDarkMode ? UIColor.black.withAlphaComponent(0.8) : UIColor.white.withAlphaComponent(0.8)
            cell.backgroundColor = normalColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = clipboardManager.clipboardItems[indexPath.item]
        if case .text(let text) = item.content {
            textDocumentProxy.insertText(text)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - Clipboard Item Cell
class ClipboardItemCell: UICollectionViewCell {
    // Static properties for theming
    static var cellBackgroundColor: UIColor = .white
    static var cellTextColor: UIColor = .black
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = 8
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        layer.masksToBounds = true
        
        contentView.addSubview(textLabel)
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Apply current theme colors
        applyTheme()
    }
    
    func configure(with text: String) {
        textLabel.text = text
        // Apply current theme colors
        applyTheme()
    }
    
    private func applyTheme() {
        backgroundColor = ClipboardItemCell.cellBackgroundColor
        textLabel.textColor = ClipboardItemCell.cellTextColor
    }
}
