import Foundation
import Firebase

class SessionStore: ObservableObject {
    @Published var session: User?
    var handle: AuthStateDidChangeListenerHandle?
    
    private let firebaseService: FirebaseServiceProtocol

    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }

    func listen() {
        handle = firebaseService.auth.addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.session = User(uid: user.uid, email: user.email)
            } else {
                self.session = nil
            }
        }
    }

    func signOut() {
        do {
            try firebaseService.auth.signOut()
            self.session = nil
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func unbind() {
        if let handle = handle {
            firebaseService.auth.removeStateDidChangeListener(handle)
        }
    }
}
