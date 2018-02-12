//
//  SimpleEntity+CoreDataProperties.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 09.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//
//

import Foundation
import CoreData


extension SimpleEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SimpleEntity> {
        return NSFetchRequest<SimpleEntity>(entityName: "SimpleEntity")
    }

    @NSManaged public var createdDate: NSDate?
    @NSManaged public var myId: Int16
    @NSManaged public var someBool: Bool
//    @NSManaged public var someText: String?
    @NSManaged public var text: TextEntity?

}
