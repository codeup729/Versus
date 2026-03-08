//
//  AuthModels.swift
//  Versus
//
//  Created by Codex on 03/07/26.
//

import Foundation

enum AuthMode {
    case login
    case signUp
}

enum AuthMethod: String {
    case password
    case phoneOTP
}

struct AuthRequest {
    let mode: AuthMode
    let method: AuthMethod
    let countryCode: String
    let phoneNumber: String
    let password: String?
    
    var normalizedPhone: String {
        phoneNumber.filter(\.isNumber)
    }
    
    var normalizedCountryCode: String {
        countryCode.hasPrefix("+") ? countryCode : "+\(countryCode)"
    }
    
    var e164Phone: String {
        "\(normalizedCountryCode)\(normalizedPhone)"
    }
}

struct OTPChallenge: Equatable {
    let id: String
    let destination: String
    let expiresAt: Date
    let debugCode: String?
}

struct OTPVerificationRequest {
    let challengeID: String
    let code: String
}

struct AuthUserSession: Equatable {
    let userID: String
    let phoneNumber: String
    let method: AuthMethod
    let signedInAt: Date
}

enum AuthStep {
    case authenticated(AuthUserSession)
    case otpRequired(OTPChallenge)
}

enum AuthError: LocalizedError, Equatable {
    case invalidPhoneNumber
    case missingPassword
    case weakPassword
    case userNotFound
    case userAlreadyExists
    case invalidCredentials
    case challengeNotFound
    case otpExpired
    case invalidOTP
    case unsupportedMethod(AuthMethod)
    case otpNotSupported
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        case .missingPassword:
            return "Please enter your password."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .userNotFound:
            return "No account found for this phone number."
        case .userAlreadyExists:
            return "An account already exists for this phone number."
        case .invalidCredentials:
            return "Phone number or password is incorrect."
        case .challengeNotFound:
            return "We could not find your verification session. Please try again."
        case .otpExpired:
            return "This code expired. Request a new one."
        case .invalidOTP:
            return "The verification code is incorrect."
        case .unsupportedMethod:
            return "This sign-in method is not available."
        case .otpNotSupported:
            return "This authentication provider does not support OTP."
        }
    }
}
