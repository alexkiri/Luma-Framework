SamplerState SamplerGenericBilinearClamp_s : register(s13);
Texture2D<float4> textureMap : register(t0);
Texture2D<float4> scatterMap : register(t1);

// This might be the only thing that draws on the final buffer, additively on a cleared to black buffer.
// It draws even if bloom is disabled.
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyzw = textureMap.Sample(SamplerGenericBilinearClamp_s, v1.xy).xyzw;
  r1.xyzw = scatterMap.Sample(SamplerGenericBilinearClamp_s, v1.xy).xyzw;
  o0.xyz = r1.xyz + r0.xyz;
  o0.w = 1;
}