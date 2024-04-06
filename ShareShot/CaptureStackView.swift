//
//  CaptureStackView.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/4/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AppKit
import Foundation
import CloudKit

struct CaptureStackView: View {
    var model: StackModel
    @AppStorage("onboardingShown") var onboardingShown = true
    
    init(model: StackModel) {
        self.model = model
    }
    
    var body: some View {
        VStack {
            let capturedImages = model.images
            
            if !capturedImages.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20){
                        ForEach(capturedImages.reversed(), id: \.self) { image in
                            ScreenShotView(image: image, saveImage: saveImage, copyImage: copyToClipboard, deleteImage: deleteImage, saveToDesktopImage: saveImageToDesktop, shareImage: shareAction, saveToiCloud: saveImageToICloud)
                                .onTapGesture {
                                    openImageInPreview(image: NSImage(data: image)!)
                                }
                                .rotationEffect(.degrees(180))
                        }
                        // Toolkit for screanshoot
                        if onboardingShown {
                            withAnimation {
                                OnboardingScreenshot()
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            onboardingShown = false
                                        }
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
    
    private func shareAction(_ imageData: ImageData) {
        let sharingPicker = NSSharingServicePicker(items: [NSImage(data: imageData) as Any])
        
        if let mainWindow =  ShareShotApp.appDelegate?.currentPreviewPanel?.contentView?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews[indexForImage(imageData)!] {
            sharingPicker.show(relativeTo: mainWindow.bounds, of: mainWindow, preferredEdge: .minX)
        } else {
            print("No windows available.")
        }
    }
    
    private func indexForImage(_ imageData: ImageData) -> Int? {
        return capturedImages.firstIndex(of: imageData)
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
        let folderManager = FolderManager()
        folderManager.loadFromUserDefaults()
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                folderManager.addFolderLink(name: formattedDate, url: url)
                
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
                #if SANDBOX
                folderManager.saveToUserDefaults()
                print(folderManager.getRecentFolders())
                #endif
            }
        }
    }
    
    private func saveImageToICloud(_ image: ImageData) {
        guard let fileURL = saveImageLocally(image) else {
            return
        }
        
        saveFileToICloud(fileURL: fileURL) { iCloudURL in
            if let iCloudURL = iCloudURL {
                print("Image saved to iCloud. URL: \(iCloudURL)")
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([iCloudURL as NSPasteboardWriting])
            } else {
                print("Error saving image to iCloud.")
            }
            deleteImage(image)
        }
    }
    
    private func saveImageLocally(_ image: ImageData) -> URL? {
        guard let nsImage = NSImage(data: image) else {
            print("Unable to convert ImageData to NSImage.")
            return nil
        }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let formattedDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let fileName = "ShareShot_\(UUID().uuidString).png"
        let fileURL = documentsDirectory?.appendingPathComponent(fileName)

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImageRep.representation(using: .png, properties: [:]) else {
            print("Error converting image to PNG format.")
            return nil
        }

        do {
            try pngData.write(to: fileURL!)
            return fileURL
        } catch {
            print("Error saving image locally: \(error)")
            return nil
        }
    }
    
    // MARK: Sandbox only
    private func saveImageToDesktop(_ image: ImageData) {
        guard let nsImage = NSImage(data: image) else {
            print("Unable to convert ImageData to NSImage.")
            return
        }
    }
    
    private func saveFileToICloud(fileURL: URL, completion: @escaping (URL?) -> Void) {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: "YourRecordType", recordID: recordID)
        
        let asset = CKAsset(fileURL: fileURL)
        record["file"] = asset
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        privateDatabase.save(record) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving to iCloud: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    print("File successfully saved to iCloud")
                    guard let record = record else {
                        print("Error: CKRecord is nil")
                        completion(nil)
                        return
                    }
                    let recordName = record.recordID.recordName
                    let shareURLString = "https://www.icloud.com/share/#\(recordName)"
                    if let shareURL = URL(string: shareURLString) {
                        completion(shareURL)
                    } else {
                        print("Error constructing share URL.")
                        completion(nil)
                    }
                }
            }
        }
    }
    
    private func saveFileToICloudAnother(fileURL: URL, completion: @escaping (URL?) -> Void) {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: "YourRecordType", recordID: recordID)
        let asset = CKAsset(fileURL: fileURL)
        record["file"] = asset

        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase

        privateDatabase.save(record) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving to iCloud: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let record = record else {
                    print("Error: CKRecord is nil")
                    completion(nil)
                    return
                }

                let recordName = record.recordID.recordName
                let shareURLString = "https://www.icloud.com/share/#\(recordName)"
                guard let shareURL = URL(string: shareURLString) else {
                    print("Error constructing share URL.")
                    completion(nil)
                    return
                }

                print("File successfully saved to iCloud")
                completion(shareURL)
            }
        }
    }

    private func deleteImage(_ image: ImageData) {
        // @Kirill likes the speed over the animations :D
        // Easier to close all by spamming the button
        model.images.removeAll(where: { $0 == image })
    }
    
    private func openImageInPreview(image: NSImage) {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryImageURL = temporaryDirectoryURL.appendingPathComponent("ShareShot.png")
        if let imageData = image.tiffRepresentation, let bitmapRep = NSBitmapImageRep(data: imageData) {
            if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: temporaryImageURL)
                } catch {
                    print("Failed to save temporary image: \(error)")
                    return
                }
            }
        }
        NSWorkspace.shared.open(temporaryImageURL)
    }

    
    // MARK: Sandbox only
    private func saveImageToDesktop(_ image: ImageData) {
        let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard let desktop = desktopURL else {
            print("Unable to access desktop directory.")
            return
        }
        
        let fileName = dateTimeUniqueScreenshotFileName()
        let filePath = desktop.appendingPathComponent(fileName)
        
        saveImageAsPng(image: image, at: filePath)
    }
}
