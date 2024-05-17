//
//  OnboardingView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 3/23/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var backgroundColor: Color = .blue
    @State private var nextButtonColor: Color = .red
    let onComplete: () -> Void
    
    let screens: [OnboardingScreen] = [
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
    
    let colors: [Color] = [.red, .green, .blue, .orange, .yellow] // Example colors
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack {
                    OnboardingScreenView(screen: screens[currentPage])
                        .padding(.top, geometry.size.height * 0.1)
                    
                    Spacer()
                    
                    PageControl(numberOfPages: screens.count, currentPage: $currentPage)
                        .padding(.bottom)
                    
                    Button(action: handleNextButton) {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func handleNextButton() {
        withAnimation {
            if currentPage == screens.count - 1 {
                onComplete()
            } else {
                currentPage += 1
                backgroundColor = colors[currentPage % colors.count]
                nextButtonColor = colors[(currentPage + 1) % colors.count]
            }
        }
    }
}

struct PageControl: View {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(page == currentPage ? .white : .gray)
            }
        }
    }
}

struct OnboardingScreenView: View {
    let screen: OnboardingScreen
    
    var body: some View {
        VStack {
            if screen.imageName == "Logo" {
                Image(screen.imageName)
                    .resizable()
                    .frame(width: 100, height: 100)
            } else {
                Image(systemName: screen.imageName)
                    .resizable()
                    .frame(width: 100, height: 100)
            }
            
            Text(screen.title)
                .bold()
                .font(.title)
                .padding()
            
            Text(screen.description)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct OnboardingScreen {
    let imageName: String
    let title: String
    let description: String
}
