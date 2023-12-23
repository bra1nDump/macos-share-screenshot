/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import Cocoa
import HotKey

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
    var statusBarItem: NSStatusItem?
    
    // The menu that drops down from the menu bar item.
    var contextMenu: NSMenu = NSMenu()
    
    // Does not work when moved outside of COntentView
    // Probably something to do with not being able to bind commands when no UI is visible
    // Try - create a random window
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])

    func applicationDidFinishLaunching(_ notification: Notification) {
        createStatusBarItem()
        
        let overlayWindow: OverlayPanel? = nil
        func startScreenshot() {
            if let existingPreview = overlayWindow?.screenshotPreview {
                existingPreview.removeFromSuperview()
            }

            let screenRect = NSScreen.main?.frame ?? NSRect.zero
            _ = OverlayPanel(contentRect: screenRect)

           
          
        }

        // Additional function for capturing a screenshot
        func captureScreenshot(rect: NSRect) -> NSImage? {
            let cgImage = CGDisplayCreateImage(CGMainDisplayID(), rect: rect)!
            return NSImage(cgImage: cgImage, size: rect.size)
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

