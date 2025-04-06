import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var expenseViewModel = ExpenseViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @StateObject private var categoryViewModel = CategoryViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                DashboardView()
                    .environmentObject(expenseViewModel)
                    .environmentObject(budgetViewModel)
                    .navigationTitle("Dashboard")
                    .navigationBarItems(trailing: profileButton)
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.pie.fill")
            }
            .tag(0)
            
            // Add Expense Tab
            NavigationView {
                AddExpenseView()
                    .environmentObject(expenseViewModel)
                    .environmentObject(categoryViewModel)
                    .navigationTitle("Add Expense")
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .tag(1)
            
            // History Tab
            NavigationView {
                ExpenseListView()
                    .environmentObject(expenseViewModel)
                    .environmentObject(categoryViewModel)
                    .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(2)
            
            // Budget Tab
            NavigationView {
                BudgetView()
                    .environmentObject(budgetViewModel)
                    .environmentObject(categoryViewModel)
                    .navigationTitle("Budget")
            }
            .tabItem {
                Label("Budget", systemImage: "dollarsign.circle.fill")
            }
            .tag(3)
            
            // Settings Tab
            NavigationView {
                SettingsView()
                    .environmentObject(authViewModel)
                    .environmentObject(categoryViewModel)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .accentColor(.accentColor)
    }
    
    private var profileButton: some View {
        Menu {
            Button(action: {
                // Show profile
            }) {
                Label("Profile", systemImage: "person")
            }
            
            Button(action: {
                authViewModel.signOut()
            }) {
                Label("Sign Out", systemImage: "arrow.right.square")
            }
        } label: {
            Image(systemName: "person.circle")
                .font(.title2)
        }
    }
}

// Placeholder views - these will be implemented in separate files
struct DashboardView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        Text("Dashboard View - To be implemented")
    }
}

struct AddExpenseView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    var body: some View {
        Text("Add Expense View - To be implemented")
    }
}

struct ExpenseListView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    var body: some View {
        Text("Expense List View - To be implemented")
    }
}

struct BudgetView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    var body: some View {
        Text("Budget View - To be implemented")
    }
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    var body: some View {
        Text("Settings View - To be implemented")
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}
