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
			return
		}
		
		textureLoader = MTKTextureLoader(device: device)
		
		DispatchQueue.global().async {
			self.network = PillRecogNet(device: self.device)
			
			DispatchQueue.main.async {
				self.spinner.stopAnimating()
				self.statusLabel.text = "Rete Neurale Pronta!"
				self.takePictureButton.isEnabled = true
				self.buttonStateChanged()
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
	}
	
	@IBAction func doneButtonPressed(_ segue: UIStoryboardSegue) {
		print("Done button pressed!")
	}

	@IBAction func takePhotoPressed(_ sender: UIButton) {
		print("Take photo button pressed!")
	}

}
