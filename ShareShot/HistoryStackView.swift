//
//  HistoryStackView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 4/15/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit

// SwiftUI view for displaying history stack of images
struct HistoryStackView: View {
    var model: StackModel
    // Initialize with a StackModel
    init(model: StackModel) {
        self.model = model
    }
    
    var body: some View {
        let capturedImages = model.images
        RoundedRectangle(cornerRadius: 10)
            .foregroundColor(.black.opacity(0.5))
            .overlay(
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(capturedImages.reversed(), id: \.self) { image in
                            // Custom view to display screenshot
                            ScreenShotView(image: image, saveImage: {_ in }, copyImage: {_ in }, deleteImage: {_ in }, saveToDesktopImage: {_ in }, shareImage: {_ in }, saveToiCloud: {_ in })
                                .rotationEffect(.degrees(180))
                        }
                    }
        }
      )
    }
}
