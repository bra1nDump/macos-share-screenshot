/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import Cocoa
import HotKey
import SwiftUI
import ScreenCaptureKit

@main
struct ShareShotApp {
    static var appDelegate: AppDelegate?
    static func main() {
        let appDelegate = AppDelegate()
        ShareShotApp.appDelegate = appDelegate
        let application = NSApplication.shared
        application.delegate = appDelegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Overlay that blocks user interaction without switching key window.
    /// - Removes standard cursor while tracking the mouse position
    /// - Adds a SwiftUI overlay that draws the area selection
    var overlayWindow: ScreenshotAreaSelectionNonactivatingPanel?
    
    /// Each screenshot is added to a stack on the bottom left
    var currentPreviewPanel: ScreenshotStackPanel?
    var capturedImages: [ImageData] = []
    
    // TODO: Shouldn't this be a computed var { overlayWindow != nil }
    private var isScreenshotInProgress = false
    
    /// Menu bar
    var statusBarItem: NSStatusItem!
    var contextMenu: NSMenu = NSMenu()
    
    // Does not work when moved outside of COntentView
    // Probably something to do with not being able to bind commands when no UI is visible
    // Try - create a random window
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        
        #if DEBUG
        startScreenshot()
        #endif

        cmdShiftSeven.keyDownHandler = { [weak self] in
            // Make sure the old window is dismissed
            self?.startScreenshot()
        }
    }
    
    @objc
    func startScreenshot() {
        // Screenshot area selection already in progress
        guard overlayWindow == nil else {
            return
        }
        
        // This is expected to be visible if we take the second screenshot in a row
        // We will re-show this after the screenshot is complete - or we cancel (might not work right now)
        if let existingPreviewPanel = self.currentPreviewPanel {
            existingPreviewPanel.orderOut(nil)
        }
        
        // Configure and show screenshot area selection
        let screenRect = NSScreen.main?.frame ?? NSRect.zero
        let screenshotAreaSelectionNoninteractiveWindow = ScreenshotAreaSelectionNonactivatingPanel(contentRect: screenRect)
        screenshotAreaSelectionNoninteractiveWindow.onComplete = { [self] capturedImageData in
            self.capturedImages.append(capturedImageData!)
            
            // Magic configuration to show the panel, combined with the panel's configuration results in
            // the app not taking away focus from the current app, yet still appearing.
            // Some of the configuraiton might be discardable - further fiddling might reveal what.
            let newCapturePreview = ScreenshotStackPanel(imageData: capturedImages)
            NSApp.activate(ignoringOtherApps: true)
            newCapturePreview.orderFront(nil)
            newCapturePreview.makeFirstResponder(newCapturePreview)
            
            self.currentPreviewPanel = newCapturePreview
            isScreenshotInProgress = false
            
            self.overlayWindow = nil
        }
        
        screenshotAreaSelectionNoninteractiveWindow.makeKeyAndOrderFront(nil)
        self.overlayWindow = screenshotAreaSelectionNoninteractiveWindow
    }

    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let statusBarItemLogo = NSImage(systemSymbolName: "camera.on.rectangle", accessibilityDescription: nil)
        statusBarItem.button?.image = statusBarItemLogo
        
        // Create a menu
        let contextMenu = NSMenu()
        
        // GitHub link
        let screenshot = NSMenuItem(title: "Screenshot", action: #selector(startScreenshot), keyEquivalent: "Shift+Cmd+7")
        let githubMenuItem = NSMenuItem(title: "GitHub", action: #selector(openGitHub), keyEquivalent: "")
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "Cmd+Q")
        
        _ = [
            screenshot,
            githubMenuItem,
            NSMenuItem.separator(),
            quitMenuItem,
        ].map(contextMenu.addItem)
        
        // Set the menu to the status bar item
        statusBarItem.menu = contextMenu
    }

    @objc func openGitHub() {
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

