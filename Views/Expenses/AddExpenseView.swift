import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var amount = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var selectedCategoryId = ""
    @State private var selectedSpenderId = ""
    @State private var location = ""
    @State private var showingCategoryPicker = false
    @State private var showingSpenderPicker = false
    @State private var showingDatePicker = false
    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // For demo purposes, we'll use the current user as the spender
    // In a real app, we would fetch household members
    private var spenders: [User] {
        if let currentUser = FirebaseService.shared.currentUser {
            return [currentUser]
        }
        return []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("€")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $amount)
                            .font(.title)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
                    )
                }
                .padding(.horizontal)
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("What did you spend on?", text: $description)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
                        )
                }
                .padding(.horizontal)
                
                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack {
                            if let category = categoryViewModel.categories.first(where: { $0.id == selectedCategoryId }) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 20, height: 20)
                                
                                Text(category.name)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select a category")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
                        )
                    }
                }
                .padding(.horizontal)
                
                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Text(dateFormatter.string(from: date))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
                        )
                    }
                }
                .padding(.horizontal)
                
                // Spender picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spender")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingSpenderPicker = true
                    }) {
                        HStack {
                            if let spender = spenders.first(where: { $0.id == selectedSpenderId }) {
                                Text(spender.name)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select a spender")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
                        )
                    }
                }
                .padding(.horizontal)
                
                // Location field (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location (Optional)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Where did you spend?", text: $location)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("TextFieldBackground", default: Color(.systemGray6)))
                        )
                }
                .padding(.horizontal)
                
                // Save button
                Button(action: {
                    saveExpense()
                }) {
                    Text("Save Expense")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .padding()
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategoryId: $selectedCategoryId, categories: categoryViewModel.categories)
        }
        .sheet(isPresented: $showingSpenderPicker) {
            SpenderPickerView(selectedSpenderId: $selectedSpenderId, spenders: spenders)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $date)
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Set default values
            if selectedCategoryId.isEmpty && !categoryViewModel.categories.isEmpty {
                selectedCategoryId = categoryViewModel.categories[0].id
            }
            
            if selectedSpenderId.isEmpty && !spenders.isEmpty {
                selectedSpenderId = spenders[0].id
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              amountValue > 0,
              !description.isEmpty,
              !selectedCategoryId.isEmpty,
              !selectedSpenderId.isEmpty else {
            return false
        }
        
        return true
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            showAlert(title: "Invalid Amount", message: "Please enter a valid amount.")
            return
        }
        
        Task {
            do {
                await expenseViewModel.addExpense(
                    amount: amountValue,
                    description: description,
                    date: date,
                    categoryId: selectedCategoryId,
                    spenderId: selectedSpenderId,
                    location: location.isEmpty ? nil : location
                )
                
                // Reset form
                DispatchQueue.main.async {
                    self.amount = ""
                    self.description = ""
                    self.date = Date()
                    self.location = ""
                    
                    // Show success message
                    self.showAlert(title: "Success", message: "Expense added successfully.")
                }
            } catch {
                showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isShowingAlert = true
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Supporting Views

struct CategoryPickerView: View {
    @Binding var selectedCategoryId: String
    let categories: [Category]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button(action: {
                        selectedCategoryId = category.id
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 20, height: 20)
                            
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
            .navigationTitle("Select Category")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SpenderPickerView: View {
    @Binding var selectedSpenderId: String
    let spenders: [User]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(spenders) { spender in
                    Button(action: {
                        selectedSpenderId = spender.id
                        presentationMode.wrappedValue.dismiss()
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
            .navigationTitle("Select Spender")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
            .environmentObject(ExpenseViewModel())
            .environmentObject(CategoryViewModel())
    }
}
