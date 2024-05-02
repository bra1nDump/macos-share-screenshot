//
//  StatusBarView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 4/16/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct StatusBarView: View {
    var startScreenshot: () -> Void
    var quitApplication: () -> Void
    var lastScreenshots: [Data]

    var body: some View {
        VStack {
            ForEach(lastScreenshots, id: \.self) { imageData in
            ScreenShotStatusBarView(image: imageData)
            }
            Button(action: startScreenshot) {
                Label("Screenshot", systemImage: "camera")
            }
            Button(action: quitApplication) {
                Label("Quit", systemImage: "power")
            }
        }
        .padding()
    }
}

struct ScreenShotStatusBarView: View {
    var image: ImageData
    var body: some View {
        RoundedRectangle(cornerRadius: 10) // Container for the screenshot view
            .frame(width: 100, height: 75)
            .foregroundColor(.clear)
            .overlay(
                Group {
                    // Check if NSImage can be created from image data
                    if NSImage(data: image) != nil {
                        // Display the image
                        Image(nsImage: NSImage(data: image)!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 75)
                            .background(Color.clear)
                            .cornerRadius(10)
                        // Enable drag and drop functionality
                            .onDrag {
                                NSItemProvider(object: NSImage(data: image)!)
                            }
                            .onTapGesture {
                                copyToClipboard(image)
                            }
                    } else {
                        // Display message for invalid image
                        Text("Invalid Image")
                    }
                }
            )
    }
    
    private func copyToClipboard(_ image: ImageData) {
        guard let nsImage = NSImage(data: image) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
    }
}
