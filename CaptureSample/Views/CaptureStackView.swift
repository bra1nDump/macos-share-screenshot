//
//  CaptureStackView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/4/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit

struct CaptureStackView: View {
   @State var capturedImages: [ImageData]
    var body: some View {
        VStack {
            if !capturedImages.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20){
                        ForEach(capturedImages.reversed(), id: \.self) { image in
                            ScreenShotView(image: image, saveImage: saveImage, copyImage: copyToClipboard, deleteImage: deleteImage)
                        }
                    }
                }
                .rotationEffect(.degrees(180))
            }
        }
        .padding(.bottom, 60)
        .padding(20)
    }
    private func copyToClipboard(_ image: ImageData) {
        if let nsImage = NSImage(data: image) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([nsImage])
            deleteImage(image)
        }
    }
    private func saveImage(_ image: ImageData) {
        guard let nsImage = NSImage(data: image) else { return }
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "image.png"
        savePanel.message = "We need access to the desktop to save files."
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                guard let tiffData = nsImage.tiffRepresentation,
                      let bitmapImageRep = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImageRep.representation(using: .png, properties: [:]) else {
                    return
                }
                do {
                    try imageData.write(to: url)
                    deleteImage(image)
                    print("Image saved to Desktop")
                } catch {
                    print("Error saving image: \(error)")
                }
            }
        }
    }
    private func deleteImage(_ image: ImageData) {
               MyApplication.appDelegate?.deleteImage(image)
        if let index = capturedImages.firstIndex(of: image) {
            withAnimation{
                capturedImages.remove(at: index)
            }
        }
       }
}

