//
//  Classification+CoreDataProperties.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 03/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//
//

import Foundation
import CoreData


extension Classification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Classification> {
        return NSFetchRequest<Classification>(entityName: "Classification")
    }

    @NSManaged public var best5Matches: NSObject?
    @NSManaged public var classificationID: Int64
    @NSManaged public var date: NSDate?
    @NSManaged public var sentToRemote: Bool
    @NSManaged public var thumbnail: NSData?
    @NSManaged public var photo: Photo?
	@NSManaged public var overriddenLabel: String?

}
