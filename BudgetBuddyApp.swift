import SwiftUI
import Firebase

@main
struct BudgetBuddyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                if authViewModel.hasHousehold {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    HouseholdSetupView()
                        .environmentObject(authViewModel)
                }
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
}

// MARK: - View Models

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasHousehold = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    
    init() {
        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            Task {
                await fetchUserData(userId: currentUser.uid)
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let user = try await firebaseService.signIn(email: email, password: password)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                self.hasHousehold = user.householdId != nil
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(name: String, email: String, password: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let user = try await firebaseService.signUp(name: name, email: email, password: password)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                self.hasHousehold = false
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try firebaseService.signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                self.hasHousehold = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func createHousehold(name: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            _ = try await firebaseService.createHousehold(name: name)
            
            if let userId = self.currentUser?.id {
                await fetchUserData(userId: userId)
            }
            
            DispatchQueue.main.async {
                self.hasHousehold = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func joinHousehold(inviteCode: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            _ = try await firebaseService.joinHousehold(inviteCode: inviteCode)
            
            if let userId = self.currentUser?.id {
                await fetchUserData(userId: userId)
            }
            
            DispatchQueue.main.async {
                self.hasHousehold = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func fetchUserData(userId: String) async {
        do {
            let user = try await firebaseService.fetchUser(userId: userId)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                self.hasHousehold = user.householdId != nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
