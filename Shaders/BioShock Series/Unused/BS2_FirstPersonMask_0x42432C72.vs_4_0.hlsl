cbuffer _Globals : register(b0)
{
  float GlobalLitLighting_hlsl_VSMain0000000000000000000020a016adcae4_46bits : packoffset(c0) = {0};
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
  float4 UniformVector_0 : packoffset(c17);
  float4 UniformVector_1 : packoffset(c18);
  float4 UniformVector_2 : packoffset(c19);
  float4 UniformVector_3 : packoffset(c20);
  float UniformScalar_0 : packoffset(c21);
  float UniformScalar_1 : packoffset(c21.y);
  float UniformScalar_2 : packoffset(c21.z);
  float UniformScalar_3 : packoffset(c21.w);
  float UniformScalar_4 : packoffset(c22);
  float UniformScalar_5 : packoffset(c22.y);

  struct
  {
    float4 light_vector;
    float4 color_invradius;
    float4 spot_projection1;
    float4 spot_projection2;
    float4 spot_projection3;
  } Lights[4] : packoffset(c23);

  float bLightEnable0 : packoffset(c43);
  float bLightEnable1 : packoffset(c43.y);
  float bLightEnable2 : packoffset(c43.z);
  float bLightEnable3 : packoffset(c43.w);
  float bLightIsSpot0 : packoffset(c44);
  float bLightIsSpot1 : packoffset(c44.y);
  float bLightIsSpot2 : packoffset(c44.z);
  float bLightIsSpot3 : packoffset(c44.w);
}

#define cmp

void main(
  float4 v0 : POSITION0,
  float3 v1 : TANGENT0,
  float3 v2 : BINORMAL0,
  float3 v3 : NORMAL0,
  float4 v4 : TEXCOORD0,
  float4 v5 : TEXCOORD1,
  float4 v6 : TEXCOORD2,
  float4 v7 : TEXCOORD3,
  float4 v8 : TEXCOORD4,
  float4 v9 : TEXCOORD5,
  float4 v10 : COLOR0,
  float4 v11 : COLOR1,
  float4 v12 : BLENDINDICES0,
  out float4 o0 : TEXCOORD6,
  out float4 o1 : TEXCOORD7,
  out float4 o2 : TEXCOORD0,
  out float2 o3 : TEXCOORD1,
  out float4 o4 : TEXCOORD4,
  out float3 o5 : TEXCOORD5,
  out float4 o6 : SV_Position0,
  out float o7 : SV_ClipDistance0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9;
  r0.xyz = v1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r1.xyz = v2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r2.xyz = v3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.x = dot(worldViewProj._m00_m01_m02_m03, v0.xyzw);
  r3.y = dot(worldViewProj._m10_m11_m12_m13, v0.xyzw);
  r3.z = dot(worldViewProj._m20_m21_m22_m23, v0.xyzw);
  r3.w = dot(worldViewProj._m30_m31_m32_m33, v0.xyzw);
  o7.x = dot(vertexClipPlane.xyzw, r3.xyzw);
  r4.xyz = localEyePos.xyz + -v0.xyz;
  o1.x = dot(r4.xyz, r0.xyz);
  o1.y = dot(r4.xyz, r1.xyz);
  o1.z = dot(r4.xyz, r2.xyz);
  r4.x = dot(screenTransform[0].xyzw, r3.xyzw);
  r4.y = dot(screenTransform[1].xyzw, r3.xyzw);
  r4.z = r3.w;
  r4.w = 1;
  r5.x = dot(screenDataToCamera._m00_m01_m02_m03, r4.xyzw);
  r5.y = dot(screenDataToCamera._m10_m11_m12_m13, r4.xyzw);
  r5.z = dot(screenDataToCamera._m20_m21_m22_m23, r4.xyzw);
  r0.w = dot(r5.xyz, r5.xyz);
  r0.w = sqrt(r0.w);
  r0.w = r0.w * fogTransform.x + fogTransform.y;
  r0.w = 1.44269502 * r0.w;
  r0.w = exp2(r0.w);
  r0.w = min(1, r0.w);
  r0.w = -fogColor.w * r0.w + fogColor.w;
  o0.z = fogTransform.z * r0.w;
  r5.xyzw = cmp(float4(0,0,0,0) < bLightEnable0);
  if (r5.x != 0) {
    r0.w = cmp(0 < bLightIsSpot0);
    r6.xyz = -v0.xyz * Lights[0].light_vector.w + Lights[0].light_vector.xyz;
    r7.xyz = Lights[0].color_invradius.w * r6.xyz;
    r8.x = dot(v0.xyzw, Lights[0].spot_projection1.xyzw);
    r8.y = dot(v0.xyzw, Lights[0].spot_projection2.xyzw);
    r1.w = dot(v0.xyzw, Lights[0].spot_projection3.xyzw);
    r2.w = -1 + r1.w;
    r2.w = Lights[0].light_vector.w * r2.w + 1;
    r4.w = r1.w * r1.w;
    r4.w = min(1, r4.w);
    r4.w = 1 + -r4.w;
    r4.w = r4.w * r4.w;
    r5.x = dot(r7.xyz, r7.xyz);
    r5.x = min(1, r5.x);
    r5.x = 1 + -r5.x;
    r6.w = r5.x * r5.x;
    r5.x = r5.x * r5.x + -r4.w;
    r4.w = Lights[0].light_vector.w * r5.x + r4.w;
    r7.xy = r8.xy / r2.ww;
#if 1
    r1.w = (r1.w < 0.0) ? 1.0 : 0.0;
#else 
    r2.w = cmp(0 < r1.w);
    r1.w = cmp(r1.w < 0);
    r1.w = (int)-r2.w + (int)r1.w;
    r1.w = (int)r1.w;
    r1.w = saturate(r1.w);
#endif
    r2.w = dot(r7.xy, r7.xy);
    r2.w = 1 + -r2.w;
    r2.w = max(0, r2.w);
    r1.w = r2.w * r1.w;
    r1.w = r1.w * r1.w;
    r1.w = r1.w * r4.w;
    r0.w = r0.w ? r1.w : r6.w;
    r7.xyz = Lights[0].color_invradius.xyz * r0.www;
    r0.w = dot(r6.xyz, r6.xyz);
    r0.w = rsqrt(r0.w);
    r6.xyz = r6.xyz * r0.www;
    r0.w = saturate(dot(r6.xyz, r2.xyz));
    r0.w = r0.w * 0.5 + 0.5;
    r1.w = dot(r7.xyz, r7.xyz);
    r1.w = r1.w * r0.w;
    r1.w = max(0.0500000007, r1.w);
    r7.xyz = r7.xyz * r0.www;
    r6.xyz = r6.xyz * r1.www;
  } else {
    r7.xyz = float3(0,0,0);
    r6.xyz = float3(0,0,0);
  }
  if (r5.y != 0) {
    r0.w = cmp(0 < bLightIsSpot1);
    r8.xyz = -v0.xyz * Lights[1].light_vector.w + Lights[1].light_vector.xyz;
    r9.xyz = Lights[1].color_invradius.w * r8.xyz;
    r5.x = dot(v0.xyzw, Lights[1].spot_projection1);
    r5.y = dot(v0.xyzw, Lights[1].spot_projection2);
    r1.w = dot(v0.xyzw, Lights[1].spot_projection3);
    r2.w = -1 + r1.w;
    r2.w = Lights[1].light_vector.w * r2.w + 1;
    r4.w = r1.w * r1.w;
    r4.w = min(1, r4.w);
    r4.w = 1 + -r4.w;
    r4.w = r4.w * r4.w;
    r6.w = dot(r9.xyz, r9.xyz);
    r6.w = min(1, r6.w);
    r6.w = 1 + -r6.w;
    r7.w = r6.w * r6.w;
    r6.w = r6.w * r6.w + -r4.w;
    r4.w = Lights[1].light_vector.w * r6.w + r4.w;
    r5.xy = r5.xy / r2.ww;
#if 1
    r1.w = (r1.w < 0.0) ? 1.0 : 0.0;
#else 
    r2.w = cmp(0 < r1.w);
    r1.w = cmp(r1.w < 0);
    r1.w = (int)-r2.w + (int)r1.w;
    r1.w = (int)r1.w;
    r1.w = saturate(r1.w);
#endif
    r2.w = dot(r5.xy, r5.xy);
    r2.w = 1 + -r2.w;
    r2.w = max(0, r2.w);
    r1.w = r2.w * r1.w;
    r1.w = r1.w * r1.w;
    r1.w = r1.w * r4.w;
    r0.w = r0.w ? r1.w : r7.w;
    r9.xyz = Lights[1].color_invradius.xyz * r0.www;
    r0.w = dot(r8.xyz, r8.xyz);
    r0.w = rsqrt(r0.w);
    r8.xyz = r8.xyz * r0.www;
    r0.w = saturate(dot(r8.xyz, r2.xyz));
    r0.w = r0.w * 0.5 + 0.5;
    r1.w = dot(r9.xyz, r9.xyz);
    r1.w = r1.w * r0.w;
    r1.w = max(0.0500000007, r1.w);
    r7.xyz = r9.xyz * r0.www + r7.xyz;
    r6.xyz = r8.xyz * r1.www + r6.xyz;
  }
  if (r5.z != 0) {
    r0.w = cmp(0 < bLightIsSpot2);
    r5.xyz = -v0.xyz * Lights[2].light_vector.w + Lights[2].light_vector.xyz;
    r8.xyz = Lights[2].color_invradius.w * r5.xyz;
    r9.x = dot(v0.xyzw, Lights[2].spot_projection1);
    r9.y = dot(v0.xyzw, Lights[2].spot_projection2);
    r1.w = dot(v0.xyzw, Lights[2].spot_projection3);
    r2.w = -1 + r1.w;
    r2.w = Lights[2].light_vector.w * r2.w + 1;
    r4.w = r1.w * r1.w;
    r4.w = min(1, r4.w);
    r4.w = 1 + -r4.w;
    r4.w = r4.w * r4.w;
    r6.w = dot(r8.xyz, r8.xyz);
    r6.w = min(1, r6.w);
    r6.w = 1 + -r6.w;
    r7.w = r6.w * r6.w;
    r6.w = r6.w * r6.w + -r4.w;
    r4.w = Lights[2].light_vector.w * r6.w + r4.w;
    r8.xy = r9.xy / r2.ww;
#if 1
    r1.w = (r1.w < 0.0) ? 1.0 : 0.0;
#else 
    r2.w = cmp(0 < r1.w);
    r1.w = cmp(r1.w < 0);
    r1.w = (int)-r2.w + (int)r1.w;
    r1.w = (int)r1.w;
    r1.w = saturate(r1.w);
#endif
    r2.w = dot(r8.xy, r8.xy);
    r2.w = 1 + -r2.w;
    r2.w = max(0, r2.w);
    r1.w = r2.w * r1.w;
    r1.w = r1.w * r1.w;
    r1.w = r1.w * r4.w;
    r0.w = r0.w ? r1.w : r7.w;
    r8.xyz = Lights[2].color_invradius.xyz * r0.www;
    r0.w = dot(r5.xyz, r5.xyz);
    r0.w = rsqrt(r0.w);
    r5.xyz = r5.xyz * r0.www;
    r0.w = saturate(dot(r5.xyz, r2.xyz));
    r0.w = r0.w * 0.5 + 0.5;
    r1.w = dot(r8.xyz, r8.xyz);
    r1.w = r1.w * r0.w;
    r1.w = max(0.0500000007, r1.w);
    r7.xyz = r8.xyz * r0.www + r7.xyz;
    r6.xyz = r5.xyz * r1.www + r6.xyz;
  }
  if (r5.w != 0) {
    r0.w = cmp(0 < bLightIsSpot3);
    r5.xyz = -v0.xyz * Lights[3].light_vector.w + Lights[3].light_vector.xyz;
    r8.xyz = Lights[3].color_invradius.w * r5.xyz;
    r9.x = dot(v0.xyzw, Lights[3].spot_projection1);
    r9.y = dot(v0.xyzw, Lights[3].spot_projection2);
    r1.w = dot(v0.xyzw, Lights[3].spot_projection3);
    r2.w = -1 + r1.w;
    r2.w = Lights[3].light_vector.w * r2.w + 1;
    r4.w = r1.w * r1.w;
    r4.w = min(1, r4.w);
    r4.w = 1 + -r4.w;
    r4.w = r4.w * r4.w;
    r5.w = dot(r8.xyz, r8.xyz);
    r5.w = min(1, r5.w);
    r5.w = 1 + -r5.w;
    r6.w = r5.w * r5.w;
    r5.w = r5.w * r5.w + -r4.w;
    r4.w = Lights[3].light_vector.w * r5.w + r4.w;
    r8.xy = r9.xy / r2.ww;
#if 1
    r1.w = (r1.w < 0.0) ? 1.0 : 0.0;
#else 
    r2.w = cmp(0 < r1.w);
    r1.w = cmp(r1.w < 0);
    r1.w = (int)-r2.w + (int)r1.w;
    r1.w = (int)r1.w;
    r1.w = saturate(r1.w);
#endif
    r2.w = dot(r8.xy, r8.xy);
    r2.w = 1 + -r2.w;
    r2.w = max(0, r2.w);
    r1.w = r2.w * r1.w;
    r1.w = r1.w * r1.w;
    r1.w = r1.w * r4.w;
    r0.w = r0.w ? r1.w : r6.w;
    r8.xyz = Lights[3].color_invradius.xyz * r0.www;
    r0.w = dot(r5.xyz, r5.xyz);
    r0.w = rsqrt(r0.w);
    r5.xyz = r5.xyz * r0.www;
    r0.w = saturate(dot(r5.xyz, r2.xyz));
    r0.w = r0.w * 0.5 + 0.5;
    r1.w = dot(r8.xyz, r8.xyz);
    r1.w = r1.w * r0.w;
    r1.w = max(0.05, r1.w);
    r7.xyz = r8.xyz * r0.www + r7.xyz;
    r6.xyz = r5.xyz * r1.www + r6.xyz;
  }
  o5.x = dot(r6.xyz, r0.xyz);
  o5.y = dot(r6.xyz, r1.xyz);
  o5.z = dot(r6.xyz, r2.xyz);
  o0.xyw = r4.xyz;
  o1.w = 1;
  o2.xyzw = v11.zyxw;
  o4.xyz = r7.xyz;
  o4.w = 0;
  o6.xyzw = r3.xyzw;
  o3.xy = v4.xy;
#if 0 // TODO: this shader isn't decompiled properly, but anyway we could delete them now, we found UW hacks
  o6.w = -1.0;
#endif
}