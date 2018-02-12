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
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        return self.createPsc(with: self.managedObjectModel)
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
        
        let migrationManager: CDMigrationService = CDMigrationService(mom: managedObjectModel)
        
        guard !migrationManager.isMigrationNeeded(at: sourceUrl) else {
            if !migrationManager.performMigration(at: sourceUrl) {
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
    
    func createPsc(with mom: NSManagedObjectModel) -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("\(momName).sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        let pragmasOption: String = CDMigrationService.isMigrationNeeded(for: managedObjectModel, sourceUrl: sourceUrl) ? "DELETE" : "WAL"
        let options: [AnyHashable : Any] = [
            NSInferMappingModelAutomaticallyOption : true,
            NSSQLitePragmasOption : ["journal_mode" : pragmasOption]
        ]
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
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
    }
    
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
        
}
