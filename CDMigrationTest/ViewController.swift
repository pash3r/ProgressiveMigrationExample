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

        let fr: NSFetchRequest<SimpleEntity> = SimpleEntity.fetchRequest()
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
        let txtObj: TextEntity = create(obj: TextEntity.self) {
            $0.text = "rnd txt" + "\(id)"
        }
        
        let obj: SimpleEntity = create(obj: SimpleEntity.self) {
            $0.myId = Int16(id)
            $0.someText = "random text" + "\(id)"
            $0.someBool = arc4random_uniform(UInt32(2)) == 1 ? true : false
//            $0.createdDate = Date() as NSDate
//            $0.text = txtObj
        }
        
        
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
    
    func create<T: NSManagedObject>(obj: T.Type, configBlock: (T) -> Swift.Void) -> T {
        let obj: T = NSEntityDescription.insertNewObject(forEntityName: String(describing: obj),
                                                         into: moc) as! T
        configBlock(obj)
        
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
//        let obj = dataSource[indexPath.row]
//        cell.textLabel?.text = obj.text?.text
        
        return cell
    }
    
}
