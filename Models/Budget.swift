import Foundation
import FirebaseFirestore

struct Budget: Identifiable, Codable {
    var id: String
    var totalAmount: Double
    var startDate: Date
    var endDate: Date
    var period: BudgetPeriod
    var createdAt: Date
    var updatedAt: Date
    var categoryAllocations: [CategoryBudget]
    
    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount
        case startDate
        case endDate
        case period
        case createdAt
        case updatedAt
        case categoryAllocations
    }
    
    init(id: String = UUID().uuidString,
         totalAmount: Double,
         startDate: Date,
         endDate: Date,
         period: BudgetPeriod = .monthly,
         categoryAllocations: [CategoryBudget] = []) {
        self.id = id
        self.totalAmount = totalAmount
        self.startDate = startDate
        self.endDate = endDate
        self.period = period
        self.categoryAllocations = categoryAllocations
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        return [
            "totalAmount": totalAmount,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "period": period.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    // Create from Firestore document
    static func fromFirestore(document: DocumentSnapshot, withAllocations allocations: [CategoryBudget] = []) -> Budget? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let totalAmount = data["totalAmount"] as? Double,
              let startDateTimestamp = data["startDate"] as? Timestamp,
              let endDateTimestamp = data["endDate"] as? Timestamp,
              let periodString = data["period"] as? String,
              let period = BudgetPeriod(rawValue: periodString),
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        var budget = Budget(
            id: id,
            totalAmount: totalAmount,
            startDate: startDateTimestamp.dateValue(),
            endDate: endDateTimestamp.dateValue(),
            period: period,
            categoryAllocations: allocations
        )
        
        budget.createdAt = createdAtTimestamp.dateValue()
        budget.updatedAt = updatedAtTimestamp.dateValue()
        
        return budget
    }
}

// Budget period enum
enum BudgetPeriod: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

// Category budget allocation
struct CategoryBudget: Identifiable, Codable {
    var id: String
    var categoryId: String
    var amount: Double
    var isPercentage: Bool
    var percentage: Double?
    var rolloverEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId
        case amount
        case isPercentage
        case percentage
        case rolloverEnabled
    }
    
    init(id: String = UUID().uuidString,
         categoryId: String,
         amount: Double,
         isPercentage: Bool = false,
         percentage: Double? = nil,
         rolloverEnabled: Bool = false) {
        self.id = id
        self.categoryId = categoryId
        self.amount = amount
        self.isPercentage = isPercentage
        self.percentage = percentage
        self.rolloverEnabled = rolloverEnabled
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "categoryId": categoryId,
            "amount": amount,
            "isPercentage": isPercentage,
            "rolloverEnabled": rolloverEnabled
        ]
        
        if let percentage = percentage {
            dict["percentage"] = percentage
        }
        
        return dict
    }
    
    // Create from Firestore document
    static func fromFirestore(document: DocumentSnapshot) -> CategoryBudget? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let categoryId = data["categoryId"] as? String,
              let amount = data["amount"] as? Double,
              let isPercentage = data["isPercentage"] as? Bool,
              let rolloverEnabled = data["rolloverEnabled"] as? Bool else {
            return nil
        }
        
        return CategoryBudget(
            id: id,
            categoryId: categoryId,
            amount: amount,
            isPercentage: isPercentage,
            percentage: data["percentage"] as? Double,
            rolloverEnabled: rolloverEnabled
        )
    }
}
