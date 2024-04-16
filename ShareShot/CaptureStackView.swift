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

// SwiftUI view for displaying captured stack of images
struct CaptureStackView: View {
    var model: StackModel
    @AppStorage("onboardingShown") var onboardingShown = true
    @State private var isPanelCollapsed = false

    // Initialize with a StackModel
    init(model: StackModel) {
        self.model = model
    }

    var body: some View {
        VStack {
            var capturedImages = model.images

            if !capturedImages.isEmpty {
                VStack{
                    if isPanelCollapsed {
                        Spacer()
                    }
                    HStack {
                            // Toggle the panel collapse state
                            Image(systemName: isPanelCollapsed ? "chevron.down" : "chevron.up")
                                .resizable()
                                .frame(width: 120, height: 30)
                                .foregroundColor(.white.opacity(0.8))
                                .onTapGesture {
                                    withAnimation {
                                        isPanelCollapsed.toggle()
                                    }
                        }
                        .padding()
                       .foregroundColor(Color.black.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.black.opacity(0.5))
                                        )
                    .rotationEffect(.degrees(180))
                    .padding()
                    
                    if !isPanelCollapsed {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 20) {
                                // Display each captured image in a reversed order
                                ForEach(capturedImages.reversed(), id: \.self) { image in
                                    // Custom view to display screenshot
                                    ScreenShotView(image: image, saveImage: saveImage, copyImage: copyToClipboard, deleteImage: deleteImage, saveToDesktopImage: saveImageToDesktop, shareImage: shareAction, saveToiCloud: saveImageToICloud)
                                        .onTapGesture {
                                            // Open the image in Preview app upon tap
                                            openImageInPreview(image: NSImage(data: image)!)
                                        }
                                        .rotationEffect(.degrees(180))
                                }
                                // Display onboarding view for screenshot toolkit if onboardingShown is true
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
                                // Close All button
                                Button(action: {
                                    // Implement logic to close all screenshots
                                    capturedImages.removeAll()
                                }) {
                                    Text("Close All")
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .rotationEffect(.degrees(180))
                    }
                }
            }
        }
        .padding(.bottom, 60)
        .padding(20)
    }


    
    // Share action to share the image
    private func shareAction(_ imageData: ImageData) {
        let sharingPicker = NSSharingServicePicker(items: [NSImage(data: imageData) as Any])
        
        // Find the main window to show the sharing picker
        if let mainWindow =  ShareShotApp.appDelegate?.currentPreviewPanel?.contentView?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews[indexForImage(imageData)!] {
            sharingPicker.show(relativeTo: mainWindow.bounds, of: mainWindow, preferredEdge: .minX)
        } else {
            print("No windows available.")
        }
    }
    
    // Get the index of the image in the model
    private func indexForImage(_ imageData: ImageData) -> Int? {
        return model.images.firstIndex(of: imageData)
    }
    
    // Copy the image to clipboard
    private func copyToClipboard(_ image: ImageData) {
        if let nsImage = NSImage(data: image) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([nsImage])
            deleteImage(image)
        }
    }
  
    // Save the image locally
    private func saveImage(_ image: ImageData) {
        // Check if NSImage can be created from image data
        guard let nsImage = NSImage(data: image) else { return }
        
        // Create a save panel for image
        let savePanel = NSSavePanel()
        
        // Format the current date for use in the file name
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let formattedDate = dateFormatter.string(from: currentDate)
        
        // Set up save panel parameters
        savePanel.nameFieldStringValue = "CaptureSample - \(formattedDate).png"
        savePanel.message = "Select a directory to save the image"
        
        // Initialize folder manager to manage saved folders
        let folderManager = FolderManager()
        folderManager.loadFromUserDefaults()
        
        // Begin working with the save panel
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                // Add a link to the saved folder in the folder manager
                folderManager.addFolderLink(name: formattedDate, url: url)
                
                // Convert image to PNG data and write to file
                guard let tiffData = nsImage.tiffRepresentation,
                      let bitmapImageRep = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImageRep.representation(using: .png, properties: [:]) else {
                    return
                }
                do {
                    try imageData.write(to: url)
                    // Delete the saved image after successful saving
                    deleteImage(image)
                    print("Image saved")
                } catch {
                    print("Error saving image: \(error)")
                }
                
                // Save folder information to UserDefaults (for sandbox mode)
                #if SANDBOX
                folderManager.saveToUserDefaults()
                print(folderManager.getRecentFolders())
                #endif
            }
        }
    }
    
    // Save the image to iCloud
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
    
    // Save the image locally and return its URL
    private func saveImageLocally(_ image: ImageData) -> URL? {
        // Convert ImageData to NSImage
        guard let nsImage = NSImage(data: image) else {
            print("Unable to convert ImageData to NSImage.")
            return nil
        }

        // Get documents directory URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        _ = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let fileName = "ShareShot_\(UUID().uuidString).png"
        let fileURL = documentsDirectory?.appendingPathComponent(fileName)

        // Convert NSImage to PNG data and save to fileURL
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
    
    // Save the file to iCloud
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

    // Delete the image from the model
    private func deleteImage(_ image: ImageData) {
        // Remove the image from the model's images array
        model.images.removeAll(where: { $0 == image })
    }
    
    // Open the image in Preview app
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
    
    // Save the image to desktop (sandbox only)
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
