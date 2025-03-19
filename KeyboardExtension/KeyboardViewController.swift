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
    private var titleLabel: UILabel!
    
    // Track if emoji picker is visible
    private var isEmojiPickerVisible = false
    
    private let clipboardHistoryHeight: CGFloat = 56 // Fixed height for clipboard items
    
    private var collectionViewHeightConstraint: NSLayoutConstraint!

    private var keyboardTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupClipboardManager()
        
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
        
        // Log for debugging
        print("⌨️ Keyboard shown - reloading clipboard items")
    }
    
    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        cleanup()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0) // iOS keyboard gray
        

        
        // Setup title label
        titleLabel = UILabel()
        titleLabel.text = "Copy History"
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .black
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 40)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
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
            // Title label at the top
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Collection view below the title
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
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
        
        // Create emoji grid
        let emojiContainer = UIView()
        emojiContainer.tag = 999
        emojiContainer.backgroundColor = .systemBackground
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.addSubview(emojiContainer)
        
        NSLayoutConstraint.activate([
            emojiContainer.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 8),
            emojiContainer.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: 8),
            emojiContainer.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor, constant: -8),
            emojiContainer.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add emoji buttons
        let buttonSize: CGFloat = 32
        let spacing: CGFloat = 8
        
        for (index, emoji) in commonEmojis.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 24)
            button.backgroundColor = .clear
            button.layer.cornerRadius = buttonSize / 2
            button.tag = index
            
            // Add action to insert emoji
            button.addTarget(self, action: #selector(insertEmoji(_:)), for: .touchUpInside)
            
            emojiContainer.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: emojiContainer.topAnchor),
                button.leadingAnchor.constraint(equalTo: emojiContainer.leadingAnchor, constant: CGFloat(index) * (buttonSize + spacing)),
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
        emojiButton.setTitle("emoji", for: .normal)
        emojiButton.titleLabel?.font = .systemFont(ofSize: 20)
        emojiButton.addTarget(self, action: #selector(showEmojiPicker), for: .touchUpInside)
        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        let keyboardView = UIView()
        keyboardView.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0) // iOS keyboard gray
        
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
                button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
                
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
            cell.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipboardItemCell else { return }
        UIView.animate(withDuration: 0.1) {
            cell.transform = .identity
            cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)
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
    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
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
        backgroundColor = UIColor.white.withAlphaComponent(0.8)
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
    
    func configure(with text: String) {
        textLabel.text = text
    }
}
