//
//  v1_to_v2_migrationPolicy.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 08.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import UIKit
import CoreData

final class v1_to_v2_migrationPolicy: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let sKeys = (sInstance.entity.attributesByName as NSDictionary).allKeys as! [String]
        let sValues = sInstance.dictionaryWithValues(forKeys: sKeys) as NSDictionary
        
        let dInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)
        let dKeys = (dInstance.entity.attributesByName as NSDictionary).allKeys as! [String]
        
        for k in dKeys {
            guard let val = sValues.value(forKey: k) else {
                continue
            }
            
            dInstance.setValue(val, forKey: k)
        }
        
        dInstance.setValue(Date(), forKey: "createdDate")
        
        manager.associate(sourceInstance: sInstance,
                          withDestinationInstance: dInstance,
                          for: mapping)
    }

}
