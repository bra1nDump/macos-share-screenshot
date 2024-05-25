//
//  ScreenShotView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/11/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit

// Main view for displaying a screenshot with action buttons
struct ScreenShotView: View {
    var image: Data
    @State private var fileURL: URL?
    @State private var isHovered = false
    var saveImage: ((Data) -> Void)
    var copyImage: ((Data) -> Void)
    var deleteImage: ((Data) -> Void)
    var saveToDesktopImage: ((Data) -> Void)
    var shareImage: ((Data) -> Void)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 201, height: 152)
            .foregroundColor(.clear)
            .overlay(
                Group {
                    // Check if NSImage can be created from image data
                    if let nsImage = NSImage(data: image) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 150)
                            .background(Color.clear)
                            .cornerRadius(20)
                        // Enable drag and drop functionality
                            .onDrag {
                                let url = saveImageToTemporaryDirectory(image: nsImage)
                                return url != nil ? NSItemProvider(contentsOf: url!)! : NSItemProvider(object: image as NSData as! NSItemProviderWriting)
                            }
                        // Overlay to show border when not hovered
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 1)
                                    .opacity(!isHovered ? 1.0 : 0.0)
                            )
                        // Overlay to show border when hovered
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 1)
                                    .opacity(isHovered ? 1.0 : 0.0)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.clear)
                                            .frame(width: 195, height: 145)
                                            .overlay(
                                                ZStack {
                                                    VStack {
                                                        HStack {
                                                            CircleButton(systemName: "xmark", action: deleteImage, image: image)
                                                            Spacer()
                                                            CircleButton(systemName: "square.and.arrow.up", action: shareImage, image: image)
                                                        }
                                                        Spacer()
                                                    }
                                                    .padding(7)
                                                    VStack(spacing: 15) {
                                                        TextButton(text: "Copy", action: copyImage, image: image)
                                                        // Conditionally show button based on a flag
#if NOSANDBOX
                                                        TextButton(text: "Save to Desktop", action: saveToDesktopImage, image: image)
#endif
                                                        TextButton(text: "Save as", action: saveImage, image: image)
                                                    }
                                                }
                                                    .opacity(isHovered ? 1.0 : 0.0)
                                            )
                                    )
                            )
                        // Track hover state
                            .onHover { hovering in
                                isHovered = hovering
                            }
                    } else {
                        // Display message for invalid image
                        Text("Invalid Image")
                    }
                }
            )
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
}

// View for small circular buttons overlaying the screenshot preview
struct CircleButton: View {
    let systemName: String
    let action: ((Data) -> Void)
    var image: Data
    var body: some View {
        Circle()
            .frame(width: 25, height: 25)
            .foregroundColor(.white)
            .overlay(
                Image(systemName: systemName)
                    .foregroundColor(.black)
            )
            .onTapGesture {
                action(image)
            }
    }
}

// View for text buttons overlaying the screenshot preview
struct TextButton: View {
    let text: String
    let action: ((Data) -> Void)
    var image: Data
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 110, height: 30)
            .foregroundColor(.white)
            .overlay(
                Text(text)
                    .foregroundColor(.black)
            )
            .onTapGesture {
                action(image)
            }
    }
}
