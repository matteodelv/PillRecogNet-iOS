//
//  Photo+CoreDataProperties.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 03/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var originalPhoto: NSData?
    @NSManaged public var photoID: Int64
    @NSManaged public var sentToRemote: Bool
    @NSManaged public var classification: Classification?

}
