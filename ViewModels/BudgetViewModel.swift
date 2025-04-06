import Foundation
import Combine
import FirebaseFirestore
import SwiftUI

class BudgetViewModel: ObservableObject {
    @Published var currentBudget: Budget?
    @Published var budgetProgress: [String: Double] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var categories: [Category] = []
    @Published var categoryMap: [String: Category] = [:]
    
    private let budgetService = BudgetService.shared
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
        setupBudgetListener()
        setupCategoriesListener()
        
        // Fetch budget progress
        Task {
            await fetchBudgetProgress()
        }
    }
    
    private func setupBudgetListener() {
        let listener = budgetService.addCurrentBudgetListener { [weak self] budget in
            DispatchQueue.main.async {
                self?.currentBudget = budget
                self?.isLoading = false
                
                // Update budget progress when budget changes
                Task {
                    await self?.fetchBudgetProgress()
                }
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
    
    // MARK: - Budget Operations
    
    func createMonthlyBudget(totalAmount: Double, categoryAllocations: [CategoryBudget]? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await budgetService.createMonthlyBudget(
                totalAmount: totalAmount,
                categoryAllocations: categoryAllocations
            )
            
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
    
    func updateBudget(_ budget: Budget) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await budgetService.updateBudget(budget)
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
    
    func deleteBudget(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await budgetService.deleteBudget(id: id)
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
    
    // MARK: - Budget Progress
    
    func fetchBudgetProgress() async {
        guard let budget = currentBudget else { return }
        
        do {
            let progress = try await budgetService.getBudgetProgress(budget: budget)
            DispatchQueue.main.async {
                self.budgetProgress = progress
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Data Helpers
    
    func getCategoryName(for categoryId: String) -> String {
        return categoryMap[categoryId]?.name ?? "Unknown Category"
    }
    
    func getCategoryColor(for categoryId: String) -> Color {
        return categoryMap[categoryId]?.color ?? .gray
    }
    
    func getCategoryProgress(for categoryId: String) -> Double {
        return budgetProgress[categoryId] ?? 0.0
    }
    
    func getOverallProgress() -> Double {
        return budgetProgress["overall"] ?? 0.0
    }
    
    func getProgressColor(for progress: Double) -> Color {
        if progress < 70 {
            return .green
        } else if progress < 90 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - Budget Allocation Helpers
    
    func createEqualCategoryAllocations(totalAmount: Double) -> [CategoryBudget] {
        let activeCategories = categories.filter { !$0.isArchived }
        
        guard !activeCategories.isEmpty else { return [] }
        
        let amountPerCategory = totalAmount / Double(activeCategories.count)
        
        return activeCategories.map { category in
            CategoryBudget(
                categoryId: category.id,
                amount: amountPerCategory,
                isPercentage: false,
                percentage: nil,
                rolloverEnabled: false
            )
        }
    }
    
    func createPercentageBasedAllocations(totalAmount: Double, percentages: [String: Double]) -> [CategoryBudget] {
        var allocations: [CategoryBudget] = []
        
        for (categoryId, percentage) in percentages {
            let amount = totalAmount * (percentage / 100.0)
            
            let allocation = CategoryBudget(
                categoryId: categoryId,
                amount: amount,
                isPercentage: true,
                percentage: percentage,
                rolloverEnabled: false
            )
            
            allocations.append(allocation)
        }
        
        return allocations
    }
    
    // Common budget templates
    func create50_30_20Budget(totalAmount: Double) async {
        // 50% Needs, 30% Wants, 20% Savings
        let needsCategories = categories.filter { category in
            ["Housing", "Groceries", "Transportation", "Utilities", "Health"].contains(category.name)
        }
        
        let wantsCategories = categories.filter { category in
            ["Dining", "Entertainment", "Shopping"].contains(category.name)
        }
        
        let savingsCategories = categories.filter { category in
            ["Personal"].contains(category.name)
        }
        
        var allocations: [CategoryBudget] = []
        
        // Allocate 50% to Needs
        let needsAmount = totalAmount * 0.5
        if !needsCategories.isEmpty {
            let amountPerNeedsCategory = needsAmount / Double(needsCategories.count)
            for category in needsCategories {
                allocations.append(CategoryBudget(
                    categoryId: category.id,
                    amount: amountPerNeedsCategory,
                    isPercentage: true,
                    percentage: 50.0 / Double(needsCategories.count),
                    rolloverEnabled: false
                ))
            }
        }
        
        // Allocate 30% to Wants
        let wantsAmount = totalAmount * 0.3
        if !wantsCategories.isEmpty {
            let amountPerWantsCategory = wantsAmount / Double(wantsCategories.count)
            for category in wantsCategories {
                allocations.append(CategoryBudget(
                    categoryId: category.id,
                    amount: amountPerWantsCategory,
                    isPercentage: true,
                    percentage: 30.0 / Double(wantsCategories.count),
                    rolloverEnabled: false
                ))
            }
        }
        
        // Allocate 20% to Savings
        let savingsAmount = totalAmount * 0.2
        if !savingsCategories.isEmpty {
            let amountPerSavingsCategory = savingsAmount / Double(savingsCategories.count)
            for category in savingsCategories {
                allocations.append(CategoryBudget(
                    categoryId: category.id,
                    amount: amountPerSavingsCategory,
                    isPercentage: true,
                    percentage: 20.0 / Double(savingsCategories.count),
                    rolloverEnabled: false
                ))
            }
        }
        
        // Create budget with these allocations
        await createMonthlyBudget(totalAmount: totalAmount, categoryAllocations: allocations)
    }
}
