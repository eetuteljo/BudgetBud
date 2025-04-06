import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignIn = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor", default: .systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 10) {
                        Image(systemName: "dollarsign.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)
                        
                        Text("BudgetBuddy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isSignIn ? "Sign in to your account" : "Create a new account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // Form fields
                    VStack(spacing: 20) {
                        if !isSignIn {
                            TextField("Name", text: $name)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    // Sign in/up button
                    Button(action: {
                        Task {
                            if isSignIn {
                                await authViewModel.signIn(email: email, password: password)
                            } else {
                                await authViewModel.signUp(name: name, email: email, password: password)
                            }
                        }
                    }) {
                        Text(isSignIn ? "Sign In" : "Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    // Toggle between sign in and sign up
                    Button(action: {
                        withAnimation {
                            isSignIn.toggle()
                            // Clear fields when switching modes
                            if isSignIn {
                                name = ""
                            }
                            email = ""
                            password = ""
                        }
                    }) {
                        Text(isSignIn ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    
                    // Error message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                
                // Loading overlay
                if authViewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        if isSignIn {
            return !email.isEmpty && !password.isEmpty && password.count >= 6
        } else {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password.count >= 6
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
            )
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Please wait...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
