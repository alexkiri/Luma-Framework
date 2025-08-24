Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[1];
}

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  const float4 icb[] = { { -0.500000, 0.500000, 0, 0},
                              { 0.500000, 0.500000, 0, 0},
                              { 0.500000, -0.500000, 0, 0},
                              { -0.500000, -0.500000, 0, 0} };
  float3 colorSum = 0.0;
  uint i = 0;
  uint iterations = 4;
  while (true) {
    if (i >= iterations) break;
    float3 color = t0.Sample(s0_s, icb[i].xy * cb0[0].xy + v1.xy).xyz;
#if !ENABLE_LUMA // No need
    color = min(float3(65504,65504,65504), color);
#endif
    colorSum += color;
    i++;
  }
  o0.xyz = colorSum / float(iterations);
  o0.w = 1;
}