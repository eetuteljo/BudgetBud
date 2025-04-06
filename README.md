# BudgetBuddy - iOS Budget Tracking App

BudgetBuddy is a comprehensive budget tracking application for iOS that helps households manage their finances together. The app allows two people in the same household to track expenses, set budgets, and visualize spending patterns.

## Features

- **User Authentication**: Secure sign-in and account creation
- **Household Management**: Create or join a household to share financial data
- **Expense Tracking**: Add, edit, and categorize expenses with details like date, category, and spender
- **Custom Categories**: Create and manage custom expense categories with colors and icons
- **Budget Management**: Set monthly budgets with different allocation strategies
  - Equal distribution across categories
  - 50/30/20 rule (needs, wants, savings)
  - Custom allocation
- **Data Visualization**: View spending patterns through pie charts and bar graphs
- **Real-time Synchronization**: All data syncs across devices in real-time
- **Offline Support**: Continue using the app without an internet connection

## Technical Details

### Architecture

- **Frontend**: SwiftUI for modern, declarative UI
- **Backend**: Firebase (Firestore, Authentication)
- **State Management**: MVVM architecture with ObservableObject view models
- **Data Persistence**: Firestore with offline capabilities
- **Authentication**: Firebase Authentication

### Project Structure

```
BudgetBuddy/
├── Models/             # Data models
│   ├── User.swift      # User and household models
│   ├── Expense.swift   # Expense model
│   ├── Category.swift  # Category model
│   └── Budget.swift    # Budget and allocation models
├── Services/           # Firebase services
│   ├── FirebaseService.swift    # Base Firebase service
│   ├── ExpenseService.swift     # Expense operations
│   ├── CategoryService.swift    # Category operations
│   └── BudgetService.swift      # Budget operations
├── ViewModels/         # Business logic
│   ├── AuthViewModel.swift      # Authentication logic
│   ├── ExpenseViewModel.swift   # Expense management
│   ├── CategoryViewModel.swift  # Category management
│   └── BudgetViewModel.swift    # Budget management
└── Views/              # UI components
    ├── Auth/           # Authentication screens
    ├── Dashboard/      # Main dashboard
    ├── Expenses/       # Expense entry and listing
    ├── Budget/         # Budget management
    └── Settings/       # App settings
```

## Setup Instructions

### Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later
- Firebase account

### Firebase Setup

1. Create a new Firebase project at [firebase.google.com](https://firebase.google.com)
2. Add an iOS app to your Firebase project
3. Download the `GoogleService-Info.plist` file
4. Add the file to your Xcode project
5. Enable Authentication with Email/Password
6. Create a Firestore database with appropriate security rules

### Installation

1. Clone the repository
2. Open the project in Xcode
3. Add the `GoogleService-Info.plist` file to the project
4. Install dependencies using Swift Package Manager
5. Build and run the app

## Usage

### First-time Setup

1. Create an account or sign in
2. Create a new household or join an existing one with an invite code
3. Start tracking expenses and setting budgets

### Adding Expenses

1. Navigate to the "Add" tab
2. Enter expense details (amount, description, category, date, spender)
3. Save the expense

### Managing Budgets

1. Navigate to the "Budget" tab
2. Create a new budget if none exists
3. Choose a budget allocation strategy
4. Monitor your spending against the budget

### Viewing Reports

1. Navigate to the "Dashboard" tab
2. View spending by category and over time
3. Use filters to analyze specific time periods or categories

## Security

- All data is stored securely in Firebase Firestore
- Authentication is handled by Firebase Authentication
- Data is only accessible to members of the same household
- Firestore security rules restrict access to authorized users only

## Future Enhancements

- Currency conversion for international users
- Recurring expense tracking
- Export functionality for reports
- Dark mode support
- Additional budget templates
- Receipt scanning using camera

## License

This project is licensed under the MIT License - see the LICENSE file for details.
