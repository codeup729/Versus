//
//  AuthViewModel.swift
//  Versus
//
//  Created by Codex on 03/07/26.
//

import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoginMode = true
    @Published var phoneNumber = ""
    @Published var countryCode = "+1"
    @Published var password = ""
    @Published private(set) var activeChallenge: OTPChallenge?
    @Published private(set) var authenticatedSession: AuthUserSession?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    private let defaultMethod: AuthMethod
    
    init(
        authService: AuthService,
        defaultMethod: AuthMethod = .password
    ) {
        self.authService = authService
        self.defaultMethod = defaultMethod
    }
    
    var isAuthenticated: Bool {
        authenticatedSession != nil
    }
    
    var canContinue: Bool {
        !phoneNumber.filter(\.isNumber).isEmpty && password.count >= 6 && !isLoading
    }
    
    func setLoginMode(_ value: Bool) {
        isLoginMode = value
        errorMessage = nil
    }
    
    func submit() async {
        isLoading = true
        errorMessage = nil
        
        let request = AuthRequest(
            mode: isLoginMode ? .login : .signUp,
            method: defaultMethod,
            countryCode: countryCode,
            phoneNumber: phoneNumber,
            password: password
        )
        
        do {
            let step = try await authService.authenticate(request)
            apply(step: step)
        } catch {
            errorMessage = mapError(error)
        }
        
        isLoading = false
    }
    
    func verifyOTP(code: String) async throws {
        errorMessage = nil
        let normalizedCode = code.filter(\.isNumber)
        
        guard let challengeID = activeChallenge?.id else {
            throw AuthError.challengeNotFound
        }
        
        let step = try await authService.verifyOTP(
            OTPVerificationRequest(
                challengeID: challengeID,
                code: normalizedCode
            )
        )
        apply(step: step)
    }
    
    func resendOTP() async throws -> OTPChallenge {
        guard let challengeID = activeChallenge?.id else {
            throw AuthError.challengeNotFound
        }
        
        let refreshed = try await authService.resendOTP(challengeID: challengeID)
        activeChallenge = refreshed
        return refreshed
    }
    
    func dismissOTP() {
        activeChallenge = nil
    }
    
    func signOut() {
        authenticatedSession = nil
        activeChallenge = nil
        password = ""
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    private func apply(step: AuthStep) {
        switch step {
        case .authenticated(let session):
            authenticatedSession = session
            activeChallenge = nil
        case .otpRequired(let challenge):
            activeChallenge = challenge
        }
    }
    
    private func mapError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.errorDescription ?? "Authentication failed."
        }
        
        if let localized = error as? LocalizedError {
            return localized.errorDescription ?? "Authentication failed."
        }
        
        return "Authentication failed."
    }
}
