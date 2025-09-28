import Foundation
import Firebase

class SessionStore: ObservableObject {
    @Published var session: User?
    var handle: AuthStateDidChangeListenerHandle?

    func listen() {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.session = User(uid: user.uid, email: user.email)
            } else {
                self.session = nil
            }
        }
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Error creating user: \(error.localizedDescription) \(error)")
            } else {
                self.session = User(uid: result?.user.uid ?? "", email: result?.user.email ?? "")
            }
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
            } else {
                self.session = User(uid: result?.user.uid ?? "", email: result?.user.email ?? "")
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.session = nil
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func unbind() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

struct User {
    var uid: String
    var email: String?
}
