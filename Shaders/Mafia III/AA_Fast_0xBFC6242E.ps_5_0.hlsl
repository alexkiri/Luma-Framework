Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

#define cmp -

// Used when AA is set to low quality, runs after tonemapping
void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xyz = t0.Sample(s0_s, v1.xy).xyz;
  r0.w = dot(r0.xyz, float3(1,1,1));
  o0.xyz = r0.xyz;
  r0.x = cmp(9.99999975e-006 < r0.w);
  o0.w = r0.x ? 1.000000 : 0;
  o0.xyz = pow(o0.xyz, 1.0 / 2.2); // RenoDX: somehow needed? //TODOFT: we should only do it on the swapchain Or after TM
}