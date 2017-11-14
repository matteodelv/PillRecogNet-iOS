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
	
	const auto means = float4(123.68f, 116.78f, 103.94f, 0.0f);	// VGG16 ImageNet RGB Mean values
	const auto inputColors = (float4(inputTexture.read(gid)) * 255.0f - means);	// Mean removal (multiplication by 255 because RGBA16 texture scales values down between 0 and 1
	const auto scaled = inputColors / 255.0f;	// Applied during fine tuning
	outputTexture.write(half4(scaled.x, scaled.y, scaled.z, 0.0f), gid);
}
