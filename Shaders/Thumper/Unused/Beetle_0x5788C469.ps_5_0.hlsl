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
TextureCube<float4> gReflectionMap : register(t2);
Texture2D<float4> gReflectivityMap : register(t3);
Texture2D<float4> gEmissiveMap : register(t4);

// Luma: unchanged
void main(
  float v0 : SV_ClipDistance0,
  float w0 : SV_CullDistance0,
  float4 v1 : SV_Position0,
  float2 v2xy : TEXCOORD0,
  float v2z : TEXCOORD4,
  float4 v3 : COLOR0,
  float3 v4 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyz = gReflectionMap.Sample(gReflectionSampler_s, v4.xyz).xyz;
  r0.xyz = gMat.Kr.xyz * r0.xyz;
  r1.xyz = gReflectivityMap.Sample(gReflectivitySampler_s, v2xy).xyz;
  r0.xyz = r0.xyz * r1.xyz + v3.xyz;
  r1.xyz = gEmissiveMap.Sample(gEmissiveSampler_s, v2xy).xyz;
  r0.xyz = gMat.KeAlpha.xyz * r1.xyz + r0.xyz;
  r0.xyz = -gEnv.fogColorDensity.xyz + r0.xyz;
  r0.xyz = v2z * r0.xyz + gEnv.fogColorDensity.xyz;
  o0.xyz = gMaxOutputColor.xyz * r0.xyz;
  o0.w = v3.w;

  // Luma: emulate UNORM
  o0.xyz = max(o0.xyz, 0.0);
  o0.w = saturate(o0.w);
}