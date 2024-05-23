//
//  DocumentStorageConfiguration.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 26/07/23.
//

import Foundation
import CoreData
import UIKit

public class CoreDataManager {


    public static let shared = CoreDataManager()
    //3.
    var fetchedDocuemnts:[Documents] = []
    let identifier: String  = "com.ScanflowDocumentCapture"//Your framework bundle ID
    let model: String       = "Documents"//Model name

    lazy var persistentContainer: NSPersistentContainer = {
        //5
        let messageKitBundle = Bundle(identifier: self.identifier)
        let modelURL = messageKitBundle!.url(forResource: self.model, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)

        // 6.
        let container = NSPersistentContainer(name: self.model, managedObjectModel: managedObjectModel!)
        container.loadPersistentStores { (storeDescription, error) in

            if let err = error{
                fatalError("❌ Loading of store failed:\(err)")
            }
        }

        return container
    }()


    public func createDocument(name: String, Data: Data, date: Date, jpegSize: String, pngSize: String, pdfSize: String) {

        let context = persistentContainer.viewContext
        let contact = NSEntityDescription.insertNewObject(forEntityName: "Documents", into: context) as! Documents
        let id = getNewDocumentId()
        print(id)

        contact.name = name
        contact.fileData  = Data
        contact.createdAt = date
        contact.pdfSize = pdfSize
        contact.jpgSize = jpegSize
        contact.pngSize = pngSize
        contact.id = id

        do {
            try context.save()
            print("✅ Document saved succesfuly")

        } catch let error {
            print("❌ Failed to create Person: \(error.localizedDescription)")
        }
    }

    private func getNewDocumentId() -> Int16 {
        if let documents = fetch() {

            return Int16(documents.count)
        } else {
            return 1
        }
    }

    public func fetch(documentID: Int? = nil) -> [Documents]? {

        let context = persistentContainer.viewContext
        var fetchRequest = NSFetchRequest<Documents>(entityName: "Documents")
        if documentID != nil {
            fetchRequest.predicate = NSPredicate(
                format: "id LIKE %@", "\(documentID!)"
            )
        }
        do{

            let documents = try context.fetch(fetchRequest)
            return documents

        } catch let fetchErr {
            print("❌ Failed to fetch Person:",fetchErr)
            return nil
        }
    }

    public func deleteDocument(id: Int) {

        // Assuming you have a managed object context
        let context: NSManagedObjectContext = persistentContainer.viewContext // Initialize your managed object context

        // Create a fetch request to retrieve the object you want to delete
        let fetchRequest: NSFetchRequest<Documents> = NSFetchRequest<Documents>(entityName: "Documents")
        fetchRequest.predicate = NSPredicate(format: "id LIKE %@", "\(id)")

        do {
            // Execute the fetch request
            let fetchedObjects = try context.fetch(fetchRequest)

            if let objectToDelete = fetchedObjects.first {
                // Delete the object from the context
                context.delete(objectToDelete)

                // Save the context to persist the deletion
                try context.save()

                print("Object deleted successfully")
            } else {
                print("Object not found")
            }
        } catch {
            print("Error deleting object: \(error.localizedDescription)")
        }

    }

    public func updateDocuemnt(id: Int, imagedata: Data? = nil, fileName: String? = nil, pdfSize: String?, jpgSize: String?, pngSize: String?) {

        // Assuming you have a managed object context
        let context: NSManagedObjectContext = persistentContainer.viewContext // Initialize your managed object context

        // Create a fetch request to retrieve the object you want to update
        let fetchRequest: NSFetchRequest<Documents> = NSFetchRequest<Documents>(entityName: "Documents")
        fetchRequest.predicate = NSPredicate(format: "id LIKE %@", "\(id)")

        do {
            // Execute the fetch request
            let fetchedObjects = try context.fetch(fetchRequest)

            if let objectToUpdate = fetchedObjects.first {
                // Modify the object's attributes
                objectToUpdate.id = Int16(id)
                if let data = imagedata {
                    objectToUpdate.fileData = imagedata
                }
                objectToUpdate.createdAt = Date()
                if let name = fileName {
                    objectToUpdate.name = name

                }
                if let pdf = pdfSize {
                    objectToUpdate.pdfSize = pdf
                }
                if let png = pngSize {
                    objectToUpdate.pngSize = png
                }
                if let jpg = jpgSize {
                    objectToUpdate.jpgSize = jpg
                }
                
                // Save the context to persist changes
                try context.save()

                print("Object updated successfully")
            } else {
                print("Object not found")
            }
        } catch {
            print("Error updating object: \(error.localizedDescription)")
        }

    }

    func coreDataObjectFromImages(images: [UIImage]) -> Data? {
        var dataArray: [Data] = []

        for img in images {
            if let data = img.pngData() {
                dataArray.append(data)
            }
        }
        var dataThings: Data?
        do {
            dataThings = try? NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: false)
        } catch {
            print("Localization erro done: \(error.localizedDescription)")
        }
        return dataThings
    }

    func imagesFromCoreData(object: Data?) -> [UIImage]? {
        var retVal:[UIImage] = []

        guard let object = object else { return nil }
        if let dataArray = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: object) {
            for data in dataArray {
                if let data = data as? Data, let image = UIImage(data: data) {
                    retVal.append(image)
                }
            }
        }
        return retVal
    }

}
