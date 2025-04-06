import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    @State private var showingCreateBudget = false
    @State private var showingBudgetDetails = false
    @State private var selectedBudgetTemplate: BudgetTemplate = .equal
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current budget section
                if let currentBudget = budgetViewModel.currentBudget {
                    currentBudgetSection(currentBudget)
                } else {
                    noBudgetSection
                }
                
                // Category allocations
                if let currentBudget = budgetViewModel.currentBudget {
                    categoryAllocationsSection(currentBudget)
                }
                
                // Budget templates section
                if budgetViewModel.currentBudget == nil {
                    budgetTemplatesSection
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingCreateBudget) {
            CreateBudgetView(
                budgetViewModel: budgetViewModel,
                categoryViewModel: categoryViewModel,
                selectedTemplate: $selectedBudgetTemplate
            )
        }
        .sheet(isPresented: $showingBudgetDetails) {
            if let budget = budgetViewModel.currentBudget {
                BudgetDetailsView(
                    budget: budget,
                    budgetViewModel: budgetViewModel,
                    categoryViewModel: categoryViewModel
                )
            }
        }
    }
    
    // MARK: - Current Budget Section
    
    private func currentBudgetSection(_ budget: Budget) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text("Current Budget")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingBudgetDetails = true
                }) {
                    Text("Details")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Budget period
            HStack {
                VStack(alignment: .leading) {
                    Text(formatDateRange(budget.startDate, budget.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("€\(budget.totalAmount, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Budget progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(budgetViewModel.getOverallProgress() / 100, 1.0)))
                        .stroke(budgetProgressColor, lineWidth: 10)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(budgetViewModel.getOverallProgress()))%")
                            .font(.headline)
                        
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Days remaining
            HStack {
                VStack(alignment: .leading) {
                    Text("Days Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(daysRemaining(until: budget.endDate))")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Daily Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("€\(dailyBudget(budget), specifier: "%.2f")")
                        .font(.headline)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color("CardBackground", default: Color(.systemBackground)))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var noBudgetSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
                .padding()
            
            Text("No Active Budget")
                .font(.headline)
            
            Text("Create a budget to track your spending and stay on top of your finances.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingCreateBudget = true
            }) {
                Text("Create Budget")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color("CardBackground", default: Color(.systemBackground)))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Category Allocations Section
    
    private func categoryAllocationsSection(_ budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category Allocations")
                .font(.headline)
            
            if budget.categoryAllocations.isEmpty {
                Text("No category allocations found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(budget.categoryAllocations) { allocation in
                    if let category = categoryViewModel.categoryMap[allocation.categoryId] {
                        CategoryBudgetRow(
                            category: category,
                            allocation: allocation,
                            progress: budgetViewModel.getCategoryProgress(for: allocation.categoryId),
                            progressColor: budgetViewModel.getProgressColor(for: budgetViewModel.getCategoryProgress(for: allocation.categoryId))
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color("CardBackground", default: Color(.systemBackground)))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Budget Templates Section
    
    private var budgetTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Budget Templates")
                .font(.headline)
            
            VStack(spacing: 10) {
                BudgetTemplateRow(
                    title: "Equal Distribution",
                    description: "Divide budget equally across all categories",
                    icon: "equal.square.fill",
                    isSelected: selectedBudgetTemplate == .equal,
                    action: { selectedBudgetTemplate = .equal }
                )
                
                BudgetTemplateRow(
                    title: "50/30/20 Rule",
                    description: "50% needs, 30% wants, 20% savings",
                    icon: "chart.pie.fill",
                    isSelected: selectedBudgetTemplate == .rule50_30_20,
                    action: { selectedBudgetTemplate = .rule50_30_20 }
                )
                
                BudgetTemplateRow(
                    title: "Custom Allocation",
                    description: "Set custom amounts for each category",
                    icon: "slider.horizontal.3",
                    isSelected: selectedBudgetTemplate == .custom,
                    action: { selectedBudgetTemplate = .custom }
                )
            }
            
            Button(action: {
                showingCreateBudget = true
            }) {
                Text("Create Budget")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color("CardBackground", default: Color(.systemBackground)))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private var budgetProgressColor: Color {
        let progress = budgetViewModel.getOverallProgress()
        return budgetViewModel.getProgressColor(for: progress)
    }
    
    private func formatDateRange(_ startDate: Date, _ endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func daysRemaining(until endDate: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        
        let components = calendar.dateComponents([.day], from: today, to: end)
        return max(0, components.day ?? 0) + 1 // Include today
    }
    
    private func dailyBudget(_ budget: Budget) -> Double {
        let days = daysRemaining(until: budget.endDate)
        if days <= 0 { return 0 }
        
        let progress = budgetViewModel.getOverallProgress() / 100.0
        let remainingBudget = budget.totalAmount * (1 - progress)
        
        return remainingBudget / Double(days)
    }
}

// MARK: - Supporting Views

struct CategoryBudgetRow: View {
    let category: Category
    let allocation: CategoryBudget
    let progress: Double
    let progressColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 12, height: 12)
                
                Text(category.name)
                    .font(.subheadline)
                
                Spacer()
                
                Text("€\(allocation.amount, specifier: "%.2f")")
                    .font(.subheadline)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: min(CGFloat(progress / 100) * geometry.size.width, geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(progress))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if allocation.isPercentage, let percentage = allocation.percentage {
                    Text("\(Int(percentage))% of total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct BudgetTemplateRow: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Supporting Screens

struct CreateBudgetView: View {
    @ObservedObject var budgetViewModel: BudgetViewModel
    @ObservedObject var categoryViewModel: CategoryViewModel
    @Binding var selectedTemplate: BudgetTemplate
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var totalAmount = ""
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date().endOfMonth
    @State private var categoryAllocations: [String: Double] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Budget Details")) {
                    HStack {
                        Text("€")
                        TextField("Total Amount", text: $totalAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Budget Template")) {
                    Picker("Template", selection: $selectedTemplate) {
                        Text("Equal Distribution").tag(BudgetTemplate.equal)
                        Text("50/30/20 Rule").tag(BudgetTemplate.rule50_30_20)
                        Text("Custom Allocation").tag(BudgetTemplate.custom)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedTemplate == .custom {
                    Section(header: Text("Category Allocations")) {
                        ForEach(categoryViewModel.categories) { category in
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(category.name)
                                
                                Spacer()
                                
                                TextField("Amount", text: Binding(
                                    get: { String(format: "%.2f", categoryAllocations[category.id] ?? 0) },
                                    set: { str in
                                        if let value = Double(str.replacingOccurrences(of: ",", with: ".")) {
                                            categoryAllocations[category.id] = value
                                        }
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            }
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: createBudget) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Create Budget")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Create Budget")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var isFormValid: Bool {
        guard let amount = Double(totalAmount.replacingOccurrences(of: ",", with: ".")),
              amount > 0,
              startDate <= endDate else {
            return false
        }
        
        if selectedTemplate == .custom {
            let totalAllocated = categoryAllocations.values.reduce(0, +)
            return totalAllocated > 0
        }
        
        return true
    }
    
    private func createBudget() {
        guard let totalAmount = Double(totalAmount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var allocations: [CategoryBudget]?
                
                switch selectedTemplate {
                case .equal:
                    allocations = budgetViewModel.createEqualCategoryAllocations(totalAmount: totalAmount)
                case .rule50_30_20:
                    // This would be implemented in the BudgetViewModel
                    try await budgetViewModel.create50_30_20Budget(totalAmount: totalAmount)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    return
                case .custom:
                    allocations = createCustomAllocations(totalAmount: totalAmount)
                }
                
                try await budgetViewModel.createMonthlyBudget(
                    totalAmount: totalAmount,
                    categoryAllocations: allocations
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createCustomAllocations(totalAmount: Double) -> [CategoryBudget] {
        return categoryViewModel.categories.compactMap { category in
            guard let amount = categoryAllocations[category.id], amount > 0 else { return nil }
            
            return CategoryBudget(
                categoryId: category.id,
                amount: amount,
                isPercentage: false,
                percentage: nil,
                rolloverEnabled: false
            )
        }
    }
}

struct BudgetDetailsView: View {
    let budget: Budget
    @ObservedObject var budgetViewModel: BudgetViewModel
    @ObservedObject var categoryViewModel: CategoryViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Budget Details")) {
                    HStack {
                        Text("Total Amount")
                        Spacer()
                        Text("€\(budget.totalAmount, specifier: "%.2f")")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Period")
                        Spacer()
                        Text(budget.period.displayName)
                    }
                    
                    HStack {
                        Text("Date Range")
                        Spacer()
                        Text(formatDateRange(budget.startDate, budget.endDate))
                    }
                    
                    HStack {
                        Text("Progress")
                        Spacer()
                        Text("\(Int(budgetViewModel.getOverallProgress()))%")
                            .foregroundColor(budgetViewModel.getProgressColor(for: budgetViewModel.getOverallProgress()))
                    }
                }
                
                Section(header: Text("Category Allocations")) {
                    ForEach(budget.categoryAllocations) { allocation in
                        if let category = categoryViewModel.categoryMap[allocation.categoryId] {
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(category.name)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("€\(allocation.amount, specifier: "%.2f")")
                                    
                                    if allocation.isPercentage, let percentage = allocation.percentage {
                                        Text("\(Int(percentage))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Budget")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Budget Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Budget"),
                    message: Text("Are you sure you want to delete this budget? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteBudget()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func formatDateRange(_ startDate: Date, _ endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func deleteBudget() {
        Task {
            await budgetViewModel.deleteBudget(id: budget.id)
            DispatchQueue.main.async {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Supporting Types

enum BudgetTemplate {
    case equal
    case rule50_30_20
    case custom
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BudgetView()
                .environmentObject(BudgetViewModel())
                .environmentObject(CategoryViewModel())
        }
    }
}
