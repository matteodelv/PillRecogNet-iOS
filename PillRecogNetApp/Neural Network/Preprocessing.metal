//
//  Preprocessing.metal
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 04/11/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void removeRGBMean(texture2d <half, access::read> inputTexture [[texture(0)]], texture2d <half, access::write> outputTexture [[texture(1)]], uint2 groupID [[thread_position_in_grid]]) {
	
	half4 inputColor = inputTexture.read(groupID);
	half4 outputColor = half4(inputColor.x * 255.0h - 103.939h, inputColor.y * 255.0h - 116.779h, inputColor.z * 255.0h - 123.68h, 0.0h);
	outputTexture.write(outputColor, groupID);
}
