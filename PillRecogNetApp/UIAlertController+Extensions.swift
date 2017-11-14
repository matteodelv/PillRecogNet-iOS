//
//  UIAlertController+Extensions.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 05/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit

extension UIAlertController {
	
	class func errorAlertWith(message: String?) -> UIAlertController {
		
		let alertController = UIAlertController(title: "Attentione", message: message, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Annulla", style: .cancel)
		alertController.addAction(cancelAction)
		return alertController
	}
}
