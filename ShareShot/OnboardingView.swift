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
    }
}

struct OnboardingThirdView: View {
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
    }
}

#Preview {
    OnboardingFirstView()
}
