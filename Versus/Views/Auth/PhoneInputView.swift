//
//  PhoneInputView.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//

import SwiftUI

struct PhoneInputView: View {
    // MARK: - Properties
    
    @Binding var phoneNumber: String
    @Binding var countryCode: String
    @FocusState.Binding var isPhoneFocused: Bool
    
    @State private var tilt: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    // MARK: - Colors
    
    private let cardBackground = Color(red: 0.06, green: 0.14, blue: 0.06)
    private let cardBorder = Color(red: 0.0, green: 0.9, blue: 0.46)
    private let inputBackground = Color(red: 0.04, green: 0.10, blue: 0.04)
    private let textMuted = Color(red: 0.5, green: 0.6, blue: 0.5)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    
    // MARK: - Body
    
    var body: some View {
        // 3D Tiltable Card
        HStack(spacing: 12) {
            // Country Code Button
            Button(action: {
                // Country picker would go here
            }) {
                HStack(spacing: 6) {
                    Text("🇺🇸")
                        .font(.system(size: 20))
                    Text(countryCode)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(inputBackground)
                .cornerRadius(12)
            }
            .buttonStyle(Press3DButtonStyle())
            
            // Phone Number Input
            TextField("", text: $phoneNumber)
                .placeholder(when: phoneNumber.isEmpty) {
                    Text("(555) 123-4567")
                        .foregroundColor(textMuted)
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .keyboardType(.phonePad)
                .focused($isPhoneFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isPhoneFocused ? accentGreen : Color.clear,
                            lineWidth: 2
                        )
                        .animation(.easeInOut(duration: 0.2), value: isPhoneFocused)
                )
                .onChange(of: phoneNumber) { oldValue, newValue in
                    phoneNumber = formatPhoneNumber(newValue)
                }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isPhoneFocused ? cardBorder.opacity(0.5) : cardBorder.opacity(0.2),
                    lineWidth: 1
                )
        )
        // 3D Tilt Effect
        .rotation3DEffect(
            .degrees(Double(tilt.width + dragOffset.width) / 20),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(Double(-tilt.height - dragOffset.height) / 20),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        // Multi-layer shadows
        .shadow(color: accentGreen.opacity(isPhoneFocused ? 0.2 : 0), radius: 0, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 16)
        .shadow(color: Color.black.opacity(0.1), radius: 50, x: 0, y: 24)
        // Drag gesture for tilt
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = CGSize(
                        width: value.translation.width.clamped(to: -30...30),
                        height: value.translation.height.clamped(to: -30...30)
                    )
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        tilt = .zero
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
    }
    
    // MARK: - Phone Formatting
    
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        let limited = String(digits.prefix(10))
        
        var formatted = ""
        for (index, digit) in limited.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            formatted += String(digit)
        }
        
        return formatted
    }
}

// MARK: - 3D Button Style

struct Press3DButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 5 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Comparable Clamping Extension

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var phone = ""
        @State var code = "+1"
        @FocusState var focused: Bool
        
        var body: some View {
            ZStack {
                Color(red: 0.02, green: 0.05, blue: 0.02)
                    .ignoresSafeArea()
                
                PhoneInputView(
                    phoneNumber: $phone,
                    countryCode: $code,
                    isPhoneFocused: $focused
                )
                .padding(.horizontal, 24)
            }
        }
    }
    
    return PreviewWrapper()
}

