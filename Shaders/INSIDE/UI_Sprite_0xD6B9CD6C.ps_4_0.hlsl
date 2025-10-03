#include "Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

#if ENABLE_LUMA // Added this, which always seems to be set at this point
cbuffer cb1 : register(b1)
{
  float4 cb1[7];
}
#endif

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float2 v2 : TEXCOORD0,
  out float4 outColor : SV_Target0)
{
  float2 uv = v2.xy;
#if ENABLE_LUMA // Fix credits being Vert- in UW
  float2 sourceSize;
  t0.GetDimensions(sourceSize.x, sourceSize.y);
  bool isCredits = sourceSize.x == 1920.0 && sourceSize.y == 1080.0; // Yes, it's the only image of that size in the whole game's UI... The UI is extremely minimal

  if (isCredits)
  {
    float sourceAspectRatio = sourceSize.x / sourceSize.y;
    float targetAspectRatio = cb1[6].x / cb1[6].y;

    float2 scale = 1.0;
    if (targetAspectRatio >= sourceAspectRatio)
      scale.xy = targetAspectRatio / sourceAspectRatio;
    else
      scale.y = sourceAspectRatio / targetAspectRatio;

    // Center the UVs before scaling them
    uv = (uv - 0.5) * scale + 0.5;
    
    if (any(uv.xy < 0) || any(uv.xy > 1))
      discard;
  }
#endif

  float4 r0,r1;
  r0.xyzw = t0.Sample(s0_s, uv).xyzw;
  r1.x = r0.w * v1.w + -0.01;
  r0.xyzw = v1.xyzw * r0.xyzw;
  outColor.xyzw = r0.xyzw;
  r0.x = (r1.x < 0);
  if (r0.x != 0) discard;
}