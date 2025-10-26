#include "../Includes/Common.hlsl"

cbuffer StandardConstants : register(b0)
{
  float4x4 gViewProj[2] : packoffset(c0);

  struct
  {
    float4x4 worldMtx;

    struct
    {
      float4 angles_ysize;
      float4 offsets;
      float4 scale;
      float4 prev_scale_lane;
    } bend;


    struct
    {
      float4x4 mtx;
      float4 offset;
    } shadow;

    float4 vScaleYOffsetFrac;
    float4 beat;
  } gXfm : packoffset(c8);


  struct
  {
    float4 globalAmbient;
    float4 lightDiffuse[2];
    float4 lightSpecular[2];
    float4 lightC;
    float4 lightL;
    float4 fogColorDensity;
  } gEnv : packoffset(c23);

  float4 gWorldEyePosition[2] : packoffset(c31);
  float4 gWorldLightPosition[2] : packoffset(c33);

  struct
  {
    float4 KeAlpha;
    float4 Ka;
    float4 Kd;
    float4 KsShininess;
    float4 Kr;
    float4x4 texXfm;
  } gMat : packoffset(c35);


  struct
  {
    float4 color_radius;
    float4 eye_centers;
    float4 scale;
    float4 uv_offset_scale;
  } gNoiseVig : packoffset(c44);


  struct
  {
    float4 beat_width_start_end[4];
    float4 atlasv_intensity_lane[4];
  } gPulse : packoffset(c48);

  float4 gTurnZScale : packoffset(c56);
  float4 gSequinMinMaxBeat : packoffset(c57);
}

cbuffer MaxOutputConstants : register(b12)
{
  float4 gMaxOutputColor : packoffset(c0);
}

SamplerState gReflectionSampler_s : register(s2);
SamplerState gReflectivitySampler_s : register(s3);
SamplerState gEmissiveSampler_s : register(s4);
SamplerState gSpecularSampler_s : register(s5);
TextureCube<float4> gReflectionMap : register(t2);
Texture2D<float4> gReflectivityMap : register(t3);
Texture2D<float4> gEmissiveMap : register(t4);
Texture2D<float4> gSpecularMap : register(t5);

// Two identical shaders with the same hash, there was different private data
void main(
  float v0 : SV_ClipDistance0,
  float w0 : SV_CullDistance0,
  float4 v1 : SV_Position0,
  float2 v2xy : TEXCOORD0,
  float v2z : TEXCOORD4,
  float3 v3 : TEXCOORD1,
  float3 v4 : TEXCOORD2,
  float3 v5 : TEXCOORD3,
  nointerpolation uint v6 : TEXCOORD6,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyz = gWorldLightPosition[0].xyz + -v3.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(max(r0.w, 1e-8)); // Luma: nans prevention
  r0.xyz = r0.xyz * r0.www;
  r0.w = v6.x;
  r1.xyz = gWorldEyePosition[r0.w].xyz + -v3.xyz;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(max(r0.w, 1e-8)); // Luma: nans prevention
  r1.xyz = r1.xyz * r0.www + r0.xyz;
  r0.x = dot(v4.xyz, r0.xyz);
  r0.y = dot(r1.xyz, r1.xyz);
  r0.y = rsqrt(max(r0.y, 1e-8)); // Luma: nans prevention
  r0.yzw = r1.xyz * r0.yyy;
  r0.y = dot(v4.xyz, r0.yzw);
  r0.xy = max(float2(0,0), r0.xy);
  r0.y = log2(r0.y);
  r0.y = gMat.KsShininess.w * r0.y; // Luma: this is too high! It's set to 30
  r0.y = exp2(r0.y);
#if 1 // This is the one that actually helps
  r0.y = min(r0.y, 2.0); // Luma: prevent infinities
#endif
  r1.xyz = gEnv.lightSpecular[0].xyz * r0.xxx;
  r0.xzw = gEnv.lightDiffuse[0].xyz * r0.xxx;
  r1.xyz = r1.xyz * r0.yyy;
  r2.xyz = -gWorldLightPosition[0].xyz + v3.xyz;
  r0.y = dot(r2.xyz, r2.xyz);
  r0.y = sqrt(abs(r0.y)) * sign(r0.y); // Luma: nans prevention
  r0.y = gEnv.lightL.x * r0.y + gEnv.lightC.x;
  r0.y = 1 / (r0.y >= 0.0 ? max(r0.y, 1e-8) : min(r0.y, -1e-8)); // Luma: nans prevention
  r1.xyz = r1.xyz * r0.yyy;
  r0.xyz = r0.xzw * r0.yyy;
  r0.xyz = gMat.Kd.xyz * r0.xyz;
  r0.xyz = gMat.Ka.xyz * gEnv.globalAmbient.xyz + r0.xyz;
  r2.xyz = gSpecularMap.Sample(gSpecularSampler_s, v2xy).xyz;
  r2.xyz = gMat.KsShininess.xyz * r2.xyz;
  r0.xyz = r2.xyz * r1.xyz + r0.xyz;
  r1.xyz = gReflectionMap.Sample(gReflectionSampler_s, v5.xyz).xyz;
  r1.xyz = gMat.Kr.xyz * r1.xyz;
  r2.xyz = gReflectivityMap.Sample(gReflectivitySampler_s, v2xy).xyz;
  r0.xyz = r1.xyz * r2.xyz + r0.xyz;
  r1.xyz = gEmissiveMap.Sample(gEmissiveSampler_s, v2xy).xyz;
  r0.xyz = gMat.KeAlpha.xyz * r1.xyz + r0.xyz;
  r0.xyz = -gEnv.fogColorDensity.xyz + r0.xyz;
  r0.xyz = v2z * r0.xyz + gEnv.fogColorDensity.xyz;
  o0.xyz = gMaxOutputColor.xyz * r0.xyz;
  o0.w = gMat.KeAlpha.w;
  
  // Luma: don't seem needed but won't hurt
  o0.xyz = IsNaN_Strict(o0.xyz) ? 0.0 : o0.xyz;
  o0.xyz = IsInfinite_Strict(o0.xyz) ? 0.0 : o0.xyz;

  // Luma: emulate UNORM
  o0.xyz = max(o0.xyz, 0.0);
  o0.w = saturate(o0.w);
}