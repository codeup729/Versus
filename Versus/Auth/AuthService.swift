//
//  AuthService.swift
//  Versus
//
//  Created by Codex on 03/07/26.
//

import Foundation

actor AuthService {
    private let providers: [AuthMethod: any AuthProvider]
    private var challengeMethodMap: [String: AuthMethod] = [:]
    
    init(providers: [any AuthProvider]) {
        self.providers = Dictionary(uniqueKeysWithValues: providers.map { ($0.method, $0) })
    }
    
    func authenticate(_ request: AuthRequest) async throws -> AuthStep {
        guard let provider = providers[request.method] else {
            throw AuthError.unsupportedMethod(request.method)
        }
        
        let step = try await provider.authenticate(request: request)
        registerChallengeIfNeeded(step: step, method: request.method)
        return step
    }
    
    func verifyOTP(_ request: OTPVerificationRequest) async throws -> AuthStep {
        guard let method = challengeMethodMap[request.challengeID] else {
            throw AuthError.challengeNotFound
        }
        
        guard let provider = providers[method] else {
            throw AuthError.unsupportedMethod(method)
        }
        
        let step = try await provider.verifyOTP(request: request)
        
        switch step {
        case .authenticated:
            challengeMethodMap.removeValue(forKey: request.challengeID)
        case .otpRequired(let challenge):
            challengeMethodMap.removeValue(forKey: request.challengeID)
            challengeMethodMap[challenge.id] = method
        }
        
        return step
    }
    
    func resendOTP(challengeID: String) async throws -> OTPChallenge {
        guard let method = challengeMethodMap[challengeID] else {
            throw AuthError.challengeNotFound
        }
        
        guard let provider = providers[method] else {
            throw AuthError.unsupportedMethod(method)
        }
        
        let challenge = try await provider.resendOTP(challengeID: challengeID)
        
        if challenge.id != challengeID {
            challengeMethodMap.removeValue(forKey: challengeID)
            challengeMethodMap[challenge.id] = method
        }
        
        return challenge
    }
    
    private func registerChallengeIfNeeded(step: AuthStep, method: AuthMethod) {
        if case .otpRequired(let challenge) = step {
            challengeMethodMap[challenge.id] = method
        }
    }
}
