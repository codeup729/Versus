//
//  HomeView.swift
//  Versus
//
//  Created by Anitej Srivastava on 04/01/26.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Colors
    
    private let backgroundDark = Color(red: 0.02, green: 0.05, blue: 0.02)
    private let backgroundLight = Color(red: 0.04, green: 0.12, blue: 0.04)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient (consistent with splash screen)
            LinearGradient(
                colors: [backgroundLight, backgroundDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40))
                    .foregroundColor(accentGreen)
                
                Text("Home")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Coming Soon")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentGreen.opacity(0.7))
            }
        }
    }
}

#Preview {
    HomeView()
}

