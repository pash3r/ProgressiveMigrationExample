//
//  ViewController.swift
//  CDMigrationTest
//
//  Created by Pavel Tikhonov on 05.02.18.
//  Copyright © 2018 Pavel Tikhonov. All rights reserved.
//

import UIKit
import CoreData

let cellIdentifier = "DefaultCell"

class ViewController: UIViewController {

    var dataSource: [SimpleEntity] = []
    
    var moc: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    }
    
    @IBOutlet weak var tableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        let fr: NSFetchRequest<SimpleEntity> = NSFetchRequest(entityName: String(describing: SimpleEntity.self))
        dataSource = (try? moc.fetch(fr)) ?? []
        dataSource.sort(by: { $0.myId < $1.myId })
        tableView.reloadData()
    }
    
    @IBAction func addBtnTapped() {
        guard let obj = createAndSaveObject(with: (getLastId() + 1)) else {
            return
        }
        
        dataSource.append(obj)
        tableView.reloadData()
    }
    
    func getLastId() -> Int {
        guard dataSource.count > 0 else {
            return 0
        }
        
        return Int(dataSource.last!.myId)
    }
    
    func createAndSaveObject(with id: Int) -> SimpleEntity? {
        let obj: SimpleEntity = NSEntityDescription.insertNewObject(forEntityName: String(describing: SimpleEntity.self),
                                                                    into: moc) as! SimpleEntity
        obj.myId = Int16(id)
        obj.someText = "random text" + "\(id)"
        obj.someBool = arc4random_uniform(UInt32(2)) == 1 ? true : false
        
        guard moc.hasChanges else {
            print("has no changes; nothing to save")
            return nil
        }
        
        var success = true
        do {
            try self.moc.save()
        } catch {
            success = false
            print("failed to save moc: \(error)")
        }
        
        guard success else {
            return nil
        }
        
        print("moc did save")
        return obj
    }

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row].someText
        
        return cell
    }
    
}
