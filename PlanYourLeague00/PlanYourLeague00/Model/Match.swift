//
//  Match.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/5/24.
//

import Foundation
import CoreData

public class Match: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Match> {
        return NSFetchRequest<Match>(entityName: "Match")
    }
    
    @NSManaged var recordID: String
    @NSManaged var leagueName: String
    @NSManaged var index: Int
    @NSManaged var date: String
    @NSManaged var round: Int
    @NSManaged var summary: String
    @NSManaged var team1RecordID: String
    @NSManaged var team1ID: String
    @NSManaged var team1Goal: String
    @NSManaged var team2RecordID: String
    @NSManaged var team2ID: String
    @NSManaged var team2Goal: String
    
    @NSManaged var team1: Team
    @NSManaged var team2: Team
    
    
}
