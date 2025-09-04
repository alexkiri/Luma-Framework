cbuffer _Globals : register(b0)
{
  float4x4 LocalToWorld : packoffset(c0);
  float4x4 InvViewProjectionMatrix : packoffset(c4);
  float3 CameraWorldPos : packoffset(c8);
  float4 ObjectWorldPositionAndRadius : packoffset(c9);
  float3 ObjectOrientation : packoffset(c10);
  float3 ObjectPostProjectionPosition : packoffset(c11);
  float3 ObjectNDCPosition : packoffset(c12);
  float4 ObjectMacroUVScales : packoffset(c13);
  float3 FoliageImpulseDirection : packoffset(c14);
  float4 FoliageNormalizedRotationAxisAndAngle : packoffset(c15);
  float4 WindDirectionAndSpeed : packoffset(c16);
  float3 CameraWorldDirection : packoffset(c17) = {1,0,0};
  float4 ObjectOriginAndPrimitiveID : packoffset(c18) = {0,0,0,0};
  float OcclusionPercentage : packoffset(c19);
  float4 UniformPixelVector_0 : packoffset(c20);
  float4 UniformPixelVector_1 : packoffset(c21);
  float4 UniformPixelVector_2 : packoffset(c22);
  float4 UniformPixelVector_3 : packoffset(c23);
  float4 CameraRight : packoffset(c24);
  float4 CameraUp : packoffset(c25);
  float3 IrradianceUVWScale : packoffset(c26);
  float3 IrradianceUVWBias : packoffset(c27);
  float AverageDynamicSkylightIntensity : packoffset(c27.w);
  float4 LightEnvironmentRedAndGreenUV : packoffset(c28);
  float2 LightEnvironmentBlueUV : packoffset(c29);
}

cbuffer PSOffsetConstants : register(b2)
{
  float4 ScreenPositionScaleBias : packoffset(c0);
  float4 MinZ_MaxZRatio : packoffset(c1);
  float NvStereoEnabled : packoffset(c2);
}

SamplerState SceneDepthTexture_s : register(s0);
SamplerState Texture2D_0_s : register(s1);
Texture2D<float4> Texture2D_0 : register(t0);
Texture2D<float4> SceneDepthTexture : register(t1);

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  float4 v2 : TEXCOORD2,
  float4 v3 : TEXCOORD4,
  float4 v4 : TEXCOORD5,
  float4 v5 : TEXCOORD6,
  float4 v6 : TEXCOORD7,
  uint v7 : SV_IsFrontFace0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xy = v4.xy / v4.ww;
  r0.xy = r0.xy * ScreenPositionScaleBias.xy + ScreenPositionScaleBias.wz;
  r0.x = SceneDepthTexture.SampleLevel(SceneDepthTexture_s, r0.xy, 0).x;
  r0.x = min(0.999000013, r0.x);
  r0.x = r0.x * MinZ_MaxZRatio.z + -MinZ_MaxZRatio.w;
  r0.x = 1 / r0.x;
  r0.x = saturate(7.00000019e-005 * r0.x);
  r0.yzw = Texture2D_0.Sample(Texture2D_0_s, v0.xy).xyz;
  r0.yzw = OcclusionPercentage * r0.yzw;
  r0.yzw = v1.xyz * r0.yzw;
  r0.xyz = r0.xxx * r0.yzw + UniformPixelVector_1.xyz;
  o0.xyz = v3.www * r0.xyz;
  o0.w = 0;
#if 0 // Disable some kind of fog (sun)
  o0.xyz = 0;
#endif
}