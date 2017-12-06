//
//  ReminderTableViewController.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 06/12/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import UserNotifications

class ReminderTableViewController: UITableViewController {
	
	var currentClassification: Classification!
	@IBOutlet weak var datePicker: UIDatePicker!
	lazy var dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .short
		formatter.locale = Locale.current
		return formatter
	}()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.title = "Imposta Promemoria"
		
		tableView.estimatedRowHeight = 44.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		datePicker.date = Date()
		datePicker.locale = Locale.current
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Salva", style: .done, target: self, action: #selector(setReminder))
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
			cell.detailTextLabel?.text = dateFormatter.string(from: datePicker.date)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func datePickerValueChanged(sender: UIDatePicker) {
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
			cell.detailTextLabel?.text = dateFormatter.string(from: datePicker.date)
		}
	}
	
	@objc func setReminder() {
		UNUserNotificationCenter.current().getNotificationSettings { (settings) in
			if settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .denied {
				DispatchQueue.main.async {
					let alert = UIAlertController.errorAlertWith(message: "L'applicazione non dispone delle necessarie autorizzazioni per impostare le notifiche. Controlla nelle Impostazioni.")
					self.present(alert, animated: true, completion: nil)
				}
			} else {
				DispatchQueue.main.async {
				let identifier = self.currentClassification.objectID.uriRepresentation().absoluteString
				let center = UNUserNotificationCenter.current()
				center.removeDeliveredNotifications(withIdentifiers: [identifier])
				center.removePendingNotificationRequests(withIdentifiers: [identifier])
				
				var repeating = false
				if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RepeatingCell {
					repeating = cell.repeatingSwitch.isOn
				}
				
				var dateComponents:DateComponents
				if repeating {
					dateComponents = Calendar.current.dateComponents([.hour, .minute], from: self.datePicker.date)
				} else {
					dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: self.datePicker.date)
				}
				
				let sortDescriptor = NSSortDescriptor(key: #keyPath(Match.probability), ascending: false)
				let sortedMatches = self.currentClassification.matches?.sortedArray(using: [sortDescriptor]) as! [Match]
				
				let content = UNMutableNotificationContent()
				content.title = "Medicinale da Assumere!"
				content.sound = UNNotificationSound.default()
				content.body = "Ricordati che devi assumere \(sortedMatches[0].label ?? "un medicinale")... Provvedi il prima possibile!"
				content.userInfo = ["ClassificationID": identifier]
				content.categoryIdentifier = "PillNotificationCategory"
				
				let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeating)
				let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
				
				center.add(request, withCompletionHandler: { (error) in
					if error != nil {
						DispatchQueue.main.async {
							let alert = UIAlertController.errorAlertWith(message: "Si è verificato un errore durante l'impostazione del promemoria. Riprovare.")
							self.present(alert, animated: true, completion: nil)
						}
					} else {
						self.dismiss(animated: true, completion: nil)
					}
				})
				}
			}
		}
	}

}
