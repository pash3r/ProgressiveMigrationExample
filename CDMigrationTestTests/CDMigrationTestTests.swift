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
    
    var helper: GeneralHelper!
    
    override func setUp() {
        super.setUp()
        
        helper = GeneralHelper()
        helper.initialSetup()
        
        startMigration()
        
        helper.recreatePersistentStoreCoordinator()
    }
    
    override func tearDown() {
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
            for p in files {
                try? fm.removeItem(atPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(p))
            }
        }
        
        super.tearDown()
    }
    
    
    func testDatabaseInNotEmpty() {
        let result = fetchAllData()
        XCTAssertTrue(result.count > 0, "data disappeared")
    }
    
    func testEntityHasText() {
        let result = fetchAllData()
        XCTAssert(result.count > 0, "data disappeared")
        for e in result {
            guard let t = e.text else {
                XCTFail("text is empty!")
                break
            }
            
            XCTAssertFalse((t.text ?? "").isEmpty, "text is empty")
        }
    }
    
    func testCreatedDateIsNotNil() {
        let result = fetchAllData()
        XCTAssert(result.count > 0, "data disappeared")
        for e in result {
            XCTAssertNotNil(e.createdDate, "createdDate is nil")
        }
    }
    
    // MARK: - Helpers
    
    func startMigration() {
        let momdUrl: URL = Bundle.main.url(forResource: "CDMigrationTest", withExtension: "momd")!
        let mom: NSManagedObjectModel = NSManagedObjectModel(contentsOf: momdUrl)!
        
        let ms = CDMigrationService(mom: mom)
        ms.performMigration(at: helper.sourceUrl)
    }
    
    func fetchAllData() -> [SimpleEntity] {
        let fr = NSFetchRequest<SimpleEntity>(entityName: String(describing: SimpleEntity.self))
        return (try? helper.managedObjectContext.fetch(fr)) ?? []
    }
        
}
