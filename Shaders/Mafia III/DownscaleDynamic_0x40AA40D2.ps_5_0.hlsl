Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[66];
}

// Luma: Unchanged
void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  uint iterations = (uint)cb0[0].x;
  float4 colorSum = 0.0;
  float weight = 0.0;
  uint i = 0;
  while (true) {
    if (i >= iterations) break;
    colorSum += t0.SampleLevel(s0_s, cb0[i+2].xy + v1.xy, 0).xyzw * cb0[i+2].z;
    weight += cb0[i+2].z;
    i++;
  }
  weight = max(9.99999975e-006, weight);
  o0.xyzw = colorSum / weight;
}