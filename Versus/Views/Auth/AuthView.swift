//
//  AuthView.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @Namespace private var animation
    @State private var showOTPScreen = false
    @State private var logoRotation: Double = 0
    @FocusState private var isPhoneFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    var onAuthenticated: (() -> Void)?
    
    // MARK: - Colors
    
    private let backgroundDark = Color(red: 0.02, green: 0.05, blue: 0.02)
    private let backgroundLight = Color(red: 0.04, green: 0.12, blue: 0.04)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    private let logoContainer = Color(red: 0.05, green: 0.17, blue: 0.05)
    private let textMuted = Color(red: 0.4, green: 0.5, blue: 0.4)
    private let toggleBackground = Color(red: 0.06, green: 0.14, blue: 0.06)
    
    // MARK: - Body
    
    @MainActor
    init(
        viewModel: AuthViewModel? = nil,
        onAuthenticated: (() -> Void)? = nil
    ) {
        let resolvedViewModel = viewModel ?? AuthViewModel(
            authService: AuthService(
                providers: [
                    PasswordAuthProvider()
                ]
            )
        )
        
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
        self.onAuthenticated = onAuthenticated
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [backgroundLight, backgroundDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if showOTPScreen, let challenge = viewModel.activeChallenge {
                OTPVerificationView(
                    challenge: challenge,
                    onBack: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.dismissOTP()
                        }
                    },
                    onVerifyCode: { code in
                        try await viewModel.verifyOTP(code: code)
                    },
                    onResendCode: {
                        try await viewModel.resendOTP()
                    },
                    onVerified: {}
                )
                .id(challenge.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else if viewModel.isAuthenticated {
                authenticatedContent
                    .transition(.opacity)
            } else {
                mainAuthContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: viewModel.activeChallenge?.id) { _, challengeID in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showOTPScreen = challengeID != nil
            }
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            onAuthenticated?()
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
                phoneNumber: $viewModel.phoneNumber,
                countryCode: $viewModel.countryCode,
                isPhoneFocused: $isPhoneFocused
            )
            .padding(.horizontal, 24)
            
            Spacer()
                .frame(height: 14)
            
            PasswordInputView(
                password: $viewModel.password,
                isPasswordFocused: $isPasswordFocused
            )
            .padding(.horizontal, 24)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.45))
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            
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
            toggleTab(title: "Log In", isSelected: viewModel.isLoginMode) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    viewModel.setLoginMode(true)
                }
            }
            
            // Sign Up Tab
            toggleTab(title: "Sign Up", isSelected: !viewModel.isLoginMode) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    viewModel.setLoginMode(false)
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
            Text(viewModel.isLoginMode ? "Welcome back" : "Create account")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .id("title_\(viewModel.isLoginMode)")
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
            
            Text(viewModel.isLoginMode ? "Enter phone + password to continue" : "Create credentials, then verify your OTP")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textMuted)
                .id("subtitle_\(viewModel.isLoginMode)")
                .transition(.opacity)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isLoginMode)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: {
            isPhoneFocused = false
            isPasswordFocused = false
            viewModel.clearError()
            Task {
                await viewModel.submit()
            }
        }) {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(backgroundDark)
                }
                
                Text(viewModel.isLoading ? "Please wait..." : "Continue")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(backgroundDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.canContinue ? accentGreen : accentGreen.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ContinueButton3DStyle(isEnabled: viewModel.canContinue))
        .disabled(!viewModel.canContinue)
        .padding(.horizontal, 24)
        // Multi-layer shadows
        .shadow(color: accentGreen.opacity(viewModel.canContinue ? 0.3 : 0), radius: 0, y: 3)
        .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
        .shadow(color: Color.black.opacity(0.2), radius: 24, y: 12)
    }
    
    // MARK: - Authenticated Content
    
    private var authenticatedContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(accentGreen)
                .shadow(color: accentGreen.opacity(0.35), radius: 22, y: 8)
            
            Text("You're signed in")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            
            Text(viewModel.authenticatedSession?.phoneNumber ?? "")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textMuted)
            
            Text("Home flow can be connected here next.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textMuted)
            
            Button("Sign Out") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.signOut()
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(backgroundDark)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(accentGreen)
            .cornerRadius(14)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 24)
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
