cbuffer _Globals : register(b0)
{
  float Base_hlsl_PSMain00000000000000008000000000080440_64bits : packoffset(c0) = {0};
  float4 fogColor : packoffset(c1);
  float3 fogTransform : packoffset(c2);
  float2 fogLuminance : packoffset(c3);
  row_major float3x4 screenDataToCamera : packoffset(c4);
  float globalScale : packoffset(c7);
  float sceneDepthAlphaMask : packoffset(c7.y);
  float globalOpacity : packoffset(c7.z);
  float distortionBufferScale : packoffset(c7.w);
  float3 wToZScaleAndBias : packoffset(c8);
  float4 screenTransform[2] : packoffset(c9);
  row_major float4x4 worldViewProj : packoffset(c11);
  float3 localEyePos : packoffset(c15);
  float4 vertexClipPlane : packoffset(c16);
  float alphaFromDiffuse : packoffset(c17);
  float edgeSpecularPower : packoffset(c17.y);
  float facingSpecularPower : packoffset(c17.z);
  float3 edgeSpecularColor : packoffset(c18);
  float3 facingSpecularColor : packoffset(c19);
  float3 edgeSelfIlluminationColor : packoffset(c20);
  float3 facingSelfIlluminationColor : packoffset(c21);
  float3 edgeDiffuseColor : packoffset(c22);
  float3 facingDiffuseColor : packoffset(c23);
  float hardness : packoffset(c23.w);
  float edgeOpacityScale : packoffset(c24);
  float facingOpacityScale : packoffset(c24.y);
  float3 subsurfaceColor : packoffset(c25);
  row_major float2x4 blendTexTransform : packoffset(c26);
  row_major float2x4 normalTexTransform : packoffset(c28);
  row_major float2x4 edgeOpacityTexTransform : packoffset(c30);
  row_major float2x4 facingOpacityTexTransform : packoffset(c32);
  row_major float2x4 edgeDiffuseTexTransform : packoffset(c34);
  row_major float2x4 facingDiffuseTexTransform : packoffset(c36);
  row_major float2x4 facingSpecularTexTransform : packoffset(c38);
  row_major float2x4 edgeSpecularTexTransform : packoffset(c40);
  float4 unlitColor : packoffset(c42);
  row_major float4x3 localToWorld : packoffset(c43);
}

SamplerState mtbSampleSlot1_s : register(s0);
SamplerState mtbSampleSlot2_s : register(s1);
Texture2D<float4> mtbSampleSlot2 : register(t0);
Texture2D<float4> mtbSampleSlot1 : register(t1);


// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : TEXCOORD6,
  float4 v1 : TEXCOORD7,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD2,
  float4 v5 : COLOR1,
  float4 v6 : TEXCOORD3,
  float4 v7 : TEXCOORD4,
  float3 v8 : TEXCOORD5,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = dot(v1.xyz, v1.xyz);
  r0.x = rsqrt(r0.x);
  r0.xyz = v1.xyz * r0.xxx;
  r0.x = dot(float3(0.00100000005,0.00100000005,1), r0.xyz);
  r0.x = 1 + -abs(r0.x);
  r0.x = max(0, r0.x);
  r0.x = log2(r0.x);
  r0.y = 1.00100005 * hardness;
  r0.x = r0.y * r0.x;
  r0.x = exp2(r0.x);
  r0.x = 1 + -r0.x;
  r1.xyzw = mtbSampleSlot2.Sample(mtbSampleSlot2_s, v4.wz).xyzw;
  r0.yzw = r1.xyz * facingSelfIlluminationColor.xyz + -edgeSelfIlluminationColor.xyz;
  r0.yzw = r0.xxx * r0.yzw + edgeSelfIlluminationColor.xyz;
  r0.yzw = unlitColor.xyz * r0.yzw;
  r1.xyz = facingDiffuseColor.xyz + -edgeDiffuseColor.xyz;
  r1.xyz = r0.xxx * r1.xyz + edgeDiffuseColor.xyz;
  r0.yzw = r1.xyz * unlitColor.xyz + r0.yzw;
  r1.xyz = fogColor.xyz + -r0.yzw;
  r0.yzw = v0.zzz * r1.xyz + r0.yzw;
  o0.xyz = globalScale * r0.yzw;
  r1.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v3.wz).xyzw;
  r2.xyzw = mtbSampleSlot1.Sample(mtbSampleSlot1_s, v3.xy).xyzw;
  r0.y = edgeOpacityScale * r2.x;
  r0.z = r1.x * facingOpacityScale + -r0.y;
  r0.x = r0.x * r0.z + r0.y;
  r0.x = alphaFromDiffuse * -r0.x + r0.x;
  r0.y = globalOpacity * v1.w;
  o0.w = r0.x * r0.y;
  return;
}