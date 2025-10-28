#include "../Includes/Common.hlsl"

#ifndef ENABLE_HDR_BOOST
#define ENABLE_HDR_BOOST 1
#endif

cbuffer g_MaterialPS_CB : register(b0)
{

  struct
  {
    float4 fs_layer0_diffuse;
    float4 fs_layer1_diffuse;
    float4 fs_layer2_diffuse;
    float4 fs_layer3_diffuse;
    float4 fs_specular_specular;
    float4 fs_specular2_specular;
    float4 fs_specular_params;
    float4 fs_surface_params;
    float4 fs_surface_params2;
    float4 fs_incandescentGlow;
    float4 fs_rimLightColour;
    float4 fs_fresnel_params;
    float4 fs_ambientColor;
    float4 fs_envmap_params;
    float4 fs_diffenv_params;
    float4 fs_refraction_color;
    float4 fs_refraction_kIndex;
    float4 fs_lego_params;
    float4 fs_vtf_kNormal;
    float4 fs_carpaint_params;
    float4 fs_brdf_params;
    float4 fs_fractal_params;
    float4 fs_carpaint_tints0;
    float4 fs_carpaint_tints1;
    float4 fs_specular3_specular;
    float4 fs_lego_brdf_fudge;
  } g_MaterialPS : packoffset(c0);

}

cbuffer g_MiscGroupPS_CB : register(b1)
{

  struct
  {
    float4 fs_fog_color;
    float4 fs_liveCubemapReflectionPlane;
    float4 fs_envRotation0;
    float4 fs_envRotation1;
    float4 fs_envRotation2;
    float4 fs_exposure;
    float4 fs_screenSize;
    float4 fs_time;
    float4 fs_exposure2;
    float4 fs_fog_color2;
    float4 fs_per_pixel_fade_pos;
    float4 fs_per_pixel_fade_col;
    float4 fs_per_pixel_fade_rot;
    float4 fs_fog_params1;
    float4 fs_fog_params2;
    float4 fs_fog_params3;
    float4 fs_fog_params4;
  } g_MiscGroupPS : packoffset(c0);

}

SamplerState layer0_sampler_ss_s : register(s5);
SamplerState layer1_sampler_ss_s : register(s6);
Texture2D<float4> layer0_sampler : register(t5);
Texture2D<float4> layer1_sampler : register(t6);

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : COLOR0,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1,
  out float4 o2 : SV_Target2)
{
  float4 r0,r1,r2;
  r0.xyz = layer0_sampler.Sample(layer0_sampler_ss_s, v1.zw).xyz;
  r0.xyz = g_MaterialPS.fs_layer0_diffuse.xyz * r0.xyz;
  r1.xyzw = layer1_sampler.Sample(layer1_sampler_ss_s, v1.xy).xyzw;
  r1.xyz = g_MaterialPS.fs_layer1_diffuse.xyz * r1.xyz;
  r0.w = g_MaterialPS.fs_layer1_diffuse.w * v2.w;
  r2.x = r0.w * r1.w;
  r0.w = -r0.w * r1.w + 1;
  r1.xyz = r2.xxx * r1.xyz;
  r0.xyz = r0.xyz * r0.www + r1.xyz;
  r1.xyz = v2.xyz + v2.xyz;
  r0.xyz = r1.xyz * r0.xyz;
  r0.xyz = r0.xyz * r0.xyz;
  r0.w = 1 + g_MaterialPS.fs_incandescentGlow.w;
  r0.xyz = r0.xyz * r0.www;
  r0.xyz = g_MiscGroupPS.fs_exposure.yyy * r0.xyz;
  r0.w = max(r0.x, r0.y);
  r0.w = max(r0.w, r0.z);
  r0.w = max(9.99999975e-006, r0.w);
  r0.w = sqrt(r0.w);
  r0.w = 45.0780563 * r0.w;
  r0.w = ceil(r0.w);
  r1.x = 0.0221837424 * r0.w;
  o0.w = 0.00392156886 * r0.w;
  r0.w = r1.x * r1.x;
  o0.xyz = r0.xyz / r0.www;
  o1.xyzw = float4(0.5,0.5,0,0);
  o2.xyzw = float4(0,0,0,0.501960814);
  
#if ENABLE_HDR_BOOST
  // Make sky nice again
  if (LumaSettings.DisplayMode == 1)
  {
    o0.xyz = gamma_to_linear(o0.xyz, GCT_MIRROR);
    float normalizationPoint = 0.025; // Found empyrically
    float fakeHDRIntensity = 0.2;
    float fakeHDRSaturation = 0.333;
    o0.xyz = FakeHDR(o0.xyz, normalizationPoint, fakeHDRIntensity, fakeHDRSaturation);
    o0.xyz = linear_to_gamma(o0.xyz, GCT_MIRROR);
  }
#endif
}