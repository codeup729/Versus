//
//  AuthProvider.swift
//  Versus
//
//  Created by Codex on 03/07/26.
//

import Foundation

protocol AuthProvider {
    var method: AuthMethod { get }
    
    func authenticate(request: AuthRequest) async throws -> AuthStep
    func verifyOTP(request: OTPVerificationRequest) async throws -> AuthStep
    func resendOTP(challengeID: String) async throws -> OTPChallenge
}

extension AuthProvider {
    func verifyOTP(request: OTPVerificationRequest) async throws -> AuthStep {
        throw AuthError.otpNotSupported
    }
    
    func resendOTP(challengeID: String) async throws -> OTPChallenge {
        throw AuthError.otpNotSupported
    }
}
