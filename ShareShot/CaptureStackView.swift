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
            if !model.images.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if isPanelCollapsed {
                            Spacer()
                            OpenAllButton(action: { isPanelCollapsed.toggle() })
                                .padding()
                                .rotationEffect(.degrees(180))
                        }
                        if !isPanelCollapsed {
                            ForEach(model.images.reversed(), id: \.self) { image in
                                ScreenShotView(image: image, saveImage: saveImage, copyImage: copyToClipboard, deleteImage: deleteImage, saveToDesktopImage: saveImageToDesktop, shareImage: shareAction, saveToiCloud: saveImageToICloud)
                                    .onTapGesture {
                                        // Open the image in Preview app upon tap
                                        openImageInPreview(image: NSImage(data: image)!)
                                    }
                                    .rotated()
                            }
                            
                            if onboardingShown {
                                OnboardingScreenshot()
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            onboardingShown = false
                                        }
                                    }
                            }
                            CloseAllButton(action: { isPanelCollapsed.toggle() })
                                .padding()
                                .rotationEffect(.degrees(180))
                        }
                    }
                }
                .rotationEffect(.degrees(180), anchor: .center)
            }
        }
        .padding(.bottom, 60)
        .padding(20)
    }
    
    // Generate actions for the screenshot view
    
    // Share action to share the image
    private func shareAction(_ imageData: ImageData) {
        guard let mainWindow = ShareShotApp.appDelegate?.currentPreviewPanel?.contentView?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews.first?.subviews[indexForImage(imageData)!] else {
            print("No windows available.")
            return
        }
        let sharingPicker = NSSharingServicePicker(items: [NSImage(data: imageData) as Any])
        sharingPicker.show(relativeTo: mainWindow.bounds, of: mainWindow, preferredEdge: .minX)
    }
    
    // Get the index of the image in the model
    private func indexForImage(_ imageData: ImageData) -> Int? {
        model.images.firstIndex(of: imageData)
    }
    
    // Copy the image to clipboard
    private func copyToClipboard(_ image: ImageData) {
        guard let nsImage = NSImage(data: image) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
        deleteImage(image)
    }
    
    // Save the image locally
    private func saveImage(_ image: ImageData) {
        guard let nsImage = NSImage(data: image) else { return }
        let savePanel = NSSavePanel()
        let currentDate = Date()
        let formattedDate = DateFormatter.localizedString(from: currentDate, dateStyle: .short, timeStyle: .short)
        savePanel.nameFieldStringValue = "CaptureSample - \(formattedDate).png"
        savePanel.message = "Select a directory to save the image"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let folderManager = FolderManager()
                folderManager.loadFromUserDefaults()
                folderManager.addFolderLink(name: formattedDate, url: url)
                guard let tiffData = nsImage.tiffRepresentation,
                      let bitmapImageRep = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImageRep.representation(using: .png, properties: [:]) else { return }
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
    
    // Save the image to iCloud
    private func saveImageToICloud(_ image: ImageData) {
        guard let fileURL = saveImageLocally(image) else { return }
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
        guard let nsImage = NSImage(data: image) else {
            print("Unable to convert ImageData to NSImage.")
            return nil
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileName = "ShareShot_\(UUID().uuidString).png"
        guard let fileURL = documentsDirectory?.appendingPathComponent(fileName) else { return nil }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImageRep.representation(using: .png, properties: [:]) else {
            print("Error converting image to PNG format.")
            return nil
        }
        do {
            try pngData.write(to: fileURL)
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
    
    // Save the image to desktop (sandbox only)
    private func saveImageToDesktop(_ image: ImageData) {
        guard let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            print("Unable to access desktop directory.")
            return
        }
        let fileName = dateTimeUniqueScreenshotFileName()
        let filePath = desktopURL.appendingPathComponent(fileName)
        saveImageAsPng(image: image, at: filePath)
    }
    
    // Generate a unique filename based on date and time
    private func dateTimeUniqueScreenshotFileName() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "ShareShot_\(formatter.string(from: currentDate)).png"
    }
}

// MARK: View Extensions

private extension View {
    func rotated() -> some View {
        self.rotationEffect(.degrees(180))
    }
}

private struct CloseAllButton: View {
    var action: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .frame(width: 100, height: 40)
            .foregroundColor(.white.opacity(0.7))
            .overlay(
                Text("Close All")
                    .font(.title2)
                    .foregroundColor(.black)
            )
            .onTapGesture {
                action()
            }
    }
}

private struct OpenAllButton: View {
    var action: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .frame(width: 100, height: 40)
            .foregroundColor(.white.opacity(0.7))
            .overlay(
                Text("Open All")
                    .font(.title2)
                    .foregroundColor(.black)
            )
            .onTapGesture {
                action()
            }
    }
}

