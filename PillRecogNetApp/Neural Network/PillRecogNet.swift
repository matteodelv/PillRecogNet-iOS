//
//  PillRecogNet.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 02/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import Foundation
import MetalPerformanceShaders
import QuartzCore

private func createPoolingMax(device: MTLDevice) -> MPSCNNPoolingMax {
	let pooling = MPSCNNPoolingMax(device: device, kernelWidth: 2, kernelHeight: 2, strideInPixelsX: 2, strideInPixelsY: 2)
	pooling.offset = MPSOffset(x: 1, y: 1, z: 0)
	return pooling
}

class PillConvolution: MPSCNNConvolution {
	
	private let convSize:UInt = 3 * 3
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	init(device: MTLDevice, inputDepth: UInt, outputDepth: UInt, parametersName: String, filter: MPSCNNNeuron?) {
		
		let sizeBias = outputDepth * UInt(MemoryLayout<Float>.size)
		let sizeWeights = inputDepth * outputDepth * convSize * UInt(MemoryLayout<Float>.size)
		
		let wPath = Bundle.main.path(forResource: parametersName + "_weights", ofType: "bin")
		let bPath = Bundle.main.path(forResource: parametersName + "_bias", ofType: "bin")
		
		let wFileDesc = open(wPath!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)
		let bFileDesc = open(bPath!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)
		
		assert(wFileDesc != -1, "Errore nell'apertura del file \(wPath!), numero: \(errno)")
		assert(bFileDesc != -1, "Errore nell'apertura del file \(bPath!), numero: \(errno)")
		
		let wMem = mmap(nil, Int(sizeWeights), PROT_READ, MAP_FILE | MAP_SHARED, wFileDesc, 0)
		let bMem = mmap(nil, Int(sizeBias), PROT_READ, MAP_FILE | MAP_SHARED, bFileDesc, 0)
		
		let weights = UnsafePointer(wMem?.bindMemory(to: Float.self, capacity: Int(sizeWeights)))
		let bias = UnsafePointer(bMem?.bindMemory(to: Float.self, capacity: Int(sizeBias)))
		
		assert(weights != UnsafePointer<Float>.init(bitPattern: -1), "mmap fallita! Errore: \(errno)")
		assert(bias != UnsafePointer<Float>.init(bitPattern: -1), "mmap fallita! Errore: \(errno)")
		
		let convDescriptor = MPSCNNConvolutionDescriptor(kernelWidth: 3, kernelHeight: 3, inputFeatureChannels: Int(inputDepth), outputFeatureChannels: Int(outputDepth), neuronFilter: filter)
		convDescriptor.strideInPixelsX = 1
		convDescriptor.strideInPixelsY = 1
		
		super.init(device: device, convolutionDescriptor: convDescriptor, kernelWeights: weights!, biasTerms: bias!, flags: .none)
		
		self.edgeMode = .zero
		
		assert(munmap(wMem, Int(sizeWeights)) == 0, "munmap fallita! Errore: \(errno)")
		assert(munmap(bMem, Int(sizeBias)) == 0, "munmap fallita! Errore: \(errno)")
		
		close(wFileDesc)
		close(bFileDesc)
	}
}

class PillFullyConnected: MPSCNNFullyConnected {
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	init(device: MTLDevice, kernelSize: UInt, inputDepth: UInt, outputDepth: UInt, parametersName: String, filter: MPSCNNNeuron?) {
		
		let sizeBias = outputDepth * UInt(MemoryLayout<Float>.size)
		let sizeWeights = inputDepth * kernelSize * kernelSize * outputDepth * UInt(MemoryLayout<Float>.size)
		
		let wPath = Bundle.main.path(forResource: parametersName + "_weights", ofType: "bin")
		let bPath = Bundle.main.path(forResource: parametersName + "_bias", ofType: "bin")
		
		let wFileDesc = open(wPath!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)
		let bFileDesc = open(bPath!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)
		
		assert(wFileDesc != -1, "Errore nell'apertura del file \(wPath!), numero: \(errno)")
		assert(bFileDesc != -1, "Errore nell'apertura del file \(bPath!), numero: \(errno)")
		
		let wMem = mmap(nil, Int(sizeWeights), PROT_READ, MAP_FILE | MAP_SHARED, wFileDesc, 0)
		let bMem = mmap(nil, Int(sizeBias), PROT_READ, MAP_FILE | MAP_SHARED, bFileDesc, 0)
		
		let weights = UnsafePointer(wMem?.bindMemory(to: Float.self, capacity: Int(sizeWeights)))
		let bias = UnsafePointer(bMem?.bindMemory(to: Float.self, capacity: Int(sizeBias)))
		
		assert(weights != UnsafePointer<Float>.init(bitPattern: -1), "mmap fallita! Errore: \(errno)")
		assert(bias != UnsafePointer<Float>.init(bitPattern: -1), "mmap fallita! Errore: \(errno)")
		
		let fcDescriptor = MPSCNNConvolutionDescriptor(kernelWidth: Int(kernelSize), kernelHeight: Int(kernelSize), inputFeatureChannels: Int(inputDepth), outputFeatureChannels: Int(outputDepth), neuronFilter: filter)
		
		super.init(device: device, convolutionDescriptor: fcDescriptor, kernelWeights: weights!, biasTerms: bias!, flags: .none)
		
		assert(munmap(wMem, Int(sizeWeights)) == 0, "munmap fallita! Errore: \(errno)")
		assert(munmap(bMem, Int(sizeBias)) == 0, "munmap fallita! Errore: \(errno)")
		
		close(wFileDesc)
		close(bFileDesc)
	}
}


public class PillRecogNet {
	let device: MTLDevice
	let commandQueue: MTLCommandQueue
	
	let rgbPipeline: MTLComputePipelineState
	
	let outputImage: MPSImage
	
	let lanczos: MPSImageLanczosScale
	let relu: MPSCNNNeuronReLU
	let softmax: MPSCNNSoftMax
	
	let block1_conv1: PillConvolution
	let block1_conv2: PillConvolution
	let block1_pool: MPSCNNPoolingMax
	
	let block2_conv1: PillConvolution
	let block2_conv2: PillConvolution
	let block2_pool: MPSCNNPoolingMax
	
	let block3_conv1: PillConvolution
	let block3_conv2: PillConvolution
	let block3_conv3: PillConvolution
	let block3_pool: MPSCNNPoolingMax
	
	let block4_conv1: PillConvolution
	let block4_conv2: PillConvolution
	let block4_conv3: PillConvolution
	let block4_pool: MPSCNNPoolingMax
	
	let block5_conv1: PillConvolution
	let block5_conv2: PillConvolution
	let block5_conv3: PillConvolution
	let block5_pool: MPSCNNPoolingMax
	
	let dense_1: PillFullyConnected
	let dense_2: PillFullyConnected
	
	let inputImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 224, height: 224, featureChannels: 3)
	let conv_block1ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 224, height: 224, featureChannels: 64)
	let pool_block1ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 112, height: 112, featureChannels: 64)
	let conv_block2ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 112, height: 112, featureChannels: 128)
	let pool_block2ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 56, height: 56, featureChannels: 128)
	let conv_block3ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 56, height: 56, featureChannels: 256)
	let pool_block3ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 28, height: 28, featureChannels: 256)
	let conv_block4ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 28, height: 28, featureChannels: 512)
	let pool_block4ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 14, height: 14, featureChannels: 512)
	let conv_block5ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 14, height: 14, featureChannels: 512)
	let pool_block5ImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 7, height: 7, featureChannels: 512)
	let denseImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 1, height: 1, featureChannels: 512)
	let outputImgDesc = MPSImageDescriptor(channelFormat: .float16, width: 1, height: 1, featureChannels: 12)
	
	var imageDescriptors:[MPSImageDescriptor] {
		get {
			return [inputImgDesc, conv_block1ImgDesc, pool_block1ImgDesc, conv_block2ImgDesc, pool_block2ImgDesc, conv_block3ImgDesc, pool_block3ImgDesc, conv_block4ImgDesc, pool_block4ImgDesc, conv_block5ImgDesc, pool_block5ImgDesc, denseImgDesc, outputImgDesc]
		}
	}
	
	let labelManager = PillLabelManager()
	
	
	init(device: MTLDevice) {
		self.device = device
		commandQueue = device.makeCommandQueue()!
		
		outputImage = MPSImage(device: device, imageDescriptor: outputImgDesc)
		lanczos = MPSImageLanczosScale(device: device)
		relu = MPSCNNNeuronReLU(device: device, a: 0)	// Passing a = 0 to get classic ReLU
		softmax = MPSCNNSoftMax(device: device)
		
		do {
			let customFunctionsLibrary = device.makeDefaultLibrary()!
			let vggPreprocessing = customFunctionsLibrary.makeFunction(name: "removeRGBMean")
			rgbPipeline = try device.makeComputePipelineState(function: vggPreprocessing!)
		} catch {
			fatalError("Errore durante l'inizializzazione del kernel per il preprocessing!")
		}
		
		block1_conv1 = PillConvolution(device: device, inputDepth: 3, outputDepth: 64, parametersName: "conv1", filter: relu)
		block1_conv2 = PillConvolution(device: device, inputDepth: 64, outputDepth: 64, parametersName: "conv2", filter: relu)
		block1_pool = createPoolingMax(device: device)
		
		block2_conv1 = PillConvolution(device: device, inputDepth: 64, outputDepth: 128, parametersName: "conv3", filter: relu)
		block2_conv2 = PillConvolution(device: device, inputDepth: 128, outputDepth: 128, parametersName: "conv4", filter: relu)
		block2_pool = createPoolingMax(device: device)
		
		block3_conv1 = PillConvolution(device: device, inputDepth: 128, outputDepth: 256, parametersName: "conv5", filter: relu)
		block3_conv2 = PillConvolution(device: device, inputDepth: 256, outputDepth: 256, parametersName: "conv6", filter: relu)
		block3_conv3 = PillConvolution(device: device, inputDepth: 256, outputDepth: 256, parametersName: "conv7", filter: relu)
		block3_pool = createPoolingMax(device: device)
		
		block4_conv1 = PillConvolution(device: device, inputDepth: 256, outputDepth: 512, parametersName: "conv8", filter: relu)
		block4_conv2 = PillConvolution(device: device, inputDepth: 512, outputDepth: 512, parametersName: "conv9", filter: relu)
		block4_conv3 = PillConvolution(device: device, inputDepth: 512, outputDepth: 512, parametersName: "conv10", filter: relu)
		block4_pool = createPoolingMax(device: device)
		
		block5_conv1 = PillConvolution(device: device, inputDepth: 512, outputDepth: 512, parametersName: "conv11", filter: relu)
		block5_conv2 = PillConvolution(device: device, inputDepth: 512, outputDepth: 512, parametersName: "conv12", filter: relu)
		block5_conv3 = PillConvolution(device: device, inputDepth: 512, outputDepth: 512, parametersName: "conv13", filter: relu)
		block5_pool = createPoolingMax(device: device)
		
		dense_1 = PillFullyConnected(device: device, kernelSize: 7, inputDepth: 512, outputDepth: 512, parametersName: "fc1", filter: relu)
		dense_2 = PillFullyConnected(device: device, kernelSize: 1, inputDepth: 512, outputDepth: 12, parametersName: "fc2", filter: nil)
		
		for desc in self.imageDescriptors {
			desc.storageMode = .private
		}
	}
	
	func classify(pill inputImage: MPSImage) -> [PillMatch] {
		autoreleasepool {
			
			if let comBuf = commandQueue.makeCommandBuffer() {
				MPSTemporaryImage.prefetchStorage(with: comBuf, imageDescriptorList: self.imageDescriptors)
				
				let scaledImage = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: inputImgDesc)
				lanczos.encode(commandBuffer: comBuf, sourceTexture: inputImage.texture, destinationTexture: scaledImage.texture)

				let preprocessedImage = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: inputImgDesc)
				
				let encoder = comBuf.makeComputeCommandEncoder()
				encoder?.setComputePipelineState(rgbPipeline)
				encoder?.setTexture(scaledImage.texture, index: 0)
				encoder?.setTexture(preprocessedImage.texture, index: 1)

				let threadsPerGroups = MTLSizeMake(8, 8, 1)
				let threadGroups = MTLSizeMake(preprocessedImage.texture.width / threadsPerGroups.width, preprocessedImage.texture.height / threadsPerGroups.height, 1)
				encoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroups)
				encoder?.endEncoding()
				scaledImage.readCount = 0
				
				let b1c1Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block1ImgDesc)
				block1_conv1.encode(commandBuffer: comBuf, sourceImage: preprocessedImage, destinationImage: b1c1Img)
				preprocessedImage.readCount = 0
				
				let b1c2Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block1ImgDesc)
				block1_conv2.encode(commandBuffer: comBuf, sourceImage: b1c1Img, destinationImage: b1c2Img)
				b1c1Img.readCount = 0
				
				let b1poolImg = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: pool_block1ImgDesc)
				block1_pool.encode(commandBuffer: comBuf, sourceImage: b1c2Img, destinationImage: b1poolImg)
				b1c2Img.readCount = 0
				
				let b2c1Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block2ImgDesc)
				block2_conv1.encode(commandBuffer: comBuf, sourceImage: b1poolImg, destinationImage: b2c1Img)
				b1poolImg.readCount = 0
				
				let b2c2Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block2ImgDesc)
				block2_conv2.encode(commandBuffer: comBuf, sourceImage: b2c1Img, destinationImage: b2c2Img)
				b2c1Img.readCount = 0
				
				let b2poolImg = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: pool_block2ImgDesc)
				block2_pool.encode(commandBuffer: comBuf, sourceImage: b2c2Img, destinationImage: b2poolImg)
				b2c2Img.readCount = 0
				
				let b3c1Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block3ImgDesc)
				block3_conv1.encode(commandBuffer: comBuf, sourceImage: b2poolImg, destinationImage: b3c1Img)
				b2poolImg.readCount = 0
				
				let b3c2Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block3ImgDesc)
				block3_conv2.encode(commandBuffer: comBuf, sourceImage: b3c1Img, destinationImage: b3c2Img)
				b3c1Img.readCount = 0
				
				let b3c3Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block3ImgDesc)
				block3_conv3.encode(commandBuffer: comBuf, sourceImage: b3c2Img, destinationImage: b3c3Img)
				b3c2Img.readCount = 0
				
				let b3poolImg = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: pool_block3ImgDesc)
				block3_pool.encode(commandBuffer: comBuf, sourceImage: b3c3Img, destinationImage: b3poolImg)
				b3c3Img.readCount = 0
				
				let b4c1Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block4ImgDesc)
				block4_conv1.encode(commandBuffer: comBuf, sourceImage: b3poolImg, destinationImage: b4c1Img)
				b3poolImg.readCount = 0
				
				let b4c2Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block4ImgDesc)
				block4_conv2.encode(commandBuffer: comBuf, sourceImage: b4c1Img, destinationImage: b4c2Img)
				b4c1Img.readCount = 0
				
				let b4c3Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block4ImgDesc)
				block4_conv3.encode(commandBuffer: comBuf, sourceImage: b4c2Img, destinationImage: b4c3Img)
				b4c2Img.readCount = 0
				
				let b4poolImg = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: pool_block4ImgDesc)
				block4_pool.encode(commandBuffer: comBuf, sourceImage: b4c3Img, destinationImage: b4poolImg)
				b4c3Img.readCount = 0
				
				let b5c1Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block5ImgDesc)
				block5_conv1.encode(commandBuffer: comBuf, sourceImage: b4poolImg, destinationImage: b5c1Img)
				b4poolImg.readCount = 0
				
				let b5c2Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block5ImgDesc)
				block5_conv2.encode(commandBuffer: comBuf, sourceImage: b5c1Img, destinationImage: b5c2Img)
				b5c1Img.readCount = 0
				
				let b5c3Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: conv_block5ImgDesc)
				block5_conv3.encode(commandBuffer: comBuf, sourceImage: b5c2Img, destinationImage: b5c3Img)
				b5c2Img.readCount = 0
				
				let b5poolImg = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: pool_block5ImgDesc)
				block5_pool.encode(commandBuffer: comBuf, sourceImage: b5c3Img, destinationImage: b5poolImg)
				b5c3Img.readCount = 0
				
				let dense1Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: denseImgDesc)
				dense_1.encode(commandBuffer: comBuf, sourceImage: b5poolImg, destinationImage: dense1Img)
				b5poolImg.readCount = 0
				
				let dense2Img = MPSTemporaryImage(commandBuffer: comBuf, imageDescriptor: outputImgDesc)
				dense_2.encode(commandBuffer: comBuf, sourceImage: dense1Img, destinationImage: dense2Img)
				dense1Img.readCount = 0
				
				softmax.encode(commandBuffer: comBuf, sourceImage: dense2Img, destinationImage: outputImage)
				dense2Img.readCount = 0
				
				comBuf.commit()
				comBuf.waitUntilCompleted()
			}
		}
		
		return self.labelManager.best5Matches(probabilities: self.outputImage.getFloatValues())
	}
}

















