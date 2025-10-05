import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .customTextField()
            
            SecureField("Password", text: $password)
                .customTextField()
            Button(action: {
                session.signIn(email: email, password: password)
            }) {
                Text("Login")
            }
            Button(action: {
                session.signUp(email: email, password: password)
            }) {
                Text("Sign Up")
            }
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(SessionStore())
    }
}
