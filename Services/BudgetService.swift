import Foundation
import FirebaseFirestore
import Combine

class BudgetService {
    static let shared = BudgetService()
    
    private let firebaseService = FirebaseService.shared
    private let expenseService = ExpenseService.shared
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - CRUD Operations
    
    func createBudget(_ budget: Budget) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        // Create budget document
        let budgetRef = firebaseService.db.collection("households").document(householdId).collection("budgets").document(budget.id)
        try await budgetRef.setData(budget.toDictionary())
        
        // Create category allocations
        for allocation in budget.categoryAllocations {
            try await budgetRef.collection("categoryAllocations").document(allocation.id).setData(allocation.toDictionary())
        }
    }
    
    func fetchBudget(id: String) async throws -> Budget {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        // Fetch budget document
        let budgetRef = firebaseService.db.collection("households").document(householdId).collection("budgets").document(id)
        let budgetDoc = try await budgetRef.getDocument()
        
        // Fetch category allocations
        let allocationsSnapshot = try await budgetRef.collection("categoryAllocations").getDocuments()
        let allocations = allocationsSnapshot.documents.compactMap { CategoryBudget.fromFirestore(document: $0) }
        
        guard let budget = Budget.fromFirestore(document: budgetDoc, withAllocations: allocations) else {
            throw NSError(domain: "BudgetService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Budget not found"])
        }
        
        return budget
    }
    
    func updateBudget(_ budget: Budget) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        var updatedBudget = budget
        updatedBudget.updatedAt = Date()
        
        // Update budget document
        let budgetRef = firebaseService.db.collection("households").document(householdId).collection("budgets").document(budget.id)
        try await budgetRef.updateData(updatedBudget.toDictionary())
        
        // Get existing allocations
        let allocationsSnapshot = try await budgetRef.collection("categoryAllocations").getDocuments()
        let existingAllocations = allocationsSnapshot.documents.compactMap { CategoryBudget.fromFirestore(document: $0) }
        
        // Create a map of existing allocations by ID
        var existingAllocationsMap: [String: CategoryBudget] = [:]
        for allocation in existingAllocations {
            existingAllocationsMap[allocation.id] = allocation
        }
        
        // Update or create allocations
        for allocation in updatedBudget.categoryAllocations {
            let allocationRef = budgetRef.collection("categoryAllocations").document(allocation.id)
            try await allocationRef.setData(allocation.toDictionary(), merge: true)
            existingAllocationsMap.removeValue(forKey: allocation.id)
        }
        
        // Delete allocations that no longer exist
        for (id, _) in existingAllocationsMap {
            try await budgetRef.collection("categoryAllocations").document(id).delete()
        }
    }
    
    func deleteBudget(id: String) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let budgetRef = firebaseService.db.collection("households").document(householdId).collection("budgets").document(id)
        
        // Delete all category allocations
        let allocationsSnapshot = try await budgetRef.collection("categoryAllocations").getDocuments()
        for document in allocationsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete budget document
        try await budgetRef.delete()
    }
    
    // MARK: - Query Operations
    
    func fetchCurrentBudget() async throws -> Budget? {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let now = Date()
        
        // Find budget that includes current date
        let query = firebaseService.db.collection("households").document(householdId).collection("budgets")
            .whereField("startDate", isLessThanOrEqualTo: Timestamp(date: now))
            .whereField("endDate", isGreaterThanOrEqualTo: Timestamp(date: now))
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        if let budgetDoc = snapshot.documents.first {
            // Fetch category allocations
            let allocationsSnapshot = try await budgetDoc.reference.collection("categoryAllocations").getDocuments()
            let allocations = allocationsSnapshot.documents.compactMap { CategoryBudget.fromFirestore(document: $0) }
            
            return Budget.fromFirestore(document: budgetDoc, withAllocations: allocations)
        }
        
        return nil
    }
    
    func fetchBudgets(limit: Int = 10) async throws -> [Budget] {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let query = firebaseService.db.collection("households").document(householdId).collection("budgets")
            .order(by: "startDate", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        var budgets: [Budget] = []
        
        for document in snapshot.documents {
            // Fetch category allocations for each budget
            let allocationsSnapshot = try await document.reference.collection("categoryAllocations").getDocuments()
            let allocations = allocationsSnapshot.documents.compactMap { CategoryBudget.fromFirestore(document: $0) }
            
            if let budget = Budget.fromFirestore(document: document, withAllocations: allocations) {
                budgets.append(budget)
            }
        }
        
        return budgets
    }
    
    // MARK: - Real-time Listeners
    
    func addCurrentBudgetListener(completion: @escaping (Budget?) -> Void) -> ListenerRegistration {
        do {
            try firebaseService.validateCurrentUser()
            try firebaseService.validateHousehold()
            
            guard let householdId = firebaseService.currentHouseholdId else {
                throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
            }
            
            let now = Date()
            
            // Find budget that includes current date
            let query = firebaseService.db.collection("households").document(householdId).collection("budgets")
                .whereField("startDate", isLessThanOrEqualTo: Timestamp(date: now))
                .whereField("endDate", isGreaterThanOrEqualTo: Timestamp(date: now))
                .limit(to: 1)
            
            let listener = query.addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    print("Error fetching current budget: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                
                if let budgetDoc = snapshot.documents.first {
                    // Fetch category allocations
                    Task {
                        do {
                            let allocationsSnapshot = try await budgetDoc.reference.collection("categoryAllocations").getDocuments()
                            let allocations = allocationsSnapshot.documents.compactMap { CategoryBudget.fromFirestore(document: $0) }
                            
                            let budget = Budget.fromFirestore(document: budgetDoc, withAllocations: allocations)
                            DispatchQueue.main.async {
                                completion(budget)
                            }
                        } catch {
                            print("Error fetching budget allocations: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
            
            listeners.append(listener)
            return listener
            
        } catch {
            print("Error setting up budget listener: \(error.localizedDescription)")
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
    
    // MARK: - Budget Analysis
    
    func getBudgetProgress(budget: Budget) async throws -> [String: Double] {
        let startDate = budget.startDate
        let endDate = budget.endDate
        
        // Get spending by category
        let spendingByCategory = try await expenseService.getSpendingByCategory(startDate: startDate, endDate: endDate)
        
        // Create a map of category allocations
        var categoryAllocations: [String: CategoryBudget] = [:]
        for allocation in budget.categoryAllocations {
            categoryAllocations[allocation.categoryId] = allocation
        }
        
        // Calculate progress for each category
        var progress: [String: Double] = [:]
        
        for (categoryId, spending) in spendingByCategory {
            if let allocation = categoryAllocations[categoryId] {
                let percentage = min(spending / allocation.amount, 1.0) * 100
                progress[categoryId] = percentage
            }
        }
        
        // Add categories with no spending
        for allocation in budget.categoryAllocations {
            if progress[allocation.categoryId] == nil {
                progress[allocation.categoryId] = 0.0
            }
        }
        
        // Calculate overall progress
        let totalSpending = spendingByCategory.values.reduce(0, +)
        let overallPercentage = min(totalSpending / budget.totalAmount, 1.0) * 100
        progress["overall"] = overallPercentage
        
        return progress
    }
    
    func createMonthlyBudget(totalAmount: Double, startDate: Date? = nil, categoryAllocations: [CategoryBudget]? = nil) async throws -> Budget {
        let calendar = Calendar.current
        
        // Use provided start date or current date
        let budgetStartDate = startDate ?? Date()
        
        // Get start of month
        let components = calendar.dateComponents([.year, .month], from: budgetStartDate)
        guard let startOfMonth = calendar.date(from: components) else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid date"])
        }
        
        // Get end of month
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            throw NSError(domain: "BudgetService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid date"])
        }
        
        // Create budget
        let budget = Budget(
            totalAmount: totalAmount,
            startDate: startOfMonth,
            endDate: endOfMonth,
            period: .monthly,
            categoryAllocations: categoryAllocations ?? []
        )
        
        try await createBudget(budget)
        
        return budget
    }
}
