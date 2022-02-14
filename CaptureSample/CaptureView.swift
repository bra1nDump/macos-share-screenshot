/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import ScreenCaptureKit
import OSLog
import Combine

struct CaptureView: View {
    
    @StateObject var screenRecorder = ScreenRecorder()
    @State var availableContent: SCShareableContent?
    @State var captureConfig = CaptureConfiguration()
    @State var error: Error?
    @State var timer: Cancellable?
    
    private let logger = Logger()
    
    var filteredWindows: [SCWindow]? {
        availableContent?.windows.sorted {
            $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? ""
        }
        .filter {
            $0.owningApplication != nil && $0.owningApplication?.applicationName != ""
        }
    }
    
    var body: some View {
        ScrollView {
            Form {
                Picker("Capture Type", selection: $captureConfig.captureType) {
                    Text("Entire Display")
                        .tag(CaptureType.display)
                    Text("Independent Window")
                        .tag(CaptureType.independentWindow)
                }
                
                switch captureConfig.captureType {
                case .display:
                    Picker("Display", selection: $captureConfig.display) {
                        ForEach(availableContent?.displays ?? [], id: \.self) { display in
                            Text("\(display.width) x \(display.height)")
                                .tag(SCDisplay?.some(display))
                        }
                    }
                    
                    Toggle("Remove this app from the stream", isOn: $captureConfig.filterOutOwningApplication)
                    
                case .independentWindow:
                    Picker("Window", selection: $captureConfig.window) {
                        ForEach(filteredWindows ?? [], id: \.self) { window in
                            Text(window.displayName)
                                .tag(SCWindow?.some(window))
                        }
                    }
                }
                
                HStack {
                    if screenRecorder.isRecording {
                        Button("Update Stream") {
                            Task {
                                await screenRecorder.update(with: captureConfig)
                            }
                        }
                    } else {
                        Button("Start Stream") {
                            error = nil
                            Task {
                                await screenRecorder.startCapture(with: captureConfig)
                            }
                        }
                    }
                    
                    Button("Stop Stream") {
                        Task(priority: .high) {
                            await screenRecorder.stopCapture()
                        }
                    }
                    .disabled(!screenRecorder.isRecording)
                }
            }
            
            if let error = screenRecorder.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
            
            if let error = error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
            
            if let frame = screenRecorder.latestFrame {
                FrameDataView(frame)
                    .padding()
                FrameView(frame.surface)
                    .aspectRatio(frame.contentRect.size, contentMode: .fit)
            }
        }
        .padding()
        .onAppear {
            timer = RunLoop.current.schedule(after: .init(.now), interval: .seconds(3)) {
                Task {
                    do {
                        availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

                        // Set the display if not previously selected.
                        if captureConfig.display == nil {
                            captureConfig.display = availableContent?.displays.first
                        }
                        
                        // Set the selected window if not previously selected.
                        if captureConfig.window == nil {
                            captureConfig.window = availableContent?.windows.first
                        }
                    } catch {
                        self.error = error
                        logger.error("Failed to get shareable content: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureView()
    }
}
