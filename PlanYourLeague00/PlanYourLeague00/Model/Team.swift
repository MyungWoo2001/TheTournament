//
//  Team.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 8/26/24.
//

import Foundation

//struct Team: Hashable {
//    var name: String
//    var point: Int
//    var rank: Int
//    var logoImage: String
//    
//    init(name: String, point: Int, rank: Int, logoImage: String) {
//        self.name = name
//        self.point = point
//        self.rank = rank
//        self.logoImage = logoImage
//    }
//    
//    init(){
//        self.init(name: "", point: 0, rank: 0, logoImage: "")
//    }
//}

import CoreData

public class Team: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        return NSFetchRequest<Team>(entityName: "Team")
    }
    
    @NSManaged public var teamID: String
    @NSManaged public var recordID: String
    @NSManaged public var rank: Int
    @NSManaged public var name: String
    @NSManaged public var pls: Int
    @NSManaged public var goals: Int
    @NSManaged public var dif: Int
    @NSManaged public var point: Int
    @NSManaged public var logoImage: Data

}
