//
//  Classification+CoreDataProperties.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 15/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//
//

import Foundation
import CoreData


extension Classification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Classification> {
        return NSFetchRequest<Classification>(entityName: "Classification")
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var thumbnail: NSData?
    @NSManaged public var matches: NSSet?
    @NSManaged public var photo: Photo?

}

// MARK: Generated accessors for matches
extension Classification {

    @objc(addMatchesObject:)
    @NSManaged public func addToMatches(_ value: Match)

    @objc(removeMatchesObject:)
    @NSManaged public func removeFromMatches(_ value: Match)

    @objc(addMatches:)
    @NSManaged public func addToMatches(_ values: NSSet)

    @objc(removeMatches:)
    @NSManaged public func removeFromMatches(_ values: NSSet)

}
