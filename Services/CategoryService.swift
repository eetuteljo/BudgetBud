import Foundation
import FirebaseFirestore
import Combine

class CategoryService {
    static let shared = CategoryService()
    
    private let firebaseService = FirebaseService.shared
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - CRUD Operations
    
    func createCategory(_ category: Category) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let categoryRef = firebaseService.db.collection("households").document(householdId).collection("categories").document(category.id)
        try await categoryRef.setData(category.toDictionary())
    }
    
    func fetchCategory(id: String) async throws -> Category {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let document = try await firebaseService.db.collection("households").document(householdId).collection("categories").document(id).getDocument()
        
        guard let category = Category.fromFirestore(document: document) else {
            throw NSError(domain: "CategoryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Category not found"])
        }
        
        return category
    }
    
    func updateCategory(_ category: Category) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        var updatedCategory = category
        updatedCategory.updatedAt = Date()
        
        let categoryRef = firebaseService.db.collection("households").document(householdId).collection("categories").document(category.id)
        try await categoryRef.updateData(updatedCategory.toDictionary())
    }
    
    func archiveCategory(_ category: Category) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        var archivedCategory = category
        archivedCategory.isArchived = true
        archivedCategory.updatedAt = Date()
        
        let categoryRef = firebaseService.db.collection("households").document(householdId).collection("categories").document(category.id)
        try await categoryRef.updateData(archivedCategory.toDictionary())
    }
    
    // We don't provide a delete method to preserve expense history
    // Instead, we archive categories
    
    // MARK: - Query Operations
    
    func fetchCategories(includeArchived: Bool = false) async throws -> [Category] {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        var query = firebaseService.db.collection("households").document(householdId).collection("categories")
        
        if !includeArchived {
            query = query.whereField("isArchived", isEqualTo: false)
        }
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Category.fromFirestore(document: $0) }
    }
    
    // MARK: - Real-time Listeners
    
    func addCategoriesListener(includeArchived: Bool = false, completion: @escaping ([Category]) -> Void) -> ListenerRegistration {
        do {
            try firebaseService.validateCurrentUser()
            try firebaseService.validateHousehold()
            
            guard let householdId = firebaseService.currentHouseholdId else {
                throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
            }
            
            var query = firebaseService.db.collection("households").document(householdId).collection("categories")
            
            if !includeArchived {
                query = query.whereField("isArchived", isEqualTo: false)
            }
            
            let listener = query.addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error fetching categories: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let categories = snapshot.documents.compactMap { Category.fromFirestore(document: $0) }
                completion(categories)
            }
            
            listeners.append(listener)
            return listener
            
        } catch {
            print("Error setting up categories listener: \(error.localizedDescription)")
            // Return a dummy listener that can be safely removed
            let listener = firebaseService.db.collection("dummy").addSnapshotListener { _, _ in }
            return listener
        }
    }
    
    func removeListener(_ listener: ListenerRegistration) {
        listener.remove()
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Default Categories
    
    func setupDefaultCategories() async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "CategoryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        // Check if categories already exist
        let snapshot = try await firebaseService.db.collection("households").document(householdId).collection("categories").getDocuments()
        
        if snapshot.documents.isEmpty {
            // Create default categories
            for category in Category.defaultCategories {
                try await createCategory(category)
            }
        }
    }
    
    // MARK: - Category Management
    
    func getCategoryMap() async throws -> [String: Category] {
        let categories = try await fetchCategories(includeArchived: true)
        var categoryMap: [String: Category] = [:]
        
        for category in categories {
            categoryMap[category.id] = category
        }
        
        return categoryMap
    }
}
