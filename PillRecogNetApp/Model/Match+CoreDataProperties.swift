//
//  Match+CoreDataProperties.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 08/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//
//

import Foundation
import CoreData


extension Match {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Match> {
        return NSFetchRequest<Match>(entityName: "Match")
    }

    @NSManaged public var label: String?
    @NSManaged public var probability: Float
    @NSManaged public var classification: Classification?

}
