cbuffer DrawableBuffer : register(b1)
{
  float4 FogColor : packoffset(c0);
  float4 DebugColor : packoffset(c1);
  float AlphaThreshold : packoffset(c2);
  float4 __InstancedMaterialOpacity[256] : packoffset(c3);
}

cbuffer SceneBuffer : register(b2)
{
  row_major float4x4 View : packoffset(c0);
  row_major float4x4 ScreenMatrix : packoffset(c4);
  float2 DepthExportScale : packoffset(c8);
  float4 FogParams : packoffset(c9);
  float3 __CameraPosition : packoffset(c10);
  float3 CameraDirection : packoffset(c11);
  float3 DepthFactors : packoffset(c12);
  float3 ShadowDepthBiasAndLightType : packoffset(c13);
  float4 SubframeViewport : packoffset(c14);
  row_major float3x4 DepthToWorld : packoffset(c15);
  float4 DepthToView : packoffset(c18);
  float4 OneOverDepthToView : packoffset(c19);
  float4 DepthToW : packoffset(c20);
  float4 ClipPlane : packoffset(c21);
  float2 ViewportDepthScaleOffset : packoffset(c22);
  float2 ColorDOFDepthScaleOffset : packoffset(c23);
  float2 TimeVector : packoffset(c24);
  float4 FogParams2 : packoffset(c25);
  float4 FogParams3 : packoffset(c26);
  float3 GlobalAmbient : packoffset(c27);
  float4 GlobalParams[16] : packoffset(c28);
  float4 ViewToFogH : packoffset(c44);
  float4 ScreenExtents : packoffset(c45);
  float2 ScreenResolution : packoffset(c46);
  float4 PSSMToMap1Lin : packoffset(c47);
  float4 PSSMToMap1Const : packoffset(c48);
  float4 PSSMToMap2Lin : packoffset(c49);
  float4 PSSMToMap2Const : packoffset(c50);
  float4 PSSMToMap3Lin : packoffset(c51);
  float4 PSSMToMap3Const : packoffset(c52);
  float4 PSSMDistances : packoffset(c53);
  row_major float4x4 WorldToPSSM0 : packoffset(c54);
  row_major float4x4 PrevViewProject : packoffset(c58);
  row_major float4x4 PrevWorld : packoffset(c62);
  row_major float4x4 ViewT : packoffset(c66);
  float4 PSSMExtents : packoffset(c70);
  float4 ShadowAtlasResolution : packoffset(c71);
  float4 UnitRimData[3] : packoffset(c72);
  float3 __CameraPositionForCorrection : packoffset(c75);
  row_major float4x4 InverseProjection : packoffset(c81);
  float4 StereoOffset : packoffset(c85);
  row_major float4x4 ScrToViewMatrix : packoffset(c86);
  row_major float4x4 ViewInv : packoffset(c90);
  float4 ColorSSAO : packoffset(c94);
  float4 GlobalFogColor : packoffset(c95);
}

SamplerState SamplerGenericPointClamp_s : register(s10);
Texture2D<float4> p_default_Material_67C899B021294604_cp0_Param_texture : register(t0);

// Unclear what this is for, it writes the final post process scene (before tonemap) to a R8G8B8A8_UNORM, which is then not always used
void main(
  nointerpolation uint4 v0 : PSIZE0,
  float4 v1 : SV_POSITION0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  r0.x = v0.x;
  r0.yz = v1.xy * ScreenExtents.zw + ScreenExtents.xy;
  r1.xyzw = p_default_Material_67C899B021294604_cp0_Param_texture.Sample(SamplerGenericPointClamp_s, r0.yz).xyzw;
  o0.w = __InstancedMaterialOpacity[r0.x].x * r1.w;
  o0.xyz = r1.xyz;
}