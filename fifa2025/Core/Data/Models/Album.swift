import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let worldCupCard = UTType(exportedAs: "femcoding.fifa2025.worldcupcard")
}

struct WorldCupCard: Identifiable, Codable, Transferable {
    let id: UUID
    let title: String
    let subtitle: String
    let hostCountry: String
    let imageName: String
    let cardType: CardType
    let rarity: CardRarity
    var isOwned: Bool
    var duplicateCount: Int
    
    enum CardType: String, Codable {
        case stadium = "Estadio"
        case country = "País"
        
        var icon: String {
            switch self {
            case .stadium: return "building.2.fill"
            case .country: return "flag.fill"
            }
        }
    }
    
    enum CardRarity: String, Codable {
        case common = "Común"
        case rare = "Raro"
        case epic = "Épico"
        case legendary = "Legendario"
        
        var color: Color {
            switch self {
            case .common: return Color.gray
            case .rare: return Color.blue
            case .epic: return Color.purple
            case .legendary: return Color(hex: "#B1E902")
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .common:
                return LinearGradient(colors: [.gray.opacity(0.8), .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .rare:
                return LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .epic:
                return LinearGradient(colors: [.purple.opacity(0.8), .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .legendary:
                return LinearGradient(colors: [Color(hex: "#B1E902").opacity(0.8), Color(hex: "#B1E902")], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .worldCupCard)
    }

}
