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
import AVFoundation
import CoreImage

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
				self.checkCameraAuthStatus(onSuccess: {
					self.updateUIAppearance(message: "Rete Neurale Pronta!", blocking: false)
				}, onFailure: {
					self.updateUIAppearance(message: "Non è possibile utilizzare la fotocamera. Controllare che sia stata concessa l'autorizzazione all'applicazione.", blocking: true)
					self.spinner.stopAnimating()
				})
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
	
	@IBAction func doneButtonPressed(_ segue: UIStoryboardSegue) {
		print("Done button pressed!")
	}

	@IBAction func takePhotoPressed(_ sender: UIButton) {
//		predictExampleImage()
		presentImagePicker()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "managementSegue" {
			if let navController = segue.destination as? UINavigationController, let managementVC = navController.topViewController as? DataListTableViewController {
				managementVC.coreDataStack = coreDataStack
			}
		}
	}

}

private extension TakePhotoViewController {
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
			spinner.startAnimating()
		} else {
			takePictureButton.isEnabled = true
			spinner.stopAnimating()
		}
		buttonStateChanged()
	}
	
	func checkCameraAuthStatus(onSuccess: @escaping () -> (), onFailure: @escaping () -> ()) {
		guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
			onFailure()
			return
		}
		
		let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
		
		switch (authStatus) {
		case .authorized:
			DispatchQueue.main.async { onSuccess() }
		case .denied, .restricted:
			DispatchQueue.main.async { onFailure() }
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
				if granted {
					DispatchQueue.main.async { onSuccess() }
				} else {
					DispatchQueue.main.async { onFailure() }
				}
			})
		}
	}
	
	func presentImagePicker() {
		checkCameraAuthStatus(onSuccess: {
			let cameraPicker = UIImagePickerController()
			cameraPicker.delegate = self
			cameraPicker.sourceType = UIImagePickerControllerSourceType.camera
			cameraPicker.allowsEditing = true
			self.present(cameraPicker, animated: true, completion: nil)
		}, onFailure: {
			self.updateUIAppearance(message: "Non è possibile utilizzare la fotocamera. Controllare che sia stata concessa l'autorizzazione all'applicazione.", blocking: false)
		})
	}
	
	func predictExampleImage() {
		updateUIAppearance(message: "Elaborando...", blocking: true)
		
		if let imageURL = Bundle.main.url(forResource: "neurontin-6367", withExtension: "JPG"), let photoTaken = UIImage(named: "neurontin-6367.JPG") {
			do {
				var coreGraphicPhoto = photoTaken.cgImage
				if coreGraphicPhoto == nil {
					var coreImagePhoto = photoTaken.ciImage
					if coreImagePhoto == nil {
						coreImagePhoto = CIImage(image: photoTaken)
					}

					let coreImageContext = CIContext.init(mtlDevice: device)
					coreGraphicPhoto = coreImageContext.createCGImage(coreImagePhoto!, from: coreImagePhoto!.extent)
				}
//				let texture = try textureLoader.newTexture(URL: imageURL, options: [MTKTextureLoader.Option.SRGB: NSNumber(value: false)])
				let texture = try textureLoader.newTexture(cgImage: coreGraphicPhoto!, options: [MTKTextureLoader.Option.SRGB: NSNumber(value: false)])
				
				thumbnailImageView.image = prepareThumbnailFrom(image: photoTaken)
				
				DispatchQueue.global().async {
					let metalImage = MPSImage(texture: texture, featureChannels: 3)
					let predictions = self.network.classify(pill: metalImage)
					
					DispatchQueue.main.async {
						self.updateUIAppearance(message: "Rete Neurale Pronta!", blocking: false)
						self.show(classifications: predictions)
					}
				}
			} catch {
				print(error)
				updateUIAppearance(message: "Errore nella classificazione. Riprovare", blocking: false)
			}
		}
	}
	
	func show(classifications: [PillMatch]) {
		print(classifications)
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
		let size = CGSize(width: 250.0, height: 250.0)
		let scale: CGFloat = 0.0
		
		UIGraphicsBeginImageContextWithOptions(size, true, scale)
		image.draw(in: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size))
		let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return thumbnail
	}
}

extension TakePhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.navigationController?.dismiss(animated: true)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		
		updateUIAppearance(message: "Elaborando...", blocking: true)
		
		let photoTaken = info[UIImagePickerControllerEditedImage] as! UIImage
		
		var coreGraphicPhoto = photoTaken.cgImage
		if coreGraphicPhoto == nil {
			var coreImagePhoto = photoTaken.ciImage
			if coreImagePhoto == nil {
				coreImagePhoto = CIImage(image: photoTaken)
			}
			
			let coreImageContext = CIContext.init(mtlDevice: device)
			coreGraphicPhoto = coreImageContext.createCGImage(coreImagePhoto!, from: coreImagePhoto!.extent)
		}
		
		do {
//			let texture = try textureLoader.newTexture(data: UIImageJPEGRepresentation(photoTaken, 1.0)!, options: [MTKTextureLoader.Option.SRGB: NSNumber(value: false)])
			let texture = try textureLoader.newTexture(cgImage: coreGraphicPhoto!, options: [MTKTextureLoader.Option.SRGB: NSNumber(value: false)])
			
			let thumb = prepareThumbnailFrom(image: photoTaken)
			thumbnailImageView.image = thumb
			
			DispatchQueue.global().async {
				let metalImage = MPSImage(texture: texture, featureChannels: 3)
				let predictions = self.network.classify(pill: metalImage)
				
				
				DispatchQueue.main.async {
					self.save(predictions: predictions, for: photoTaken, thumb: thumb)
					self.updateUIAppearance(message: "Rete Neurale Pronta!", blocking: false)
					self.show(classifications: predictions)	// TODO: change this to try core data saving and loading
				}
			}
		} catch {
			print(error)
			updateUIAppearance(message: "Errore nella classificazione. Riprovare.", blocking: false)
		}
		
		dismiss(animated: true, completion: nil)
	}
}

extension TakePhotoViewController {
	
	func save(predictions: [PillMatch], for image: UIImage, thumb: UIImage?) {
		let context = coreDataStack.childContext
		
		let classification = Classification(context: context)
		classification.date = Date() as NSDate
		classification.overriddenLabel = nil
		
		var thumbData: Data?
		if thumb == nil, let t = prepareThumbnailFrom(image: image) {
			thumbData = UIImageJPEGRepresentation(t, 1.0)
		} else if let t = thumb {
			thumbData = UIImageJPEGRepresentation(t, 1.0)
		}
		classification.thumbnail = thumbData as NSData?
		
		let original = Photo(context: context)
		original.originalPhoto = UIImageJPEGRepresentation(image, 1.0) as NSData?
		classification.photo = original
		
		for prediction in predictions {
			let match = Match(context: context)
			match.label = prediction.label
			match.probability = prediction.probability
			classification.addToMatches(match)
		}
		
		coreDataStack.save(usingChildContext: true, onSuccess: nil) { (error) in
			DispatchQueue.main.async {
				let alertController = UIAlertController.errorAlertWith(message: "Si è verificato un errore durante il salvataggio della classificazione!")
				self.present(alertController, animated: true, completion: nil)
				context.rollback()
			}
		}
		
//		coreDataStack.save(usingChildContext: true, onSuccess: {
//			DispatchQueue.main.async {
//				let alertController = UIAlertController.errorAlertWith(message: "OK :D")
//				self.present(alertController, animated: true, completion: nil)
////				context.rollback()
//			}
//		}, onError: { (error) in
//
//		})
	}
}

