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
    var history: () -> Void
    var onboarding: () -> Void
    var lastScreenshots: [Data]
    
    private let imageSize: CGSize = CGSize(width: 100, height: 75)
    
    var body: some View {
        VStack {
            ForEach(lastScreenshots, id: \.self) { imageData in
                ScreenShotStatusBarView(imageData: imageData, size: imageSize)
            }
            Button(action: startScreenshot) {
                Label("Screenshot", systemImage: "camera")
            }
            Button(action: history) {
                Label("History", systemImage: "tray.full")
            }
            Button(action: onboarding) {
                Label("Onboarding", systemImage: "info.circle")
            }
            Button(action: quitApplication) {
                Label("Quit", systemImage: "power")
            }
        }
        .padding()
    }
}

struct ScreenShotStatusBarView: View {
    var imageData: Data
    var size: CGSize
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(width: size.width, height: size.height)
            .foregroundColor(.clear)
            .overlay(
                Group {
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .background(Color.clear)
                            .cornerRadius(10)
                            .onDrag {
                                            if isReceivingURL() {
                                                let url = saveImageToTemporaryDirectory(image: nsImage)
                                                return NSItemProvider(contentsOf: url!)!
                                            } else {
                                                return NSItemProvider(object: nsImage)
                                            }
                                        }
                            .onTapGesture { copyToClipboard(nsImage) }
                    } else {
                        Text("Invalid Image")
                            .frame(width: size.width, height: size.height)
                            .background(Color.clear)
                            .cornerRadius(10)
                    }
                }
            )
    }
    
    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    // Function to save the image to a temporary directory and return the URL
       func saveImageToTemporaryDirectory(image: NSImage) -> URL? {
           let temporaryDirectory = FileManager.default.temporaryDirectory
           let fileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")

           guard let data = image.tiffRepresentation,
                 let bitmap = NSBitmapImageRep(data: data),
                 let pngData = bitmap.representation(using: .png, properties: [:]) else {
               return nil
           }

           do {
               try pngData.write(to: fileURL)
               return fileURL
           } catch {
               print("Failed to save image to temporary directory: \(error)")
               return nil
           }
       }

       func isReceivingURL() -> Bool {
           return true
}

}
