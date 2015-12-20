//
//  Shaders.metal
//  HelloMetal
//
//  Created by Russell Gordon on 2015-12-20.
//  Copyright © 2015 Royal St. George's College. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// STEP 4: Create a Vertex Shader

vertex float4 basic_vertex(

    const device packed_float3* vertex_array [[ buffer(0) ]], // array that contains position of each vertex
                           unsigned int vid [[ vertex_id ]]   // see tutorial
)

    {
    
        // look up position inside the vertex array based on the provided vertex id and return this
        // also, convert vector to float4 format
        // (see tutorial for further explanation)
        return float4( vertex_array[vid], 1.0);
        
}


