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
                ScreenShotView(image: imageData, saveImage: {_ in }, copyImage: {_ in }, deleteImage: {_ in }, saveToDesktopImage: {_ in }, shareImage: {_ in })
                    .onTapGesture {
                        openImageInPreview(image: NSImage(data: imageData)!)
                    }
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
    private func deleteImage(_ image: ImageData) {
    }
    
    // Open the image in Preview app
    private func openImageInPreview(image: NSImage) {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryImageURL = temporaryDirectoryURL.appendingPathComponent("ShareShot.png")
        if let imageData = image.tiffRepresentation, let bitmapRep = NSBitmapImageRep(data: imageData) {
            if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: temporaryImageURL)
                } catch {
                    print("Failed to save temporary image: \(error)")
                    return
                }
            }
        }
        NSWorkspace.shared.open(temporaryImageURL)
    }
    
    // Save the image to desktop (sandbox only)
    private func saveImageToDesktop(_ image: ImageData) {
        guard let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            print("Unable to access desktop directory.")
            return
        }
        let fileName = dateTimeUniqueScreenshotFileName()
        let filePath = desktopURL.appendingPathComponent(fileName)
        saveImageAsPng(image: image, at: filePath)
    }
    
    // Generate a unique filename based on date and time
    private func dateTimeUniqueScreenshotFileName() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "ShareShot_\(formatter.string(from: currentDate)).png"
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
                        ScreenShotView(image: imageData, saveImage: {_ in }, copyImage: {_ in }, deleteImage: {_ in }, saveToDesktopImage: {_ in }, shareImage: {_ in })
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
