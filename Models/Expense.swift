import Foundation
import FirebaseFirestore

struct Expense: Identifiable, Codable {
    var id: String
    var amount: Double
    var description: String
    var date: Date
    var categoryId: String
    var spenderId: String
    var createdAt: Date
    var updatedAt: Date
    
    // Optional fields
    var location: String?
    var receiptImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case description
        case date
        case categoryId
        case spenderId
        case createdAt
        case updatedAt
        case location
        case receiptImageURL
    }
    
    init(id: String = UUID().uuidString,
         amount: Double,
         description: String,
         date: Date,
         categoryId: String,
         spenderId: String,
         location: String? = nil,
         receiptImageURL: String? = nil) {
        self.id = id
        self.amount = amount
        self.description = description
        self.date = date
        self.categoryId = categoryId
        self.spenderId = spenderId
        self.location = location
        self.receiptImageURL = receiptImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "amount": amount,
            "description": description,
            "date": Timestamp(date: date),
            "categoryId": categoryId,
            "spenderId": spenderId,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let location = location {
            dict["location"] = location
        }
        
        if let receiptImageURL = receiptImageURL {
            dict["receiptImageURL"] = receiptImageURL
        }
        
        return dict
    }
    
    // Create from Firestore document
    static func fromFirestore(document: DocumentSnapshot) -> Expense? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let amount = data["amount"] as? Double,
              let description = data["description"] as? String,
              let dateTimestamp = data["date"] as? Timestamp,
              let categoryId = data["categoryId"] as? String,
              let spenderId = data["spenderId"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        var expense = Expense(
            id: id,
            amount: amount,
            description: description,
            date: dateTimestamp.dateValue(),
            categoryId: categoryId,
            spenderId: spenderId
        )
        
        expense.createdAt = createdAtTimestamp.dateValue()
        expense.updatedAt = updatedAtTimestamp.dateValue()
        expense.location = data["location"] as? String
        expense.receiptImageURL = data["receiptImageURL"] as? String
        
        return expense
    }
}
