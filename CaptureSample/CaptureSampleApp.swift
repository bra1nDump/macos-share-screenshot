/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import Cocoa
import HotKey
import SwiftUI

@main
struct MyApplication {
  static func main() {
      let appDelegate = AppDelegate()
      let application = NSApplication.shared
      application.delegate = appDelegate
      _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var currentPreviewPanel: ScreenshotPreviewPanel?
    var statusBarItem: NSStatusItem?
    var capturedImages: [ImageData] = []
    // The menu that drops down from the menu bar item.
    var contextMenu: NSMenu = NSMenu()
    var overlayWindow: OverlayPanel?
    // Does not work when moved outside of COntentView
    // Probably something to do with not being able to bind commands when no UI is visible
    // Try - create a random window
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])

    func applicationDidFinishLaunching(_ notification: Notification) {
        createStatusBarItem()
        
        func startScreenshot() {
            if let existingPreview = overlayWindow?.screenshotPreview {
                existingPreview.removeFromSuperview()
            }
            if let existingPreviewPanel = self.currentPreviewPanel {
                    existingPreviewPanel.orderOut(nil)
                }
            let screenRect = NSScreen.main?.frame ?? NSRect.zero
            self.overlayWindow = OverlayPanel(contentRect: screenRect)
            overlayWindow?.onCapture = { [self] capturedImageData in
                   self.capturedImages.append(capturedImageData)
                let newCapturePreview = ScreenshotPreviewPanel(imageData: capturedImages)
                       newCapturePreview.makeKeyAndOrderFront(nil)
                self.currentPreviewPanel = newCapturePreview
                      }
        }
        // DEBUGGING
        startScreenshot()

        cmdShiftSeven.keyDownHandler = {
            // Make sure the old window is dismissed
            startScreenshot()
        }
    }

    private func createStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let item = statusBarItem {
            item.button?.title = "lol" // TODO: replace with image
            item.button?.action = #selector(statusBarItemClicked(_:))
            item.button?.target = self
        }
    }

    @objc func statusBarItemClicked(_ sender: AnyObject?) {
        print("Status bar item clicked")

        // Show the menu with a single example item: "Hello World".
        let menuItem = NSMenuItem(title: "Hello World", action: nil, keyEquivalent: "")
        contextMenu.addItem(menuItem)
        statusBarItem?.menu = contextMenu
        

        // Handle the action when the status bar item is clicked
    }

    // Implement any other necessary AppDelegate methods here
}

class ScreenshotPreviewPanel: NSPanel {
    init(imageData: [ImageData]) {
        let previewRect = NSRect(x: 0, y: 0, width: 300, height: 800)
        super.init(contentRect: previewRect, styleMask: .borderless, backing: .buffered, defer: false)
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
     
        let hostingView = NSHostingView(rootView: CaptureStackView(capturedImages: imageData))
        hostingView.frame = previewRect
        self.contentView?.addSubview(hostingView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
