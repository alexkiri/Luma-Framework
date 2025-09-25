cbuffer DrawableBuffer : register(b1)
{
  float4 FogColor : packoffset(c0);
  float4 DebugColor : packoffset(c1);
  float MaterialOpacity : packoffset(c2);
  float AlphaThreshold : packoffset(c3);
}

cbuffer InstanceBuffer : register(b5)
{
  float4 InstanceParams[8] : packoffset(c0);
}

SamplerState p_default_Material_00DD4274319654666_Param_sampler_s : register(s0);
Texture2D<float4> p_default_Material_00DD4274319654666_Param_texture : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xyzw = p_default_Material_00DD4274319654666_Param_texture.Sample(p_default_Material_00DD4274319654666_Param_sampler_s, v1.xy).xyzw;
  r0.xyzw = InstanceParams[4].xyzw * r0.xyzw;
  r0.xyzw = r0.xyzw * InstanceParams[5].xyzw + InstanceParams[6].xyzw;
  o0.w = MaterialOpacity * r0.w;
  o0.xyz = r0.xyz;
  // Luma: fixed subtractive alpha creating negative colors (this matches UNORM blends behaviour)
  o0.xyz = max(o0.xyz, 0.0);
  o0.w = saturate(o0.w);
}