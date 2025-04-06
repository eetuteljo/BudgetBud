import Foundation
import Combine
import FirebaseFirestore

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var categories: [Category] = []
    @Published var categoryMap: [String: Category] = [:]
    @Published var spenders: [User] = []
    @Published var spenderMap: [String: User] = [:]
    
    private let expenseService = ExpenseService.shared
    private let categoryService = CategoryService.shared
    private var listeners: [ListenerRegistration] = []
    
    init() {
        fetchData()
    }
    
    deinit {
        removeAllListeners()
    }
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        // Setup listeners
        setupExpensesListener()
        setupCategoriesListener()
        
        // Fetch spenders (household members)
        // This would be implemented in a real app
    }
    
    private func setupExpensesListener() {
        let listener = expenseService.addExpensesListener { [weak self] expenses in
            DispatchQueue.main.async {
                self?.expenses = expenses
                self?.isLoading = false
            }
        }
        
        listeners.append(listener)
    }
    
    private func setupCategoriesListener() {
        let listener = categoryService.addCategoriesListener { [weak self] categories in
            DispatchQueue.main.async {
                self?.categories = categories
                
                // Update category map
                var categoryMap: [String: Category] = [:]
                for category in categories {
                    categoryMap[category.id] = category
                }
                self?.categoryMap = categoryMap
            }
        }
        
        listeners.append(listener)
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Expense Operations
    
    func addExpense(amount: Double, description: String, date: Date, categoryId: String, spenderId: String, location: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let expense = Expense(
            amount: amount,
            description: description,
            date: date,
            categoryId: categoryId,
            spenderId: spenderId,
            location: location
        )
        
        do {
            try await expenseService.createExpense(expense)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func updateExpense(_ expense: Expense) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await expenseService.updateExpense(expense)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteExpense(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await expenseService.deleteExpense(id: id)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Data Helpers
    
    func getCategoryName(for categoryId: String) -> String {
        return categoryMap[categoryId]?.name ?? "Unknown Category"
    }
    
    func getCategoryColor(for categoryId: String) -> String {
        return categoryMap[categoryId]?.colorHex ?? "#8E8E93"
    }
    
    func getSpenderName(for spenderId: String) -> String {
        return spenderMap[spenderId]?.name ?? "Unknown User"
    }
    
    // MARK: - Filtering
    
    func getExpensesByCategory(categoryId: String) -> [Expense] {
        return expenses.filter { $0.categoryId == categoryId }
    }
    
    func getExpensesBySpender(spenderId: String) -> [Expense] {
        return expenses.filter { $0.spenderId == spenderId }
    }
    
    func getExpensesByDateRange(startDate: Date, endDate: Date) -> [Expense] {
        return expenses.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    // MARK: - Analytics
    
    func getTotalSpending() -> Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func getSpendingByCategory() -> [String: Double] {
        var spendingByCategory: [String: Double] = [:]
        
        for expense in expenses {
            let currentAmount = spendingByCategory[expense.categoryId] ?? 0
            spendingByCategory[expense.categoryId] = currentAmount + expense.amount
        }
        
        return spendingByCategory
    }
    
    func getSpendingBySpender() -> [String: Double] {
        var spendingBySpender: [String: Double] = [:]
        
        for expense in expenses {
            let currentAmount = spendingBySpender[expense.spenderId] ?? 0
            spendingBySpender[expense.spenderId] = currentAmount + expense.amount
        }
        
        return spendingBySpender
    }
    
    func getDailySpending(for days: Int = 7) -> [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var result: [(date: Date, amount: Double)] = []
        
        // Create array of dates
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                result.append((date: date, amount: 0))
            }
        }
        
        // Add spending amounts
        for expense in expenses {
            let expenseDate = calendar.startOfDay(for: expense.date)
            
            if let index = result.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: expenseDate) }) {
                result[index].amount += expense.amount
            }
        }
        
        return result.sorted(by: { $0.date < $1.date })
    }
}
