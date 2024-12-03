//
//  Tournament.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 11/11/24.
//

import Foundation
import CoreData

public class Tournament: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tournament> {
        return NSFetchRequest<Tournament>(entityName: "Tournament")
    }
    
    @NSManaged public var name: String
    @NSManaged public var shortName: String
    @NSManaged public var summary: String

    @NSManaged public var manager: String
    @NSManaged public var phone: String
    @NSManaged public var email: String
    
    @NSManaged public var accessPassword: String
    
    @NSManaged public var image: Data
}
