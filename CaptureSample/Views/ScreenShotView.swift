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
    @State private var isHovered = false
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
                .draggable(Image(nsImage: NSImage(data: image)!))
                .rotationEffect(.degrees(180))
                .blur(radius: isHovered ? 5.0 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
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
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "pin.fill")
                                                        .foregroundColor(.black)
                                                        .rotationEffect(.degrees(45))
                                                )
                                                .onTapGesture {
                                                    pinImage(image: NSImage(data: image)!)
                                                }
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
                                                .onTapGesture {
                                                    saveToCloudImage(image: NSImage(data: image)!)
                                                }
                                            Spacer()
                                            Circle()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                                .overlay(
                                                    Image(systemName: "icloud.and.arrow.up.fill")
                                                        .foregroundColor(.black)
                                                )
                                                .onTapGesture {
                                                    openImageInNewWindow(image: NSImage(data: image)!)
                                                }
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
                                    .rotationEffect(.degrees(180))
                                    .opacity(isHovered ? 1.0 : 0.0)
                                )
                        )
                )
                .focusable(false)
                .onTapGesture {
                    openImageInNewWindow(image: NSImage(data: image)!)
                }
                .onHover { hovering in
                        isHovered = hovering
                }
        }
}

func openImageInNewWindow(image: NSImage) {
    let imageViewController = NSViewController()
    let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    imageView.image = image
    imageViewController.view = imageView
    let imageWindow = NSWindow(contentViewController: imageViewController)
    imageWindow.makeKeyAndOrderFront(nil)
}

func editImage(image: NSImage) {
    print("edit image")
    let imageViewController = NSViewController()
    let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    imageView.image = image
    imageViewController.view = imageView
    let imageWindow = NSWindow(contentViewController: imageViewController)
    imageWindow.makeKeyAndOrderFront(nil)
}

func pinImage(image: NSImage) {
    print("pin image")
    let imageViewController = NSViewController()
    let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    imageView.image = image
    imageViewController.view = imageView
    let imageWindow = NSWindow(contentViewController: imageViewController)
    imageWindow.makeKeyAndOrderFront(nil)
    imageWindow.hidesOnDeactivate = false
}

func saveToCloudImage(image: NSImage) {
    print("save to cloud image")
}
