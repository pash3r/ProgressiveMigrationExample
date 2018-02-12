//
//  GeneralHelper.swift
//  CDMigrationTestTests
//
//  Created by Pavel Tikhonov on 12.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import UIKit
import CoreData

@testable import CDMigrationTest

final class GeneralHelper: NSObject {
    
    var managedObjectModel: NSManagedObjectModel!
    var managedObjectContext: NSManagedObjectContext!
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    var momName: String {
        return "CDMigrationTest"
    }
    
    var sourceUrl: URL {
        return URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appending("\(momName).sqlite"))
    }
    
    
    func initialSetup() {
        try? FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "CDMigrationTest-old", ofType: "sqlite")!, toPath: sourceUrl.path)
        
        managedObjectModel = NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: try! NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceUrl, options: nil))
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        guard addPersistentStore(option: "DELETE") else {
            return
        }
        
        managedObjectContext = createManagedObjectContext(with: persistentStoreCoordinator)
        addRandomObjects()
    }
    
    func recreatePersistentStoreCoordinator() {
        managedObjectModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: momName, withExtension: "momd")!)
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        guard addPersistentStore(option: "WAL") else {
            return
        }
        
        managedObjectContext = createManagedObjectContext(with: persistentStoreCoordinator)
    }
    
    
    // MARK: - Private stuff
    
    private func addRandomObjects() {
        for i in 0...5 {
            let obj: SimpleEntity = NSEntityDescription.insertNewObject(forEntityName: String(describing: SimpleEntity.self), into: self.managedObjectContext) as! SimpleEntity
            
            obj.myId = Int16(i)
            obj.someBool = arc4random_uniform(UInt32(2)) == 1
            obj.someText = "rnd text \(i)"
        }
        
        guard self.managedObjectContext.hasChanges else {
            return
        }
        
        do {
            try self.managedObjectContext.save()
        } catch _ {
            self.managedObjectContext.rollback()
        }
    }
    
    private func createManagedObjectContext(with psc: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = psc
        
        return moc
    }
    
    private func addPersistentStore(option: String) -> Bool {
        var success = true
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                              configurationName: nil,
                                                              at: sourceUrl,
                                                              options: [NSSQLitePragmasOption : ["journal_mode" : option]])
        } catch {
            success = false
            print("\(#function) failed with error: \(error)")
        }
        
        return success
    }

}
