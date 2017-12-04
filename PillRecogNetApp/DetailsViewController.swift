//
//  DetailsViewController.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 14/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController {
	
	var coreDataStack: CoreDataStack!
	var classification: Classification!
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var classificationLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var infoTextView: UITextView!
	
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
	}

}
