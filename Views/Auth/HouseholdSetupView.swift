import SwiftUI

struct HouseholdSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isCreatingHousehold = true
    @State private var householdName = ""
    @State private var inviteCode = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor", default: .systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 10) {
                        Image(systemName: "house.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)
                        
                        Text("Household Setup")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isCreatingHousehold ? "Create a new household" : "Join an existing household")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // Segmented control
                    Picker("Household Option", selection: $isCreatingHousehold) {
                        Text("Create").tag(true)
                        Text("Join").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 30)
                    
                    // Form fields
                    VStack(spacing: 20) {
                        if isCreatingHousehold {
                            TextField("Household Name", text: $householdName)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.words)
                        } else {
                            TextField("Invite Code", text: $inviteCode)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Action button
                    Button(action: {
                        Task {
                            if isCreatingHousehold {
                                await authViewModel.createHousehold(name: householdName)
                            } else {
                                await authViewModel.joinHousehold(inviteCode: inviteCode)
                            }
                        }
                    }) {
                        Text(isCreatingHousehold ? "Create Household" : "Join Household")
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
                    
                    // Sign out button
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 20)
                    
                    // Error message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Help text
                    VStack(alignment: .leading, spacing: 10) {
                        if isCreatingHousehold {
                            Text("Creating a household will allow you to:")
                                .font(.footnote)
                                .fontWeight(.bold)
                            
                            Text("• Track expenses for your household")
                                .font(.footnote)
                            
                            Text("• Set budgets for different categories")
                                .font(.footnote)
                            
                            Text("• Invite another person to join")
                                .font(.footnote)
                        } else {
                            Text("To join a household:")
                                .font(.footnote)
                                .fontWeight(.bold)
                            
                            Text("• Ask the household creator for the invite code")
                                .font(.footnote)
                            
                            Text("• Enter the code exactly as provided")
                                .font(.footnote)
                            
                            Text("• You'll have access to shared expenses and budgets")
                                .font(.footnote)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                
                // Loading overlay
                if authViewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationBarHidden(true)
            .onChange(of: isCreatingHousehold) { _ in
                // Clear fields when switching modes
                householdName = ""
                inviteCode = ""
                authViewModel.errorMessage = nil
            }
        }
    }
    
    private var isFormValid: Bool {
        if isCreatingHousehold {
            return !householdName.isEmpty
        } else {
            return !inviteCode.isEmpty
        }
    }
}

struct HouseholdSetupView_Previews: PreviewProvider {
    static var previews: some View {
        HouseholdSetupView()
            .environmentObject(AuthViewModel())
    }
}
