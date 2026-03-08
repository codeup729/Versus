//
//  PasswordInputView.swift
//  Versus
//
//  Created by Codex on 03/07/26.
//

import SwiftUI

struct PasswordInputView: View {
    @Binding var password: String
    @FocusState.Binding var isPasswordFocused: Bool
    
    @State private var isSecure = true
    
    private let cardBackground = Color(red: 0.06, green: 0.14, blue: 0.06)
    private let cardBorder = Color(red: 0.0, green: 0.9, blue: 0.46)
    private let inputBackground = Color(red: 0.04, green: 0.10, blue: 0.04)
    private let textMuted = Color(red: 0.5, green: 0.6, blue: 0.5)
    private let accentGreen = Color(red: 0.0, green: 0.9, blue: 0.46)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textMuted)
                .padding(.leading, 14)
            
            Group {
                if isSecure {
                    SecureField("", text: $password)
                        .placeholder(when: password.isEmpty) {
                            Text("Password")
                                .foregroundColor(textMuted)
                        }
                } else {
                    TextField("", text: $password)
                        .placeholder(when: password.isEmpty) {
                            Text("Password")
                                .foregroundColor(textMuted)
                        }
                }
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isPasswordFocused)
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(inputBackground)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .padding(.vertical, 8)
        .background(cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isPasswordFocused ? cardBorder.opacity(0.5) : cardBorder.opacity(0.2),
                    lineWidth: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isPasswordFocused ? accentGreen : Color.clear,
                    lineWidth: 2
                )
                .padding(1)
                .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
        )
        .shadow(color: accentGreen.opacity(isPasswordFocused ? 0.2 : 0), radius: 0, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 16)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var password = ""
        @FocusState var focused: Bool
        
        var body: some View {
            ZStack {
                Color(red: 0.02, green: 0.05, blue: 0.02)
                    .ignoresSafeArea()
                
                PasswordInputView(password: $password, isPasswordFocused: $focused)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    return PreviewWrapper()
}
