/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import SwiftUI

@main
struct CaptureSampleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
//            DebugView()
            ContentView(appDelegate: appDelegate)
                .frame(minWidth: 960, minHeight: 724)
                .background(.black)
        }
    }
}
