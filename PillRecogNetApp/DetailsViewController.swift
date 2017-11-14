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
	@IBOutlet var overrideButton: UIButton!
	
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
		
		overrideButton.layer.cornerRadius = 10.0
		
		imageView.isUserInteractionEnabled = true
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
		imageView.addGestureRecognizer(tapRecognizer)
		
		populateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func overrideButtonTapped(_ sender: UIButton) {
		
	}
	
	func populateUI() {
		let sortDescriptor = NSSortDescriptor(key: #keyPath(Match.probability), ascending: false)
		let sortedMatches = classification.matches?.sortedArray(using: [sortDescriptor]) as! [Match]
		
		if let overridden = classification.overriddenLabel, overridden.count > 0 {
			classificationLabel.text = "\(overridden) (Manuale)"
		} else {
			let probNumber = NSNumber(value: sortedMatches[0].probability)
			classificationLabel.text = "\(sortedMatches[0].label ?? "") (\(numberFormatter.string(from: probNumber) ?? "0.0"))"
		}
		
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
		print("pressed!")
		self.performSegue(withIdentifier: "ImageViewerFromDetailsSegue", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ImageViewerFromDetailsSegue", let destination = segue.destination as? ImageViewerViewController {
			destination.pillImageData = classification.photo?.originalPhoto
		}
	}

}
