//
//  DatabaseManager.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/12.
//

import UIKit
import CoreData

@objcMembers
final class DatabaseManager: NSObject {

    // MARK: - Singleton
    static let shared = DatabaseManager()
    class func sharedInstance() -> DatabaseManager { shared }

    // MARK: - Core Data context access
    /// 嘗試從 AppDelegate 取得 `managedObjectContext`，
    /// 若沒有則回退讀取 `persistentContainer.viewContext`
    dynamic var managedObjectContext: NSManagedObjectContext? {
        // 1) Objective-C 專案舊寫法：AppDelegate.managedObjectContext
        if let delegate = UIApplication.shared.delegate as? NSObject,
           delegate.responds(to: #selector(getter: self.managedObjectContext)),
           let ctx = delegate.value(forKey: "managedObjectContext") as? NSManagedObjectContext {
            return ctx
        }

        // 2) 新寫法：AppDelegate.persistentContainer.viewContext
        if let delegate = UIApplication.shared.delegate as? NSObject,
           delegate.responds(to: Selector(("persistentContainer"))),
           let container = delegate.value(forKey: "persistentContainer") as? NSPersistentContainer {
            return container.viewContext
        }

        // 3) 取不到就回傳 nil（呼叫端需處理）
        return nil
    }

    // MARK: - CRUD
    /// 對應 ObjC: - (void)insertWithName:(NSString *)name withScore:(int)score;
    func insert(withName name: String, withScore score: Int32) {
        guard let context = managedObjectContext else {
            print("DatabaseManager: managedObjectContext unavailable.")
            return
        }

        let entityName = "Entity" // 對應你 Core Data model 的 entity 名稱
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? NSManagedObject else {
            return
        }

        obj.setValue(name, forKey: "name")
        obj.setValue(NSNumber(value: score), forKey: "score")

        do {
            try context.save()
        } catch {
            print("Whoops, couldn't save: \(error.localizedDescription)")
        }
    }

    /// 對應 ObjC: - (NSArray *)load;
    func load() -> [NSManagedObject] {
        guard let context = managedObjectContext else {
            print("DatabaseManager: managedObjectContext unavailable.")
            return []
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Entity")
        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error.localizedDescription)")
            return []
        }
    }
}
