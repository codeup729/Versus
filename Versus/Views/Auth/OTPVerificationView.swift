//
//  OTPVerificationView.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//

import SwiftUI

struct OTPVerificationView: View {
    // MARK: - Properties
    
    let phoneNumber: String
    let countryCode: String
    var onBack: () -> Void
    var onVerified: () -> Void
    
    @State private var otpCode: [String] = Array(repeating: "", count: 6)
    @State private var focusedIndex: Int = 0
    @State private var isShaking: Bool = false
    @State private var isVerified: Bool = false
    @State private var resendTimer: Int = 30
    @State private var canResend: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // Hidden text field for keyboard
    @State private var hiddenInput: String = ""
    
    // MARK: - Colors
    
    private let backgroundDark = Color(red: 0.02, green: 0.05, blue: 0.02)
    private let backgroundLight = Color(red: 0.04, green: 0.12, blue: 0.04)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    private let cellBackground = Color(red: 0.06, green: 0.14, blue: 0.06)
    private let textMuted = Color(red: 0.4, green: 0.5, blue: 0.4)
    
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
            .onTapGesture {
                isInputFocused = true
            }
            
            VStack(spacing: 0) {
                // Header with back button
                headerSection
                
                Spacer()
                    .frame(height: 60)
                
                // Title
                titleSection
                
                Spacer()
                    .frame(height: 40)
                
                // OTP Cells
                otpCellsSection
                
                Spacer()
                    .frame(height: 32)
                
                // Resend Section
                resendSection
                
                Spacer()
                
                // Verify Button
                verifyButton
                
                Spacer()
                    .frame(height: 50)
            }
            
            // Hidden input field for keyboard
            TextField("", text: $hiddenInput)
                .keyboardType(.numberPad)
                .focused($isInputFocused)
                .opacity(0)
                .onChange(of: hiddenInput) { oldValue, newValue in
                    handleInput(newValue)
                }
        }
        .onAppear {
            isInputFocused = true
            startResendTimer()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(accentGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(cellBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(Press3DButtonStyle())
            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Enter the code")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("We sent a code to \(countryCode) \(phoneNumber)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - OTP Cells Section
    
    private var otpCellsSection: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                OTPCellView(
                    digit: otpCode[index],
                    isActive: focusedIndex == index && !isVerified,
                    isVerified: isVerified,
                    index: index
                )
                .onTapGesture {
                    isInputFocused = true
                }
            }
        }
        .padding(.horizontal, 24)
        .modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
    }
    
    // MARK: - Resend Section
    
    private var resendSection: some View {
        Group {
            if canResend {
                Button(action: resendCode) {
                    Text("Resend code")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accentGreen)
                }
            } else {
                Text("Resend code in \(resendTimer)s")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textMuted)
            }
        }
    }
    
    // MARK: - Verify Button
    
    private var verifyButton: some View {
        let isFilled = otpCode.allSatisfy { !$0.isEmpty }
        
        return Button(action: verifyCode) {
            HStack(spacing: 10) {
                if isVerified {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(isVerified ? "Verified!" : "Verify")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(backgroundDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFilled || isVerified ? accentGreen : accentGreen.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ContinueButton3DStyle(isEnabled: isFilled))
        .disabled(!isFilled && !isVerified)
        .padding(.horizontal, 24)
        .shadow(color: accentGreen.opacity(isFilled ? 0.3 : 0), radius: 0, y: 3)
        .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
        .shadow(color: Color.black.opacity(0.2), radius: 24, y: 12)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVerified)
    }
    
    // MARK: - Methods
    
    private func handleInput(_ newValue: String) {
        let digits = newValue.filter { $0.isNumber }
        let limited = String(digits.prefix(6))
        
        // Update OTP cells
        for i in 0..<6 {
            if i < limited.count {
                let index = limited.index(limited.startIndex, offsetBy: i)
                otpCode[i] = String(limited[index])
            } else {
                otpCode[i] = ""
            }
        }
        
        // Update focused index
        focusedIndex = min(limited.count, 5)
        
        // Auto verify when all filled
        if limited.count == 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                verifyCode()
            }
        }
    }
    
    private func verifyCode() {
        // Simulate verification (always succeed for demo)
        let code = otpCode.joined()
        
        if code.count == 6 {
            // Success animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVerified = true
            }
            
            // Navigate after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onVerified()
            }
        } else {
            // Shake on error
            withAnimation(.default) {
                isShaking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isShaking = false
            }
        }
    }
    
    private func resendCode() {
        canResend = false
        resendTimer = 30
        startResendTimer()
    }
    
    private func startResendTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if resendTimer > 0 {
                resendTimer -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - OTP Cell View

struct OTPCellView: View {
    let digit: String
    let isActive: Bool
    let isVerified: Bool
    let index: Int
    
    @State private var flipRotation: Double = 0
    
    private let cellBackground = Color(red: 0.06, green: 0.14, blue: 0.06)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(cellBackground)
                .frame(width: 48, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isVerified ? accentGreen :
                                (isActive ? accentGreen.opacity(0.8) : accentGreen.opacity(0.2)),
                            lineWidth: isActive ? 2 : 1
                        )
                )
            
            Text(digit)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        // 3D Effects
        .rotation3DEffect(
            .degrees(isActive ? 5 : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .rotation3DEffect(
            .degrees(flipRotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .scaleEffect(isActive ? 1.08 : 1.0)
        // Shadows
        .shadow(color: accentGreen.opacity(isActive ? 0.3 : 0), radius: 8, y: 4)
        .shadow(color: Color.black.opacity(0.4), radius: isActive ? 12 : 8, y: isActive ? 8 : 4)
        .shadow(color: Color.black.opacity(0.2), radius: 20, y: 12)
        // Animations
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: digit)
        .onChange(of: isVerified) { oldValue, newValue in
            if newValue {
                // Staggered flip animation on verify
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.08)) {
                    flipRotation = 360
                }
            }
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 4) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    OTPVerificationView(
        phoneNumber: "(555) 123-4567",
        countryCode: "+1",
        onBack: {},
        onVerified: {}
    )
}

