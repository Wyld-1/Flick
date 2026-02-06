//
//  ContentView.swift
//  Coda
//
//  Created by Liam Lefohn on 2/5/26.
//

import SwiftUI

struct ContentView: View {
    @State private var settings = SharedSettings.load()

    var body: some View {
        if !settings.isTutorialCompleted {
            WelcomeView()
        } else {
            MainView()
        }
    }
}

#Preview {
    ContentView()
}
