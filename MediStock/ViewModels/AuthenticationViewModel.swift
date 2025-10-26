//
//  AuthenticationViewModel.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 10/10/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI

class AuthenticationViewModel: ObservableObject {
    @Published var email = "" {
        didSet { validate(.email) }
    }
    @Published var password = "" {
        didSet { validate(.password) }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isEmailValid = true
    @Published var isPasswordValid = true

    var sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    enum Field {
        case email, password
    }

    func validate(_ field: Field) {
        switch field {
        case .email:
            isEmailValid = isValidEmail(email)
        case .password:
            isPasswordValid = isValidPassword(password)
        }
        updateErrorMessage()
    }

    func updateErrorMessage() {
        if !isEmailValid {
            errorMessage = "Invalid email format"
        } else if !isPasswordValid {
            errorMessage = "Password must be at least 8 characters, with uppercase, lowercase, and a number"
        } else {
            errorMessage = nil
        }
    }

    var canSubmit: Bool {
        isEmailValid && isPasswordValid && !password.isEmpty && !isLoading
    }

    func signIn() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        Auth.auth().signIn(withEmail: emailTrimmed, password: passwordTrimmed) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error as NSError? {
                    self?.handleAuthError(error)
                } else if let user = result?.user {
                    self?.sessionStore.session = User(uid: user.uid, email: user.email)
                }
            }
        }
    }

    func signUp() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        Auth.auth().createUser(withEmail: emailTrimmed, password: passwordTrimmed) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error as NSError? {
                    self?.handleAuthError(error)
                } else if let user = result?.user {
                    self?.sessionStore.session = User(uid: user.uid, email: user.email)
                }
            }
        }
    }

    func handleAuthError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            alertMessage = "Invalid email address"
        case AuthErrorCode.wrongPassword.rawValue:
            alertMessage = "Incorrect password"
        case AuthErrorCode.userNotFound.rawValue:
            alertMessage = "No account found with this email"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            alertMessage = "An account already exists with this email"
        case AuthErrorCode.weakPassword.rawValue:
            alertMessage = "Password is too weak"
        case AuthErrorCode.networkError.rawValue:
            alertMessage = "Network error. Please check your connection"
        case AuthErrorCode.tooManyRequests.rawValue:
            alertMessage = "Too many requests. Please try again later"
        default:
            alertMessage = "Authentication failed: \(error.localizedDescription)"
        }
        showAlert = true
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d@$!%*?&]{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegEx).evaluate(with: password)
    }
}
