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
            
            TextField("Email", text: $viewModel.email)
                .customTextField()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
            
            SecureField("Password", text: $viewModel.password)
                .customTextField()
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.signIn()
                }) {
                    Text(viewModel.isLoading ? "Processing..." : "Sign In")
                        .foregroundStyle(Color.white)
                        .padding(12)
                        .padding(.horizontal)
                        .background(Color.green)
                        .cornerRadius(100)
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1.0 : 0.5)

                Button(action: {
                    viewModel.signUp()
                }) {
                    Text(viewModel.isLoading ? "Processing..." : "Sign Up")
                        .foregroundStyle(Color.white)
                        .padding(12)
                        .padding(.horizontal)
                        .background(Color.green)
                        .cornerRadius(100)
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1.0 : 0.5)
            }
            
            Spacer()
        }
        .padding()
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
