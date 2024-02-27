//
//  ScreenShotView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/11/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit

struct ScreenShotView: View {
    var image: ImageData
    @State private var fileURL: URL?
    @State private var isHovered = false
    var saveImage: ((ImageData) -> Void)
    var copyImage: ((ImageData) -> Void)
    var deleteImage: ((ImageData) -> Void)
    var saveToDesktopImage: ((ImageData) -> Void)
    var shareImage: ((ImageData) -> Void)
    var saveToiCloud: ((ImageData) -> Void)
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 201, height: 152)
            .foregroundColor(.clear)
            .overlay(
            Image(nsImage: NSImage(data: image)!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 150)
                .background(Color.clear)
                .cornerRadius(10)
                .draggable(Image(nsImage: NSImage(data: image)!), preview: {
                    Image(nsImage: NSImage(data: image)!)
                    .frame(width: 100, height: 75)
                      .cornerRadius(10)
                      .overlay(
                          RoundedRectangle(cornerRadius: 10)
                              .stroke(Color.gray, lineWidth: 1)
                              .opacity(!isHovered ? 1.0 : 0.0)
                      )
                  })
                .rotationEffect(.degrees(180))
                .blur(radius: isHovered ? 5.0 : 0)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray, lineWidth: 1)
                        .opacity(!isHovered ? 1.0 : 0.0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 1)
                        .rotationEffect(.degrees(180))
                        .opacity(isHovered ? 1.0 : 0.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                            .frame(width: 195, height: 145)
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
                                            HStack{
                                                Circle()
                                                    .frame(width: 25, height: 25)
                                                    .foregroundColor(.white)
                                                    .overlay(
                                                        Image(systemName: "square.and.arrow.up")
                                                            .foregroundColor(.black)
                                                            .offset(y:-2)
                                                    )
                                                    .onTapGesture {
                                                        shareImage(image)
                                                    }
                                            }
                                        }
                                        Spacer()
                               #if NOSANDBOX
                                        HStack{
                                            Spacer()
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "cloud")
                                                        .foregroundColor(.black)
                                                )
                                                .onTapGesture {
                                                    saveToiCloud(image)
                                                }
                                        }
                                #endif
                                    }
                                    .padding(7)
                                    VStack(spacing: 15){
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 110, height: 30)
                                            .foregroundColor(.white)
                                            .overlay(
                                                Text("Copy")
                                                    .foregroundColor(.black)
                                            )
                                            .onTapGesture {
                                                copyImage(image)
                                            }
                                        #if NOSANDBOX
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 110, height: 30)
                                            .foregroundColor(.white)
                                            .overlay(
                                                Text("Save to Desktop")
                                                    .foregroundColor(.black)
                                            )
                                            .onTapGesture {
                                                saveToDesktopImage(image)
                                            }
                                        #endif
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 110, height: 30)
                                            .foregroundColor(.white)
                                            .overlay(
                                                Text("Save as")
                                                    .foregroundColor(.black)
                                            )
                                            .onTapGesture {
                                                saveImage(image)
                                            }
                                 }
                                }
                                    .rotationEffect(.degrees(180))
                                    .opacity(isHovered ? 1.0 : 0.0)
                                )
                        )
                )
                .focusable(false)
                .onHover { hovering in
                        isHovered = hovering
                }
           )
        }

       func copyURLToClipboard(url: URL) {
           let pasteboard = NSPasteboard.general
           pasteboard.clearContents()
           pasteboard.setString(url.absoluteString, forType: .string)
       }
}
