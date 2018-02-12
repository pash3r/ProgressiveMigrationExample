//
//  CDMigrationTestTests.swift
//  CDMigrationTestTests
//
//  Created by Pavel Tikhonov on 09.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import XCTest
import CoreData

@testable import CDMigrationTest

class CDMigrationTestTests: XCTestCase {
    
    var managedObjectModel: NSManagedObjectModel!
    var managedObjectContext: NSManagedObjectContext!
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    var sourceUrl: URL {
        return URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appending("CDMigrationTest.sqlite"))
    }
    
    
    override func setUp() {
        super.setUp()
        
        setupInitialDatabase()
        startMigration()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
            for p in files {
                try? fm.removeItem(atPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(p))
            }
        }
        
        super.tearDown()
    }
    
    
    func testDatabaseInNotEmpty() {
        let fr = NSFetchRequest<SimpleEntity>(entityName: String(describing: SimpleEntity.self))
        let result = (try? managedObjectContext.fetch(fr)) ?? []
        XCTAssertTrue(result.count > 0, "data disappeared")
    }
    
    func testEntityHasText() {
        let fr = NSFetchRequest<SimpleEntity>(entityName: String(describing: SimpleEntity.self))
        let result = (try? managedObjectContext.fetch(fr)) ?? []
        XCTAssert(result.count > 0, "data disappeared")
        for e in result {
            guard let text = e.someText else {
                XCTAssert(true, "text is nil")
                break
            }
            
            XCTAssert(!text.isEmpty, "text is empty")
        }
    }
    
    
    func setupInitialDatabase() {
        try? FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "CDMigrationTest-old", ofType: "sqlite")!, toPath: sourceUrl.path)
        
        managedObjectModel = NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: try! NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceUrl, options: nil))
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        var success = true
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                              configurationName: nil,
                                                              at: sourceUrl,
                                                              options: [NSSQLitePragmasOption : ["journal_mode" : "DELETE"]])
        } catch {
            success = false
            print("\(#function) failed with error: \(error)")
        }

        guard success else {
            return
        }
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        addRandomObjects()
    }
    
    func addRandomObjects() {
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
    
    func startMigration() {
        let momdUrl: URL = Bundle.main.url(forResource: "CDMigrationTest", withExtension: "momd")!
        let mom: NSManagedObjectModel = NSManagedObjectModel(contentsOf: momdUrl)!
        
        let ms = CDMigrationService(mom: mom)
        ms.performMigration(at: sourceUrl)
    }
        
}
