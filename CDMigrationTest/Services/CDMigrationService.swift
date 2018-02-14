//
//  CDMigrationService.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 09.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import UIKit
import CoreData

final class CDMigrationService: NSObject {
    
    private let managedObjectModel: NSManagedObjectModel!
    
    static func isMigrationNeeded(for mom: NSManagedObjectModel, sourceUrl: URL) -> Bool {
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                                at: sourceUrl,
                                                                                                options: nil) else {
                                                                                                    return false
        }
        
        return !mom.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata)
    }

    
    init(mom: NSManagedObjectModel) {
        managedObjectModel = mom
    }
    

    func isMigrationNeeded(at: URL) -> Bool {
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                                at: at,
                                                                                                options: nil) else {
                                                                                                    return false
        }
        
        return !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata)
    }
    
    @discardableResult
    func performMigration(at sourceUrl: URL) -> Bool {
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                                at: sourceUrl,
                                                                                                options: nil) else {
                                                                                                    print("\(#function) failed to get existing store metadata")
                                                                                                    return false
        }
        
        guard !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) else {
            print("\(#function) all migration steps are passed")
            return true
        }
        
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: sourceMetadata) else {
            print("\(#function) failed to get source model")
            return false
        }
        
        var allVersions: [String] = []
        let momdPaths = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil)
        for p in momdPaths {
            allVersions.append(contentsOf: Bundle.main.paths(forResourcesOfType: "mom", inDirectory: (p as NSString).lastPathComponent))
        }
        
        var mapping: NSMappingModel!
        var destinationModel: NSManagedObjectModel!
        var modelName: String!
        for p in allVersions {
            guard mapping == nil else {
                break
            }
            
            destinationModel = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: p))
            mapping = NSMappingModel(from: nil,
                                     forSourceModel: sourceModel,
                                     destinationModel: destinationModel)
            
            modelName = ((p as NSString).lastPathComponent as NSString).deletingPathExtension
        }
        
        guard mapping != nil, destinationModel != nil else {
            print("\(#function) failed to find mapping or create destination model\nmapping: \(mapping), dModel: \(destinationModel)")
            return false
        }
        
        print("\(#function) will migrate from: \(sourceModel) to: \(destinationModel)")
        
        let fileExtension: String = (sourceUrl.path as NSString).pathExtension
        let destinationName = "\(modelName!)" + "." + fileExtension
        let destinationPath = ((sourceUrl.path as NSString).deletingLastPathComponent as NSString).appendingPathComponent(destinationName)
        let destinationUrl = URL(fileURLWithPath: destinationPath)
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        
        var success = true
        do {
            try manager.migrateStore(from: sourceUrl,
                                     sourceType: NSSQLiteStoreType,
                                     options: nil,
                                     with: mapping,
                                     toDestinationURL: destinationUrl,
                                     destinationType: NSSQLiteStoreType,
                                     destinationOptions: nil)
        } catch {
            success = false
            print("\(#function) failed to migrate: \(error)")
        }
        
        guard success else {
            return success
        }
        
        let fm = FileManager.default
        try? fm.removeItem(at: sourceUrl)
        try? fm.moveItem(at: destinationUrl, to: sourceUrl)
        
        return performMigration(at: sourceUrl)
    }
    
}
