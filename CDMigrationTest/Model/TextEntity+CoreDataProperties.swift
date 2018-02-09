//
//  TextEntity+CoreDataProperties.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 09.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//
//

import Foundation
import CoreData


extension TextEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextEntity> {
        return NSFetchRequest<TextEntity>(entityName: "TextEntity")
    }

    @NSManaged public var text: String?
    @NSManaged public var simpleEntity: SimpleEntity?

}
