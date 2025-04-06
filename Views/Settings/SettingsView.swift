import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    @State private var showingAddCategory = false
    @State private var showingEditCategory = false
    @State private var selectedCategory: Category?
    @State private var showingLogoutConfirmation = false
    @State private var showingHouseholdCode = false
    
    var body: some View {
        List {
            // Categories section
            Section(header: Text("Categories")) {
                ForEach(categoryViewModel.categories) { category in
                    Button(action: {
                        selectedCategory = category
                        showingEditCategory = true
                    }) {
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            
                            Text(category.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: {
                    showingAddCategory = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        
                        Text("Add Category")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // Household section
            if let user = authViewModel.currentUser, let householdId = user.householdId {
                Section(header: Text("Household")) {
                    Button(action: {
                        showingHouseholdCode = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.accentColor)
                            
                            Text("Invite Member")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Account section
            Section(header: Text("Account")) {
                if let user = authViewModel.currentUser {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(user.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    showingLogoutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square.fill")
                            .foregroundColor(.red)
                        
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // About section
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .sheet(isPresented: $showingAddCategory) {
            CategoryFormView(mode: .add, categoryViewModel: categoryViewModel)
        }
        .sheet(isPresented: $showingEditCategory) {
            if let category = selectedCategory {
                CategoryFormView(mode: .edit(category), categoryViewModel: categoryViewModel)
            }
        }
        .sheet(isPresented: $showingHouseholdCode) {
            if let user = authViewModel.currentUser, let householdId = user.householdId {
                HouseholdInviteView(householdId: householdId)
            }
        }
        .alert(isPresented: $showingLogoutConfirmation) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign Out")) {
                    authViewModel.signOut()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Supporting Views

struct CategoryFormView: View {
    enum Mode {
        case add
        case edit(Category)
    }
    
    let mode: Mode
    @ObservedObject var categoryViewModel: CategoryViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var selectedColorHex = "#007AFF"
    @State private var selectedIcon = "tag"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    
    private var isEditMode: Bool {
        switch mode {
        case .add: return false
        case .edit: return true
        }
    }
    
    private var category: Category? {
        switch mode {
        case .add: return nil
        case .edit(let category): return category
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name", text: $name)
                    
                    // Color picker
                    NavigationLink(destination: ColorPickerView(selectedColorHex: $selectedColorHex)) {
                        HStack {
                            Text("Color")
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color(hex: selectedColorHex) ?? .blue)
                                .frame(width: 20, height: 20)
                        }
                    }
                    
                    // Icon picker
                    NavigationLink(destination: IconPickerView(selectedIcon: $selectedIcon)) {
                        HStack {
                            Text("Icon")
                            
                            Spacer()
                            
                            Image(systemName: selectedIcon)
                                .foregroundColor(Color(hex: selectedColorHex) ?? .blue)
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
                    Button(action: saveCategory) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(isEditMode ? "Update Category" : "Add Category")
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
                
                if isEditMode {
                    Section {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Archive Category")
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Category" : "Add Category")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let category = category {
                    name = category.name
                    selectedColorHex = category.colorHex
                    selectedIcon = category.icon
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Archive Category"),
                    message: Text("Are you sure you want to archive this category? It will no longer appear in the active categories list, but existing expenses will still reference it."),
                    primaryButton: .destructive(Text("Archive")) {
                        archiveCategory()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty
    }
    
    private func saveCategory() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isEditMode, let existingCategory = category {
                    var updatedCategory = existingCategory
                    updatedCategory.name = name
                    updatedCategory.colorHex = selectedColorHex
                    updatedCategory.icon = selectedIcon
                    
                    await categoryViewModel.updateCategory(updatedCategory)
                } else {
                    await categoryViewModel.addCategory(
                        name: name,
                        colorHex: selectedColorHex,
                        icon: selectedIcon
                    )
                }
                
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
    
    private func archiveCategory() {
        guard let category = category else { return }
        
        isLoading = true
        
        Task {
            await categoryViewModel.archiveCategory(category)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ColorPickerView: View {
    @Binding var selectedColorHex: String
    @Environment(\.presentationMode) var presentationMode
    
    private let colorOptions = CategoryViewModel().getColorOptions()
    
    var body: some View {
        List {
            ForEach(colorOptions, id: \.hex) { colorOption in
                Button(action: {
                    selectedColorHex = colorOption.hex
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: colorOption.hex) ?? .blue)
                            .frame(width: 20, height: 20)
                        
                        Text(colorOption.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedColorHex == colorOption.hex {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Color")
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.presentationMode) var presentationMode
    
    private let iconOptions = CategoryViewModel().getIconOptions()
    
    var body: some View {
        List {
            ForEach(iconOptions, id: \.systemName) { iconOption in
                Button(action: {
                    selectedIcon = iconOption.systemName
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: iconOption.systemName)
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        
                        Text(iconOption.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedIcon == iconOption.systemName {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Icon")
    }
}

struct HouseholdInviteView: View {
    let householdId: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("Invite to Household")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Share this code with someone to invite them to join your household.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(householdId)
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            
            Button(action: {
                UIPasteboard.general.string = householdId
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Code")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .foregroundColor(.accentColor)
            }
            .padding()
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(AuthViewModel())
                .environmentObject(CategoryViewModel())
        }
    }
}
