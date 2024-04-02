//
//  Persistance.swift
//  ShareShot
//
//  Created by Kirill Dubovitskiy on 4/1/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import AppKit

func screenshotHistoryUrl() -> URL {
    FileManager.default.homeDirectoryForCurrentUser.appending(component: "screenshots")
}

func dateTimeUniqueScreenshotFileName() -> String {
    let currentDate = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yy:MM:dd - HH:mm:ss"
    let formattedDate = dateFormatter.string(from: currentDate)
    let fileName = "ShareScreenshot_\(formattedDate).png"
    return fileName
}

func saveImageAsPng(image: ImageData, at fileURL: URL) {
    do {
        guard let nsImage = NSImage(data: image) else {
            print("Unable to convert ImageData to NSImage.")
            return
        }
        
        let imageData: Data
        if let tiffData = nsImage.tiffRepresentation,
           let bitmapImageRep = NSBitmapImageRep(data: tiffData) {
            imageData = bitmapImageRep.representation(using: .png, properties: [:]) ?? Data()
        } else {
            print("Error converting image to PNG format.")
            return
        }
        
        try imageData.write(to: fileURL)
        print("Image saved at \(fileURL.absoluteString)")
    } catch {
        print("Error saving image: \(error)")
    }
}
