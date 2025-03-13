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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clipboardManager = ClipboardManager()
        setupUI()
        
        // Listen for clipboard changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipboardDidChange),
            name: Notification.Name("ClipboardHistoryDidChange"),
            object: nil
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 150, height: 70)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ClipboardItemCell.self, forCellWithReuseIdentifier: "ClipboardItemCell")
        collectionView.showsHorizontalScrollIndicator = false
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 86)
        ])
        
        // Setup keyboard switcher button
        nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 20)
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
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
    }
    
    override func textWillChange(_ textInput: UITextInput?) {}
    
    override func textDidChange(_ textInput: UITextInput?) {}
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func clipboardDidChange() {
        collectionView.reloadData()
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
            cell.configure(with: text) { [weak self] in
                self?.clipboardManager.deleteItem(item)
                collectionView.reloadData()
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = clipboardManager.clipboardItems[indexPath.item]
        if case .text(let text) = item.content {
            textDocumentProxy.insertText(text)
        }
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
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    var onDelete: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(textLabel)
        contentView.addSubview(deleteButton)
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    func configure(with text: String, onDelete: @escaping () -> Void) {
        textLabel.text = text
        self.onDelete = onDelete
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}
