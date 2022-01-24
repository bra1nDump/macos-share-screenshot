/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A sample app that demonstrates how to use ScreenCaptureKit.
*/
import SwiftUI

@main
struct CaptureSampleApp: App {
    var body: some Scene {
        WindowGroup {
            CaptureView()
                .frame(minWidth: 960, minHeight: 724, alignment: .center)
        }
        
    }
}
