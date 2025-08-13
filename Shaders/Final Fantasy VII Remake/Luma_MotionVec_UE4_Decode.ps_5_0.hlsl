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

// 3Dmigoto declarations
#define cmp -

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  float4 v2 : SV_Position0,
  out float4 o0 : SV_Target0) // Output only motion vectors for DLSS
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7;
  uint4 bitmask, uiDest;
  float4 fDest;

  // Get pixel coordinates
  r0.xy = (int2)v2.xy;
  r1.xy = trunc(v2.xy);
  r1.xy = float2(0.5,0.5) + r1.xy;
  
  // Convert to screen space coordinates
  r1.xy = -cb1[121].xy + r1.xy; // Subtract viewport min
  r1.xy = cb1[122].zw * r1.xy;  // Scale by render resolution inverse
  r1.xy = r1.xy * float2(2,2) + float2(-1,-1); // Convert to [-1,1] range

  // subtract jitter offset
  float2 JitterNorm = cb1[118].xy;
// Convert to pixel space
  float2 JitterPixels = JitterNorm.xy * cb1[122].xy * float2(0.5, -0.5);
  r1.xy = r1.xy + cb1[118].xy; // Apply jitter offset
  
  // Setup viewport bounds for clamping
  r2.xyzw = (int4)cb1[121].xyxy; // viewport min
  r3.xyzw = cb1[122].xyxy + cb1[121].xyxy; // viewport size + min
  r3.xyzw = float4(-1,-1,-1,-1) + r3.xyzw; // viewport max - 1
  r3.xyzw = (int4)r3.xyzw;
  
  // Clamp pixel coordinates to valid range
  r4.xy = max((int2)r2.zw, (int2)r0.xy);
  r4.xy = min((int2)r4.xy, (int2)r3.xy);
  r4.zw = float2(0,0);
  
  // Sample depth at current pixel
  r5.x = t1.Load(r4.xyw).x;
  
  // MOTION VECTOR DILATION (similar to VelocityCombine.usf)
  // Sample depth in cross pattern to find nearest (foreground) pixel
  r6.xyzw = (int4)r0.xyxy + int4(-1,-1,1,-1); // Cross pattern offsets
  r6.xyzw = max((int4)r6.xyzw, (int4)r2.xyzw);
  r6.xyzw = min((int4)r6.zwxy, (int4)r3.zwxy);
  
  r7.xy = r6.zw;
  r7.zw = float2(0,0);
  r7.x = t1.Load(r7.xyz).x; // Sample depth at (+1,-1)
  
  r6.zw = float2(0,0);
  r7.y = t1.Load(r6.xyz).x; // Sample depth at (-1,-1)
  
  r6.xyzw = (int4)r0.xyxy + int4(-1,1,1,1);
  r6.xyzw = max((int4)r6.xyzw, (int4)r2.xyzw);
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
  r0.w = cmp(r5.x < r6.x);
  
  // Determine offset for velocity sampling based on nearest depth
  r5.yz = float2(0,0); // Default: no offset
  
  if (r0.w) {
    // Complex logic to determine which sample had the nearest depth
    // (Simplified version - in practice you'd want the full logic from original)
    r5.yz = float2(1,0); // Use some offset for nearest pixel
  }
  
  // Calculate screen position for reprojection
  float3 PosN;
  PosN.xy = r1.xy; // Screen position [-1,1]
  PosN.z = r5.x;   // Depth
  
  // Camera motion calculation
  r6.xyz = cb1[115].xyw * r1.yyy; // View matrix multiplication
  r6.xyz = r1.xxx * cb1[114].xyw + r6.xyz;
  r6.xyz = PosN.z * cb1[116].xyw + r6.xyz;
  r6.xyz = cb1[117].xyw + r6.xyz;
  
  r5.xw = r6.xy / r6.z; // Previous frame screen position
  r5.xw = r1.xy - r5.xw; // Camera motion vector
  
  // Sample velocity texture (with potential offset for dilation)
  r5.yz = (int2)r0.xy + (int2)r5.yz;
  r5.yz = max((int2)r5.yz, (int2)r2.xy);
  r6.xy = min((int2)r5.yz, (int2)r3.xy);
  r6.zw = float2(0,0);
  
  r5.yz = t4.Load(r6.xyz).xy; // Sample encoded velocity
  
  // Check if we have dynamic motion
  r0.w = dot(r5.yz, r5.yz);
  r0.w = cmp(0 < r0.w);
  
  // Decode velocity if available
  r5.yz = float2(-0.499992371,-0.499992371) + r5.yz;
  r5.yz = float2(4.00801611,4.00801611) * r5.yz;
  
  // Use dynamic motion if available, otherwise camera motion
  r5.xy = r0.ww ? r5.yz : r5.xw;
  
  // DLSS-SPECIFIC MOTION VECTOR PREPARATION
  // Convert motion vectors to pixel space for DLSS
  // VelocityCombine.usf uses: -BackTemp * float2(0.5, -0.5)
  // where BackTemp = BackN * ViewportSize
  
  // Get render resolution for scaling
  float2 RenderResolution = cb1[122].xy;
  
  // Convert motion vector to pixel space
  float2 MotionPixels = r5.xy * RenderResolution;
  
  // Apply DLSS-specific scaling and negation
  // DLSS expects motion vectors in pixel units with specific sign convention
  float2 DLSSMotionVector = -MotionPixels * float2(0.5, -0.5);
  
  // Output motion vector for DLSS
  o0.xy = DLSSMotionVector;
  o0.zw = float2(0,0);
  
  return;
}