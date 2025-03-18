//
//  ActionExtension.swift
//  ClipboardHistory
//
//  Created by Arpad Bencze on 13.03.25.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    private var clipboardManager: ClipboardManager!
    private lazy var historyView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        clipboardManager = ClipboardManager.shared
        clipboardManager.loadSavedItems()
        
        // Process any shared content
        processSharedContent()
    }
    
    private func setupUI() {
        navigationItem.title = "Clipboard History"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        view.addSubview(historyView)
        historyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            historyView.topAnchor.constraint(equalTo: view.topAnchor),
            historyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func cancelTapped() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func processSharedContent() {
        // Ensure we have a valid extension context with input items
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            print("No input items found")
            return
        }
        
        // Process each input item
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for provider in attachments {
                // Check for text content
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                        guard let self = self, let text = text as? String, !text.isEmpty else { return }
                        
                        print("Received shared text: \(text)")
                        
                        // Add to clipboard history on main thread
                        DispatchQueue.main.async {
                            // Create a new clipboard item with the shared text
                            let newItem = ClipboardItem(content: .text(text))
                            self.clipboardManager.addItem(newItem)
                            
                            // Show success message and dismiss
                            let alert = UIAlertController(title: "Added to Clipboard History", message: nil, preferredStyle: .alert)
                            self.present(alert, animated: true) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    alert.dismiss(animated: true) {
                                        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension ActionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipboardManager.clipboardItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = clipboardManager.clipboardItems[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        switch item.content {
        case .text(let text):
            content.text = text
        case .image:
            content.text = "Image"
        }
        content.secondaryText = item.timestamp.formatted(date: .numeric, time: .shortened)
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = clipboardManager.clipboardItems[indexPath.row]
        clipboardManager.copyToClipboard(item)
        
        // Show a brief success message
        let alert = UIAlertController(title: "Copied!", message: nil, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true) {
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
            }
        }
    }
}
