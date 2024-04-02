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
import CloudKit


struct CaptureStackView: View {
    @StateObject var model: StackModel
    @AppStorage("onboardingShown") var onboardingShown = true
    
    init(model: StateObject<StackModel>, onboardingShown: Bool = true) {
        self._model = model
        self.onboardingShown = onboardingShown
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
                        if onboardingShown{
                            withAnimation{
                                OnboardingScreenshot()
                                    .onAppear{
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
        if let mainWindow = ShareShotApp.appDelegate?.currentPreviewPanel{
            sharingPicker.show(relativeTo: mainWindow.contentView!.subviews.first!.bounds, of: mainWindow.contentView!.subviews.first!.subviews.first!, preferredEdge: .maxY)
            
        } else {
            print("No windows available.")
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
        guard let nsImage = NSImage(data: image) else {
            print("Unable to convert ImageData to NSImage.")
            return
        }

        // Obtain the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory.")
            return
        }
        
        // Generate a unique filename based on the current date and time
        let currentDate = Date()
        let formattedDate = DateFormatter.localizedString(from: currentDate, dateStyle: .short, timeStyle: .short)
        let fileName = "ShareShot_\(UUID().uuidString).png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImageRep.representation(using: .png, properties: [:]) else {
            print("Error converting image to PNG format.")
            return
        }
        
        do {
            // Write PNG data to a file in the documents directory
            try pngData.write(to: fileURL)
            
            // Save to iCloud
            saveFileToICloud(fileURL: fileURL) { iCloudURL in
                // Handle iCloud saving completion (e.g., show a notification)
                if let iCloudURL = iCloudURL {
                    print("Image saved to iCloud. URL: \(iCloudURL)")
                    
                    // Optionally, copy the iCloud URL to the clipboard
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([iCloudURL as NSPasteboardWriting])
                } else {
                    print("Error saving image to iCloud.")
                }
            }
            
            // Delete the original image
            deleteImage(image)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Failed to save image to iCloud."
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .critical
            alert.runModal()
            print("Error saving image: \(error)")
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
                    
                    // TODO: When opening this url nothing happens
                    // Is it possible the record is only sharable inside the app?
                    // So CloudKit is more just like a database, but cannot actually be used for sharing with other people
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
        withAnimation {
            model.images.removeAll(where: { $0 == image })
        }
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
