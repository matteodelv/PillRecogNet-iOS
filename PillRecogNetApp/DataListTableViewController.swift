//
//  DataListTableViewController.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 17/10/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import CoreData

class DataListTableViewController: UITableViewController {
	
	var coreDataStack: CoreDataStack!
	
	private lazy var frc: NSFetchedResultsController<Classification> = {
		let fetchRequest: NSFetchRequest<Classification> = NSFetchRequest(entityName: "Classification")
		fetchRequest.fetchBatchSize = 20
		
		let dateSortDesc = NSSortDescriptor(key: #keyPath(Classification.date), ascending: true)
		fetchRequest.sortDescriptors = [dateSortDesc]
		
		let context = coreDataStack.mainContext
		let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "classificationsCache")
		frc.delegate = self
		return frc
	}()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationController?.navigationBar.barStyle = .black
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DataListTableViewController {
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		guard let sections = frc.sections else { return 0 }
		return sections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sectionInfo = frc.sections?[section] else { return 0 }
		return sectionInfo.numberOfObjects
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "PillPhotoCellIdentifier", for: indexPath)
		configure(cell: cell, for: indexPath)
		return cell
	}
	
	func configure(cell: UITableViewCell, for indexPath: IndexPath) {
		
	}
}

extension DataListTableViewController: NSFetchedResultsControllerDelegate {
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		
		switch (type) {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
		case .update:
			if let cell = tableView.cellForRow(at: indexPath!) {
				configure(cell: cell, for: indexPath!)
			}
		case .move:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		
		switch (type) {
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
		default: break
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
}
