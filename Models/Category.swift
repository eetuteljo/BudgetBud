import Foundation
import FirebaseFirestore
import SwiftUI

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var colorHex: String
    var icon: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorHex
        case icon
        case isArchived
        case createdAt
        case updatedAt
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         colorHex: String = "#007AFF",
         icon: String = "tag",
         isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isArchived = isArchived
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Get color from hex string
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "colorHex": colorHex,
            "icon": icon,
            "isArchived": isArchived,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    // Create from Firestore document
    static func fromFirestore(document: DocumentSnapshot) -> Category? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let name = data["name"] as? String,
              let colorHex = data["colorHex"] as? String,
              let icon = data["icon"] as? String,
              let isArchived = data["isArchived"] as? Bool,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        var category = Category(
            id: id,
            name: name,
            colorHex: colorHex,
            icon: icon,
            isArchived: isArchived
        )
        
        category.createdAt = createdAtTimestamp.dateValue()
        category.updatedAt = updatedAtTimestamp.dateValue()
        
        return category
    }
}

// Default categories
extension Category {
    static let defaultCategories: [Category] = [
        Category(name: "Groceries", colorHex: "#4CD964", icon: "cart"),
        Category(name: "Dining", colorHex: "#FF9500", icon: "fork.knife"),
        Category(name: "Transportation", colorHex: "#007AFF", icon: "car"),
        Category(name: "Housing", colorHex: "#5856D6", icon: "house"),
        Category(name: "Utilities", colorHex: "#FF2D55", icon: "bolt"),
        Category(name: "Entertainment", colorHex: "#AF52DE", icon: "tv"),
        Category(name: "Shopping", colorHex: "#FF3B30", icon: "bag"),
        Category(name: "Health", colorHex: "#34C759", icon: "heart"),
        Category(name: "Personal", colorHex: "#5AC8FA", icon: "person"),
        Category(name: "Other", colorHex: "#8E8E93", icon: "ellipsis")
    ]
}

// Color extension to create from hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
