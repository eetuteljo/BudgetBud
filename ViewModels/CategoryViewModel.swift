import Foundation
import Combine
import FirebaseFirestore
import SwiftUI

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var archivedCategories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        
        // Setup listeners for active categories
        setupCategoriesListener()
        
        // Fetch archived categories
        Task {
            await fetchArchivedCategories()
        }
    }
    
    private func setupCategoriesListener() {
        let listener = categoryService.addCategoriesListener(includeArchived: false) { [weak self] categories in
            DispatchQueue.main.async {
                self?.categories = categories
                self?.isLoading = false
            }
        }
        
        listeners.append(listener)
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Category Operations
    
    func addCategory(name: String, colorHex: String, icon: String) async {
        isLoading = true
        errorMessage = nil
        
        let category = Category(
            name: name,
            colorHex: colorHex,
            icon: icon
        )
        
        do {
            try await categoryService.createCategory(category)
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
    
    func updateCategory(_ category: Category) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await categoryService.updateCategory(category)
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
    
    func archiveCategory(_ category: Category) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await categoryService.archiveCategory(category)
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Refresh archived categories
                Task {
                    await self.fetchArchivedCategories()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func unarchiveCategory(_ category: Category) async {
        isLoading = true
        errorMessage = nil
        
        var updatedCategory = category
        updatedCategory.isArchived = false
        
        do {
            try await categoryService.updateCategory(updatedCategory)
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Refresh archived categories
                Task {
                    await self.fetchArchivedCategories()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Archived Categories
    
    func fetchArchivedCategories() async {
        do {
            let allCategories = try await categoryService.fetchCategories(includeArchived: true)
            let archived = allCategories.filter { $0.isArchived }
            
            DispatchQueue.main.async {
                self.archivedCategories = archived
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Default Categories
    
    func setupDefaultCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await categoryService.setupDefaultCategories()
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
    
    // MARK: - Helper Methods
    
    func getColorOptions() -> [(name: String, hex: String)] {
        return [
            ("Red", "#FF3B30"),
            ("Orange", "#FF9500"),
            ("Yellow", "#FFCC00"),
            ("Green", "#34C759"),
            ("Mint", "#00C7BE"),
            ("Teal", "#30B0C7"),
            ("Cyan", "#32ADE6"),
            ("Blue", "#007AFF"),
            ("Indigo", "#5856D6"),
            ("Purple", "#AF52DE"),
            ("Pink", "#FF2D55"),
            ("Brown", "#A2845E"),
            ("Gray", "#8E8E93")
        ]
    }
    
    func getIconOptions() -> [(name: String, systemName: String)] {
        return [
            ("Home", "house"),
            ("Food", "fork.knife"),
            ("Groceries", "cart"),
            ("Car", "car"),
            ("Transport", "bus"),
            ("Health", "heart"),
            ("Fitness", "figure.walk"),
            ("Entertainment", "tv"),
            ("Shopping", "bag"),
            ("Clothes", "tshirt"),
            ("Education", "book"),
            ("Work", "briefcase"),
            ("Travel", "airplane"),
            ("Bills", "doc.text"),
            ("Utilities", "bolt"),
            ("Phone", "phone"),
            ("Internet", "wifi"),
            ("Gifts", "gift"),
            ("Charity", "heart.circle"),
            ("Savings", "banknote"),
            ("Investments", "chart.line.uptrend.xyaxis"),
            ("Pets", "pawprint"),
            ("Kids", "figure.and.child.holdinghands"),
            ("Beauty", "sparkles"),
            ("Other", "ellipsis")
        ]
    }
    
    func getColor(from hex: String) -> Color {
        return Color(hex: hex) ?? .gray
    }
}
