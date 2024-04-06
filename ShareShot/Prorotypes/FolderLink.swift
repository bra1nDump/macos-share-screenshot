//
//  FolderLink.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 3/3/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

// Structure to represent a folder link
struct FolderLink: Codable {
    var name: String
    var url: URL
}

// Manager class for handling recent folders
class FolderManager {
    // Array to store recent folder links
    private var recentFolders: [FolderLink] = []
    // Maximum number of recent folders to keep
    private let maxRecentFoldersCount = 3
    
    // Add a folder link to recent folders
    func addFolderLink(name: String, url: URL) {
        let newLink = FolderLink(name: name, url: url)
        // Check if the folder already exists, remove it before adding to keep it unique
        if let existingIndex = recentFolders.firstIndex(where: { $0.url == url }) {
            recentFolders.remove(at: existingIndex)
        }
        // Insert the new folder link at the beginning of the array
        recentFolders.insert(newLink, at: 0)
        // Remove the last folder link if the count exceeds the maximum
        if recentFolders.count > maxRecentFoldersCount {
            recentFolders.removeLast()
        }
        // Save the recent folders to UserDefaults
        saveToUserDefaults()
    }
    
    // Retrieve the recent folders
    func getRecentFolders() -> [FolderLink] {
        return recentFolders
    }
    
    // Save recent folders to UserDefaults
    func saveToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentFolders)
            UserDefaults.standard.set(data, forKey: "recentFolders")
        } catch {
            print("Failed to save recent folders to UserDefaults: \(error)")
        }
    }
    
    // Load recent folders from UserDefaults
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "recentFolders") {
            do {
                let decoder = JSONDecoder()
                recentFolders = try decoder.decode([FolderLink].self, from: data)
            } catch {
                print("Failed to load recent folders from UserDefaults: \(error)")
            }
        }
    }
}
