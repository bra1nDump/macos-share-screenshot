//
//  ScreenShotView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/11/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ScreenShotView: View {
    var image: ImageData
    @State var isHovered = false
    var saveImage: ((ImageData) -> Void)
    var copyImage: ((ImageData) -> Void)
    var deleteImage: ((ImageData) -> Void)
    var body: some View {
            Image(nsImage: NSImage(data: image)!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 150)
                .background(Color.clear)
                .cornerRadius(10)
                .rotationEffect(.degrees(180))
                .draggable(Image(nsImage: NSImage(data: image)!))
                .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 1)
                            .overlay(
                                ZStack{
                                    VStack{
                                        HStack{
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "xmark")
                                                        .foregroundColor(.black)
                                                )
                                                .onTapGesture {
                                                    deleteImage(image)
                                                }
                                            Spacer()
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "pin.fill")
                                                        .foregroundColor(.black)
                                                        .rotationEffect(.degrees(45))
                                                )
                                        }
                                        Spacer()
                                        HStack{
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "pencil")
                                                        .foregroundColor(.black)
                                                )
                                            Spacer()
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "icloud.and.arrow.up.fill")
                                                        .foregroundColor(.black)
                                                )
                                        }
                                    }
                                    .padding(5)
                                    VStack{
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 50, height: 25)
                                            .foregroundColor(.white)
                                            .overlay(
                                                Text("Copy")
                                                    .foregroundColor(.black)
                                            )
                                            .onTapGesture {
                                                copyImage(image)
                                            }
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 50, height: 25)
                                            .foregroundColor(.white)
                                            .overlay(
                                                Text("Save")
                                                    .foregroundColor(.black)
                                            )
                                            .onTapGesture {
                                                saveImage(image)
                                            }
                                    }
                                }
                            )
                            .rotationEffect(.degrees(180))
                            .opacity(isHovered ? 1.0 : 0.0)
                )
                .onHover { hovering in
                                   isHovered = hovering
                               }
                .focusable(false)
            }
}
