//
//  UIImage+Extensions.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 04/12/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit

extension UIImage {
	func fixOrientation() -> UIImage {
		guard imageOrientation != .up else {
			return self
		}
		
		var transform = CGAffineTransform.identity
		
		switch imageOrientation {
		case .down, .downMirrored:
			transform = transform.translatedBy(x: size.width, y: size.height)
			transform = transform.rotated(by: CGFloat.pi)
		case .left, .leftMirrored:
			transform = transform.translatedBy(x: size.width, y: 0)
			transform = transform.rotated(by: CGFloat.pi / 2)
		case .right, .rightMirrored:
			transform = transform.translatedBy(x: 0, y: size.height)
			transform = transform.rotated(by: -(CGFloat.pi / 2))
		default:
			break
		}
		
		switch imageOrientation {
		case .upMirrored, .downMirrored:
			transform.translatedBy(x: size.width, y: 0)
			transform.scaledBy(x: -1, y: 1)
		case .leftMirrored, .rightMirrored:
			transform.translatedBy(x: size.height, y: 0)
			transform.scaledBy(x: -1, y: 1)
		default:
			break
		}
		
		let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
		
		ctx.concatenate(transform)
		
		switch imageOrientation {
		case .left, .leftMirrored, .right, .rightMirrored:
			ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
		default:
			ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
			break
		}
		
		let cgImage: CGImage = ctx.makeImage()!
		return UIImage(cgImage: cgImage)
	}
}
