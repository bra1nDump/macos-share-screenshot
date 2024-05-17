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
    
    // Convenience initializer to reduce redundancy
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // Setup function for common initialization tasks
    private func setup() {
        registerForDraggedTypes([.fileURL])
    }
    
    // Draw the view
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.setFill()
        dirtyRect.fill()
    }
    
    // Invoked when a drag enters the view
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return shouldAllowDrag(sender) ? .copy : []
    }
    
    // Invoked when a drag operation is performed
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let fileURL = getURL(from: sender) else { return false }
        print("Received file: \(fileURL.path)")
        return true
    }
    
    // Check if drag should be allowed
    private func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        guard let types = draggingInfo.draggingPasteboard.types else { return false }
        return types.contains(.fileURL)
    }
    
    // Get the URL from dragging info
    private func getURL(from draggingInfo: NSDraggingInfo) -> URL? {
        let classes = [NSURL.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        return draggingInfo.draggingPasteboard.readObjects(forClasses: classes, options: options)?.first as? URL
    }
}
