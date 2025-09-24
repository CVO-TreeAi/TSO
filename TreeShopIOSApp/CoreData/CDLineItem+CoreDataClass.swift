import Foundation
import CoreData

@objc(CDLineItem)
public class CDLineItem: NSManagedObject {

}

extension CDLineItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDLineItem> {
        return NSFetchRequest<CDLineItem>(entityName: "LineItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var serviceType: String?
    @NSManaged public var quantity: Double
    @NSManaged public var unitPrice: Double
    @NSManaged public var totalPrice: Double
    @NSManaged public var itemDescription: String?
    @NSManaged public var treeHeight: Double
    @NSManaged public var treeDBH: Double
    @NSManaged public var treeCanopy: Double
    @NSManaged public var trimPercent: Double
    @NSManaged public var stumpDiameter: Double
    @NSManaged public var grindDepth: Double
    @NSManaged public var acres: Double
    @NSManaged public var maxDBH: Double
    @NSManaged public var complexityMultiplier: Double
    @NSManaged public var nearStructure: Bool
    @NSManaged public var powerLines: Bool
    @NSManaged public var slope: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var proposal: CDProposal?
}

extension CDLineItem : Identifiable {
    public var treeScore: Double {
        guard treeHeight > 0 && treeDBH > 0 else { return 0 }
        return treeHeight + (treeDBH * 2) + treeCanopy
    }

    public var summary: String {
        guard let serviceType = serviceType else { return "" }

        switch serviceType {
        case "Tree Removal":
            if treeHeight > 0 && treeDBH > 0 {
                return "\(Int(treeHeight))' tall, \(Int(treeDBH))\" diameter"
            }
            return "Tree removal"

        case "Tree Trimming":
            if trimPercent > 0 {
                return "\(Int(trimPercent))% trim"
            }
            return "Tree trimming"

        case "Stump Grinding":
            if stumpDiameter > 0 {
                return "\(Int(stumpDiameter))\" stump, \(Int(grindDepth))\" deep"
            }
            return "Stump grinding"

        case "Forestry Mulching":
            if acres > 0 {
                return "\(acres) acres, up to \(Int(maxDBH))\" trees"
            }
            return "Forestry mulching"

        default:
            return "\(quantity) units"
        }
    }
}