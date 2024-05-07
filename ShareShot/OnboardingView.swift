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
                         title: "Welcome to ShareShot!",
                         description: "Let's guide you through a quick setup and tailor ShareShot to your preferences."),
        OnboardingScreen(imageName: "command",
                         title: "Shortcut for Screenshots",
                         description: "Use ⇧⌘7 to capture screenshots."),
        OnboardingScreen(imageName: "plus.square.on.square",
                         title: "Drag and Drop",
                         description: "Drag and drop options available in the status bar."),
        OnboardingScreen(imageName: "gear",
                         title: "Set Your Preferences",
                         description: "Customize settings from the status bar.")
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all) // Set background color for entire view
            
            VStack {
                // Display the current onboarding screen
                OnboardingScreenView(screen: screens[currentPage])
                    .padding(.top, 100)
                
                Spacer()
                
                // Page indicators
                PageControl(numberOfPages: screens.count, currentPage: $currentPage)
                    .padding(.bottom)
                
                // Next/Start button with animation
                Button(action: {
                    withAnimation {
                        // Handle button tap
                        if currentPage == screens.count - 1 {
                            onComplete() // If on the last screen, call completion handler
                        } else {
                            currentPage += 1 // Otherwise, move to the next screen
                            backgroundColor = getNextColor() // Change background color
                            nextButtonColor = getButtonColor()
                        }
                    }
                }) {
                    Label(currentPage == screens.count - 1 ? "Start" : "Next", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(nextButtonColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 5)
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

// Custom page control indicator
struct PageControl: View {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack {
            ForEach(0..<numberOfPages) { page in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(page == currentPage ? .white : .gray)
            }
        }
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
                .font(.title)
                .padding()
            
            Text(screen.description) // Display description
                .multilineTextAlignment(.center)
                .padding()
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
