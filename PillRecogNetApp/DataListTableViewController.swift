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
	
	lazy var dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .short
		formatter.locale = Locale.current
		return formatter
	}()
	
	lazy var numberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .percent
		formatter.minimumFractionDigits = 2
		formatter.maximumFractionDigits = 2
		return formatter
	}()
	
	// Initialize controller to retrieve classifications from Core Data
	private lazy var frc: NSFetchedResultsController<Classification> = {
		let fetchRequest: NSFetchRequest<Classification> = NSFetchRequest(entityName: "Classification")
		fetchRequest.fetchBatchSize = 20
		
		let dateSortDesc = NSSortDescriptor(key: #keyPath(Classification.date), ascending: true)
		fetchRequest.sortDescriptors = [dateSortDesc]
		
		let context = coreDataStack.mainContext
		let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		frc.delegate = self
		return frc
	}()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.title = "Classificazioni"
		
		self.navigationController?.navigationBar.barStyle = .black
		tableView.rowHeight = 90.0
		tableView.register(ClassificationTableViewCell.self, forCellReuseIdentifier: "PillPhotoCellIdentification")
		
		do {
			try frc.performFetch()
		} catch {
			let alertController = UIAlertController.errorAlertWith(message: "Si è verificato un errore durante il caricamento dei dati. Riprovare.")
			self.present(alertController, animated: true, completion: nil)
		}
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ClassificationDetailsSegue" {
			if let indexPath = tableView.indexPathForSelectedRow, let destination = segue.destination as? DetailsViewController {
				let classification = frc.object(at: indexPath)
				destination.classification = classification
				destination.coreDataStack = coreDataStack
			} else {
				let alertController = UIAlertController.errorAlertWith(message: "Si è verificato un errore durante il caricamento dei dati. Impossibile visualizzare i dettagli.")
				self.present(alertController, animated: true, completion: nil)
			}
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func dismiss(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

}

// TableView management code
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
		let cell = tableView.dequeueReusableCell(withIdentifier: "PillPhotoCellIdentifier", for: indexPath) as! ClassificationTableViewCell
		configure(cell: cell, for: indexPath)
		return cell
	}
	
	func configure(cell: ClassificationTableViewCell, for indexPath: IndexPath) {
		let classification = frc.object(at: indexPath)
		
		let sortDescriptor = NSSortDescriptor(key: #keyPath(Match.probability), ascending: false)
		let sortedMatches = classification.matches?.sortedArray(using: [sortDescriptor]) as! [Match]
		let probNumber = NSNumber(value: sortedMatches[0].probability)
		cell.classificationLabel.text = "\(sortedMatches[0].label ?? "") (\(numberFormatter.string(from: probNumber) ?? "0.0"))"
		
		if let date = classification.date as Date? {
			cell.dateLabel?.text = dateFormatter.string(from: date)
		}
		
		if let thumbData = classification.thumbnail as Data?, let thumb = UIImage(data: thumbData) {
			cell.thumbnailImageView.image = thumb
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "ClassificationDetailsSegue", sender: self)
	}
}

// Fetched Results Controller delegate methods
extension DataListTableViewController: NSFetchedResultsControllerDelegate {
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		print(#function)
		switch (type) {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
		case .update:
			if let cell = tableView.cellForRow(at: indexPath!) as? ClassificationTableViewCell {
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
