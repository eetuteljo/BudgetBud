import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService {
    static let shared = FirebaseService()
    
    let db = Firestore.firestore()
    var currentUser: User?
    var currentHouseholdId: String?
    
    private init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = try await fetchUser(userId: authResult.user.uid)
        self.currentUser = user
        
        if let householdId = user.householdId {
            self.currentHouseholdId = householdId
        }
        
        return user
    }
    
    func signUp(name: String, email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let user = User(
            id: authResult.user.uid,
            name: name,
            email: email
        )
        
        try await saveUser(user)
        self.currentUser = user
        
        return user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
        self.currentHouseholdId = nil
    }
    
    // MARK: - User Operations
    
    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = User.fromFirestore(document: document) else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return user
    }
    
    func saveUser(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(user.toDictionary())
    }
    
    func updateUser(_ user: User) async throws {
        var updatedUser = user
        updatedUser.updatedAt = Date()
        
        try await db.collection("users").document(user.id).updateData(updatedUser.toDictionary())
        
        if user.id == currentUser?.id {
            currentUser = updatedUser
        }
    }
    
    // MARK: - Household Operations
    
    func createHousehold(name: String) async throws -> Household {
        guard let currentUser = self.currentUser else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let household = Household(name: name, createdBy: currentUser.id)
        
        let householdRef = db.collection("households").document(household.id)
        try await householdRef.setData(household.toDictionary())
        
        // Add current user as a member
        try await householdRef.collection("members").document(currentUser.id).setData([
            "userId": currentUser.id,
            "role": "owner",
            "joinedAt": Timestamp(date: Date())
        ])
        
        // Update user with household ID
        var updatedUser = currentUser
        updatedUser.householdId = household.id
        try await updateUser(updatedUser)
        
        self.currentHouseholdId = household.id
        
        // Create default categories
        for category in Category.defaultCategories {
            try await householdRef.collection("categories").document(category.id).setData(category.toDictionary())
        }
        
        return household
    }
    
    func fetchHousehold(householdId: String) async throws -> Household {
        let document = try await db.collection("households").document(householdId).getDocument()
        
        guard let household = Household.fromFirestore(document: document) else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Household not found"])
        }
        
        return household
    }
    
    func joinHousehold(inviteCode: String) async throws -> Household {
        guard let currentUser = self.currentUser else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // In a real app, we would validate the invite code here
        // For simplicity, we'll assume the invite code is the household ID
        let householdId = inviteCode
        
        let household = try await fetchHousehold(householdId: householdId)
        
        // Add user as a member
        try await db.collection("households").document(householdId).collection("members").document(currentUser.id).setData([
            "userId": currentUser.id,
            "role": "member",
            "joinedAt": Timestamp(date: Date())
        ])
        
        // Update user with household ID
        var updatedUser = currentUser
        updatedUser.householdId = householdId
        try await updateUser(updatedUser)
        
        self.currentHouseholdId = householdId
        
        return household
    }
    
    func leaveHousehold() async throws {
        guard let currentUser = self.currentUser, let householdId = currentUser.householdId else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not in a household"])
        }
        
        // Remove user from household members
        try await db.collection("households").document(householdId).collection("members").document(currentUser.id).delete()
        
        // Update user to remove household ID
        var updatedUser = currentUser
        updatedUser.householdId = nil
        try await updateUser(updatedUser)
        
        self.currentHouseholdId = nil
    }
    
    // MARK: - Helper Methods
    
    func validateCurrentUser() throws {
        guard currentUser != nil else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
    }
    
    func validateHousehold() throws {
        guard currentHouseholdId != nil else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not in a household"])
        }
    }
}
