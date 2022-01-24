/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that renders a captured video frame.
*/

import SwiftUI

struct FrameView: NSViewRepresentable {
    
    let frame: IOSurface
    
    init(_ frame: IOSurface) {
        self.frame = frame
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        if view.layer == nil {
            view.makeBackingLayer()
        }
        view.layer?.contents = frame
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.contents = frame
    }
}
