//
//  ImageEditorWindow.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 3/3/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Cocoa

// Window controller for image editing
class ImageEditorWindowController: NSWindowController, NSWindowDelegate {
    private var imageView: NSImageView!
    var openImage: ((ImageData) -> Void)?
    
    // Convenience initializer to set up the window
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.closable, .resizable, .miniaturizable, .fullSizeContentView],
                              backing: .buffered,
                              defer: false)
        self.init(window: window)
        
        window.title = "Image Editor"
        window.delegate = self
        window.center()
        
        setupUI()
    }
    
    // Setup UI elements within the window
    private func setupUI() {
        imageView = NSImageView(frame: NSRect(x: 20, y: 20, width: 400, height: 300))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        window?.contentView?.addSubview(imageView)
        
        let openButton = NSButton(title: "Open Image", target: self, action: #selector(openImage(_:)))
        openButton.frame = NSRect(x: 440, y: 250, width: 140, height: 30)
        window?.contentView?.addSubview(openButton)
        
        let saveButton = NSButton(title: "Save Image", target: self, action: #selector(saveImage(_:)))
        saveButton.frame = NSRect(x: 440, y: 200, width: 140, height: 30)
        window?.contentView?.addSubview(saveButton)
    }
    
    // Action method to open an image
    @objc private func openImage(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["jpg", "jpeg", "png"]
        
        openPanel.begin { response in
            if response == .OK, let imageURL = openPanel.url {
                let image = NSImage(contentsOf: imageURL)
                self.imageView.image = image
            }
        }
    }
    
    // Action method to save the edited image
    @objc private func saveImage(_ sender: Any) {
        guard let image = imageView.image else {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["png", "jpg", "jpeg"]
        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                guard let data = image.tiffRepresentation else {
                    // Handle the case when there is an issue with image representation
                    return
                }
                
                do {
                    try data.write(to: saveURL, options: .atomic)
                } catch {
                    // Handle the error while saving
                    print("Error saving image: \(error)")
                }
            }
        }
    }
}
