//
//  ScreenshotAreaSelectionView.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import Carbon
import ScreenCaptureKit
import AVFoundation
// Current problem:
// When app not in actual focus (title visible) - no view is rendered, mouse moves come through
// When app is in focus - it renders the view, but mouse moves don't come

// Seems like the key difference is - the app is not active when creating the window initially
// I can probably create it once the app starts and actually add stuff to it later on

// Define your SwiftUI view
struct ScreenshotAreaSelectionView: View {
    @State private var capturedImageData: ImageData?
    @State private var capturedImages: [ImageData] = []
    enum CaptureOverlayState {
        case placingAnchor(currentVirtualCursorPosition: CGPoint)
        // Starts out the same as anchor
        case selectingFrame(anchorPoint: CGPoint, virtualCursorPosition: CGPoint)
        
        // Final state does not need to be represented here, will be called out with a frame and recored once this window dies
        // hmmm but for gifs this would need to change, so lets just keep it here
        
        case capturing(frame: CGRect)
    }
    
    // State manager class
    class KeyboardAndMouseEventMonitors: ObservableObject {
        private var globalMonitors: [Any?] = []

        func startMonitoringEvents(onMouseDown: @escaping (CGPoint) -> Void, onMouseUp: @escaping (CGPoint) -> Void, onMouseMove: @escaping (CGPoint) -> Void, onEscape: @escaping () -> Void) {
            print("startMonitoringEvents")
            
            // Ensure no duplicate monitors
            stopMonitoringEvents()
            
            func adaptorEventToMousePosition(_ handler: @escaping (CGPoint) -> Void) -> (NSEvent) -> NSEvent {
                return { (event: NSEvent) in
                    guard let window = event.window else { return event }
                    let point = convertToSwiftUICoordinates(event.locationInWindow, in: window)
                    handler(point)
                    
                    return event
                }
            }

            globalMonitors = [
                // This will only work when mouse is not down, we still need it for anchor placement stage
                NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved], handler: adaptorEventToMousePosition(onMouseMove)),
                
                // Drag will be emited while mouse is down
                // IDEA: right mouse dragged for capturing video / creating link by default
                NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged, .otherMouseDragged], handler: adaptorEventToMousePosition(onMouseMove)),
                
                NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown], handler: adaptorEventToMousePosition(onMouseDown)),
                
                NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp], handler: adaptorEventToMousePosition(onMouseUp)),
                
                // Catch Escape by watching all keyboard presses
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if Int(event.keyCode) == kVK_Escape {
                        print("escape")
                        onEscape()
                        
                        // To avoid the beep
                        return nil
                    } else {
                        return nil
                    }
                },
            ]
        }

        func stopMonitoringEvents() {
            for monitor in globalMonitors {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
            globalMonitors.removeAll()
        }
        
        // Why is this not being called?!
        deinit {
            stopMonitoringEvents()
        }
    }

    let onComplete: (_ imageData: Data?) -> Void
    @ObservedObject private var eventMonitors = KeyboardAndMouseEventMonitors()
    @State private var state: CaptureOverlayState
    
    init(initialMousePosition: CGPoint, onComplete: @escaping (_: Data?) -> Void) {
        self.onComplete = onComplete
        self.state = .placingAnchor(currentVirtualCursorPosition: initialMousePosition)
    }
    
    var body: some View {
        GeometryReader { geometry in
            createOverlayView(geometry: geometry)
                .onDisappear {
                    print("on dissapear")
                    eventMonitors.stopMonitoringEvents()
                }
                .onAppear {
                    print("on appear")
                    
                    // We might be able to move this up to the view init code
                    eventMonitors.startMonitoringEvents(
                        onMouseDown: { point in
                            print("mouse down")
                            // TODO: Only if we are in placing anchor
                            
                            // Capture the initial point and transition to placingAnchor state
                            state = .selectingFrame(anchorPoint: point, virtualCursorPosition: point)
                        },
                        onMouseUp: { point in
                            print("mouse up")
                            // Finalize the selection if in selectingFrame state
                            if case .selectingFrame(let anchorPoint, let virtualCursorPosition) = state {
                                let frame = Self.toFrame(anchorPoint: anchorPoint, virtualCursorPosition: virtualCursorPosition)
                                // Check if the frame's size is zero
                                if frame.size.width == 0 || frame.size.height == 0 {
                                    onComplete(nil)
                                } else {
                                    state = .capturing(frame: frame)
                                    // TODO: Kick off the actual screen capture
                                }
                            }
                        },
                        onMouseMove: { point in
                            // The state might need to move as I think this might not be releasing the window when escape is clicked
                            print("on move")
                            switch state {
                            case .placingAnchor(_):
                                print("== placingAnchor")
                                // Transition to selectingFrame state
                                state = .placingAnchor(currentVirtualCursorPosition: point)
                            case .selectingFrame(let anchorPoint, _):
                                print("== selectingFrame")
                                // When mouse down - we stop recieving moves :D
                                // Update virtualCursorPosition
                                state = .selectingFrame(anchorPoint: anchorPoint, virtualCursorPosition: point)
                            case .capturing:
                                print("ignore")
                                // Ignore if in final state
                                break
                            }
                        },
                        onEscape: {
                            // Manually release monitors to release the view - otherwise the monitors hold on to reference to the Window (somehow) I am assuming and the window does not get ordered out
                            eventMonitors.stopMonitoringEvents()
                            onComplete(nil)
                        }
                    )
                }
        }
    }

    @ViewBuilder
    private func createOverlayView(geometry: GeometryProxy) -> some View {
        // Parametrize the cursor parameters and create view based on current state
        switch state {
        case .placingAnchor(let currentVirtualCursorPosition):
            createCrosshairView(center: currentVirtualCursorPosition)
        case .selectingFrame(let anchorPoint, let virtualCursorPosition):
            createSelectionRectangle(anchor: anchorPoint, currentPoint: virtualCursorPosition)
            createCrosshairView(center: virtualCursorPosition)
        case .capturing(let frame):
            withAnimation{
                createCaptureView(frame: frame)
            }
        }
    }

    private func createCrosshairView(center: CGPoint) -> some View {
        Path { path in
            path.move(to: CGPoint(x: center.x - 8, y: center.y))
            path.addLine(to: CGPoint(x: center.x + 8, y: center.y))
            path.move(to: CGPoint(x: center.x, y: center.y - 8))
            path.addLine(to: CGPoint(x: center.x, y: center.y + 8))
        }
        .stroke(Color.blue, lineWidth: 1)
    }

    private func createSelectionRectangle(anchor: CGPoint, currentPoint: CGPoint) -> some View {
        print("anchor \(anchor) current: \(currentPoint)")
        let frame = Self.toFrame(anchorPoint: anchor, virtualCursorPosition: currentPoint)
        
        // Create a rectangle view based on anchor and currentPoint
        return Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }
    func getShareableContent() async throws -> SCDisplay? {
        return try await withCheckedThrowingContinuation { continuation in
            SCShareableContent.getWithCompletionHandler { availableContent, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    guard let availableContent = availableContent else {
                        continuation.resume(returning: nil)
                        return
                    }
                    guard let display = availableContent.displays.first else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: display)
                }
            }
        }
    }
    func captureScreenshotKit(rect: CGRect, display: SCDisplay) async throws -> NSImage? {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        if #available(macOS 14.0, *) {
            let config = SCStreamConfiguration.defaultConfig(width: Int(rect.width), height: Int(rect.height))
            
            let image = try? await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            if let cgImage = image {
                return NSImage(cgImage: cgImage, size: rect.size)
            }
        }
        return nil
    }
    private func captureScreenshot(rect: CGRect) -> NSImage? {
        guard let cgImage = CGDisplayCreateImage(CGMainDisplayID(), rect: rect) else {
            return nil
        }
        let capturedImage = NSImage(cgImage: cgImage, size: rect.size)
        guard capturedImage.isValid else {
            return nil
        }
        return capturedImage
    }
    private func captureScreenshotT(rect: CGRect) -> NSImage? {
        let group = DispatchGroup()
        var resultImage: NSImage?
        Task {
            group.enter()
            do {
                resultImage = try await captureScreenshotKit(rect: rect, display: getShareableContent()!)
            } catch {
                print("Error capturing image: \(error)")
            }
            group.leave()
        }
        group.wait()

        return resultImage
    }
    private func createCaptureView(frame: CGRect) -> some View {
        DispatchQueue.main.async {
            if let screenshot = captureScreenshot(rect: frame),
               
               let imageData = screenshot.tiffRepresentation,
               !capturedImages.contains(imageData) {
                capturedImages.append(imageData)
                onComplete(imageData)
            }
        }
        return EmptyView()
    }
    static private func toFrame(anchorPoint: CGPoint, virtualCursorPosition: CGPoint) -> CGRect {
        CGRect(x: min(anchorPoint.x, virtualCursorPosition.x),
               y: min(anchorPoint.y, virtualCursorPosition.y),
               width: abs(anchorPoint.x - virtualCursorPosition.x),
               height: abs(anchorPoint.y - virtualCursorPosition.y))
    }
}
typealias ImageData = Data
func getShareableContent() {
  SCShareableContent.getWithCompletionHandler { availableContent, error in
    guard let availableContent = availableContent else {
      return
    }
      guard availableContent.displays.first != nil else {
      return
    }
  }
}
func captureScreen(windows: [SCWindow], display: SCDisplay) async throws -> CGImage? {
    let availableWindows = windows.filter { window in
        Bundle.main.bundleIdentifier != window.owningApplication?.bundleIdentifier
    }
    let filter = SCContentFilter(display: display, including: availableWindows)

    if #available(macOS 14.0, *) {
        let image = try? await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: SCStreamConfiguration.defaultConfig(
                        width: display.width,
                        height: display.height
                )
        )
        return image
    } else {
        return nil
    }
}
extension SCStreamConfiguration {
    static func defaultConfig(width: Int, height: Int) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.width = width
        config.height = height
        config.showsCursor = false
        if #available(macOS 14.0, *) {
            config.captureResolution = .best
        }
        return config
    }
}

