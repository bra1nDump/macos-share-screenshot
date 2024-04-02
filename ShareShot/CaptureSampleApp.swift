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
    @AppStorage("onboardingShown") static var onboardingShown = false
    static var appDelegate: AppDelegate?
    
    static func main() {
        let appDelegate = AppDelegate()
        ShareShotApp.appDelegate = appDelegate
        let application = NSApplication.shared
        application.delegate = appDelegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

enum StackState {
    case inactive
    case userTookAScreenshot
    case userAskedToShowHistory
}

class StackModel: ObservableObject {
    var state: StackState
    /// Images shown
    var images: [ImageData]
    
    init(state: StackState, images: [ImageData]) {
        self.state = state
        self.images = images
    }
}

/**
 * Showing onboarding
 * Idle
 * Taking new screenshot
 *  (optionally some screenshots are already taken)
 * Showing stack of screenshots
 *  (could be from history, could be after taking a screenshot)
 *  - panel showing the view, array of images to show, a way to modify the array from inside the view
 */

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Overlay that blocks user interaction without switching key window.
    /// - Removes standard cursor while tracking the mouse position
    /// - Adds a SwiftUI overlay that draws the area selection
    var overlayWindow: ScreenshotAreaSelectionNonactivatingPanel?
    
    /// Each screenshot is added to a stack on the bottom left
    var currentPreviewPanel: ScreenshotStackPanel?
    
    // Start out empty
    @StateObject var stackModel = StackModel(state: .inactive, images: [])
    
    /// Menu bar
    var statusBarItem: NSStatusItem!
    var contextMenu: NSMenu = NSMenu()
    
    // Hot Keys
    // Screenshot
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])
    // Show screenshot history
    let cmdShiftEight = HotKey(key: .eight, modifiers: [.command, .shift])
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        
        // TODO: We might want to ask for permissions before trying to screen record using CGRequestScreenCaptureAccess()
        // Probably should do this before allowing the user to proceed with the screenshot
        // That api is known to show settings only once: https://stackoverflow.com/questions/75617005/how-to-show-screen-recording-permission-programmatically-using-swiftui
        // so we might want to track if we shown this before, maybe show additional info to the user suggesting to go to settings
        // but do not open the area selection - no point
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "HasLaunchedBefore") == false {
            showOnboardingView()
        } else {
#if DEBUG
      //  startScreenshot()
#endif
        }
        defaults.set(true, forKey: "HasLaunchedBefore")

        cmdShiftSeven.keyDownHandler = { [weak self] in
            // Make sure the old window is dismissed
            self?.startScreenshot()
        }
        
        cmdShiftEight.keyDownHandler = { [weak self] in
            // TODO:
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
        
        screenshotAreaSelectionNoninteractiveWindow.onComplete = { [weak self] capturedImageData in
            // If image data is nil:
            //   - We canceled by either clicking and doing a single pixel selection
            //   - Or by pressing escape
            // Either way show the stack, unless its empty
            
            // Always destroy the screenshot area selection panel
            self?.overlayWindow = nil
            
            // New screenshot arrived, we did not just cancel
            guard let capturedImageData, let self else {
                return
            }
            
            // TODO: Save image
            
            // Use date
            let screenshotsDirectory = screenshotHistoryUrl()
            
            // TODO: Cleanup the old data
            // Sort by url - they are carefuly formatted. Delete all (usually one) in the tail
//            FileManager.default.contentsOfDirectory(at: screenshotsDirectory, includingPropertiesForKeys: nil)
            
            let newCapturedScreenshotPath = screenshotsDirectory.appendingPathComponent(dateTimeUniqueScreenshotFileName())
            try? capturedImageData.write(to: newCapturedScreenshotPath)
            
            self.stackModel.images.insert(capturedImageData, at: 0)

            // Show panel if now showing already - actually should never be present!
            if self.currentPreviewPanel == nil {
                // Magic configuration to show the panel, combined with the panel's configuration results in
                // the app not taking away focus from the current app, yet still appearing.
                // Some of the configuraiton might be discardable - further fiddling might reveal what.
                let newCapturePreview = ScreenshotStackPanel(stackModelState: _stackModel)
                NSApp.activate(ignoringOtherApps: true)
                newCapturePreview.orderFront(nil)
                newCapturePreview.makeFirstResponder(newCapturePreview)
                
                print("New model image count: \(_stackModel.wrappedValue.images.count)")
                
                self.currentPreviewPanel = newCapturePreview
            }
        }
        
        screenshotAreaSelectionNoninteractiveWindow.makeKeyAndOrderFront(nil)
        self.overlayWindow = screenshotAreaSelectionNoninteractiveWindow
    }
    
    /// Show history in the same panel as we normally show users
    func showScreenshotHistoryStack() {
        let last4Screenshots = lastNScreenshots(n: 4)
        
        // Mutate model in-place
        stackModel.images = last4Screenshots
        stackModel.state = .userAskedToShowHistory
        
        let newCapturePreview = ScreenshotStackPanel(stackModelState: _stackModel)
        NSApp.activate(ignoringOtherApps: true)
        newCapturePreview.orderFront(nil)
        newCapturePreview.makeFirstResponder(newCapturePreview)
    }

    func lastNScreenshots(n: Int) -> [ImageData] {
        let screenshotsDirectory = screenshotHistoryUrl()
        let urls = try! FileManager.default.contentsOfDirectory(at: screenshotsDirectory, includingPropertiesForKeys: nil)
        let sortedUrls = urls.sorted { $0.path < $1.path }
        let lastN = sortedUrls.suffix(n)
        return lastN.compactMap { try? Data(contentsOf: $0) }
    }
    
    private func showOnboardingView() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
                            styleMask: [.titled, .closable, .resizable],
                            backing: .buffered,
                            defer: false)
        let onboardingView = OnboardingView(onComplete: { self.startScreenshot(); panel.close()})
        let onboardingViewController = NSHostingController(rootView: onboardingView)

        panel.contentView = NSHostingView(rootView: onboardingView)
        panel.center() // Центрируем панель на экране

        // Устанавливаем panel.level, чтобы панель была поверх других окон
        panel.level = .floating
        
        panel.makeKeyAndOrderFront(nil)
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
            CGRequestScreenCaptureAccess()
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
    
    // Implement any other necessary AppDelegate methods here
}

