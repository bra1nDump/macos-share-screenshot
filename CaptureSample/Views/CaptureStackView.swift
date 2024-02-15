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
import SwiftUiSharing

//import EasySwiftUI


struct CaptureStackView: View {
    
   @State var capturedImages: [ImageData]
    var body: some View {
        VStack {
            if !capturedImages.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20){
                        ForEach(capturedImages.reversed(), id: \.self) { image in
                            ScreenShotView(image: image, saveImage: saveImage, copyImage: copyToClipboard, deleteImage: deleteImage)
                                .contextMenu {
                                      Button {
                                        //  shareImage(image)
                                          shareAction(image)
                                      } label: {
                                          HStack{
                                              Image(systemName: "square.and.arrow.up")
                                              Text("Share")
                                          }
                                      }
                                      Button {
                                        deleteImage(image)
                                      } label: {
                                          Image(systemName: "location.circle")
                                                      Text("Delete")
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
    func shareImage(_ image: ImageData) {
        if let nsImage = NSImage(data: image) {
            let sharingService = NSSharingService(named: .composeMessage)
             sharingService?.perform(withItems: [nsImage])
         }
     }
    func shareAction(_ image: ImageData) {
        if let nsImage = NSImage(data: image) {
            let sharingServicePicker = NSSharingServicePicker(items: [nsImage])
            
            if let contentView = NSApp.mainWindow?.contentView {
                sharingServicePicker.show(relativeTo: .zero, of: contentView.superview!, preferredEdge: .minY)
            }
        }
    }
    private func shareButtonClicked(_ image: ImageData) {
        let textToShare = ""
        let sharingPicker = NSSharingServicePicker(items: [textToShare, NSImage(data: image) as Any])
        sharingPicker.delegate = NSSharingDelegate()

        if let keyWindow = NSApp.keyWindow, let contentView = keyWindow.contentView {
            sharingPicker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        } else {
            print("Unable to show NSSharingServicePicker: keyWindow or contentView is nil.")
        }
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
                    print("Image saved")
                } catch {
                    print("Error saving image: \(error)")
                }
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
    func saveImageToFile(_ image: NSImage) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = formatter.string(from: Date())
        let fileName = "image_\(dateString).png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let imageData = image.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: imageData),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
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

class ViewController: NSViewController {

    @IBAction func shareButtonClicked(_ sender: NSButton) {
        let textToShare = "Текст для обмена"
        let imageToShare = NSImage(named: "yourImage")!

        let sharingPicker = NSSharingServicePicker(items: [textToShare, imageToShare])
        sharingPicker.delegate = self

        sharingPicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func setClipboard(text: String) {
    }
}

extension ViewController: NSSharingServicePickerDelegate {
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: NSImage.Name("copy")) else {
            return proposedServices
        }
        
        var share = proposedServices
        let customService = NSSharingService(title: "Copy Text", image: image, alternateImage: image, handler: {
            if let text = items.first as? String {
                self.setClipboard(text: text)
            }
        })
        share.insert(customService, at: 0)
        
        return share
    }
}

class NSSharingDelegate: NSObject, NSSharingServicePickerDelegate {
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: "copy") else {
            return proposedServices
        }

        var share = proposedServices
        let customService = NSSharingService(title: "Copy Text", image: image, alternateImage: image, handler: {
            if let text = items.first as? String {
                print("Sharing text:", text)
            }
        })
        share.insert(customService, at: 0)

        return share
    }
}
extension NSSharingService {
    private static let items = NSSharingService.sharingServices(forItems: [""])
    static func submenu(text: String) -> some View {
        return Menu(
            content: {
                ForEach(items, id: \.title) { item in
                    Button(action: { item.perform(withItems: []) }) {
                        Image(nsImage: item.image)
                        Text(item.title)
                    }
                }
            },
            label: {
                Text("Share")
                Image(systemName: "chevron.right")
            }
        )
    }
}
