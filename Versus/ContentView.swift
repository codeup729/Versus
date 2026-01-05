//
//  ContentView.swift
//  Versus
//
//  Created by Anitej Srivastava on 31/12/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - State
    
    @State private var showSplash = true
    @State private var showTennisBallTransition = false
    @State private var showAuthScreen = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Auth Screen (base layer)
            if showAuthScreen {
                AuthView()
                    .opacity(showAuthScreen ? 1 : 0)
                    .animation(.easeIn, value: showAuthScreen)
            }
            
            // Splash Screen (on top initially)
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeOut) {
                        showSplash = false
                    }
                    showAuthScreen = true
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Transition Methods
    
//    private func startTennisBallTransition() {
//        // Show auth screen first (it will be behind the tennis ball)
//        showAuthScreen = true
//        
//        // Fade out splash
//        withAnimation(.easeOut(duration: 0.4)) {
//            showSplash = false
//        }
//        
//        // Show tennis ball transition after splash fades
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//            withAnimation(.easeIn(duration: 0.3)) {
//                showTennisBallTransition = true
//            }
//        }
//    }
//    
//    private func completeTennisBallTransition() {
//        // Fade out tennis ball to reveal auth screen beneath
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            withAnimation(.easeOut(duration: 0.8)) {
//                showTennisBallTransition = false
//            }
//        }
//    }
}

#Preview {
    ContentView()
}
