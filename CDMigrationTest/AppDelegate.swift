//
//  AppDelegate.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 05.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cadiridris.coreDataTemplate" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: momName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    var momName: String {
        return "CDMigrationTest"
    }
    
    var sourceUrl: URL {
        return applicationDocumentsDirectory.appendingPathComponent(momName + ".sqlite")
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        setupCoreData()
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack
    
    func setupCoreData() {
        let rootController: UIViewController!
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard !isMigrationNeeded() else {
            if !performMigration() {
                rootController = storyboard.instantiateViewController(withIdentifier: "MainNavigationViewController")
                window?.rootViewController = rootController
                window?.makeKeyAndVisible()
                _ = persistentStoreCoordinator
            }
            
            return
        }
        
        rootController = storyboard.instantiateViewController(withIdentifier: "MainNavigationViewController")
        window?.rootViewController = rootController
        window?.makeKeyAndVisible()
        _ = persistentStoreCoordinator
    }
    
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("\(momName).sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
//        let options: [AnyHashable : Any] = [
//
//            NSMigratePersistentStoresAutomaticallyOption : true,
//            NSInferMappingModelAutomaticallyOption : true
//        ]
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - Migration stuff
    
    func isMigrationNeeded() -> Bool {
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                                at: sourceUrl,
                                                                                                options: nil) else {
                                                                                                    return false
        }
        
        return !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata)
    }

    func performMigration() -> Bool {
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                                at: sourceUrl,
                                                                                                options: nil) else {
                                                                                                    print("\(#function) failed to get existing store metadata")
                                                                                                    return false
        }
        
        guard !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) else {
            print("\(#function) all migration steps are passed")
            return false
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
        
        return performMigration()
    }
    
}
