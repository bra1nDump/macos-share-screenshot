/*
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
    
    /// Menu bar
    var statusBarItem: NSStatusItem!
    var contextMenu: NSMenu = NSMenu()
    
    // Does not work when moved outside of COntentView
    // Probably something to do with not being able to bind commands when no UI is visible
    // Try - create a random window
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        
        // TODO: We might want to ask for permissions before trying to screen record using CGRequestScreenCaptureAccess()
        // Probably should do this before allowing the user to proceed with the screenshot
        // That api is known to show settings only once: https://stackoverflow.com/questions/75617005/how-to-show-screen-recording-permission-programmatically-using-swiftui
        // so we might want to track if we shown this before, maybe show additional info to the user suggesting to go to settings
        // but do not open the area selection - no point
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "HasLaunchedBefore") {
            showScreenRecordingPermissionAlert()
        }
        defaults.set(true, forKey: "HasLaunchedBefore")
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
            // If image data is nil:
            //   - We canceled by either clicking and doing a single pixel selection
            //   - Or by pressing escape
            // Either way show the stack, unless its empty
            
            if let capturedImageData {
                // 0th element is top of the stack
                capturedImages.insert(capturedImageData, at: 0)
            }
            
            if !capturedImages.isEmpty {
                // Magic configuration to show the panel, combined with the panel's configuration results in
                // the app not taking away focus from the current app, yet still appearing.
                // Some of the configuraiton might be discardable - further fiddling might reveal what.
                let newCapturePreview = ScreenshotStackPanel(imageData: capturedImages)
                NSApp.activate(ignoringOtherApps: true)
                newCapturePreview.orderFront(nil)
                newCapturePreview.makeFirstResponder(newCapturePreview)
                
                self.currentPreviewPanel = newCapturePreview
            }
            
            // Always destroy the screenshot area selection panel
            self.overlayWindow = nil
        }
        
        screenshotAreaSelectionNoninteractiveWindow.makeKeyAndOrderFront(nil)
        self.overlayWindow = screenshotAreaSelectionNoninteractiveWindow
    }
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let statusBarItemLogo = NSImage(named: NSImage.Name("LogoForStatusBarItem"))!
        // https://stackoverflow.com/questions/33703966/osx-status-bar-image-sizing-cocoa#:~:text=The%20size%20of%20the%20image%20should%20be%20set%20to%20(18.0%2C%2018.0)
        statusBarItemLogo.size = NSSize(width: 18, height: 18)
        statusBarItem.button?.image = statusBarItemLogo
        
        // Create a menu
        let contextMenu = NSMenu()
        
        let screenshot = NSMenuItem(title: "Screenshot", action: #selector(startScreenshot), keyEquivalent: "7")
        screenshot.keyEquivalentModifierMask = [.command, .shift]
        let githubMenuItem = NSMenuItem(title: "GitHub", action: #selector(openGitHub), keyEquivalent: "")
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "Q")
        quitMenuItem.keyEquivalentModifierMask = [.command, .shift]
        _ = [
            screenshot,
            githubMenuItem,
            NSMenuItem.separator(),
            quitMenuItem,
        ].map(contextMenu.addItem)
        
        // Set the menu to the status bar item
        statusBarItem.menu = contextMenu
    }
    
    @objc func showScreenRecordingPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "To use this app, please grant screen recording permission in System Preferences > Security & Privacy > Privacy > Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        } else {
        }
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

