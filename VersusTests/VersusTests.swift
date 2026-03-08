//
//  VersusTests.swift
//  VersusTests
//
//  Created by Anitej Srivastava on 31/12/25.
//

import XCTest
@testable import Versus

final class VersusTests: XCTestCase {
    func testSignupRequiresOTPAndCreatesAccountAfterVerification() async throws {
        let service = makeAuthService()
        
        let signupStep = try await service.authenticate(
            AuthRequest(
                mode: .signUp,
                method: .password,
                countryCode: "+1",
                phoneNumber: "(555) 123-4567",
                password: "secure123"
            )
        )
        
        guard case .otpRequired(let challenge) = signupStep else {
            XCTFail("Expected OTP challenge for sign up")
            return
        }
        
        let verifyStep = try await service.verifyOTP(
            OTPVerificationRequest(
                challengeID: challenge.id,
                code: challenge.debugCode ?? ""
            )
        )
        
        guard case .authenticated(let session) = verifyStep else {
            XCTFail("Expected authenticated session after OTP verification")
            return
        }
        
        XCTAssertEqual(session.phoneNumber, "+15551234567")
        XCTAssertEqual(session.method, .password)
        
        let loginStep = try await service.authenticate(
            AuthRequest(
                mode: .login,
                method: .password,
                countryCode: "+1",
                phoneNumber: "(555) 123-4567",
                password: "secure123"
            )
        )
        
        guard case .authenticated = loginStep else {
            XCTFail("Expected login to authenticate existing account")
            return
        }
    }
    
    func testLoginForUnknownUserFails() async throws {
        let service = makeAuthService()
        
        do {
            _ = try await service.authenticate(
                AuthRequest(
                    mode: .login,
                    method: .password,
                    countryCode: "+1",
                    phoneNumber: "(555) 765-4321",
                    password: "secret12"
                )
            )
            XCTFail("Expected userNotFound error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .userNotFound)
        }
    }
    
    func testInvalidOTPIsRejected() async throws {
        let service = makeAuthService()
        
        let signupStep = try await service.authenticate(
            AuthRequest(
                mode: .signUp,
                method: .password,
                countryCode: "+1",
                phoneNumber: "(555) 333-9999",
                password: "secret12"
            )
        )
        
        guard case .otpRequired(let challenge) = signupStep else {
            XCTFail("Expected OTP challenge for sign up")
            return
        }
        
        do {
            _ = try await service.verifyOTP(
                OTPVerificationRequest(challengeID: challenge.id, code: "000000")
            )
            XCTFail("Expected invalidOTP error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidOTP)
        }
    }
    
    func testDuplicateSignupFailsAfterAccountCreation() async throws {
        let service = makeAuthService()
        
        let initialStep = try await service.authenticate(
            AuthRequest(
                mode: .signUp,
                method: .password,
                countryCode: "+1",
                phoneNumber: "(555) 111-2222",
                password: "secret12"
            )
        )
        
        guard case .otpRequired(let challenge) = initialStep else {
            XCTFail("Expected OTP challenge for sign up")
            return
        }
        
        _ = try await service.verifyOTP(
            OTPVerificationRequest(
                challengeID: challenge.id,
                code: challenge.debugCode ?? ""
            )
        )
        
        do {
            _ = try await service.authenticate(
                AuthRequest(
                    mode: .signUp,
                    method: .password,
                    countryCode: "+1",
                    phoneNumber: "(555) 111-2222",
                    password: "another12"
                )
            )
            XCTFail("Expected userAlreadyExists error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .userAlreadyExists)
        }
    }
    
    private func makeAuthService() -> AuthService {
        let store = InMemoryAuthStore()
        let provider = PasswordAuthProvider(store: store, latencyNanos: 0)
        return AuthService(providers: [provider])
    }
}
