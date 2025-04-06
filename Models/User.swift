import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var householdId: String?
    var createdAt: Date
    var updatedAt: Date
    var profileImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case householdId
        case createdAt
        case updatedAt
        case profileImageURL
    }
    
    init(id: String,
         name: String,
         email: String,
         householdId: String? = nil,
         profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.householdId = householdId
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let householdId = householdId {
            dict["householdId"] = householdId
        }
        
        if let profileImageURL = profileImageURL {
            dict["profileImageURL"] = profileImageURL
        }
        
        return dict
    }
    
    // Create from Firestore document
    static func fromFirestore(document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let name = data["name"] as? String,
              let email = data["email"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        var user = User(
            id: id,
            name: name,
            email: email,
            householdId: data["householdId"] as? String,
            profileImageURL: data["profileImageURL"] as? String
        )
        
        user.createdAt = createdAtTimestamp.dateValue()
        user.updatedAt = updatedAtTimestamp.dateValue()
        
        return user
    }
}

// Household model
struct Household: Identifiable, Codable {
    var id: String
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var createdBy: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case updatedAt
        case createdBy
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         createdBy: String) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    // Create from Firestore document
    static func fromFirestore(document: DocumentSnapshot) -> Household? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let name = data["name"] as? String,
              let createdBy = data["createdBy"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        var household = Household(
            id: id,
            name: name,
            createdBy: createdBy
        )
        
        household.createdAt = createdAtTimestamp.dateValue()
        household.updatedAt = updatedAtTimestamp.dateValue()
        
        return household
    }
}
