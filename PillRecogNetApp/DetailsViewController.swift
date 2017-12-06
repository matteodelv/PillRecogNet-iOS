//
//  DetailsViewController.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 14/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class DetailsViewController: UIViewController {
	
	var coreDataStack: CoreDataStack!
	var classification: Classification!
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var classificationLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var infoTextView: UITextView!
	
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
	

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.title = "Dettagli"
		
		// Allows imageView to be tapped and to show original image
		imageView.isUserInteractionEnabled = true
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
		imageView.addGestureRecognizer(tapRecognizer)
		
		populateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// Shows all the information about a specific classification
	func populateUI() {
		let sortDescriptor = NSSortDescriptor(key: #keyPath(Match.probability), ascending: false)
		let sortedMatches = classification.matches?.sortedArray(using: [sortDescriptor]) as! [Match]
		
		let probNumber = NSNumber(value: sortedMatches[0].probability)
		classificationLabel.text = "\(sortedMatches[0].label ?? "") (\(numberFormatter.string(from: probNumber) ?? "0.0"))"
		
		if let date = classification.date as Date? {
			dateLabel.text = dateFormatter.string(from: date)
		}
		
		if let thumbData = classification.thumbnail as Data?, let thumb = UIImage(data: thumbData) {
			imageView.image = thumb
		}
		
		var allClassifications: String = ""
		for (i, classif) in sortedMatches.enumerated() {
			let label = classif.label
			let probString = numberFormatter.string(from: NSNumber(value: classif.probability))
			allClassifications += "\(i+1)) \(label ?? "") (\(probString ?? ""))\n"
		}
		infoTextView.text = allClassifications
	}
	
	@objc func imageViewTapped() {
		self.performSegue(withIdentifier: "ImageViewerFromDetailsSegue", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ImageViewerFromDetailsSegue", let destination = segue.destination as? ImageViewerViewController {
			destination.pillImageData = classification.photo?.originalPhoto
		}
		else if segue.identifier == "ReminderFromDetailsSegue", let destination = segue.destination as? ReminderTableViewController {
			destination.currentClassification = classification
			
		}
	}
	
	// Allows to send via email the results of a classification
	@IBAction func sendByEmail(sender: UIBarButtonItem) {
		let sortDescriptor = NSSortDescriptor(key: #keyPath(Match.probability), ascending: false)
		let sortedMatches = classification.matches?.sortedArray(using: [sortDescriptor]) as! [Match]
		
		let firstProbNumber = NSNumber(value: sortedMatches[0].probability)
		
		var message = "L'immagine allegata è stata riconosciuta come \"\(sortedMatches[0].label ?? "")\", con una probabilità pari al \(numberFormatter.string(from: firstProbNumber) ?? "0.0")\n"
		
		if let date = classification.date as Date? {
			message += "La classificazione è stata effettuata il \(dateFormatter.string(from: date))\n\n"
		}
		message += "In caso ci siano problemi con il riconoscimento, di seguito sono mostrate le possibili alternative che hanno registrato una probabilità maggiore:\n"
		
		let remaining = sortedMatches.dropFirst()
		for (i, classif) in remaining.enumerated() {
			let label = classif.label
			let prob = numberFormatter.string(from: NSNumber(value: classif.probability))
			message += "\(i+1)) \(label ?? "") (\(prob ?? "0.0"))\n"
		}
		message += "\n"
		
		if MFMailComposeViewController.canSendMail() {
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.setMessageBody(message, isHTML: false)
			mailVC.setSubject("Risultato classificazione medicinale")
			if let thumbData = classification.thumbnail as Data? {
				mailVC.addAttachmentData(thumbData, mimeType: "image/jpeg", fileName: "foto")
			}
			present(mailVC, animated: true, completion: nil)
		} else {
			let alert = UIAlertController.errorAlertWith(message: "Impossibile inviare la mail. Controlla che almeno un account email sia stato configurato.")
			present(alert, animated: true, completion: nil)
		}
	}
	
	@IBAction func setReminder(sender: UIBarButtonItem) {
		print(#function)
	}

}

// Mail Compose VC delegate
extension DetailsViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		dismiss(animated: true, completion: nil)
	}
}
