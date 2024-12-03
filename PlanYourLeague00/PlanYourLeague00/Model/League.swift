//
//  League.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 8/29/24.
//
import Foundation
import CoreData

public class League: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<League> {
        return NSFetchRequest<League>(entityName: "League")
    }
    
    @NSManaged public var name: String
    @NSManaged public var teamCount: Int

}
