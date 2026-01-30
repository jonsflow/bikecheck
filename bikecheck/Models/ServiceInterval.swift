//
//  ServiceInterval.swift
//  bikecheck
//
//  Created by clutchcoder on 1/14/24.
//

import Foundation
import CoreData

public class ServiceInterval: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var part: String
    @NSManaged public var lastServiceDate: Date?
    @NSManaged public var lastNotificationDate: Date?
    @NSManaged public var intervalTime: Double
    @NSManaged public var notify: Bool
    @NSManaged public var bikeId: String

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }

    /// Get the associated Bike from the Strava store
    public func getBike(from context: NSManagedObjectContext) -> Bike? {
        let fetchRequest = NSFetchRequest<Bike>(entityName: "Bike")
        fetchRequest.predicate = NSPredicate(format: "id == %@", bikeId)
        fetchRequest.fetchLimit = 1

        do {
            let bikes = try context.fetch(fetchRequest)
            return bikes.first
        } catch {
            print("Error fetching bike with id \(bikeId): \(error)")
            return nil
        }
    }
}
