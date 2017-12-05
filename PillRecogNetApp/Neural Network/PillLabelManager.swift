//
//  PillLabelManager.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 03/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import Foundation

// Convenient type to manage a classification with its probability
public typealias PillMatch = (label: String, probability: Float)

public class PillLabelManager {
	
	// Change this with the number of total classes the network has been trained on
	private static let labelCount = 12
	private var labels = [String](repeating: "", count: labelCount)
	
	init() {
		if let labelFile = Bundle.main.path(forResource: "pillLabels", ofType: "txt") {
			do {
				let content = try String(contentsOfFile: labelFile, encoding: .utf8)
				let rows = content.components(separatedBy: NSCharacterSet.newlines)
				
				// Generate classification labels from pillLabels.txt content
				// Each row should be in the format "index|label", with index starting from 0
				// The correspondence between index and label MUST be the same returned
				// when training or evaluating the network, to avoid mismatches
				for (i, row) in rows.enumerated() {
					if i < PillLabelManager.labelCount {
						self.labels[i] = row.components(separatedBy: "|")[1]
					}
				}
			} catch {
				fatalError("Errore durante il caricamento delle label!")
			}
		}
	}
	
	// Returns an array containing the best 5 classifications sorted by higher probability
	func best5Matches(probabilities: [Float]) -> [PillMatch] {
		precondition(probabilities.count == PillLabelManager.labelCount)
		
		let zippedSequence = zip(0...PillLabelManager.labelCount, probabilities)
		let sorted = zippedSequence.sorted { (a: (index: Int, probability: Float), b: (index: Int, probability: Float)) -> Bool in
			a.probability > b.probability
		}
		let best5 = sorted.prefix(through: 4)
		let result = best5.map { (elem: (index:Int, probability: Float)) -> PillMatch in
			(self.labels[elem.index], elem.probability)
		}
		return result
	}
}
