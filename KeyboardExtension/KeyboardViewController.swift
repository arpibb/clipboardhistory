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
    private var toggleButton: UIButton!
    private var toggleLabel: UILabel!
    private var keyboardView: UIView!
    private var isHistoryExpanded: Bool = false
    
    private let collapsedHeight: CGFloat = 24 // Height for toggle button + padding
    private let expandedHeight: CGFloat = 56 // Height for clipboard items
    
    private var collectionViewHeightConstraint: NSLayoutConstraint!
    private var toggleButtonHeightConstraint: NSLayoutConstraint!
    private var keyboardTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupClipboardManager()
        
        // Set initial state to collapsed
        toggleButtonHeightConstraint.constant = 24 // Keep toggle button visible
        collectionViewHeightConstraint.constant = 0
        collectionView.isHidden = true
        collectionView.alpha = 0
        

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
        

        
        // Setup toggle button
        toggleButton = UIButton(type: .system)
        toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        toggleButton.tintColor = .black
        toggleButton.backgroundColor = .clear // Remove background
        toggleButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        toggleButton.addTarget(self, action: #selector(toggleHistoryView), for: .touchUpInside)
        
        // Setup toggle label
        toggleLabel = UILabel()
        toggleLabel.text = "Clipboard History"
        toggleLabel.font = .systemFont(ofSize: 15)
        toggleLabel.textColor = .black
        
        view.addSubview(toggleButton)
        view.addSubview(toggleLabel)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
        toggleButtonHeightConstraint = toggleButton.heightAnchor.constraint(equalToConstant: 20)
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: expandedHeight)
        keyboardTopConstraint = keyboardView.topAnchor.constraint(equalTo: collectionView.bottomAnchor)
        
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            toggleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            toggleButton.widthAnchor.constraint(equalToConstant: 30),
            toggleButtonHeightConstraint,
            
            toggleLabel.centerYAnchor.constraint(equalTo: toggleButton.centerYAnchor),
            toggleLabel.leadingAnchor.constraint(equalTo: toggleButton.trailingAnchor, constant: 4),
            
            collectionView.topAnchor.constraint(equalTo: toggleButton.bottomAnchor),
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
        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 30),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
        updateHistoryViewVisibility()
    }
    
    @objc private func toggleHistoryView() {
        isHistoryExpanded.toggle()
        updateHistoryViewVisibility()
    }
    
    private func updateHistoryViewVisibility() {
        // Update heights
        toggleButtonHeightConstraint.constant = 24 // Keep toggle button height constant
        collectionViewHeightConstraint.constant = isHistoryExpanded ? expandedHeight : 0
        
        // Update visibility
        collectionView.isHidden = !isHistoryExpanded
        collectionView.alpha = isHistoryExpanded ? 1.0 : 0.0
        
        // Rotate chevron
        toggleButton.transform = isHistoryExpanded ? 
            CGAffineTransform(rotationAngle: .pi) : .identity
        
        // Update label
        toggleLabel.text = isHistoryExpanded ? "Close History" : "Copy History"
        
        // Force layout update
        view.layoutIfNeeded()
    }
    
    private func createKeyboardView() -> UIView {
        let keyboardView = UIView()
        keyboardView.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0) // iOS keyboard gray
        
        // Define key layouts
        let layout = [
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
            ["123", "space", "return"]
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
                button.layer.cornerRadius = 5
                button.titleLabel?.font = .systemFont(ofSize: 18)
                button.tintColor = .black // iOS keyboard text color
                
                if key == "space" {
                    button.setTitle(" ", for: .normal)
                }
                
                button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
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
        
        return keyboardView
    }
    
    @objc private func keyPressed(_ sender: UIButton) {
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
