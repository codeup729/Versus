//
//  SplashScreenView.swift
//  Versus
//
//  Created by Anitej Srivastava on 04/01/26.
//

import SwiftUI

struct SplashScreenView: View {
    // MARK: - Properties
    
    @State private var progress: Double = 0.0
    var onComplete: () -> Void
    
    // MARK: - Colors
    
    private let backgroundDark = Color(red: 0.02, green: 0.05, blue: 0.02)
    private let backgroundLight = Color(red: 0.04, green: 0.12, blue: 0.04)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    private let logoContainer = Color(red: 0.05, green: 0.17, blue: 0.05)
    private let textMuted = Color(red: 0.29, green: 0.35, blue: 0.29)
    private let progressTrack = Color(red: 0.1, green: 0.16, blue: 0.1)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [backgroundLight, backgroundDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and branding section
                VStack(spacing: 24) {
                    // Logo container with glow
                    ZStack {
                        // Glow effect
                        RoundedRectangle(cornerRadius: 28)
                            .fill(accentGreen.opacity(0.15))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                        
                        // Logo background
                        RoundedRectangle(cornerRadius: 28)
                            .fill(logoContainer)
                            .frame(width: 120, height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Lightning bolt icon
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundColor(accentGreen)
                    }
                    
                    // Title
                    Text("VERSUS")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    // Tagline
                    Text("FIND YOUR MATCH")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentGreen)
                        .tracking(6)
                }
                
                Spacer()
                Spacer()
                
                // Progress section
                VStack(spacing: 12) {
                    // Progress labels
                    HStack {
                        Text("CONNECTING...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textMuted)
                            .tracking(2)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentGreen)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressTrack)
                                .frame(height: 6)
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentGreen)
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 40)
                
                // Version text
                Text("V 1.0.0 • BETA")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textMuted)
                    .tracking(2)
                
                Spacer()
                    .frame(height: 30)
            }
        }
        .onAppear {
            startProgressAnimation()
        }
    }
    
    // MARK: - Methods
    
    private func startProgressAnimation() {
        // Animate progress from 0 to 1 over 3 seconds
        withAnimation(.easeInOut(duration: 1)) {
            progress = 1.0
        }
        
        // Trigger completion after animation finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            onComplete()
        }
    }
}

#Preview {
    SplashScreenView(onComplete: {})
}

