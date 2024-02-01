//
//  CaptureStackView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/4/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit
import Cocoa
import Foundation


struct CaptureStackView: View {
   @State var capturedImages: [ImageData]
    var body: some View {
        VStack {
            if !capturedImages.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20){
                        ForEach(capturedImages.reversed(), id: \.self) { image in
                            ScreenShotView(image: image, saveImage: saveImage, copyImage: copyToClipboard, deleteImage: deleteImage, saveImageDesktop: saveImageToDesktop)
                                .contextMenu {
                                      Button {
                                          print("Share")
                                      } label: {
                                          Label("Share", systemImage: "globe")
                                      }

                                      Button {
                                        deleteImage(image)
                                      } label: {
                                          Label("Delete", systemImage: "location.circle")
                                      }
                                  }
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
        let currentDate = Date()
               let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
               let formattedDate = dateFormatter.string(from: currentDate)
        savePanel.nameFieldStringValue = "CaptureSample - \(formattedDate).png"
        savePanel.message = "Select a directory to save the image"
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
    private func saveImageToDesktop(_ image: ImageData) {
        if let savedURL = UserSettings.securityScopedURL {
            DispatchQueue.global(qos: .background).async {
                let saveURL = savedURL.appendingPathComponent("image.png")
                guard let nsImage = NSImage(data: image),
                      let tiffData = nsImage.tiffRepresentation,
                      let bitmapImageRep = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImageRep.representation(using: .png, properties: [:]) else {
                    return
                }

                do {
                    try imageData.write(to: saveURL)
                    deleteImage(image)
                    print("Image saved to selected directory")
                } catch {
                    print("Error saving image: \(error)")
                }

                savedURL.stopAccessingSecurityScopedResource()
            }
        } else {
            // Если сохраненного пути нет, запросить разрешение у пользователя
            requestUserPermission { securityScopedURL in
                guard let securityScopedURL = securityScopedURL else {
                    print("Security scoped URL not available.")
                    return
                }

                let saveURL = securityScopedURL.appendingPathComponent("image.png")

                guard let nsImage = NSImage(data: image),
                      let tiffData = nsImage.tiffRepresentation,
                      let bitmapImageRep = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImageRep.representation(using: .png, properties: [:]) else {
                    return
                }
                do {
                    try imageData.write(to: saveURL)
                    deleteImage(image)
                    print("Image saved to selected directory")
                } catch {
                    print("Error saving image: \(error)")
                }

                securityScopedURL.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func requestUserPermission(completion: @escaping (URL?) -> Void) {
            if let savedURL = UserSettings.securityScopedURL {
                completion(savedURL)
            } else {
                let openPanel = NSOpenPanel()
                openPanel.canChooseDirectories = true
                openPanel.canChooseFiles = false
                openPanel.allowsMultipleSelection = false
                openPanel.title = "Select a directory to save the image"
                openPanel.begin { response in
                    if response == .OK, let url = openPanel.url {
                        do {
                            let securityScopedURL = try url.startAccessingSecurityScopedResource() ? url : nil
                            UserSettings.securityScopedURL = securityScopedURL
                            completion(securityScopedURL)
                        } catch {
                            print("Error accessing security scoped resource: \(error)")
                            completion(nil)
                        }
                    } else {
                        completion(nil)
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

struct UserSettings {
    static var securityScopedURL: URL? {
        get {
            return UserDefaults.standard.url(forKey: "securityScopedURL")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "securityScopedURL")
        }
    }
}
