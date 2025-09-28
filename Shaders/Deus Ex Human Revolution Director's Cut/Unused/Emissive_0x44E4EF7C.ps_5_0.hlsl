cbuffer DrawableBuffer : register(b1)
{
  float4 FogColor : packoffset(c0);
  float4 DebugColor : packoffset(c1);
  float MaterialOpacity : packoffset(c2);
  float AlphaThreshold : packoffset(c3);
}

cbuffer SceneBuffer : register(b2)
{
  row_major float4x4 View : packoffset(c0);
  row_major float4x4 ScreenMatrix : packoffset(c4);
  float2 DepthExportScale : packoffset(c8);
  float2 FogScaleOffset : packoffset(c9);
  float3 CameraPosition : packoffset(c10);
  float3 CameraDirection : packoffset(c11);
  float3 DepthFactors : packoffset(c12);
  float2 ShadowDepthBias : packoffset(c13);
  float4 SubframeViewport : packoffset(c14);
  row_major float3x4 DepthToWorld : packoffset(c15);
  float4 DepthToView : packoffset(c18);
  float4 OneOverDepthToView : packoffset(c19);
  float4 DepthToW : packoffset(c20);
  float4 ClipPlane : packoffset(c21);
  float2 ViewportDepthScaleOffset : packoffset(c22);
  float2 ColorDOFDepthScaleOffset : packoffset(c23);
  float2 TimeVector : packoffset(c24);
  float3 HeightFogParams : packoffset(c25);
  float3 GlobalAmbient : packoffset(c26);
  float4 GlobalParams[16] : packoffset(c27);
  float DX3_SSAOScale : packoffset(c43);
  float4 ScreenExtents : packoffset(c44);
  float2 ScreenResolution : packoffset(c45);
  float4 PSSMToMap1Lin : packoffset(c46);
  float4 PSSMToMap1Const : packoffset(c47);
  float4 PSSMToMap2Lin : packoffset(c48);
  float4 PSSMToMap2Const : packoffset(c49);
  float4 PSSMToMap3Lin : packoffset(c50);
  float4 PSSMToMap3Const : packoffset(c51);
  float4 PSSMDistances : packoffset(c52);
  row_major float4x4 WorldToPSSM0 : packoffset(c53);
  float StereoOffset : packoffset(c25.w);
}

cbuffer MaterialBuffer : register(b3)
{
  float4 MaterialParams[32] : packoffset(c0);
}

SamplerState p_default_Material_085C212425400875_0B6F578C16613359_0581B3643227900_DeferredBufferTexture_sampler_s : register(s0);
SamplerState p_default_Normal_085C30E423235227_Texture_sampler_s : register(s1);
SamplerState p_default_Material_07A6D1241186035_Texture_sampler_s : register(s2);
SamplerState p_default_Material_07C658648894890_Texture_sampler_s : register(s3);
Texture2D<float4> p_default_Material_085C212425400875_0B6F578C16613359_0581B3643227900_DeferredBufferTexture_texture : register(t0);
Texture2D<float4> p_default_Normal_085C30E423235227_Texture_texture : register(t1);
Texture2D<float4> p_default_Material_07A6D1241186035_Texture_texture : register(t2);
TextureCube<float4> p_default_Material_07C658648894890_Texture_texture : register(t3);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float3 v2 : TEXCOORD2,
  float3 v3 : TEXCOORD3,
  float3 v4 : TEXCOORD4,
  float4 v5 : TEXCOORD5,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xy = MaterialParams[4].zw * v1.xy;
  r0.xyz = p_default_Normal_085C30E423235227_Texture_texture.Sample(p_default_Normal_085C30E423235227_Texture_sampler_s, r0.xy).xyw;
  r0.y = r0.y * r0.z;
  r0.xy = r0.xy * float2(2,2) + float2(-1,-1);
  r0.z = dot(r0.xy, r0.xy);
  r0.xy = MaterialParams[5].xx * r0.xy;
  r0.z = 1 + -r0.z;
  r0.z = max(0, r0.z);
  r0.z = sqrt(r0.z);
  r1.xyz = v4.xyz * r0.yyy;
  r0.xyw = r0.xxx * v3.xyz + r1.xyz;
  r0.xyz = r0.zzz * v2.xyz + r0.xyw;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.www * r0.xyz;
  r1.xyz = CameraPosition.xyz + -v5.xyz;
  r0.w = dot(r1.xyz, r1.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = r0.www * r1.xyz;
  r0.w = dot(r1.xyz, r0.xyz);
  r0.w = r0.w + r0.w;
  r0.xyz = r0.xyz * -r0.www + r1.xyz;
  r0.xyz = -r0.xyz;
  r0.xyz = p_default_Material_07C658648894890_Texture_texture.Sample(p_default_Material_07C658648894890_Texture_sampler_s, r0.xyz).xyz;
  r1.xy = MaterialParams[2].xy * r0.xy;
  r0.w = r1.x + r1.y;
  r0.w = r0.z * MaterialParams[2].z + r0.w;
  r0.w = 0.333333343 * r0.w;
  r1.x = 1 / MaterialParams[1].w;
  r1.x = TimeVector.x * r1.x;
  r1.y = r1.x / MaterialParams[4].x;
  r1.x = trunc(r1.x);
  r1.x = r1.x / MaterialParams[4].x;
  r1.y = trunc(r1.y);
  r1.y = r1.y / MaterialParams[4].y;
  r1.zw = trunc(v1.wz);
  r1.zw = v1.wz + -r1.zw;
  r1.zw = r1.zw / MaterialParams[4].xy;
  r2.xy = r1.zy + r1.xw;
  r1.xyz = p_default_Material_07A6D1241186035_Texture_texture.Sample(p_default_Material_07A6D1241186035_Texture_sampler_s, r2.xy).xyz;
  r1.x = r1.x + r1.y;
  r1.x = r1.x + r1.z;
  r1.y = -r1.x * 0.333333343 + 1;
  r1.x = 0.333333343 * r1.x;
  r1.z = -MaterialParams[0].w + 1;
  r1.y = -r1.y * r1.z + 1;
  r0.w = max(r1.y, r0.w);
  o0.w = MaterialOpacity * r0.w;
  r0.w = MaterialParams[3].w * TimeVector.x;
  r0.w = sin(r0.w);
  r1.yzw = r0.www * MaterialParams[5].yyy + MaterialParams[1].xyz;
  r1.yzw = -MaterialParams[3].xyz + r1.yzw;
  r1.xyz = r1.xxx * r1.yzw + MaterialParams[3].xyz;
  r0.xyz = r0.xyz * MaterialParams[2].xyz + r1.xyz;
  r1.xy = v0.xy * ScreenExtents.zw + ScreenExtents.xy;
  r1.xyz = p_default_Material_085C212425400875_0B6F578C16613359_0581B3643227900_DeferredBufferTexture_texture.Sample(p_default_Material_085C212425400875_0B6F578C16613359_0581B3643227900_DeferredBufferTexture_sampler_s, r1.xy).xyz;
  r1.xyz = r1.xyz * float3(2,2,2) + MaterialParams[0].xyz;
  r1.xyz = GlobalParams[0].xyz + r1.xyz;
  r2.xyz = r1.xyz * r0.xyz;
  r0.xyz = -r0.xyz * r1.xyz + FogColor.xyz;
  r0.w = saturate(v5.w);
  r0.w = GlobalParams[2].x * r0.w;
  o0.xyz = r0.www * r0.xyz + r2.xyz;
  
  //o0.rgb *= 33.0; // Test (unnecessary now as we have emissive boost)
  //o0.w *= 2.0;
}