//
//  FolderLink.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 3/3/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

struct FolderLink: Codable {
    var name: String
    var url: URL
}

class FolderManager {
    private var recentFolders: [FolderLink] = []
    private let maxRecentFoldersCount = 3
    
    func addFolderLink(name: String, url: URL) {
        let newLink = FolderLink(name: name, url: url)
        if let existingIndex = recentFolders.firstIndex(where: { $0.url == url }) {
            recentFolders.remove(at: existingIndex)
        }
        recentFolders.insert(newLink, at: 0)
        if recentFolders.count > maxRecentFoldersCount {
            recentFolders.removeLast()
        }
        saveToUserDefaults()
    }
    
    func getRecentFolders() -> [FolderLink] {
        return recentFolders
    }
    
    func saveToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentFolders)
            UserDefaults.standard.set(data, forKey: "recentFolders")
        } catch {
            print("Failed to save recent folders to UserDefaults: \(error)")
        }
    }
    
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
