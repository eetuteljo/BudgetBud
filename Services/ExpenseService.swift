import Foundation
import FirebaseFirestore
import Combine

class ExpenseService {
    static let shared = ExpenseService()
    
    private let firebaseService = FirebaseService.shared
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - CRUD Operations
    
    func createExpense(_ expense: Expense) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let expenseRef = firebaseService.db.collection("households").document(householdId).collection("expenses").document(expense.id)
        try await expenseRef.setData(expense.toDictionary())
    }
    
    func fetchExpense(id: String) async throws -> Expense {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let document = try await firebaseService.db.collection("households").document(householdId).collection("expenses").document(id).getDocument()
        
        guard let expense = Expense.fromFirestore(document: document) else {
            throw NSError(domain: "ExpenseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Expense not found"])
        }
        
        return expense
    }
    
    func updateExpense(_ expense: Expense) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        var updatedExpense = expense
        updatedExpense.updatedAt = Date()
        
        let expenseRef = firebaseService.db.collection("households").document(householdId).collection("expenses").document(expense.id)
        try await expenseRef.updateData(updatedExpense.toDictionary())
    }
    
    func deleteExpense(id: String) async throws {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let expenseRef = firebaseService.db.collection("households").document(householdId).collection("expenses").document(id)
        try await expenseRef.delete()
    }
    
    // MARK: - Query Operations
    
    func fetchExpenses(limit: Int = 50) async throws -> [Expense] {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let query = firebaseService.db.collection("households").document(householdId).collection("expenses")
            .order(by: "date", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Expense.fromFirestore(document: $0) }
    }
    
    func fetchExpensesByDateRange(startDate: Date, endDate: Date) async throws -> [Expense] {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let query = firebaseService.db.collection("households").document(householdId).collection("expenses")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Expense.fromFirestore(document: $0) }
    }
    
    func fetchExpensesByCategory(categoryId: String) async throws -> [Expense] {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let query = firebaseService.db.collection("households").document(householdId).collection("expenses")
            .whereField("categoryId", isEqualTo: categoryId)
            .order(by: "date", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Expense.fromFirestore(document: $0) }
    }
    
    func fetchExpensesBySpender(spenderId: String) async throws -> [Expense] {
        try firebaseService.validateCurrentUser()
        try firebaseService.validateHousehold()
        
        guard let householdId = firebaseService.currentHouseholdId else {
            throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
        }
        
        let query = firebaseService.db.collection("households").document(householdId).collection("expenses")
            .whereField("spenderId", isEqualTo: spenderId)
            .order(by: "date", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Expense.fromFirestore(document: $0) }
    }
    
    // MARK: - Real-time Listeners
    
    func addExpensesListener(completion: @escaping ([Expense]) -> Void) -> ListenerRegistration {
        do {
            try firebaseService.validateCurrentUser()
            try firebaseService.validateHousehold()
            
            guard let householdId = firebaseService.currentHouseholdId else {
                throw NSError(domain: "ExpenseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID not found"])
            }
            
            let query = firebaseService.db.collection("households").document(householdId).collection("expenses")
                .order(by: "date", descending: true)
            
            let listener = query.addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error fetching expenses: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let expenses = snapshot.documents.compactMap { Expense.fromFirestore(document: $0) }
                completion(expenses)
            }
            
            listeners.append(listener)
            return listener
            
        } catch {
            print("Error setting up expenses listener: \(error.localizedDescription)")
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
    
    // MARK: - Analytics
    
    func getTotalSpending(startDate: Date, endDate: Date) async throws -> Double {
        let expenses = try await fetchExpensesByDateRange(startDate: startDate, endDate: endDate)
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func getSpendingByCategory(startDate: Date, endDate: Date) async throws -> [String: Double] {
        let expenses = try await fetchExpensesByDateRange(startDate: startDate, endDate: endDate)
        
        var spendingByCategory: [String: Double] = [:]
        
        for expense in expenses {
            let currentAmount = spendingByCategory[expense.categoryId] ?? 0
            spendingByCategory[expense.categoryId] = currentAmount + expense.amount
        }
        
        return spendingByCategory
    }
    
    func getSpendingBySpender(startDate: Date, endDate: Date) async throws -> [String: Double] {
        let expenses = try await fetchExpensesByDateRange(startDate: startDate, endDate: endDate)
        
        var spendingBySpender: [String: Double] = [:]
        
        for expense in expenses {
            let currentAmount = spendingBySpender[expense.spenderId] ?? 0
            spendingBySpender[expense.spenderId] = currentAmount + expense.amount
        }
        
        return spendingBySpender
    }
    
    func getDailySpending(startDate: Date, endDate: Date) async throws -> [Date: Double] {
        let expenses = try await fetchExpensesByDateRange(startDate: startDate, endDate: endDate)
        
        var dailySpending: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for expense in expenses {
            // Get date components to normalize to start of day
            let components = calendar.dateComponents([.year, .month, .day], from: expense.date)
            guard let normalizedDate = calendar.date(from: components) else { continue }
            
            let currentAmount = dailySpending[normalizedDate] ?? 0
            dailySpending[normalizedDate] = currentAmount + expense.amount
        }
        
        return dailySpending
    }
}
