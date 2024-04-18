//
//  StatusBarView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 4/16/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

class StatusBarManager {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    init() {
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("LogoForStatusBarItem"))
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Screenshot", action: #selector(startScreenshot), keyEquivalent: "7"))
        menu.addItem(NSMenuItem.separator())
        let lastScreenshots = lastNScreenshots(n: 5)
        for (index, screenshot) in lastScreenshots.enumerated() {
            let resizedImage = resizeImage(NSImage(data: screenshot)!, newSize: NSSize(width: 70, height: 50))
            let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            menuItem.image = resizedImage
            menuItem.representedObject = screenshot
            menuItem.target = self
            menuItem.submenu = createCopyToClipboardSubmenu(for: screenshot)
            menu.addItem(menuItem)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "Q"))
        
        statusItem.menu = menu
    }
    
    @objc func startScreenshot() {
        // Handle screenshot action
    }
    
    @objc func quitApplication() {
        NSApplication.shared.terminate(self)
    }
    
    func lastNScreenshots(n: Int) -> [Data] {
        // Implementation to get last n screenshots
        return []
    }
    
    func resizeImage(_ image: NSImage, newSize: NSSize) -> NSImage {
        // Implementation to resize image
        return image
    }
    
    func createCopyToClipboardSubmenu(for screenshot: Data) -> NSMenu {
        // Implementation to create submenu for copying to clipboard
        return NSMenu()
    }
}

struct StatusBarView: View {
    var model: StackModel
    var startScreenshot: () -> Void
    var quitApplication: () -> Void
    
    init(model: StackModel, startScreenshot: @escaping () -> Void, quitApplication: @escaping () -> Void) {
            self.model = model
            self.startScreenshot = startScreenshot
            self.quitApplication = quitApplication
        }
    
    var body: some View {
        var capturedImages = model.images
        Menu {
            Button(action: startScreenshot) {
                Label("Screenshot", systemImage: "camera")
            }
            
            ForEach(1..<6) { index in
                Button(action: {}) {
                    Label("Screenshot \(index)", systemImage: "photo")
                }
                ForEach(capturedImages.reversed(), id: \.self) { image in
                    ScreenShotStatusBarView(image: image)
                }
            }
            
            Divider()
            
            Button(action: quitApplication) {
                Label("Quit", systemImage: "power")
            }
        } label: {
            Image(systemName: "star")
                .foregroundColor(.blue)
                .imageScale(.large)
        }
    }
}

