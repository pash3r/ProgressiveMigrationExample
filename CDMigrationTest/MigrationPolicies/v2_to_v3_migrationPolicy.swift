//
//  v2_to_v3_migrationPolicy.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 09.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import UIKit
import CoreData

class v2_to_v3_migrationPolicy: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let sKeys = (sInstance.entity.attributesByName as NSDictionary).allKeys as! [String]
        let sValues = sInstance.dictionaryWithValues(forKeys: sKeys)
        
        let dInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!,
                                                            into: manager.destinationContext)
        
        let dKeys = (dInstance.entity.attributesByName as NSDictionary).allKeys as! [String]
        for k in dKeys {
            guard k != "text" else {
                continue
            }
            
            guard let v = sValues[k] else {
                continue
            }
            
            dInstance.setValue(v, forKey: k)
        }
        
        if let t = sInstance.value(forKey: "someText") {
            let textObject = NSEntityDescription.insertNewObject(forEntityName: "TextEntity", into: manager.destinationContext)
            textObject.setValue(t, forKey: "text")
            
            dInstance.setValue(textObject, forKey: "text")
        }
        
        manager.associate(sourceInstance: sInstance, withDestinationInstance: dInstance, for: mapping)
    }
    
//    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
//        let fr = NSFetchRequest<SimpleEntity>(entityName: "SimpleEntity")
//        fr.predicate = NSPredicate(format: "objectId == %@", dInstance.objectID)
//
//        guard let oldInstance = try? manager.sourceContext.fetch(fr).first else {
//            print("\(#function) failed to load oldInstance")
//            return
//        }
//
//        let textObject = NSEntityDescription.insertNewObject(forEntityName: "TextEntity", into: manager.destinationContext)
//        textObject.setValue(oldInstance?.value(forKey: "someText"), forKey: "text")
//
//        dInstance.setValue(textObject, forKey: "text")
//    }

}
