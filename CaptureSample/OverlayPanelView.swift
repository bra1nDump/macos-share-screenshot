//
//  OverlayPanelView.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import Carbon

// Current problem:
// When app not in actual focus (title visible) - no view is rendered, mouse moves come through
// When app is in focus - it renders the view, but mouse moves don't come

// Seems like the key difference is - the app is not active when creating the window initially
// I can probably create it once the app starts and actually add stuff to it later on

// Define your SwiftUI view
struct CaptureOverlayView: View {
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
                // This adds additional layer so double the color
                .background(Color.gray.opacity(0.2))
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
                                state = .capturing(frame: Self.toFrame(anchorPoint: anchorPoint, virtualCursorPosition: virtualCursorPosition))
                                
                                // TODO: Kick off the actual screen capture
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
            createCaptureView(frame: frame)
        }
    }

    private func createCrosshairView(center: CGPoint) -> some View {
        Path { path in
            path.move(to: CGPoint(x: center.x - 4, y: center.y))
            path.addLine(to: CGPoint(x: center.x + 4, y: center.y))
            path.move(to: CGPoint(x: center.x, y: center.y - 4))
            path.addLine(to: CGPoint(x: center.x, y: center.y + 4))
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

    private func createCaptureView(frame: CGRect) -> some View {
        // Create a view that represents the capturing state
        return Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }
    
    static private func toFrame(anchorPoint: CGPoint, virtualCursorPosition: CGPoint) -> CGRect {
        CGRect(x: min(anchorPoint.x, virtualCursorPosition.x),
               y: min(anchorPoint.y, virtualCursorPosition.y),
               width: abs(anchorPoint.x - virtualCursorPosition.x),
               height: abs(anchorPoint.y - virtualCursorPosition.y))
    }
}

typealias ImageData = Data
