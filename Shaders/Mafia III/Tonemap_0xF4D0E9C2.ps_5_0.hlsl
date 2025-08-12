Texture3D<float4> t9 : register(t9); // LUT?
Texture2D<float4> t8 : register(t8); // Film grain map
Texture2D<float4> t7 : register(t7); // Lens flare
Texture2D<float4> t6 : register(t6); // Iris/vignette fullscreen effect?
Texture2D<float4> t5 : register(t5); // Some noise map?
Texture2D<float4> t4 : register(t4); // Exposure?
Texture2D<float4> t3 : register(t3); // Blood overlay
Texture2D<float4> t2 : register(t2); // Bloom
Texture2D<float4> t1 : register(t1); // Scene
Texture2D<float4> t0 : register(t0); // Some overlay

SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[7];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[7];
}

#define cmp -

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1)
{
  float4 r0,r1,r2,r3,r4,r5,r6;

  r0.xyz = t1.Sample(s1_s, v1.yz).xyz;
  
#if 0 // Disable all - linear untonemapped raw HDR
  r0.a = 1.0;
  o0 = r0;
  o1 = 0.0;
  return;
#endif
  
  r1.xyzw = cmp(float4(0,0,0,0) < cb0[3].xyzw);
  
#if 0 // Chromatic Aberration (doesn't have a user toggle)
  if (r1.x != 0) {
    r2.xy = max(float2(0.00999999978,0), cb1[6].zw);
    r2.zw = v1.yz * float2(2,2) + float2(-1,-1);
    r2.zw = r2.zw * r2.zw;
    r1.x = r2.z + r2.w;
    r1.x = sqrt(r1.x);
    r2.y = 0.00499999989 * r2.y;
    r1.x = max(9.99999975e-006, r1.x);
    r1.x = log2(r1.x);
    r1.x = r2.x * r1.x;
    r1.x = exp2(r1.x);
    r2.z = r2.y * r1.x;
    r2.x = -r2.z;
    r2.yw = float2(0,0);
    r2.xyzw = v1.yzyz + r2.xyzw;
    r2.x = t1.Sample(s1_s, r2.xy).x;
    r2.y = t1.Sample(s1_s, r2.zw).z;
    r2.xy = r2.xy + r0.xz;
    r0.xz = float2(0.5,0.5) * r2.xy;
  }
#endif
  
  // Overlays additive draw
  if (r1.y != 0) {
    r2.xyz = t7.Sample(s2_s, v1.yz).xyz;
    r1.x = t3.Sample(s2_s, v1.yz).x;
    r1.y = t6.Sample(s2_s, v1.yz).x;
    r1.x = 0.100000001 * r1.x;
    r1.x = r1.x * r1.x;
    r2.xyz = r1.xxx * r2.xyz;
    r1.x = r1.y * 100 + 5;
    r2.xyz = r2.xyz * r1.xxx;
    r0.w = r0.y;
    r0.xyz = r2.xyz * cb1[0].zzz + r0.xwz;
  }
  
  // Bloom and something else
  if (r1.z != 0) {
    r1.xyz = t2.Sample(s2_s, v1.yz).xyz;
    float3 someOverlay = t0.Sample(s2_s, v1.yz).xyz;
    r1.xyz += someOverlay * cb0[2].y;
    r0.xyz += r1.xyz * saturate(r0.xyz * 10.0); // RenoDX: fix bloom raising blacks too much (random)
  }
  
  r2.xyzw = cmp(float4(0,0,0,0) < cb0[4].xyzw);
  
  // Levels (multiply and add)
  if (r2.x) 
  {
    r0.xyz = r0.xyz * cb1[2].xyz + cb1[1].xyz;
  }
  // RenoDX: removed "r0.xyz" saturate here
  
  // Tonemapper (and exposure?)
  if (r1.w != 0 && 0) {
    r1.xyz = min(float3(65504,65504,65504), r0.xyz);
    r3.xy = t4.Sample(s1_s, float2(0.5,0.5)).yw;
    r0.w = r3.x * r3.y;
    r2.x = cb1[5].y / cb1[5].z;
    r3.y = cb1[4].z * cb1[4].y;
    r3.z = cb1[4].x * r0.w + r3.y;
    r4.xy = cb1[5].xx * cb1[5].yz;
    r3.z = r0.w * r3.z + r4.x;
    r3.w = cb1[4].x * r0.w + cb1[4].y;
    r0.w = r0.w * r3.w + r4.y;
    r0.w = r3.z / r0.w;
    r0.w = r0.w + -r2.x;
    r0.w = 1 / r0.w;
    r1.xyz = r3.xxx * r1.xyz;
    r3.xyz = cb1[4].xxx * r1.xyz + r3.yyy;
    r3.xyz = r1.xyz * r3.xyz + r4.xxx;
    r4.xzw = cb1[4].xxx * r1.xyz + cb1[4].yyy;
    r1.xyz = r1.xyz * r4.xzw + r4.yyy;
    r1.xyz = r3.xyz / r1.xyz;
    r1.xyz = r1.xyz + -r2.xxx;
    r1.xyz = r1.xyz * r0.www; // RenoDX: removed saturate()
    r1.xyz = log2(r1.xyz);
    r1.xyz = cb0[2].xxx * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r1.xyz = r1.xyz; // RenoDX: removed saturate()
  } else {
    r1.xyz = r0.xyz;
  }
  
  // LUT
  if (r2.y != 0 && 0) {
    r0.w = cmp(0 < cb0[5].y);
    if (r0.w != 0) {
      r0.w = max(r1.x, r1.y);
      r0.w = max(r0.w, r1.z);
      r0.w = max(9.99999997e-007, r0.w);
      r2.x = -r0.w * 1.90476203 + 5.80952358;
      r2.x = r0.w * r2.x + -0.429761916;
      r2.x = 0.25 * r2.x;
      r3.x = 1 + -r0.w;
      r3.x = cmp(abs(r3.x) < 0.524999976);
      r3.y = min(1, r0.w);
      r2.x = r3.x ? r2.x : r3.y;
      r0.w = r2.x / r0.w;
      r3.xyz = r1.xyz * r0.www;
      r4.xyz = max(float3(9.99999975e-006,9.99999975e-006,9.99999975e-006), r3.xyz);
      r4.xyz = log2(r4.xyz);
      r4.xyz = float3(0.454545468,0.454545468,0.454545468) * r4.xyz;
      r4.xyz = exp2(r4.xyz);
      r4.xyz = r4.xyz * float3(0.9375,0.9375,0.9375) + float3(0.03125,0.03125,0.03125);
      r4.xyz = t9.Sample(s2_s, r4.xyz).xyz;
      r4.xyz = max(float3(9.99999975e-006,9.99999975e-006,9.99999975e-006), r4.xyz);
      r4.xyz = log2(r4.xyz);
      r4.xyz = float3(2.20000005,2.20000005,2.20000005) * r4.xyz;
      r4.xyz = exp2(r4.xyz);
      r2.x = saturate(cb1[6].y);
      r4.xyz = -r1.xyz * r0.www + r4.xyz;
      r3.xyz = r2.xxx * r4.xyz + r3.xyz;
      r1.xyz = r3.xyz / r0.www;
    } else {
      r3.xyz = max(float3(9.99999975e-006,9.99999975e-006,9.99999975e-006), r1.xyz);
      r3.xyz = log2(r3.xyz);
      r3.xyz = float3(0.454545468,0.454545468,0.454545468) * r3.xyz;
      r3.xyz = exp2(r3.xyz);
      r3.xyz = r3.xyz * float3(0.9375,0.9375,0.9375) + float3(0.03125,0.03125,0.03125);
      r3.xyz = t9.Sample(s2_s, r3.xyz).xyz;
      r3.xyz = max(float3(9.99999975e-006,9.99999975e-006,9.99999975e-006), r3.xyz);
      r3.xyz = log2(r3.xyz);
      r3.xyz = float3(2.20000005,2.20000005,2.20000005) * r3.xyz;
      r3.xyz = exp2(r3.xyz);
      r0.w = saturate(cb1[6].y);
      r3.xyz = r3.xyz + -r1.xyz;
      r1.xyz = r0.www * r3.xyz + r1.xyz; // RenoDX: removed saturate()
    }
  }
  
  r0.w = saturate(cb1[6].x);
  r3.xyz = min(float3(65504,65504,65504), r1.xyz);
  r2.x = dot(r3.xyz, float3(0.212500006,0.715399981,0.0720999986));
  r3.xyz = r2.xxx + -r1.xyz;
  r3.xyz = r0.www * r3.xyz + r1.xyz;
  r1.xyz = r2.zzz ? r3.xyz : r1.xyz;
  // Additive Film Grain
  if (r2.w != 0) {
    r3.xy = cb0[0].xx * v1.yz;
    r4.x = dot(cb0[1].xy, r3.xy);
    r4.y = dot(cb0[1].zw, r3.xy);
    r3.xyz = t8.Sample(s0_s, r4.xy).xyz;
    r1.xyz += r3.xyz * cb0[0].yyy;
  }
  
  r2.x = cmp(0 < cb0[5].x);
  r3.xyz = float3(-1,-1,-1) + cb1[3].xyz;
  r3.xyz = saturate(v1.xxx * r3.xyz + float3(1,1,1));
  r4.xyz = r3.xyz * r1.xyz;
  r1.xyz = r2.xxx ? r4.xyz : r1.xyz;
  if (r1.w != 0) {
    r4.xyz = min(float3(65504,65504,65504), r0.xyz);
    r5.xy = t4.Sample(s1_s, float2(0.5,0.5)).yw;
    r1.w = r5.x * r5.y;
    r3.w = cb1[5].y / cb1[5].z;
    r4.w = cb1[4].z * cb1[4].y;
    r5.y = cb1[4].x * r1.w + r4.w;
    r5.zw = cb1[5].xx * cb1[5].yz;
    r5.y = r1.w * r5.y + r5.z;
    r6.x = cb1[4].x * r1.w + cb1[4].y;
    r1.w = r1.w * r6.x + r5.w;
    r1.w = r5.y / r1.w;
    r1.w = r1.w + -r3.w;
    r1.w = 1 / r1.w;
    r4.xyz = r5.xxx * r4.xyz;
    r6.xyz = cb1[4].xxx * r4.xyz + r4.www;
    r5.xyz = r4.xyz * r6.xyz + r5.zzz;
    r6.xyz = cb1[4].xxx * r4.xyz + cb1[4].yyy;
    r4.xyz = r4.xyz * r6.xyz + r5.www;
    r4.xyz = r5.xyz / r4.xyz;
    r4.xyz = r4.xyz + -r3.www;
    r4.xyz = saturate(r4.xyz * r1.www);
    r4.xyz = log2(r4.xyz);
    r4.xyz = cb0[2].xxx * r4.xyz;
    r4.xyz = exp2(r4.xyz);
    r0.xyz = min(float3(1,1,1), r4.xyz);
  }
  if (r2.y != 0) {
    r4.xyz = max(float3(9.99999975e-006,9.99999975e-006,9.99999975e-006), r0.xyz);
    r4.xyz = log2(r4.xyz);
    r4.xyz = float3(0.454545468,0.454545468,0.454545468) * r4.xyz;
    r4.xyz = exp2(r4.xyz);
    r4.xyz = r4.xyz * float3(0.9375,0.9375,0.9375) + float3(0.03125,0.03125,0.03125);
    r4.xyz = t9.Sample(s2_s, r4.xyz).xyz;
    r4.xyz = max(float3(9.99999975e-006,9.99999975e-006,9.99999975e-006), r4.xyz);
    r4.xyz = log2(r4.xyz);
    r4.xyz = float3(2.20000005,2.20000005,2.20000005) * r4.xyz;
    r4.xyz = exp2(r4.xyz);
    r1.w = saturate(cb1[6].y);
    r4.xyz = r4.xyz + -r0.xyz;
    r0.xyz = saturate(r1.www * r4.xyz + r0.xyz);
  }
  r4.xyz = min(float3(65504,65504,65504), r0.xyz);
  r1.w = dot(r4.xyz, float3(0.212500006,0.715399981,0.0720999986));
  r4.xyz = r1.www + -r0.xyz;
  r4.xyz = r0.www * r4.xyz + r0.xyz;
  r0.xyz = r2.zzz ? r4.xyz : r0.xyz;
  if (r2.w != 0) {
    r2.yz = cb0[0].xx * v1.yz;
    r4.x = dot(cb0[1].xy, r2.yz);
    r4.y = dot(cb0[1].zw, r2.yz);
    r2.yzw = t8.Sample(s0_s, r4.xy).xyz;
    r0.xyz = r2.yzw * cb0[0].yyy + r0.xyz;
  }
  r2.yzw = r0.xyz * r3.xyz;
  o1.xyz = r2.xxx ? r2.yzw : r0.xyz;
  r0.x = cmp(0 < cb0[6].z);
  if (r0.x != 0) {
    r0.xy = cb0[6].xy + v0.xy;
    r0.xy = (int2)r0.xy;
    r0.xy = (int2)r0.xy & int2(63,63);
    r0.zw = float2(0,0);
    r0.xyz = t5.Load(r0.xyz).xyz;
    r0.xyz = r0.xyz * float3(2,2,2) + float3(-1,-1,-1);
    r2.xyz = max(float3(0,0,0), r1.xyz);
    r2.xyz = sqrt(r2.xyz);
    r3.xyz = cb0[6].www + r2.xyz;
    r3.xyz = min(cb0[6].zzz, r3.xyz);
    r0.xyz = r0.xyz * r3.xyz + r2.xyz;
    r1.xyz = r0.xyz * r0.xyz;
  }
  o0.xyz = r1.xyz;
  o0.w = 1;
  o1.w = 1;
}