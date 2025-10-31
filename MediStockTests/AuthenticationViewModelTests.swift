//
//  AuthenticationViewModelTests.swift
//  MediStockTests
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import XCTest
@testable import MediStock

final class AuthenticationViewModelTests: XCTestCase {
    var session: SessionStore!
    var authVM: AuthenticationViewModel!
    var mockFirebaseService: MockFirebaseService!

    override func setUp() {
        super.setUp()
        mockFirebaseService = MockFirebaseService()
        session = SessionStore(firebaseService: mockFirebaseService)
        authVM = AuthenticationViewModel(sessionStore: session)
    }

    override func tearDown() {
        authVM = nil
        session = nil
        mockFirebaseService = nil
        super.tearDown()
    }

    func testEmailValidation() {
        authVM.email = "test@example.com"
        XCTAssertTrue(authVM.isEmailValid)

        authVM.email = "invalidEmail"
        XCTAssertFalse(authVM.isEmailValid)
        
        authVM.email = "test@"
        XCTAssertFalse(authVM.isEmailValid)
        
        authVM.email = "@example.com"
        XCTAssertFalse(authVM.isEmailValid)
    }

    func testPasswordValidation() {
        authVM.password = "StrongPassword123"
        XCTAssertTrue(authVM.isPasswordValid)

        authVM.password = "123"
        XCTAssertFalse(authVM.isPasswordValid)
        
        authVM.password = "weak"
        XCTAssertFalse(authVM.isPasswordValid)
        
        authVM.password = "NoNumbers"
        XCTAssertFalse(authVM.isPasswordValid)
        
        authVM.password = "nonumbersorspecial"
        XCTAssertFalse(authVM.isPasswordValid)
    }

    func testCanSubmit() {
        authVM.email = "test@example.com"
        authVM.password = "StrongPassword123"
        XCTAssertTrue(authVM.canSubmit)

        authVM.password = "1"
        XCTAssertFalse(authVM.canSubmit)
        
        authVM.password = ""
        XCTAssertFalse(authVM.canSubmit)
        
        authVM.password = "StrongPassword123"
        authVM.email = "invalid"
        XCTAssertFalse(authVM.canSubmit)
    }
    
    func testErrorMessageUpdates() {
        authVM.email = "invalid"
        XCTAssertEqual(authVM.errorMessage, "Invalid email format")
        
        authVM.email = "test@example.com"
        authVM.password = "weak"
        XCTAssertEqual(authVM.errorMessage, "Password must be at least 8 characters, with uppercase, lowercase, and a number")
        
        authVM.password = "StrongPassword123"
        XCTAssertNil(authVM.errorMessage)
    }
}
