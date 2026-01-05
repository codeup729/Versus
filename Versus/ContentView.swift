//
//  ContentView.swift
//  Versus
//
//  Created by Anitej Srivastava on 31/12/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    
    @State private var showSplash = true
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
                .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
