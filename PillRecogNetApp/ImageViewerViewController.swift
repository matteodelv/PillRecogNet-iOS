//
//  ImageViewerViewController.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 14/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit

class ImageViewerViewController: UIViewController, UIScrollViewDelegate {
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var scrollView: UIScrollView!
	var pillImageData: NSData?

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.title = "Foto Scattata"
		
		// Allows photo to be zoomed with double tap on it
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(zoom))
		tapRecognizer.numberOfTapsRequired = 2
		scrollView.addGestureRecognizer(tapRecognizer)
		
		// Load image data and show it
		if let imageData = pillImageData as Data? {
			let image = UIImage(data: imageData)
			imageView.image = image
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	// Zoom the image
	@objc func zoom(sender: UITapGestureRecognizer) {
		if scrollView.zoomScale <= 1.5 {
			scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
		} else {
			scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
		}
	}

}
