//
//  CoreDataStack.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 03/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import Foundation
import CoreData

// Custom closures to execute code when saving
public typealias CoreDataStackSaveSuccessBlock = (() -> Void)?
public typealias CoreDataStackSaveErrorBlock = ((Error) -> Void)?


class CoreDataStack {
	
	fileprivate var modelName:String
	
	lazy var storeContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: self.modelName)
		container.loadPersistentStores { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Impossibile inizializzare Core Data per la gestione dei dati... Uscita...")
			}
		}
		return container
	}()
	
	// Intended to be used for retrieving the data
	lazy var mainContext: NSManagedObjectContext = {
		return self.storeContainer.viewContext
	}()
	
	// Intende to be used for writing and updating the database
	lazy var childContext: NSManagedObjectContext = {
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = self.mainContext
		return context
	}()
	
	init(modelName: String) {
		self.modelName = modelName
	}
	
	func save(usingChildContext: Bool, onSuccess: CoreDataStackSaveSuccessBlock = nil, onError: CoreDataStackSaveErrorBlock = nil) {
		
		if usingChildContext {
			guard childContext.hasChanges else { return }
			
			do {
				try childContext.obtainPermanentIDs(for: Array(childContext.insertedObjects))
				try childContext.save()
			} catch let error as NSError {
				if let errorBlock = onError {
					errorBlock(error)
					return
				} else {
					fatalError("Errore non gestito durante il salvataggio: \(error)")
				}
			}
		}
		
		guard mainContext.hasChanges else { return }
		
		mainContext.performAndWait {
			do {
				try self.mainContext.save()
				
				if let successBlock = onSuccess {
					successBlock()
				}
			} catch let error as NSError {
				if let errorBlock = onError {
					errorBlock(error)
				} else {
					fatalError("Errore non gestito durante il salvataggio: \(error)")
				}
			}
		}
	}
}
