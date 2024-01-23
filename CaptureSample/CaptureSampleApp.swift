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
    static var appDelegate: AppDelegate?
    static func main() {
        let appDelegate = AppDelegate()
        MyApplication.appDelegate = appDelegate
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
    private var isScreenshotInProgress = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        createStatusBarItem()
        
        func startScreenshot() {
            guard !isScreenshotInProgress else {
                       return
                   }
                   isScreenshotInProgress = true
            if let existingPreview = overlayWindow?.screenshotPreview {
                existingPreview.removeFromSuperview()
            }
            if let existingPreviewPanel = self.currentPreviewPanel {
                    existingPreviewPanel.orderOut(nil)
                }
            let screenRect = NSScreen.main?.frame ?? NSRect.zero
            self.overlayWindow = OverlayPanel(contentRect: screenRect)
            overlayWindow?.makeKeyAndOrderFront(nil)
            overlayWindow?.onComplete = { [self] capturedImageData in
                   self.capturedImages.append(capturedImageData!)
                let newCapturePreview = ScreenshotPreviewPanel(imageData: capturedImages)
                NSApp.activate(ignoringOtherApps: true)
                       newCapturePreview.orderFront(nil)
                newCapturePreview.makeFirstResponder(newCapturePreview)
                self.currentPreviewPanel = newCapturePreview
                isScreenshotInProgress = false
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
            // Set the button's image (placeholder, replace with your own image)
            if let image = NSImage(systemSymbolName: "camera.on.rectangle", accessibilityDescription: nil) {
                   item.button?.image = image
               }
            
            // Set the action and target
            item.button?.action = #selector(statusBarItemClicked(_:))
            item.button?.target = self
        }
    }

    @objc func statusBarItemClicked(_ sender: AnyObject?) {
        print("Status bar item clicked")

        // Create a menu
        let contextMenu = NSMenu()

        // Add GitHub link
        let githubMenuItem = NSMenuItem(title: "GitHub", action: #selector(openGitHub), keyEquivalent: "")
        contextMenu.addItem(githubMenuItem)

        // Add a separator
        contextMenu.addItem(NSMenuItem.separator())

        // Add Quit item
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "q")
        contextMenu.addItem(quitMenuItem)

        // Set the menu to the status bar item
        statusBarItem?.menu = contextMenu
    }

    @objc func openGitHub() {
        // Replace "YOUR_GITHUB_URL" with the actual GitHub link
        if let url = URL(string: "https://github.com/bra1nDump/macos-share-shot") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func quitApplication() {
        NSApplication.shared.terminate(self)
    }

    @objc func deleteImage(_ image: ImageData) {
        if let index = capturedImages.firstIndex(of: image) {
            capturedImages.remove(at: index)
        }
    }

    // Implement any other necessary AppDelegate methods here
}

