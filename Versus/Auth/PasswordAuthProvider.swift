//
//  PasswordAuthProvider.swift
//  Versus
//
//  Created by Codex on 03/07/26.
//

import Foundation

final class PasswordAuthProvider: AuthProvider {
    let method: AuthMethod = .password
    
    private let store: InMemoryAuthStore
    private let latencyNanos: UInt64
    
    init(
        store: InMemoryAuthStore = .shared,
        latencyNanos: UInt64 = 250_000_000
    ) {
        self.store = store
        self.latencyNanos = latencyNanos
    }
    
    func authenticate(request: AuthRequest) async throws -> AuthStep {
        try validate(request: request)
        try await simulateLatency()
        
        switch request.mode {
        case .login:
            let account = try await store.login(phone: request.e164Phone, password: request.password ?? "")
            return .authenticated(
                AuthUserSession(
                    userID: account.userID,
                    phoneNumber: account.phoneNumber,
                    method: method,
                    signedInAt: Date()
                )
            )
        case .signUp:
            let challenge = try await store.startSignup(
                countryCode: request.normalizedCountryCode,
                rawPhone: request.phoneNumber,
                e164Phone: request.e164Phone,
                password: request.password ?? ""
            )
            return .otpRequired(challenge)
        }
    }
    
    func verifyOTP(request: OTPVerificationRequest) async throws -> AuthStep {
        try await simulateLatency()
        let account = try await store.completeSignup(challengeID: request.challengeID, code: request.code)
        return .authenticated(
            AuthUserSession(
                userID: account.userID,
                phoneNumber: account.phoneNumber,
                method: method,
                signedInAt: Date()
            )
        )
    }
    
    func resendOTP(challengeID: String) async throws -> OTPChallenge {
        try await simulateLatency()
        return try await store.resendCode(challengeID: challengeID)
    }
    
    private func validate(request: AuthRequest) throws {
        guard request.normalizedPhone.count >= 8 else {
            throw AuthError.invalidPhoneNumber
        }
        
        guard let password = request.password, !password.isEmpty else {
            throw AuthError.missingPassword
        }
        
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
    }
    
    private func simulateLatency() async throws {
        guard latencyNanos > 0 else { return }
        try await Task.sleep(nanoseconds: latencyNanos)
    }
}

actor InMemoryAuthStore {
    struct Account {
        let userID: String
        let phoneNumber: String
        let password: String
    }
    
    struct PendingSignup {
        let challengeID: String
        let countryCode: String
        let rawPhone: String
        let phoneNumber: String
        let password: String
        var code: String
        var expiresAt: Date
    }
    
    static let shared = InMemoryAuthStore()
    
    private var accounts: [String: Account] = [:]
    private var pendingSignups: [String: PendingSignup] = [:]
    
    func login(phone: String, password: String) throws -> Account {
        guard let account = accounts[phone] else {
            throw AuthError.userNotFound
        }
        
        guard account.password == password else {
            throw AuthError.invalidCredentials
        }
        
        return account
    }
    
    func startSignup(
        countryCode: String,
        rawPhone: String,
        e164Phone: String,
        password: String
    ) throws -> OTPChallenge {
        guard accounts[e164Phone] == nil else {
            throw AuthError.userAlreadyExists
        }
        
        let challengeID = UUID().uuidString
        let code = generateCode()
        let expiresAt = Date().addingTimeInterval(5 * 60)
        
        pendingSignups[challengeID] = PendingSignup(
            challengeID: challengeID,
            countryCode: countryCode,
            rawPhone: rawPhone,
            phoneNumber: e164Phone,
            password: password,
            code: code,
            expiresAt: expiresAt
        )
        
        return OTPChallenge(
            id: challengeID,
            destination: "\(countryCode) \(rawPhone)",
            expiresAt: expiresAt,
            debugCode: code
        )
    }
    
    func completeSignup(challengeID: String, code: String) throws -> Account {
        guard let pending = pendingSignups[challengeID] else {
            throw AuthError.challengeNotFound
        }
        
        guard Date() <= pending.expiresAt else {
            pendingSignups.removeValue(forKey: challengeID)
            throw AuthError.otpExpired
        }
        
        guard pending.code == code else {
            throw AuthError.invalidOTP
        }
        
        guard accounts[pending.phoneNumber] == nil else {
            pendingSignups.removeValue(forKey: challengeID)
            throw AuthError.userAlreadyExists
        }
        
        let account = Account(
            userID: UUID().uuidString,
            phoneNumber: pending.phoneNumber,
            password: pending.password
        )
        
        accounts[pending.phoneNumber] = account
        pendingSignups.removeValue(forKey: challengeID)
        return account
    }
    
    func resendCode(challengeID: String) throws -> OTPChallenge {
        guard var pending = pendingSignups[challengeID] else {
            throw AuthError.challengeNotFound
        }
        
        let refreshedCode = generateCode()
        let refreshedExpiry = Date().addingTimeInterval(5 * 60)
        
        pending.code = refreshedCode
        pending.expiresAt = refreshedExpiry
        pendingSignups[challengeID] = pending
        
        return OTPChallenge(
            id: pending.challengeID,
            destination: "\(pending.countryCode) \(pending.rawPhone)",
            expiresAt: pending.expiresAt,
            debugCode: pending.code
        )
    }
    
    private func generateCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
}
