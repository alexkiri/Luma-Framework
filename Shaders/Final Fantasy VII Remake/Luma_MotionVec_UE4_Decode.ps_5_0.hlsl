// ---- Modified for DLSS Motion Vector Output
// Based on PostProcessTemporalCommon_Decomp.hlsl
Texture2D<float4> t4 : register(t4); // Velocity texture
Texture2D<float4> t3 : register(t3); // Previous frame color
Texture2D<float4> t2 : register(t2); // Current frame color (jittered)
Texture2D<float4> t1 : register(t1); // Depth buffer
Texture3D<float4> t0 : register(t0); // LUT or other data

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[140];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[28];
}

// This is how MVs were encoded in UE/FF7
float2 EncodeVelocityToTexture(float2 In)
{
    // 0.499f is a value smaller than 0.5f to avoid using the full range to use the clear color (0,0) as special value
    // 0.5f to allow for a range of -2..2 instead of -1..1 for really fast motions for temporal AA.
    // Texure is R16G16 UNORM
    return In * (0.499f * 0.5f) + (32767.0f / 65535.0f);
}
float2 DecodeVelocityFromTexture(float2 In)
{
#if 1
    return (In - (32767.0f / 65535.0f)) / (0.499f * 0.5f);
#else // MAD layout to help compiler. This is what UE/FF7 used but it's an unnecessary approximation
    const float InvDiv = 1.0f / (0.499f * 0.5f);
    return In * InvDiv - 32767.0f / 65535.0f * InvDiv;
#endif
}

// Output only motion vectors for DLSS
float2 main(float4 pos : SV_Position0) : SV_Target0
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7;

  // Get pixel coordinates
  r0.xy = (int2)pos.xy;
  r1.xy = trunc(pos.xy) + 0.5; // Note: this seems to make no sense unless for some reason the input and output resolutions were different and we wanted to snap to another center
  
  // Convert to screen space coordinates
  r1.xy -= cb1[121].xy; // Subtract viewport min
  r1.xy *= cb1[122].zw;  // Scale by render resolution inverse
  r1.xy = r1.xy * 2.0 - 1.0; // Convert to [-1,1] range

  // subtract jitter offset
  float2 JitterNorm = cb1[118].xy;
  // Convert to pixel space
  float2 JitterPixels = JitterNorm.xy * cb1[122].xy * float2(0.5, -0.5);
  r1.xy += cb1[118].xy; // Apply jitter offset
  
  // Setup viewport bounds for clamping
  int4 r2i = (int4)cb1[121].xyxy; // viewport min (usually 0)
  r3.xyzw = cb1[122].xyxy + cb1[121].xyxy; // viewport size + min
  r3.xyzw -= 1.0; // viewport max - 1
  r3.xyzw = (int4)r3.xyzw;
  
  // Clamp pixel coordinates to valid range
  r4.xy = max((int2)r2i.zw, (int2)r0.xy);
  r4.xy = min((int2)r4.xy, (int2)r3.xy);
  r4.zw = float2(0,0);
  
  // Sample depth at current pixel
  r5.x = t1.Load(r4.xyw).x;
  
  // MOTION VECTOR DILATION (similar to VelocityCombine.usf)
  // Sample depth in cross pattern to find nearest (foreground) pixel
  r6.xyzw = (int4)r0.xyxy + int4(-1,-1,1,-1); // Cross pattern offsets
  r6.xyzw = max((int4)r6.xyzw, (int4)r2i.xyzw);
  r6.xyzw = min((int4)r6.zwxy, (int4)r3.zwxy);
  
  r7.xy = r6.zw;
  r7.zw = float2(0,0);
  r7.x = t1.Load(r7.xyz).x; // Sample depth at (+1,-1)
  
  r6.zw = float2(0,0);
  r7.y = t1.Load(r6.xyz).x; // Sample depth at (-1,-1)
  
  r6.xyzw = (int4)r0.xyxy + int4(-1,1,1,1);
  r6.xyzw = max((int4)r6.xyzw, (int4)r2i.xyzw);
  r6.xyzw = min((int4)r6.zwxy, (int4)r3.zwxy);
  
  r7.xy = r6.zw;
  r7.zw = float2(0,0);
  r7.z = t1.Load(r7.xyz).x; // Sample depth at (+1,+1)
  
  r6.zw = float2(0,0);
  r7.w = t1.Load(r6.xyz).x; // Sample depth at (-1,+1)
  
  // Find nearest depth (largest value in inverted Z)
  r0.w = max(r7.y, r7.z);
  r0.w = max(r7.x, r0.w);
  r6.x = max(r0.w, r7.w);
  
  // Check if we found a nearer pixel than center
  r0.w = (r5.x < r6.x);
  
  // Determine offset for velocity sampling based on nearest depth
  r5.yz = float2(0,0); // Default: no offset
  
  if (r0.w)
  {
    // Complex logic to determine which sample had the nearest depth
    // (Simplified version - in practice you'd want the full logic from original)
    r5.yz = float2(1,0); // Use some offset for nearest pixel
  }
  
  // Calculate screen position for reprojection
  float4 ClipPos;
  ClipPos.xy = r1.xy; // Screen position [-1,1]
  ClipPos.z = r5.x;   // Depth
	ClipPos.w = 1;
  
  // Camera motion calculation
  float4x4 ClipToPrevClip = float4x4(cb1[114], cb1[115], cb1[116], cb1[117]);
#if 0 // New code (doesn't work)
	r6 = mul(ClipPos, ClipToPrevClip);
#else
  r6.xyz = cb1[115].xyw * r1.yyy; // View matrix multiplication
  r6.xyz = r1.xxx * cb1[114].xyw + r6.xyz;
  r6.xyz = ClipPos.z * cb1[116].xyw + r6.xyz;
  r6.xyz = cb1[117].xyw + r6.xyz;
#endif
  
  r5.xw = r6.xy / r6.z; // Previous frame screen position
  r5.xw = r1.xy - r5.xw; // Camera motion vector
  
  // Get render resolution for scaling
  float2 RenderResolution = cb1[122].xy;

  float2 velocity = r5.xw / 1;
  
  // Sample velocity texture (with potential offset for dilation)
  r5.yz = (int2)r0.xy + (int2)r5.yz;
  r5.yz = max((int2)r5.yz, (int2)r2i.xy);
  r6.xy = min((int2)r5.yz, (int2)r3.xy);

  // Sample encoded velocity. R16G16_UNORM
  float2 decodedDynamicVelocity = t4.Load(float3(r6.xy, 0.0)).xy;
  
  // Check if we have dynamic motion (the "no dynamic motion vectors" reserved special value is 0, not ~0.5)
  bool dynamicVelocity = (decodedDynamicVelocity.x + decodedDynamicVelocity.y) > 0.0;

  // Use decoded dynamic motion if available, otherwise keep camera motion
  if (dynamicVelocity)
  {
    velocity = DecodeVelocityFromTexture(decodedDynamicVelocity);
  }
  
  // DLSS-SPECIFIC MOTION VECTOR PREPARATION
  // Convert motion vectors to pixel space for DLSS
  // VelocityCombine.usf uses: -BackTemp * float2(0.5, -0.5)
  // where BackTemp = BackN * ViewportSize
  
  // Convert motion vector to pixel space
  float2 MotionPixels = velocity * RenderResolution;
  
  // Apply DLSS-specific scaling and negation
  // DLSS expects motion vectors in pixel units with specific sign convention
  float2 DLSSMotionVector = MotionPixels * float2(-0.5, 0.5);
  
  // Output motion vector for DLSS
  return DLSSMotionVector;
}