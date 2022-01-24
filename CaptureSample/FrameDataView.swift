/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that renders information about a captured frame.
*/

import SwiftUI
import ScreenCaptureKit

struct FrameDataView: View {
    
    var frameData: CapturedFrame
    
    init(_ frame: CapturedFrame) {
        frameData = frame
    }
    
    var body: some View {
        HStack {
            Text("Content Rect: \(frameData.contentRect.debugDescription)")
            Divider()
            Text(String(format: "Content Scale: %.1f", frameData.contentScale))
            Divider()
            Text(String(format: "Scale Factor: %.1f", frameData.scaleFactor))
            Divider()
            Text("Surface Size: \(frameData.surface.width) x \(frameData.surface.height)")
            Divider()
            Text(String(format: "Display Time (sec): %.2f", frameData.displayTime))
                .frame(width: 200, alignment: .leading)
        }
        .textSelection(.enabled)
    }
}
