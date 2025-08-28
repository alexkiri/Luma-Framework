RWTexture2D<float4> u0 : register(u0);  // OutScatteredMaxVelocity
Texture2D<float4> t0 : register(t0);    // PostprocessInput0

cbuffer cb0 : register(b0)
{
    float4 cb0[19];
}

// Map constant buffers based on actual usage in decompiled code
#define ViewportRect_zw cb0[15].zw
#define VelocityToPixelsScale cb0[18].zz

#define cmp -

[numthreads(16, 16, 1)]
void main(uint3 vThreadID : SV_DispatchThreadID)
{
    float4 r0, r1, r2, r3, r4, r5, r6, r7, r8;
    
    // Load initial velocity data
    r0.xy = vThreadID.xy;
    r0.zw = float2(0, 0);
    r0 = t0.Load(r0.xyz);
    
    r1.zw = float2(0, 0);
    r2.y = 0;
    r3 = r0;  // Current min/max velocity
    r2.w = -4;  // Start of outer loop
    
    // Outer loop: x from -3 to 3
    while (true) {
        r4.x = cmp(4 < (int)r2.w);
        if (r4.x != 0) break;
        
        r4.x = cmp((int)r2.w == 0);  // Skip center pixel
        r5 = r3;
        r4.y = -4;  // Start of inner loop
        
        // Inner loop: y from -3 to 3
        while (true) {
            r4.z = cmp(4 < (int)r4.y);
            if (r4.z != 0) break;
            
            r4.z = cmp((int)r4.y == 0);
            r4.z = r4.z ? r4.x : 0;  // Skip if both x and y are 0
            if (r4.z != 0) {
                r4.y = 1;
                continue;
            } else {
                r2.z = r4.y;
            }
            
            // Calculate sample position
            r1.xy = (int2)r2.wz + (int2)vThreadID.xy;
            
            // Bounds check
            r4.zw = cmp((int2)r1.xy >= int2(0, 0));
            r6.xy = cmp((int2)r1.xy < asint(ViewportRect_zw));
            r4.zw = r4.zw ? r6.xy : 0;
            r4.z = r4.w ? r4.z : 0;
            
            if (r4.z == 0) {
                r4.y = (int)r2.z + 1;
                continue;
            }
            
            // Sample neighbor velocity data
            r6 = t0.Load(r1.xyz);
            
            // Convert max velocity to pixels
            r1.xy = VelocityToPixelsScale * r6.zw;
            
            // Calculate velocity length and direction
            r4.z = dot(r1.xy, r1.xy);
            r4.w = 9.99999994e-09 + r4.z;
            r4.w = (uint)r4.w >> 1;
            r4.w = (int)-r4.w + 0x5f3759df;  // Fast rsqrt
            r2.x = r4.z * r4.w;  // velocity length in pixels
            r7.xy = r4.ww * r1.xy;  // normalized velocity direction
            
            // Calculate pixel extent and quad extent
            r1.x = abs(r7.x) + abs(r7.y);
            r1.xy = r1.xx * float2(0.99000001, 0.99000001) + r2.xy;
            
            // Project offset onto velocity axes
            r4.zw = (int2)r2.wz;  // offset
            r8.x = dot(r7.xy, r4.zw);  // project onto velocity dir
            r7.z = -r7.y;
            r8.y = dot(r7.zx, r4.zw);  // project onto perpendicular
            
            // Check if inside quad
            r1.xy = cmp(abs(r8.xy) < r1.xy);
            r1.x = r1.y ? r1.x : 0;
            
            // MinMaxLength operation
            r1.y = dot(r5.xy, r5.xy);
            r2.x = dot(r6.xy, r6.xy);
            r1.y = cmp(r1.y < r2.x);
            r7.xy = r1.yy ? r5.xy : r6.xy;  // min
            
            r1.y = dot(r5.zw, r5.zw);
            r2.x = dot(r6.zw, r6.zw);
            r1.y = cmp(r2.x < r1.y);
            r7.zw = r1.yy ? r5.zw : r6.zw;  // max
            
            // Update if inside quad
            r5 = r1.xxxx ? r7 : r5;
            
            r4.y = (int)r2.z + 1;
        }
        r3 = r5;
        r2.w = (int)r2.w + 1;
    }
    
    // Final bounds check and output
    r0.xy = cmp((uint2)vThreadID.xy < asuint(ViewportRect_zw));
    r0.x = r0.y ? r0.x : 0;
    if (r0.x != 0) {
        u0[vThreadID.xy] = r3;
    }
}