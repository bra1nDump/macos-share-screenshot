//
//  ScreenShotStatusBarView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 4/18/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ScreenShotStatusBarView: View {
    var image: ImageData
    var body: some View {
        RoundedRectangle(cornerRadius: 20) // Container for the screenshot view
            .frame(width: 201, height: 152)
            .foregroundColor(.clear)
            .overlay(
                Group {
                    // Check if NSImage can be created from image data
                    if NSImage(data: image) != nil {
                        // Display the image
                        Image(nsImage: NSImage(data: image)!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 150)
                            .background(Color.clear)
                            .cornerRadius(10)
                            .cornerRadius(20)
                        // Enable drag and drop functionality
                            .onDrag {
                                NSItemProvider(object: NSImage(data: image)!)
                            }
                    } else {
                        // Display message for invalid image
                        Text("Invalid Image")
                    }
                }
            )
    }
}
