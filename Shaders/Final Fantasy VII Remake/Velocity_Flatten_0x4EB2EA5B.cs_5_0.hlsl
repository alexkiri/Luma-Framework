#include "includes/Common.hlsl"

#define THREADGROUP_SIZEX		16
#define THREADGROUP_SIZEY		16
#define THREADGROUP_TOTALSIZE	(THREADGROUP_SIZEX * THREADGROUP_SIZEY)

groupshared float4 g0[THREADGROUP_TOTALSIZE];

cbuffer cb2 : register(b2)
{
  float4 cb2[5];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[58];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[20];
}

Texture2D<float4> t0 : register(t0);  // PostprocessInput0
Texture2D<float4> t1 : register(t1);  // PostprocessInput1

RWTexture2D<float4> u0 : register(u0);  // OutVelocityFlat
RWTexture2D<float4> u1 : register(u1);  // OutMaxTileVelocity

#define cmp -

[numthreads(THREADGROUP_SIZEX, THREADGROUP_SIZEY, 1)]
void main(
    uint3 vThreadGroupID : SV_GroupID,
    uint3 vThreadID : SV_DispatchThreadID,
    uint3 vThreadIDInGroup : SV_GroupThreadID,
    uint vThreadIDInGroupFlattened : SV_GroupIndex)
{
    float4 r0, r1, r2, r3, r4;
    float4 viewportSize;
    float resolutionScale;
    if (LumaData.GameData.DrewUpscaling)
    {
        // viewportSize = LumaData.GameData.OutputResolution;
        viewportSize = asint(LumaData.GameData.ViewportRect);
        resolutionScale = LumaData.GameData.ResolutionScale.x;
    }
    else {
        viewportSize = asint(cb0[15]); 
        resolutionScale = 1.0f;
    }

    // // Calculate pixel position
    
    r0.xy = (int2)(vThreadID.xy * resolutionScale) + asint(viewportSize.xy);
    r0.zw = float2(0, 0);
    
    // Sample velocity and depth
    r1.xy = t0.Load(r0.xyw).xy;
    r2.z = t1.Load(r0.xyz).x;
    
    // Calculate screen UV
    r0.zw = (uint2)vThreadID.xy;
    r0.zw = float2(0.5, 0.5) + r0.zw;
    r0.zw *= resolutionScale;
    r1.zw = asint(-viewportSize.xy) + asint(viewportSize.zw);
    r1.zw = (uint2)r1.zw;
    r2.xy = r0.zw / r1.zw;
    
    // Camera motion calculation
    r0.z = dot(r2.xyz, cb2[0].xyz);
    r0.z = cb2[0].w + r0.z;
    r0.z = rcp(r0.z);
    
    r1.zw = cb2[1].xw * r2.yy;
    r0.w = cb2[1].y * r2.z + r1.z;
    r0.w = cb2[1].z + r0.w;
    r0.w = r2.x * r0.w + r1.w;
    r1.zw = r2.xy * r2.xy;
    r0.w = r1.z * cb2[2].x + r0.w;
    r0.w = cb2[2].y * r2.z + r0.w;
    r0.w = cb2[2].z + r0.w;
    r3.x = -2.0 * r0.w;  // Fixed: multiply by -2.0 for velocity.x calculation
    
    r2.xw = cb2[3].xw * r2.xx;
    r0.w = cb2[3].y * r2.z + r2.x;
    r0.w = cb2[3].z + r0.w;
    r0.w = r2.y * r0.w + r2.w;
    r0.w = r1.w * cb2[4].x + r0.w;
    r0.w = cb2[4].y * r2.z + r0.w;
    r3.y = 2.0 * (cb2[4].z + r0.w);  // Fixed: multiply by 2.0 for velocity.y calculation
    
    r0.zw = r3.xy * r0.zz;
    r3.xy = r0.zw;  // Fixed: don't double the camera motion velocity
    
    // Check if velocity is encoded (velocity.x > 0.0)
    r0.z = dot(r1.xy, r1.xy);
    r0.z = cmp(0 < r0.z);
    
    // Decode velocity (DecodeVelocityFromTexture equivalent)
    r1.xy = float2(-0.499992371, -0.499992371) + r1.xy;
    r4.xy = float2(4.00801611, 4.00801611) * r1.xy;
    r4.zw = float2(0, 0);  // Fixed: camera motion velocity should go to zw when not encoded
    r1.xyzw = r0.zzzz ? r4.xyzw : r3.xyzw;  // Fixed: proper velocity selection
    
    // Apply aspect ratio (negative for Y)
    r1.y = -cb0[18].x * r1.y;  // Fixed: only apply negative aspect ratio to Y (may need to multiply by resolution scale)
    r1.x = cb0[18].x * r1.x;   // Fixed: apply aspect ratio to X without negation (may need to multiply by resolution scale)
    
    // Calculate polar coordinates (atan2Fast implementation)
    r0.zw = max(float2(9.99999975e-05, 9.99999975e-05), abs(r1.xy));
    r2.x = min(r0.z, r0.w);
    r2.y = max(r0.z, r0.w);
    r2.x = r2.x / r2.y;
    r2.y = r2.x * r2.x;
    r2.w = r2.y * -0.0464964733 + 0.159314215;
    r2.w = r2.w * r2.y + -0.327622771;
    r2.y = r2.w * r2.y + 1;
    r2.w = r2.y * r2.x;
    r0.z = cmp(r0.z < r0.w);
    r0.w = -r2.y * r2.x + 1.57079637;
    r0.z = r0.z ? r0.w : r2.w;
    r0.w = cmp(r1.y < 0);  // Fixed: check r1.y instead of r1.z
    r2.x = 3.14159274 + -r0.z;
    r0.z = r0.w ? r2.x : r0.z;
    r0.w = cmp(r1.x < 0);
    r3.y = r0.ww ? -r0.z : r0.z;  // Fixed: angle goes to r3.y
    r3.w = r3.y;
    
    // Calculate velocity length
    r0.z = length(r1.xy);  // Fixed: use proper length calculation
    r3.x = r0.z;  // Fixed: velocity length goes to r3.x
    
    // Handle NaN case
    if (any(isnan(r3.xy)))
    {
        r3.xy = float2(0.0, 0.0);
    }
    
    // Viewport bounds check
    r0.zw = cmp((uint2)r0.xy < asint(viewportSize.zw));
    r0.z = r0.w ? r0.z : 0;
    
    // Output velocity if inside viewport
    if (r0.z != 0) {
        r0.w = r2.z * cb1[57].x + cb1[57].y;
        r2.x = r2.z * cb1[57].z + -cb1[57].w;
        r2.x = rcp(r2.x);
        r1.y = r2.x + r0.w;
        r1.x = r3.y * (0.5 / 3.14159265359) + 0.5;  // Fixed: encode angle properly
        r1.zw = float2(0, 0);
        u0[r0.xy] = float4(r3.x, r1.x, r1.y, 0);  // Fixed: proper encoding order
    }
    
    // Limit velocity
    r0.x = cb0[18].w / cb0[18].y;
    r0.x = min(r3.x, r0.x);  // Fixed: limit the velocity length
    r3.xz = r0.z ? float2(r0.x, r0.x) : float2(2, 0);  // Fixed: proper min/max setup
    
    // Store in shared memory
    g0[vThreadIDInGroupFlattened] = r3;
    GroupMemoryBarrierWithGroupSync();
    
    // Parallel reduction (MinMaxLengthPolar)
    r0.xyzw = cmp((uint4)vThreadIDInGroupFlattened.xxxx < int4(128, 64, 32, 16));
    
    if (r0.x != 0) {
        r0.x = (int)vThreadIDInGroupFlattened + 128;
        r1 = g0[r0.x];
        r0.x = cmp(r3.x < r1.x);
        r2.xy = r0.xx ? r3.xy : r1.xy;
        r0.x = cmp(r1.z < r3.z);
        r2.zw = r0.xx ? r3.zw : r1.zw;
        g0[vThreadIDInGroupFlattened] = r2;
        r3 = r2;  // Fixed: update r3 with new values
    }
    GroupMemoryBarrierWithGroupSync();
    
    if (r0.y != 0) {
        r1 = g0[vThreadIDInGroupFlattened];
        r0.x = (int)vThreadIDInGroupFlattened + 64;
        r2 = g0[r0.x];
        r0.x = cmp(r1.x < r2.x);
        r3.xy = r0.xx ? r1.xy : r2.xy;
        r0.x = cmp(r2.z < r1.z);
        r3.zw = r0.xx ? r1.zw : r2.zw;
        g0[vThreadIDInGroupFlattened] = r3;
    }
    GroupMemoryBarrierWithGroupSync();
    
    if (r0.z != 0) {
        r1 = g0[vThreadIDInGroupFlattened];
        r0.x = (int)vThreadIDInGroupFlattened + 32;
        r2 = g0[r0.x];
        r0.x = cmp(r1.x < r2.x);
        r3.xy = r0.xx ? r1.xy : r2.xy;
        r0.x = cmp(r2.z < r1.z);
        r3.zw = r0.xx ? r1.zw : r2.zw;
        g0[vThreadIDInGroupFlattened] = r3;
    }
    
    if (r0.w != 0) {
        r0 = g0[vThreadIDInGroupFlattened];
        r1.x = (int)vThreadIDInGroupFlattened + 16;
        r1 = g0[r1.x];
        r2.x = cmp(r0.x < r1.x);
        r2.xy = r2.xx ? r0.xy : r1.xy;
        r0.x = cmp(r1.z < r0.z);
        r2.zw = r0.xx ? r0.zw : r1.zw;
        g0[vThreadIDInGroupFlattened] = r2;
        r3 = r2;  // Fixed: update r3
    }
    
    r0.xyzw = cmp((uint4)vThreadIDInGroupFlattened.xxxx < int4(8, 4, 2, 1));
    
    if (r0.x != 0) {
        r1 = g0[vThreadIDInGroupFlattened];
        r0.x = (int)vThreadIDInGroupFlattened + 8;
        r2 = g0[r0.x];
        r0.x = cmp(r1.x < r2.x);
        r3.xy = r0.xx ? r1.xy : r2.xy;
        r0.x = cmp(r2.z < r1.z);
        r3.zw = r0.xx ? r1.zw : r2.zw;
        g0[vThreadIDInGroupFlattened] = r3;
    }
    
    if (r0.y != 0) {
        r1 = g0[vThreadIDInGroupFlattened];
        r0.x = (int)vThreadIDInGroupFlattened + 4;
        r2 = g0[r0.x];
        r0.x = cmp(r1.x < r2.x);
        r3.xy = r0.xx ? r1.xy : r2.xy;
        r0.x = cmp(r2.z < r1.z);
        r3.zw = r0.xx ? r1.zw : r2.zw;
        g0[vThreadIDInGroupFlattened] = r3;
    }
    
    if (r0.z != 0) {
        r1 = g0[vThreadIDInGroupFlattened];
        r0.x = (int)vThreadIDInGroupFlattened + 2;
        r2 = g0[r0.x];
        r0.x = cmp(r1.x < r2.x);
        r3.xy = r0.xx ? r1.xy : r2.xy;
        r0.x = cmp(r2.z < r1.z);
        r3.zw = r0.xx ? r1.zw : r2.zw;
        g0[vThreadIDInGroupFlattened] = r3;
    }
    
    if (r0.w != 0) {
        r0 = g0[0];
        r1 = g0[1];
        r2.x = cmp(r0.x < r1.x);
        r2.xy = r2.xx ? r0.xy : r1.xy;
        r0.x = cmp(r1.z < r0.z);
        r2.zw = r0.xx ? r0.zw : r1.zw;
        g0[0] = r2;
    }
    
    if (vThreadIDInGroupFlattened == 0) {
        r0 = g0[0];
        // PolarToCartesian for min velocity
        sincos(r0.y, r1.y, r1.x);
        r1.xy = r1.xy * r0.x;
        // PolarToCartesian for max velocity  
        sincos(r0.w, r2.y, r2.x);
        r1.zw = r2.xy * r0.z;
        u1[vThreadGroupID.xy] = r1;
    }
}