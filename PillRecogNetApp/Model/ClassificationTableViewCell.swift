//
//  ClassificationTableViewCell.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 06/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit

class ClassificationTableViewCell: UITableViewCell {
	
	@IBOutlet weak var classificationLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var thumbnailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
		
		self.accessoryType = .disclosureIndicator
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
