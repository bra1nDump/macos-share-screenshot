//
//  OnboardingView.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 3/23/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct OnboardingFirstView: View {
    var body: some View {
        NavigationStack{
            VStack{
                Image("Logo")
                    .resizable()
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
                Text("Welcome to the ShareShot!")
                    .bold()
                    .font(.largeTitle)
                    .padding()
                Text("Let's guide you through a quick setup and tailor ShareShot to your preferences.")
                NavigationLink(destination: OnboardingSecondView().navigationBarBackButtonHidden()) {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 150, height: 40)
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .overlay(
                            Text("Next")
                                .bold()
                        )
                        .padding()
                }
            }
            .padding()
            .frame(width: 500, height: 400)
        }
    }
}

struct OnboardingSecondView: View {
    var body: some View {
        VStack{
            Image(systemName: "command")
                .resizable()
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
            Text("Shortcut for screnshot")
                .bold()
                .font(.largeTitle)
                .padding()
            Text("Let's use ⇧⌘7 for screenshot.")
            NavigationLink(destination: OnboardingThirdView().navigationBarBackButtonHidden()) {
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: 150, height: 40)
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    .overlay(
                        Text("Next")
                            .bold()
                    )
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct OnboardingThirdView: View {
    var body: some View {
        VStack{
            Image(systemName: "plus.square.on.square")
                .resizable()
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
            Text("Drag and Grop")
                .bold()
                .font(.largeTitle)
                .padding()
            Text("More options in status bar.")
            RoundedRectangle(cornerRadius: 15)
                .frame(width: 150, height: 40)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                .overlay(
                Text("Next")
                    .bold()
                )
                .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct OnboardingFourthView: View {
    var body: some View {
        VStack{
            Image(systemName: "gear")
                .resizable()
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
            Text("Set your preferences")
                .bold()
                .font(.largeTitle)
                .padding()
            Text("More options in status bar.")
            RoundedRectangle(cornerRadius: 15)
                .frame(width: 150, height: 40)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                .overlay(
                Text("Next")
                    .bold()
                )
                .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct OnboardingScreenshot: View{
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

