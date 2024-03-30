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
    var onComplete: () -> Void
    let screens = [
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
        VStack {
            ScrollView {
                OnboardingScreenView(screen: screens[currentPage])
            }
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 150, height: 30)
                .foregroundColor(.blue)
                .overlay(
                    VStack{
                        if currentPage == 3{
                            Text("Start")
                                .bold()
                                .padding()
                                .foregroundColor(.white)
                        }else{
                            Text("Next")
                                .bold()
                                .padding()
                                .foregroundColor(.white)
                        }
                    }
                )
                .onTapGesture {
                    if currentPage == 3{
                        onComplete()
                    }else{
                        currentPage += 1
                    }
                }
                .padding()
        }
        .frame(width: 500, height: 400)
    }
}

struct OnboardingScreenView: View {
    let screen: OnboardingScreen
    var body: some View {
        VStack {
            if screen.imageName == "Logo"{
                Image(screen.imageName)
                    .resizable()
                    .frame(width: 100, height: 100)
            }else{
                Image(systemName: screen.imageName)
                    .resizable()
                    .frame(width: 100, height: 100)
            }
            Text(screen.title)
                .bold()
                .font(.largeTitle)
                .padding()
            Text(screen.description)
        }
        .padding()
    }
}

struct OnboardingScreen {
    let imageName: String
    let title: String
    let description: String
}

struct OnboardingScreenshot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 201, height: 152)
            .foregroundColor(.gray.opacity(0.7))
            .overlay(
                Text("Use ⇧⌘7 for screenshot")
                    .bold()
            )
            .rotationEffect(.degrees(180))
    }
}
