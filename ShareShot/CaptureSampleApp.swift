/*
 Abstract:
 The entry point into this app.
 */
import Cocoa
import HotKey
import SwiftUI
import ScreenCaptureKit

// For the new @Observable macro
import Observation

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

@Observable
class StackModel {
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
    // Settings
    let maxScreenshotsToShowOnStack = 5
    let maxStoredHistory = 50
    
    /// Overlay that blocks user interaction without switching key window.
    /// - Removes standard cursor while tracking the mouse position
    /// - Adds a SwiftUI overlay that draws the area selection
    var overlayWindow: ScreenshotAreaSelectionNonactivatingPanel?
    
    /// Each screenshot is added to a stack on the bottom left
    var currentPreviewPanel: ScreenshotStackPanel?
    
    // Start out empty
    // https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro
    let stackModel = StackModel(state: .inactive, images: [])
    
    /// Menu bar
    var statusBarItem: NSStatusItem!
    var contextMenu: NSMenu = NSMenu()
    var popover: NSPopover!
    var eventMonitor: Any?
    // Hot Keys
    // Screenshot
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])
    // Show screenshot history
    let cmdShiftEight = HotKey(key: .eight, modifiers: [.command, .shift])
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        requestAuthorizationForLoginItem()
        
        // TODO: We might want to ask for permissions before trying to screen record using CGRequestScreenCaptureAccess()
        // Probably should do this before allowing the user to proceed with the screenshot
        // That api is known to show settings only once: https://stackoverflow.com/questions/75617005/how-to-show-screen-recording-permission-programmatically-using-swiftui
        // so we might want to track if we shown this before, maybe show additional info to the user suggesting to go to settings
        // but do not open the area selection - no point
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "HasLaunchedBefore") {
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
            self?.showScreenshotHistoryStack()
        }
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleClickOutsidePopover))
        NSApplication.shared.keyWindow?.contentView?.addGestureRecognizer(clickRecognizer)
        handleClickOutsidePopover(sender: clickRecognizer)
        
    }
    
    @objc
    func startScreenshot() {
        // Screenshot area selection already in progress
        guard overlayWindow == nil else {
            return
        }
        
        // This is expected to be visible if we take the second screenshot in a row
        // We will re-show this after the screenshot is complete - or we cancel (might not work right now)
        currentPreviewPanel?.orderOut(nil)
        
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
            
            // Persist new one
            let screenshotsDirectory = screenshotHistoryUrl()
            // Ensure directory exixts
            try? FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: false)
            
            // Cleanup old screenshots
            deleteOldScreenshots()
            
            let newCapturedScreenshotPath = screenshotsDirectory.appendingPathComponent(dateTimeUniqueScreenshotFileName())
            do {
                try capturedImageData.write(to: newCapturedScreenshotPath)
            } catch {
                print("error saving screenshot to history", error, "at path: ", newCapturedScreenshotPath)
            }
            
            // Update model
            stackModel.images.insert(capturedImageData, at: 0)
            
            // Only push up to fixed number of screenshots
            if stackModel.images.count + 1 > maxScreenshotsToShowOnStack {
                stackModel.images.removeLast(stackModel.images.count + 1 - maxScreenshotsToShowOnStack )
            }
            
            // Create panel hosting the stack if not shown
            if currentPreviewPanel == nil {
                currentPreviewPanel = ScreenshotStackPanel(stackModelState: stackModel)
            }
            
            // Always activate the app
            //
            // Magic configuration to show the panel, co7mbined with the panel's configuration results in
            // the app not taking away focus from the current app, yet still appearing.
            // Some of the configuraiton might be discardable - further fiddling might reveal what.
            NSApp.activate(ignoringOtherApps: true)
            currentPreviewPanel?.orderFront(nil)
            currentPreviewPanel?.makeFirstResponder(self.currentPreviewPanel)
        }
        
        screenshotAreaSelectionNoninteractiveWindow.makeKeyAndOrderFront(nil)
        self.overlayWindow = screenshotAreaSelectionNoninteractiveWindow
    }
    
    /// Show history in the same panel as we normally show users
    @objc
    func showScreenshotHistoryStack() {
        // To avoid overflow show only last 44
        let last4Screenshots = lastNScreenshots(n: 4)
        
        // Mutate model in-place
        stackModel.images = last4Screenshots
        stackModel.state = .userAskedToShowHistory
        
        let newCapturePreview = ScreenshotStackPanel(stackModelState: stackModel)
        NSApp.activate(ignoringOtherApps: true)
        newCapturePreview.orderFront(nil)
        newCapturePreview.makeFirstResponder(newCapturePreview)
    }
    
    func allScreenshotUrlsMostRecentOneIsLast() -> [URL] {
        let screenshotsDirectory = screenshotHistoryUrl()
        let urls = try? FileManager.default.contentsOfDirectory(at: screenshotsDirectory, includingPropertiesForKeys: nil)
        let sortedUrls = (urls ?? []).sorted { $0.path < $1.path }
        return sortedUrls
    }
    
    func lastNScreenshots(n: Int) -> [ImageData] {
        let urls = allScreenshotUrlsMostRecentOneIsLast()
        let lastN = urls.suffix(n)
        return lastN.compactMap { try? Data(contentsOf: $0) }
    }
    
    func deleteOldScreenshots() {
        let urls = allScreenshotUrlsMostRecentOneIsLast()
        
        // Drop the urls to keep
        let urlsToDelete = urls.dropLast(maxStoredHistory)
        
        for url in urlsToDelete {
            print("removing old screenshot at ", url)
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    @objc private func showOnboardingView() {
        // Create a new NSPanel
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
                            styleMask: [.titled, .closable, .resizable],
                            backing: .buffered,
                            defer: false)
        
        // Create an instance of the OnboardingView with a completion handler
        let onboardingView = OnboardingView(onComplete: { self.startScreenshot(); panel.close()})
        
        // Create an NSHostingController with the OnboardingView as its rootView
        _ = NSHostingController(rootView: onboardingView)
        
        // Set panel properties
        panel.isFloatingPanel = true
        panel.worksWhenModal = true
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: onboardingView)
        panel.center() // Center the panel on the screen
        panel.level = .floating // Set the panel's level to floating
        
        // Make the panel key and order it front
        panel.makeKeyAndOrderFront(nil)
    }
    
    func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let statusBarItemLogo = NSImage(named: NSImage.Name("LogoForStatusBarItem"))!
        statusBarItemLogo.size = NSSize(width: 18, height: 18)
        statusBarItem.button?.image = statusBarItemLogo
        statusBarItem.button?.action = #selector(togglePopover(_:))
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: StatusBarView(startScreenshot: startScreenshot, quitApplication: quitApplication, history:  showScreenshotHistoryStack, onboarding: showOnboardingView, lastScreenshots: lastNScreenshots(n: 5)))
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
          if popover.isShown {
              popover.performClose(sender)
              if let eventMonitor = eventMonitor {
                  NSEvent.removeMonitor(eventMonitor)
                  self.eventMonitor = nil
              }
          } else if let button = statusBarItem.button {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
              popover.behavior = .applicationDefined
              
              eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                  if let strongSelf = self, strongSelf.popover.isShown {
                      strongSelf.popover.performClose(sender)
                      if let eventMonitor = strongSelf.eventMonitor {
                          NSEvent.removeMonitor(eventMonitor)
                          strongSelf.eventMonitor = nil
                      }
                  }
              }
          }
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
    
    func requestAuthorizationForLoginItem() {
        let helperBundleIdentifier = "com.bra1ndump.share-screenshot"
        guard let launcherAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: helperBundleIdentifier) else {
            return
        }
        
        // AppleScript command to add application to login items
        let scriptString = "tell application \"System Events\" to make login item at end with properties {path:\"\(launcherAppURL.path)\", hidden:false}"
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptString) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("Error adding login item: \(error)")
            }
        }
    }
    
    @objc func handleClickOutsidePopover(sender: NSClickGestureRecognizer) {
        if popover.isShown {
            let location = sender.location(in: nil)
            if !popover.contentViewController!.view.frame.contains(location) {
                popover.performClose(sender)
            }
        }
    }
    // Implement any other necessary AppDelegate methods here
    
}

