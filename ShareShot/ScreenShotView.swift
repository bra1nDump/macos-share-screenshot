//
//  ScreenShotView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/11/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit

// View model for holding the image data
class ImageViewModel: ObservableObject {
    @Published var image: NSImage?

    init(imageData: ImageData) {
        if let nsImage = NSImage(data: imageData) {
            image = nsImage
        }
    }
}

// This view is for creating a screenshot preview with overlaid buttons.
struct ScreenShotView: View {
    @ObservedObject var viewModel: ImageViewModel
    @State private var isHovered = false
    var saveImage: (() -> Void)
    var copyImage: (() -> Void)
    var deleteImage: (() -> Void)
    var saveToDesktopImage: (() -> Void)?
    var shareImage: (() -> Void)
    var saveToiCloud: (() -> Void)?

    var body: some View {
        RoundedRectangle(cornerRadius: 20) // Container for the screenshot view
            .frame(width: 201, height: 152)
            .foregroundColor(.clear)
            .overlay(
                Group {
                    if let image = viewModel.image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 150)
                            .cornerRadius(10)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 1)
                                    .opacity(!isHovered ? 1.0 : 0.0)
                            )
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
                                                    // Buttons for actions
                                                    VStack {
                                                        HStack {
                                                            CircleButton(systemName: "xmark", action: deleteImage)
                                                            Spacer()
                                                            HStack {
                                                                CircleButton(systemName: "square.and.arrow.up", action: shareImage)
                                                            }
                                                        }
                                                        Spacer()
                                                        HStack {
                                                            Spacer()
                                                            if let saveToiCloud = saveToiCloud {
                                                                CircleButton(systemName: "cloud", action: saveToiCloud)
                                                            }
                                                        }
                                                    }
                                                    .padding(7)
                                                    // Buttons for actions
                                                    VStack(spacing: 15) {
                                                        TextButton(text: "Copy", action: copyImage)
                                                        if let saveToDesktopImage = saveToDesktopImage {
                                                            TextButton(text: "Save to Desktop", action: saveToDesktopImage)
                                                        }
                                                        TextButton(text: "Save as", action: saveImage)
                                                    }
                                                }
                                                .opacity(isHovered ? 1.0 : 0.0)
                                            )
                                    )
                            )
                            .focusable(false)
                            .onHover { hovering in
                                isHovered = hovering
                            }
                            .onDrag {
                                NSItemProvider(object: image)
                            }
                    } else {
                        // Display message for invalid image
                        Text("Invalid Image")
                    }
                }
            )
    }
}

// This view is for the small buttons with image overlaying the screenshot preview.
struct CircleButton: View {
    let systemName: String
    let action: (() -> Void)

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(.black)
                .frame(width: 25, height: 25)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

// This view is for the text buttons overlaying the screenshot preview.
struct TextButton: View {
    let text: String
    let action: (() -> Void)

    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundColor(.black)
                .frame(width: 110, height: 30)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
