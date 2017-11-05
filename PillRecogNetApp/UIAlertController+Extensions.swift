//
//  UIAlertController+Extensions.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 05/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit

extension UIAlertController {
	
	class func errorAlertWith(message: String?, isFatal: Bool = false) -> UIAlertController {
		
		let alertController = UIAlertController(title: "Attentione", message: message, preferredStyle: .alert)
		if isFatal {
			let quitAction = UIAlertAction(title: "Esci dall'App", style: .cancel, handler: { (action) in
				// Invocare exit() comporta un crash dell'app ma è l'unico modo per prevenire l'uso dell'app
				// ad esempio quando il dispositivo in uso non supporta i MPS
				exit(0)
			})
			alertController.addAction(quitAction)
		} else {
			let cancelAction = UIAlertAction(title: "Annulla", style: .cancel)
			alertController.addAction(cancelAction)
		}
		return alertController
	}
}
