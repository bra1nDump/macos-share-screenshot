//
//  CaptureStackView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/4/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct CaptureStackView: View {
   // @ObservedObject private var captureManager = CaptureManager()
@State var capturedImages: [ImageData] = []
    var body: some View {
        VStack {
            if capturedImages.isEmpty {
                Text("No Captured Images")
                    .foregroundColor(.gray)
                    .padding()
                    .onAppear{
                        print("zero")
                    }
            } else {
                ScrollView {
                    ForEach(capturedImages.reversed(), id: \.self) { image in
                        Image(nsImage: NSImage(data: image)!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 150)
                            .background(Color.clear)
                            .cornerRadius(10)
                            .rotationEffect(.degrees(180))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .rotationEffect(.degrees(180))
            }
        }
        .padding(.bottom, 60)
        .padding(20) 
    }
}

struct CaptureStackView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureStackView()
    }
}
