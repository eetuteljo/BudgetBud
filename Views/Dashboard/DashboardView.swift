import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingAllCategories = false
    
    private var totalSpending: Double {
        switch selectedTimeRange {
        case .week:
            return expenseViewModel.getDailySpending(for: 7).reduce(0) { $0 + $1.amount }
        case .month:
            let calendar = Calendar.current
            let startDate = calendar.startOfMonth(for: Date())
            let endDate = calendar.endOfMonth(for: Date())
            return expenseViewModel.getExpensesByDateRange(startDate: startDate, endDate: endDate).reduce(0) { $0 + $1.amount }
        case .year:
            let calendar = Calendar.current
            let startDate = calendar.startOfYear(for: Date())
            let endDate = calendar.endOfYear(for: Date())
            return expenseViewModel.getExpensesByDateRange(startDate: startDate, endDate: endDate).reduce(0) { $0 + $1.amount }
        }
    }
    
    private var spendingByCategory: [CategorySpending] {
        let spendingMap = expenseViewModel.getSpendingByCategory()
        
        return spendingMap.compactMap { (categoryId, amount) in
            guard let category = expenseViewModel.categoryMap[categoryId] else { return nil }
            return CategorySpending(
                id: categoryId,
                name: category.name,
                amount: amount,
                color: category.color
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    private var topCategories: [CategorySpending] {
        let count = showingAllCategories ? spendingByCategory.count : min(5, spendingByCategory.count)
        return Array(spendingByCategory.prefix(count))
    }
    
    private var dailySpending: [DailySpending] {
        let dailyData = expenseViewModel.getDailySpending(for: selectedTimeRange == .week ? 7 : 30)
        return dailyData.map { DailySpending(date: $0.date, amount: $0.amount) }
    }
    
    private var budgetProgress: Double {
        budgetViewModel.getOverallProgress()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("Week").tag(TimeRange.week)
                    Text("Month").tag(TimeRange.month)
                    Text("Year").tag(TimeRange.year)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Summary cards
                HStack(spacing: 15) {
                    // Total spending card
                    SummaryCard(
                        title: "Total Spending",
                        value: "€\(totalSpending, specifier: "%.2f")",
                        icon: "eurosign.circle.fill",
                        color: .blue
                    )
                    
                    // Budget progress card
                    if let budget = budgetViewModel.currentBudget {
                        SummaryCard(
                            title: "Budget",
                            value: "\(Int(budgetProgress))%",
                            icon: "chart.pie.fill",
                            color: budgetProgressColor
                        )
                    } else {
                        SummaryCard(
                            title: "Budget",
                            value: "Not Set",
                            icon: "chart.pie.fill",
                            color: .gray
                        )
                    }
                }
                .padding(.horizontal)
                
                // Spending by category
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Spending by Category")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showingAllCategories.toggle()
                            }
                        }) {
                            Text(showingAllCategories ? "Show Less" : "Show All")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    if spendingByCategory.isEmpty {
                        Text("No spending data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Pie chart
                        PieChartView(categories: topCategories)
                            .frame(height: 200)
                            .padding(.vertical)
                        
                        // Category list
                        ForEach(topCategories) { category in
                            CategorySpendingRow(
                                name: category.name,
                                amount: category.amount,
                                percentage: category.amount / totalSpending * 100,
                                color: category.color
                            )
                        }
                    }
                }
                .padding()
                .background(Color("CardBackground", default: Color(.systemBackground)))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Daily spending chart
                VStack(alignment: .leading, spacing: 15) {
                    Text("Daily Spending")
                        .font(.headline)
                    
                    if dailySpending.isEmpty {
                        Text("No spending data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        DailySpendingChartView(data: dailySpending)
                            .frame(height: 200)
                    }
                }
                .padding()
                .background(Color("CardBackground", default: Color(.systemBackground)))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Recent transactions
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Recent Transactions")
                            .font(.headline)
                        
                        Spacer()
                        
                        NavigationLink(destination: ExpenseListView()) {
                            Text("See All")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    if expenseViewModel.expenses.isEmpty {
                        Text("No transactions available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(expenseViewModel.expenses.prefix(3)) { expense in
                            ExpenseRow(
                                expense: expense,
                                categoryName: expenseViewModel.getCategoryName(for: expense.categoryId),
                                categoryColor: expenseViewModel.getCategoryColor(for: expense.categoryId),
                                spenderName: expenseViewModel.getSpenderName(for: expense.spenderId)
                            )
                            .padding(.vertical, 5)
                            
                            if expense.id != expenseViewModel.expenses.prefix(3).last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding()
                .background(Color("CardBackground", default: Color(.systemBackground)))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                Spacer(minLength: 30)
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
    }
    
    private var budgetProgressColor: Color {
        if budgetProgress < 70 {
            return .green
        } else if budgetProgress < 90 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground", default: Color(.systemBackground)))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CategorySpendingRow: View {
    let name: String
    let amount: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Text("€\(amount, specifier: "%.2f")")
                .font(.subheadline)
            
            Text("(\(Int(percentage))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PieChartView: View {
    let categories: [CategorySpending]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(categories) { category in
                    SectorMark(
                        angle: .value("Amount", category.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(category.color)
                    .cornerRadius(5)
                    .annotation(position: .overlay) {
                        if category.amount / categories.reduce(0) { $0 + $1.amount } > 0.05 {
                            Text("\(Int(category.amount / categories.reduce(0) { $0 + $1.amount } * 100))%")
                                .font(.caption)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        } else {
            // Fallback for iOS 15
            ZStack {
                ForEach(0..<categories.count, id: \.self) { index in
                    PieSliceView(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        color: categories[index].color
                    )
                }
                
                Circle()
                    .fill(Color("CardBackground", default: Color(.systemBackground)))
                    .frame(width: 100)
                
                VStack {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("€\(categories.reduce(0) { $0 + $1.amount }, specifier: "%.0f")")
                        .font(.headline)
                }
            }
        }
    }
    
    private func startAngle(for index: Int) -> Double {
        let total = categories.reduce(0) { $0 + $1.amount }
        let proportions = categories.map { $0.amount / total }
        
        var angle: Double = 0
        for i in 0..<index {
            angle += proportions[i] * 360
        }
        
        return angle
    }
    
    private func endAngle(for index: Int) -> Double {
        return startAngle(for: index + 1)
    }
}

struct PieSliceView: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let innerRadius = radius * 0.6
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(endAngle - 90),
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: innerRadius,
                    startAngle: .degrees(endAngle - 90),
                    endAngle: .degrees(startAngle - 90),
                    clockwise: true
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct DailySpendingChartView: View {
    let data: [DailySpending]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(5)
                }
            }
        } else {
            // Fallback for iOS 15
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(data) { item in
                        VStack {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: barWidth(for: geometry.size.width), height: barHeight(for: item.amount, in: geometry.size.height))
                                .cornerRadius(5)
                            
                            Text(formatDate(item.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: barWidth(for: geometry.size.width))
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func barWidth(for totalWidth: CGFloat) -> CGFloat {
        let count = CGFloat(data.count)
        let spacing = CGFloat(5)
        return (totalWidth - (spacing * (count - 1))) / count
    }
    
    private func barHeight(for value: Double, in totalHeight: CGFloat) -> CGFloat {
        let maxValue = data.map { $0.amount }.max() ?? 1
        return CGFloat(value / maxValue) * (totalHeight - 30)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Models

struct CategorySpending: Identifiable {
    let id: String
    let name: String
    let amount: Double
    let color: Color
}

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

enum TimeRange {
    case week
    case month
    case year
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
                .environmentObject(ExpenseViewModel())
                .environmentObject(BudgetViewModel())
        }
    }
}
