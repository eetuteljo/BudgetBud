import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedCategoryId: String? = nil
    @State private var selectedSpenderId: String? = nil
    @State private var dateRange: DateRange = .thisMonth
    @State private var customStartDate = Date().startOfMonth
    @State private var customEndDate = Date().endOfMonth
    
    private var filteredExpenses: [Expense] {
        var result = expenseViewModel.expenses
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.categoryId == categoryId }
        }
        
        // Filter by spender
        if let spenderId = selectedSpenderId {
            result = result.filter { $0.spenderId == spenderId }
        }
        
        // Filter by date range
        let (startDate, endDate) = getDateRange(for: dateRange)
        result = result.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search expenses", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color("TextFieldBackground", default: Color(.systemGray6)))
            .padding(.horizontal)
            
            // Filter bar
            HStack {
                Button(action: {
                    showingFilters = true
                }) {
                    HStack {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                        Text("Filter")
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                // Date range picker
                Menu {
                    Button("Today") { dateRange = .today }
                    Button("This Week") { dateRange = .thisWeek }
                    Button("This Month") { dateRange = .thisMonth }
                    Button("This Year") { dateRange = .thisYear }
                    Button("Custom Range...") { dateRange = .custom }
                } label: {
                    HStack {
                        Text(dateRangeLabel)
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Custom date range picker (if selected)
            if dateRange == .custom {
                VStack(spacing: 10) {
                    DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                .padding()
                .background(Color("TextFieldBackground", default: Color(.systemGray6)))
                .padding(.horizontal)
            }
            
            // Active filters display
            if selectedCategoryId != nil || selectedSpenderId != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if let categoryId = selectedCategoryId, let category = categoryViewModel.categoryMap[categoryId] {
                            FilterChip(label: category.name, color: category.color) {
                                selectedCategoryId = nil
                            }
                        }
                        
                        if let spenderId = selectedSpenderId, let spender = expenseViewModel.spenderMap[spenderId] {
                            FilterChip(label: spender.name, color: .blue) {
                                selectedSpenderId = nil
                            }
                        }
                        
                        if selectedCategoryId != nil || selectedSpenderId != nil {
                            Button(action: {
                                selectedCategoryId = nil
                                selectedSpenderId = nil
                            }) {
                                Text("Clear All")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            
            // Expenses list
            if filteredExpenses.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No expenses found")
                        .font(.headline)
                    
                    Text("Try changing your filters or add a new expense")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(groupExpensesByDate(filteredExpenses), id: \.date) { group in
                        Section(header: Text(formatDate(group.date))) {
                            ForEach(group.expenses) { expense in
                                ExpenseRow(
                                    expense: expense,
                                    categoryName: expenseViewModel.getCategoryName(for: expense.categoryId),
                                    categoryColor: expenseViewModel.getCategoryColor(for: expense.categoryId),
                                    spenderName: expenseViewModel.getSpenderName(for: expense.spenderId)
                                )
                                .contextMenu {
                                    Button(action: {
                                        // Edit expense (would be implemented in a real app)
                                    }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        deleteExpense(expense)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(
                categories: categoryViewModel.categories,
                selectedCategoryId: $selectedCategoryId,
                spenders: Array(expenseViewModel.spenderMap.values),
                selectedSpenderId: $selectedSpenderId
            )
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        Task {
            await expenseViewModel.deleteExpense(id: expense.id)
        }
    }
    
    private func groupExpensesByDate(_ expenses: [Expense]) -> [(date: Date, expenses: [Expense])] {
        let calendar = Calendar.current
        
        // Group expenses by date
        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        // Sort by date (newest first)
        return grouped.map { (date: $0.key, expenses: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func getDateRange(for range: DateRange) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .today:
            return (calendar.startOfDay(for: now), calendar.endOfDay(for: now))
        case .thisWeek:
            return (calendar.startOfWeek(for: now), calendar.endOfWeek(for: now))
        case .thisMonth:
            return (calendar.startOfMonth(for: now), calendar.endOfMonth(for: now))
        case .thisYear:
            return (calendar.startOfYear(for: now), calendar.endOfYear(for: now))
        case .custom:
            return (calendar.startOfDay(for: customStartDate), calendar.endOfDay(for: customEndDate))
        }
    }
    
    private var dateRangeLabel: String {
        switch dateRange {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisYear: return "This Year"
        case .custom:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        }
    }
}

// MARK: - Supporting Views and Extensions

struct ExpenseRow: View {
    let expense: Expense
    let categoryName: String
    let categoryColor: String
    let spenderName: String
    
    var body: some View {
        HStack {
            // Category color indicator
            Circle()
                .fill(Color(hex: categoryColor) ?? .gray)
                .frame(width: 12, height: 12)
            
            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.headline)
                
                HStack {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !spenderName.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(spenderName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let location = expense.location, !location.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text("€\(expense.amount, specifier: "%.2f")")
                .font(.headline)
        }
    }
}

struct FilterChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.footnote)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
        )
    }
}

struct FilterView: View {
    let categories: [Category]
    @Binding var selectedCategoryId: String?
    let spenders: [User]
    @Binding var selectedSpenderId: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Categories")) {
                    ForEach(categories) { category in
                        Button(action: {
                            selectedCategoryId = (selectedCategoryId == category.id) ? nil : category.id
                        }) {
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(category.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedCategoryId == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Spenders")) {
                    ForEach(spenders) { spender in
                        Button(action: {
                            selectedSpenderId = (selectedSpenderId == spender.id) ? nil : spender.id
                        }) {
                            HStack {
                                Text(spender.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedSpenderId == spender.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Filters")
            .navigationBarItems(
                leading: Button("Reset") {
                    selectedCategoryId = nil
                    selectedSpenderId = nil
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

enum DateRange {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case custom
}

extension Calendar {
    func startOfDay(for date: Date) -> Date {
        return self.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
    }
    
    func endOfDay(for date: Date) -> Date {
        return self.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
    }
    
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
    
    func endOfWeek(for date: Date) -> Date {
        let startOfWeek = self.startOfWeek(for: date)
        let endOfWeek = self.date(byAdding: .day, value: 6, to: startOfWeek)!
        return endOfDay(for: endOfWeek)
    }
    
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
    
    func endOfMonth(for date: Date) -> Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        let startOfMonth = self.startOfMonth(for: date)
        let endOfMonth = self.date(byAdding: components, to: startOfMonth)!
        return endOfDay(for: endOfMonth)
    }
    
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components)!
    }
    
    func endOfYear(for date: Date) -> Date {
        var components = DateComponents()
        components.year = 1
        components.day = -1
        let startOfYear = self.startOfYear(for: date)
        let endOfYear = self.date(byAdding: components, to: startOfYear)!
        return endOfDay(for: endOfYear)
    }
}

extension Date {
    var startOfMonth: Date {
        return Calendar.current.startOfMonth(for: self)
    }
    
    var endOfMonth: Date {
        return Calendar.current.endOfMonth(for: self)
    }
}

struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseListView()
            .environmentObject(ExpenseViewModel())
            .environmentObject(CategoryViewModel())
    }
}
