//
//  KeyboardAndMouseEventMonitors.swift
//  ShareShot
//
//  Created by Kirill Dubovitskiy on 3/19/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import AppKit
import Carbon

import Combine

class KeyboardAndMouseEventMonitors: ObservableObject {
    private var globalMonitors: [Any?] = []
    
    func startMonitoringEvents(
        onMouseDown: @escaping (CGPoint) -> Void,
        onMouseMove: @escaping (CGPoint) -> Void,
        onMouseUp: @escaping (CGPoint) -> Void,
        onEscape: @escaping () -> Void
    ) {
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
