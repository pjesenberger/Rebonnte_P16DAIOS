import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @EnvironmentObject var session: SessionStore
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    init(sessionStore: SessionStore) {
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("MediStock")
                .font(.title)
                .bold()
            
            Text("Log In")
                .font(.title2)
                .padding(.bottom, 32)
            
            TextField("Email", text: $viewModel.email)
                .customTextField()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
            
            SecureField("Password", text: $viewModel.password)
                .customTextField()
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit { viewModel.submit() }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                viewModel.submit()
            }) {
                Text(viewModel.isLoading ? "Processing..." : "Login")
                    .foregroundStyle(Color.white)
                    .padding(12)
                    .padding(.horizontal)
                    .background(Color.green)
                    .cornerRadius(100)
            }
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1.0 : 0.5)
            
            Spacer()
        }
        .padding()
        .alert("Create Account", isPresented: $viewModel.showSignupConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Create Account") {
                viewModel.signUp()
            }
        } message: {
            Text("No account found with this email. Would you like to create a new account?")
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(sessionStore: SessionStore()).environmentObject(SessionStore())
    }
}
