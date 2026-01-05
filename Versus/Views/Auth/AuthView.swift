//
//  AuthView.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//

import SwiftUI

struct AuthView: View {
    // MARK: - Properties
    
    @Namespace private var animation
    @State private var isLoginMode: Bool = true
    @State private var phoneNumber: String = ""
    @State private var countryCode: String = "+1"
    @State private var showOTPScreen: Bool = false
    @State private var logoRotation: Double = 0
    @FocusState private var isPhoneFocused: Bool
    
    // MARK: - Colors
    
    private let backgroundDark = Color(red: 0.02, green: 0.05, blue: 0.02)
    private let backgroundLight = Color(red: 0.04, green: 0.12, blue: 0.04)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    private let logoContainer = Color(red: 0.05, green: 0.17, blue: 0.05)
    private let textMuted = Color(red: 0.4, green: 0.5, blue: 0.4)
    private let toggleBackground = Color(red: 0.06, green: 0.14, blue: 0.06)
    
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
            
            if showOTPScreen {
                OTPVerificationView(
                    phoneNumber: phoneNumber,
                    countryCode: countryCode,
                    onBack: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showOTPScreen = false
                        }
                    },
                    onVerified: {
                        // Navigate to Hero page
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                mainAuthContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            startIdleAnimations()
        }
    }
    
    // MARK: - Main Auth Content
    
    private var mainAuthContent: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // 3D Floating Logo
            logoSection
            
            Spacer()
                .frame(height: 40)
            
            // Toggle Section
            toggleSection
            
            Spacer()
                .frame(height: 32)
            
            // Welcome Text
            welcomeTextSection
            
            Spacer()
                .frame(height: 32)
            
            // Phone Input
            PhoneInputView(
                phoneNumber: $phoneNumber,
                countryCode: $countryCode,
                isPhoneFocused: $isPhoneFocused
            )
            .padding(.horizontal, 24)
            
            Spacer()
                .frame(height: 24)
            
            // Continue Button
            continueButton
            
            Spacer()
            
            // Terms Text
            termsText
            
            Spacer()
                .frame(height: 30)
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 12) {
            // Logo with 3D rotation
            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 18)
                    .fill(accentGreen.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)
                
                // Container
                RoundedRectangle(cornerRadius: 18)
                    .fill(logoContainer)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                    )
                
                // Icon
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(accentGreen)
            }
            .rotation3DEffect(
                .degrees(logoRotation),
                axis: (x: 0, y: 1, z: 0)
            )
            .shadow(color: accentGreen.opacity(0.3), radius: 15, y: 8)
            .shadow(color: Color.black.opacity(0.4), radius: 20, y: 12)
            
            // Title
            Text("VERSUS")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .tracking(3)
        }
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        HStack(spacing: 0) {
            // Log In Tab
            toggleTab(title: "Log In", isSelected: isLoginMode) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isLoginMode = true
                }
            }
            
            // Sign Up Tab
            toggleTab(title: "Sign Up", isSelected: !isLoginMode) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isLoginMode = false
                }
            }
        }
        .padding(4)
        .background(toggleBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentGreen.opacity(0.15), lineWidth: 1)
        )
        // 3D shadow
        .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
        .shadow(color: Color.black.opacity(0.2), radius: 24, y: 12)
        .padding(.horizontal, 60)
    }
    
    private func toggleTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentGreen.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentGreen.opacity(0.4), lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "toggle", in: animation)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Welcome Text Section
    
    private var welcomeTextSection: some View {
        VStack(spacing: 8) {
            Text(isLoginMode ? "Welcome back" : "Create account")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .id("title_\(isLoginMode)")
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
            
            Text(isLoginMode ? "Enter your phone to continue" : "Enter your phone to get started")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textMuted)
                .id("subtitle_\(isLoginMode)")
                .transition(.opacity)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isLoginMode)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: {
            if !phoneNumber.isEmpty {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showOTPScreen = true
                }
            }
        }) {
            Text("Continue")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(backgroundDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(phoneNumber.isEmpty ? accentGreen.opacity(0.4) : accentGreen)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(ContinueButton3DStyle(isEnabled: !phoneNumber.isEmpty))
        .disabled(phoneNumber.isEmpty)
        .padding(.horizontal, 24)
        // Multi-layer shadows
        .shadow(color: accentGreen.opacity(phoneNumber.isEmpty ? 0 : 0.3), radius: 0, y: 3)
        .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
        .shadow(color: Color.black.opacity(0.2), radius: 24, y: 12)
    }
    
    // MARK: - Terms Text
    
    private var termsText: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to our")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(textMuted)
            
            HStack(spacing: 4) {
                Button("Terms of Service") {}
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentGreen.opacity(0.8))
                
                Text("&")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(textMuted)
                
                Button("Privacy Policy") {}
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentGreen.opacity(0.8))
            }
        }
    }
    
    // MARK: - Animations
    
    private func startIdleAnimations() {
        // Logo pendulum animation
        withAnimation(
            .easeInOut(duration: 3)
            .repeatForever(autoreverses: true)
        ) {
            logoRotation = 8
        }
    }
}

// MARK: - Continue Button 3D Style

struct ContinueButton3DStyle: ButtonStyle {
    var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 3 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    AuthView()
}
