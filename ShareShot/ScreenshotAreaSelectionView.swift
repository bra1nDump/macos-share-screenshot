//
//  ScreenshotAreaSelectionView.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import ScreenCaptureKit
import AVFoundation

/**
 This view is
 */
struct ScreenshotAreaSelectionView: View {

    private enum CaptureOverlayState {
        case placingAnchor(currentVirtualCursorPosition: CGPoint)
        // Starts out the same as anchor
        case selectingFrame(anchorPoint: CGPoint, virtualCursorPosition: CGPoint)
        
        // No need to keep track of the frame
        case capturingInProgress
    }
    
    let onComplete: (_ imageData: Data?) -> Void
    @ObservedObject private var eventMonitors = KeyboardAndMouseEventMonitors()
    @State private var state: CaptureOverlayState
    
    var isDebugging = false
    
    init(initialMousePosition: CGPoint, onComplete: @escaping (_: Data?) -> Void) {
        self.onComplete = onComplete
        self.state = .placingAnchor(currentVirtualCursorPosition: initialMousePosition)
    }
    
    func printWhenDebugging(_ items: Any...) {
        if isDebugging {
            // well shiiit Pass array to variadic function is not yet supported :/
            // https://github.com/apple/swift/issues/42750
            for item in items {
                print(item, terminator: "")
            }
            print()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            createOverlayView(geometry: geometry)
                .onDisappear {
                    printWhenDebugging("on dissapear")
                    eventMonitors.stopMonitoringEvents()
                }
                .onAppear {
                    printWhenDebugging("on appear")
                    
                    // We might be able to move this up to the view init code
                    eventMonitors.startMonitoringEvents(
                        onMouseDown: { point in
                            printWhenDebugging("mouse down")
                            
                            let isPlacingAnchor = switch state { case .placingAnchor(_): true; default: false }
                            assert(isPlacingAnchor, "Mouse down detected, but state is not .placingAnchor")
                            
                            // Capture the initial point and transition to placingAnchor state
                            state = .selectingFrame(anchorPoint: point, virtualCursorPosition: point)
                        },
                        onMouseMove: { point in
                            // The state might need to move as I think this might not be releasing the window when escape is clicked
                            printWhenDebugging("on move")

                            switch state {
                            case .placingAnchor(_):
                                printWhenDebugging("state == placingAnchor")
                                
                                // Update crosshair position
                                state = .placingAnchor(currentVirtualCursorPosition: point)
                            case .selectingFrame(let anchorPoint, _):
                                printWhenDebugging("state == selectingFrame")
                                
                                // Update cursor position
                                state = .selectingFrame(anchorPoint: anchorPoint, virtualCursorPosition: point)
                            case .capturingInProgress:
                                printWhenDebugging("state == capturing; ignore mouse movement")
                                break
                            }
                        },
                        onMouseUp: { point in
                            printWhenDebugging("mouse up")
                            
                            // Have to be in selectingFrame state
                            guard case .selectingFrame(let anchorPoint, let virtualCursorPosition) = state else {
                                print("WARNING: Mouse up should only happen in selectingFrame state")
                                onComplete(nil)
                                return
                            }
                            
                            let frame = Self.toFrame(anchorPoint: anchorPoint, virtualCursorPosition: virtualCursorPosition)
                            
                            // Frame has to not be empty
                            guard frame.size.width != 0 && frame.size.height != 0 else {
                                print("WARNING: Mouse up should only happen in selectingFrame state")
                                onComplete(nil)
                                return
                            }
                            
                            // Mark as in progress - the capture process is async
                            state = .capturingInProgress

                            Task(priority: .userInitiated) {
                                if let screenshot = await captureScreenshot(rect: frame) {
                                    onComplete(screenshot)
                                } else {
                                    print("WARNING: Capture failed! Still dismissing screenshot view")
                                    onComplete(nil)
                                }
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
        switch state {
        case .placingAnchor(let currentVirtualCursorPosition):
            createCrosshairView(center: currentVirtualCursorPosition)
        case .selectingFrame(let anchorPoint, let virtualCursorPosition):
            createSelectionRectangle(anchor: anchorPoint, currentPoint: virtualCursorPosition)
            createCrosshairView(center: virtualCursorPosition)
        case .capturingInProgress:
            EmptyView()
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
        printWhenDebugging("anchor \(anchor) current: \(currentPoint)")
        
        let frame = Self.toFrame(anchorPoint: anchor, virtualCursorPosition: currentPoint)
        
        // Create a rectangle view based on anchor and currentPoint
        return Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }
    
    func getShareableContent() async -> SCDisplay? {
        let availableContent = try? await SCShareableContent.current
        
        guard let availableContent = availableContent,
              let display = availableContent.displays.first else {
            return nil
        }
        
        return display
    }
    
    private func captureScreenshot(rect: CGRect) async -> Data? {
        if #available(macOS 14.0, *) {
            guard let display = await getShareableContent() else {
                return nil
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            // Note: Configuring height / width reduced the quality somehow
            let config = SCStreamConfiguration()
            config.showsCursor = false
            config.captureResolution = .best
            
            // Source.
            // Essential that the rect and the content filter have matching coordinate spaces.
            // Currently it just kinda works... Kinda because its only for a single screen :D
            config.sourceRect = rect
            
            // Destination
            // We are upsampling due to retina. Not sure at which point things break, but if we don't upsample, the final image will have
            //   number of pixels matching logical pixels captured, not the real retina physical pixels.
            //   We should probably be multiplying by the display scale factor physicalPixelDensityPerLogicalPixel
            
            // Configure size aka bounds
            config.width = Int(rect.width * 4)
            config.height = Int(rect.height * 4)
            
            // Configure where inside the bounds to place content
            config.destinationRect = CGRect(x: 0, y: 0, width: rect.width * 4, height: rect.height * 4)
            
            
            guard let cgImage = try? await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            ) else {
                return nil
            }
            
            return NSImage(cgImage: cgImage, size: rect.size).tiffRepresentation
        } else {
            guard let cgImage = CGDisplayCreateImage(CGMainDisplayID(), rect: rect) else {
                return nil
            }
            let capturedImage = NSImage(cgImage: cgImage, size: rect.size)
            guard capturedImage.isValid else {
                return nil
            }

            return capturedImage.tiffRepresentation
        }
    }

    static private func toFrame(anchorPoint: CGPoint, virtualCursorPosition: CGPoint) -> CGRect {
        CGRect(x: min(anchorPoint.x, virtualCursorPosition.x),
               y: min(anchorPoint.y, virtualCursorPosition.y),
               width: abs(anchorPoint.x - virtualCursorPosition.x),
               height: abs(anchorPoint.y - virtualCursorPosition.y))
    }
}

typealias ImageData = Data

