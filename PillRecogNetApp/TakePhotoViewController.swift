//
//  ViewController.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 17/10/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import CoreData
import MetalKit
import MetalPerformanceShaders

class TakePhotoViewController: UIViewController {
	
	var coreDataStack: CoreDataStack!
	private var device: MTLDevice!
	private var textureLoader: MTKTextureLoader!
	private var network: PillRecogNet!
	
	@IBOutlet var takePictureButton: UIButton!
	@IBOutlet var statusLabel: UILabel!
	@IBOutlet var spinner: UIActivityIndicatorView!
	@IBOutlet var thumbnailImageView: UIImageView!
	@IBOutlet var bestMatchLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var classificationsTextView: UITextView!
	
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
		
		self.navigationController?.navigationBar.barStyle = .black // To set status bar style
		spinner.startAnimating()
		bestMatchLabel.text = nil
		dateLabel.text = nil
		statusLabel.text = "Caricamento Rete Neurale..."
		takePictureButton.layer.cornerRadius = 10.0
		takePictureButton.isEnabled = false
		
		device = MTLCreateSystemDefaultDevice()
		guard MPSSupportsMTLDevice(device) else {
			self.present(UIAlertController.errorAlertWith(message: "Il dispositivo in uso non soddisfa i requisiti necessari per l'utilizzo dell'applicazione."), animated: true)
			statusLabel.text = "Rete Neurale non supportata!"
			spinner.stopAnimating()
			return
		}
		
		textureLoader = MTKTextureLoader(device: device)
		
		DispatchQueue.global().async {
			self.network = PillRecogNet(device: self.device)
			
			DispatchQueue.main.async {
				self.updateUIAppearance(message: "Rete Neurale Pronta!", blocking: false)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		buttonStateChanged()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func buttonStateChanged() {
		if takePictureButton.state == .disabled {
			takePictureButton.tintColor = UIColor(red: 90.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0)
		} else {
			takePictureButton.tintColor = UIColor(red: 205.0/255.0, green: 0.0, blue: 0.0, alpha: 1.0)
		}
		takePictureButton.setNeedsDisplay()
	}
	
	func updateUIAppearance(message: String, blocking: Bool) {
		statusLabel.text = message
		if blocking {
			takePictureButton.isEnabled = false
			statusLabel.textAlignment = .left
			spinner.startAnimating()
		} else {
			takePictureButton.isEnabled = true
			statusLabel.textAlignment = .center
			spinner.stopAnimating()
		}
		buttonStateChanged()
	}
	
	func predictExampleImage() {
		updateUIAppearance(message: "Elaborando...", blocking: true)
		
		if let imageURL = Bundle.main.url(forResource: "pipram-6476", withExtension: "JPG"), let image = UIImage(named: "pipram-6476.JPG") {
			do {
				let texture = try textureLoader.newTexture(URL: imageURL, options: [MTKTextureLoader.Option.SRGB: NSNumber(value: false)])
				
				thumbnailImageView.image = prepareThumbnailFrom(image: image)
				
				DispatchQueue.global().async {
					let metalImage = MPSImage(texture: texture, featureChannels: 3)
					let predictions = self.network.classify(pill: metalImage)
					
					DispatchQueue.main.async {
						self.updateUIAppearance(message: "Rete Neurale Pronta!", blocking: false)
						self.show(classifications: predictions)
					}
				}
			} catch {
				updateUIAppearance(message: "Errore nella classificazione", blocking: false)
			}
		}
	}
	
	func show(classifications: [PillMatch]) {
		dateLabel.text = dateFormatter.string(from: Date())
		// Handle overridden value
		let firstLabel = classifications.first?.label
		let firstProb = numberFormatter.string(from: NSNumber(value: classifications.first?.probability ?? 0.0))
		bestMatchLabel.text = "\(firstLabel ?? "") (\(firstProb ?? ""))"
		
		var allClassifications: String = ""
		for (i, classif) in classifications.enumerated() {
			let label = classif.label
			let probString = numberFormatter.string(from: NSNumber(value: classif.probability))
			allClassifications += "\(i+1)) \(label) (\(probString ?? ""))\n"
		}
		classificationsTextView.text = allClassifications
	}
	
	func prepareThumbnailFrom(image: UIImage) -> UIImage? {
		let size = CGSize(width: 90.0, height: 90.0)
		let scale: CGFloat = 0.0
		
		UIGraphicsBeginImageContextWithOptions(size, true, scale)
		image.draw(in: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size))
		let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return thumbnail
	}
	
	@IBAction func doneButtonPressed(_ segue: UIStoryboardSegue) {
		print("Done button pressed!")
	}

	@IBAction func takePhotoPressed(_ sender: UIButton) {
		print("Take photo button pressed!")
		
		predictExampleImage()
	}

}

