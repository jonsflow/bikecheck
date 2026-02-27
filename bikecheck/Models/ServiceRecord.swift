import Foundation
import CoreData

public class ServiceRecord: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var isReset: Bool
    @NSManaged public var note: String?
    @NSManaged public var serviceInterval: ServiceInterval?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        date = Date()
    }
}
