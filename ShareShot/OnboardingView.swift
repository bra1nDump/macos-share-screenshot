//
//  OnboardingView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 3/23/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

// View for onboarding process
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var backgroundColor = Color.blue // Background color for demonstration
    @State private var nextButtonColor = Color.red
    let onComplete: () -> Void
    let screens = [
        // Array of onboarding screens
        OnboardingScreen(imageName: "Logo",
                         title: "Welcome to the ShareShot!",
                         description: "Let's guide you through a quick setup and tailor ShareShot to your preferences."),
        OnboardingScreen(imageName: "command",
                         title: "Shortcut for screenshot",
                         description: "Let's use ⇧⌘7 for screenshot."),
        OnboardingScreen(imageName: "plus.square.on.square",
                         title: "Drag and Drop",
                         description: "More options in status bar."),
        OnboardingScreen(imageName: "gear",
                         title: "Set your preferences",
                         description: "More options in status bar.")
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all) // Set background color for entire view
            
            VStack {
                    // Display the current onboarding screen
                    OnboardingScreenView(screen: screens[currentPage])
                    .padding(.top, 100)
                Spacer()
                // Next/Start button with animation
                    Image(systemName: currentPage == 3 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(nextButtonColor)
                        .onTapGesture {
                            withAnimation {
                                // Handle button tap
                                if currentPage == 3 {
                                    onComplete() // If on the last screen, call completion handler
                                } else {
                                    currentPage += 1 // Otherwise, move to the next screen
                                    backgroundColor = getNextColor() // Change background color
                                    nextButtonColor = getButtonColor()
                                }
                        }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Set frame to fill entire window
    }
    
    // Function to get the next background color
    func getNextColor() -> Color {
        let colors: [Color] = [.red, .green, .blue, .orange, .yellow] // Example colors
        return colors[currentPage % colors.count]
    }
    func getButtonColor() -> Color {
        let colors: [Color] = [.green, .blue, .orange, .yellow] // Example colors
        return colors[currentPage % colors.count]
    }
}

// View for individual onboarding screen
struct OnboardingScreenView: View {
    let screen: OnboardingScreen
    
    var body: some View {
        VStack {
            if screen.imageName == "Logo" {
                Image(screen.imageName) // Show image if it's the logo
                    .resizable()
                    .frame(width: 100, height: 100)
            } else {
                Image(systemName: screen.imageName) // Otherwise, show system image
                    .resizable()
                    .frame(width: 100, height: 100)
            }
            
            Text(screen.title) // Display title
                .bold()
                .font(.largeTitle)
                .padding()
            
            Text(screen.description) // Display description
        }
        .padding()
    }
}

// Model representing an onboarding screen
struct OnboardingScreen {
    let imageName: String
    let title: String
    let description: String
}

// View for onboarding screenshot example
struct OnboardingScreenshot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 201, height: 152)
            .foregroundColor(.gray.opacity(0.7))
            .overlay(
                Text("Use ⇧⌘7 for screenshot") // Display instructions for screenshot shortcut
                    .bold()
            )
            .rotationEffect(.degrees(180))
    }
}
