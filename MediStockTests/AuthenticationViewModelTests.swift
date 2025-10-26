//
//  MediStockTests.swift
//  MediStockTests
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import XCTest
@testable import MediStock

final class AuthenticationViewModelTests: XCTestCase {
    var session: SessionStore!
    var authVM: AuthenticationViewModel!

    override func setUp() {
        super.setUp()
        session = SessionStore()
        authVM = AuthenticationViewModel(sessionStore: session)
    }

    func testEmailValidation() {
        authVM.email = "test@example.com"
        XCTAssertTrue(authVM.isEmailValid)

        authVM.email = "invalidEmail"
        XCTAssertFalse(authVM.isEmailValid)
    }

    func testPasswordValidation() {
        authVM.password = "StrongPassword123"
        XCTAssertTrue(authVM.isPasswordValid)

        authVM.password = "123"
        XCTAssertFalse(authVM.isPasswordValid)
    }

    func testCanSubmit() {
        authVM.email = "test@example.com"
        authVM.password = "StrongPassword123"
        XCTAssertTrue(authVM.canSubmit)

        authVM.password = "1"
        XCTAssertFalse(authVM.canSubmit)
    }
}
