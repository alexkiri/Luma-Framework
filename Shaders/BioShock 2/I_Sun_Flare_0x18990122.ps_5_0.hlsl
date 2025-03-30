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

SamplerState Texture2D_0_s : register(s0);
SamplerState Texture2D_1_s : register(s1);
Texture2D<float4> Texture2D_0 : register(t0);
Texture2D<float4> Texture2D_1 : register(t1);

#define cmp -

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
  float4 r0,r1,r2;
  r0.x = 3978.87354 * v2.y;
  r0.y = cmp(r0.x >= -r0.x);
  r0.x = frac(abs(r0.x));
  r0.x = r0.y ? r0.x : -r0.x;
  r0.x = 6.28318548 * r0.x;
  sincos(r0.x, r0.x, r1.x);
  r2.x = -r0.x;
  r2.y = r1.x;
  r2.z = r0.x;
  r0.xy = float2(-0.5,-0.5) + v0.xy;
  r1.x = dot(r2.yx, r0.xy);
  r1.y = dot(r2.zy, r0.xy);
  r0.xy = float2(0.5,0.5) + r1.xy;
  r0.x = Texture2D_1.Sample(Texture2D_1_s, r0.xy).x;
  r0.x = r0.x * r0.x;
  r0.x = 0.25 * r0.x;
  r0.yzw = Texture2D_0.Sample(Texture2D_0_s, v0.xy).xyz;
  r0.xyz = r0.yzw * r0.yzw + r0.xxx;
  r0.w = v2.w * v2.w;
  r1.x = OcclusionPercentage * OcclusionPercentage;
  r0.w = r1.x * r0.w;
  r0.xyz = r0.www * r0.xyz;
  r0.xyz = float3(0.5,0.5,0.5) * r0.xyz;
  r0.xyz = min(float3(1,1,1), r0.xyz);
  r1.xyz = v1.www * v1.xyz;
  r0.xyz = r0.xyz * r1.xyz + UniformPixelVector_1.xyz;
  o0.xyz = v3.www * r0.xyz;
#if 0 // LUMA: make sun sprite stronger
  o0.xyz *= 2.5;
#endif
  o0.w = 0;
}