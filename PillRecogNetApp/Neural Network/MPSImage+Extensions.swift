//
//  MPSImage+Extensions.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 03/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import Foundation
import Accelerate
import MetalPerformanceShaders


extension MPSImage {
	public func getFloatValues() -> [Float] {
		let count = self.width * self.height * self.featureChannels
		
		var output16Bit = [UInt16](repeating: 0, count: count)
		var floatOutput = [Float](repeating: 0, count: count)
		let slices = (self.featureChannels + 3)/4
		let channels = 4
		let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: self.width, height: self.height, depth: 1))
		
		for i in 0..<slices {
			self.texture.getBytes(&(output16Bit[self.width * self.height * i * channels]), bytesPerRow: MemoryLayout<UInt16>.size * self.width * channels, bytesPerImage: 0, from: region, mipmapLevel: 0, slice: i)
		}
		
		var buffer16Bit = vImage_Buffer(data: &output16Bit, height: 1, width: UInt(count), rowBytes: count * 2)
		var buffer32Bit = vImage_Buffer(data: &floatOutput, height: 1, width: UInt(count), rowBytes: count * 4)
		
		if vImageConvert_Planar16FtoPlanarF(&buffer16Bit, &buffer32Bit, 0) != kvImageNoError {
			print("Errore nella conversione dei valori in float")
		}
		
		return floatOutput
	}
}
