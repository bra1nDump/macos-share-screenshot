//
//  DragAndDrop.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 5/15/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Cocoa

class DragDropView: NSView {
    
    // Initialize the DragDropView
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Register for file URL drag types
        registerForDraggedTypes([.fileURL])
    }
    
    // Initialize from Coder
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Register for file URL drag types
        registerForDraggedTypes([.fileURL])
    }
    
    // Draw the view
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Fill with white color
        NSColor.white.setFill()
        dirtyRect.fill()
    }
    
    // Invoked when a drag enters the view
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Check if drag is allowed
        if shouldAllowDrag(sender) {
            return .copy
        } else {
            return []
        }
    }
    
    // Invoked when a drag operation is performed
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // Get the URL of the dropped file
        if let fileURL = getURL(from: sender) {
            // Print the received file path
            print("Received file: \(fileURL.path)")
            return true
        }
        return false
    }
    
    // Check if drag should be allowed
    private func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        guard let types = draggingInfo.draggingPasteboard.types else { return false }
        return types.contains(.fileURL)
    }
    
    // Get the URL from dragging info
    private func getURL(from draggingInfo: NSDraggingInfo) -> URL? {
        guard let board = draggingInfo.draggingPasteboard.propertyList(forType: .fileURL) as? String else { return nil }
        return URL(string: board)
    }
}
