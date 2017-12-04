//
//  Preprocessing.metal
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 04/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void removeRGBMean(texture2d <half, access::read> inputTexture [[texture(0)]], texture2d <half, access::write> outputTexture [[texture(1)]], uint2 gid [[thread_position_in_grid]]) {
	
	const auto means = half4(123.68h, 116.78h, 103.94h, 0.0h);	// VGG16 ImageNet RGB Mean values
	const auto inputColors = (half4(inputTexture.read(gid)) * 255.0h - means);	// Mean removal (multiplication by 255 because input image texture scales values down between 0 and 1
	const auto scaled = inputColors / 255.0h;	// Applied during fine tuning
	outputTexture.write(half4(scaled.x, scaled.y, scaled.z, 0.0h), gid);
}
