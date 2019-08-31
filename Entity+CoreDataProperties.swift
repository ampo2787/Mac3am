//
//  Entity+CoreDataProperties.swift
//  
//
//  Created by 박지훈 on 25/08/2019.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var name: String?
    @NSManaged public var skip: Int32
    @NSManaged public var emotion: String?

}
