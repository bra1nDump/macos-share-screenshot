/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import ScreenCaptureKit
import OSLog
import Combine

import LaunchAtLogin
import HotKey

struct ContentView: View {
    // Nil for preview
    let appDelegate: AppDelegate?
    
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    
    @StateObject var screenRecorder = ScreenRecorder()
    
    let cmdShiftSeven = HotKey(key: .seven, modifiers: [.command, .shift])
    
    var body: some View {
        HSplitView {
            ConfigurationView(screenRecorder: screenRecorder, userStopped: $userStopped)
                .frame(minWidth: 280, maxWidth: 280)
                .disabled(disableInput)
            screenRecorder.capturePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                .padding(8)
                .overlay {
                    if userStopped {
                        Image(systemName: "nosign")
                            .font(.system(size: 250, weight: .bold))
                            .foregroundColor(Color(white: 0.3, opacity: 1.0))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.0, opacity: 0.5))
                    }
                }
        }
        .overlay {
            if isUnauthorized {
                VStack() {
                    Spacer()
                    VStack {
                        Text("No screen recording permission.")
                            .font(.largeTitle)
                            .padding(.top)
                        Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                            .font(.title2)
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    
                }
            }
        }
        .navigationTitle("Screen Capture Sample")
        .onAppear {
            // TODO: Pass the callback to do stuff
            cmdShiftSeven.keyDownHandler = {
                print("Key Down")
            }
//            HotkeySolution.register()
            cmdShiftSeven.keyUpHandler = {
                
                
                // Showing the window I should setup the actual screenshotting s
//                appDelegate?.showOverlayWindow()

                var screenRect = NSScreen.main?.frame ?? NSRect.zero
                    
                // For debugging only allocate part of the screen for testing to be able to stop debugging
                screenRect = screenRect.insetBy(dx: screenRect.width / 4, dy: screenRect.height / 4)
                
                let _ = OverlayWindow(contentRect: screenRect, styleMask: .borderless, backing: .buffered, defer: false)
                
//                overlayWindow.makeKeyAndOrderFront(nil)
            }
            
            Task {
                if await screenRecorder.canRecord {
//                    await screenRecorder.start()
                } else {
                    isUnauthorized = true
                    disableInput = true
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appDelegate: nil)
    }
}
