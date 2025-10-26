// Randomly assign the luma data cbuffer to another register, to void error X4578 when multiple cbs are specified with the same index to the same index... We don't read from it anyway.
#ifdef LUMA_DATA_CB_INDEX
#undef LUMA_DATA_CB_INDEX
#define LUMA_DATA_CB_INDEX b4
#endif

#include "../Includes/Common.hlsl"

cbuffer BrightPassConstants : register(b5)
{
  float4 gMiddleGrayOverLuminance_WhiteCutoffSq : packoffset(c0);
}

static const uint samples = 16; // Can't easily be changed

#if defined(LUMA_DATA_CB_INDEX) && 0 // This would be 7 (set in c++), and we can't change it as all other slots are taken, so we live swap it in code. We found a better way for now so this is disabled. However, Luma's cbuffers won't be available in this shader.
cbuffer Down4Constants : register(b4)
#else
cbuffer Down4Constants : register(b7)
#endif
{
  float4 gTexelDown4Offsets[samples] : packoffset(c0);
}

SamplerState gSceneSampler_s : register(s1);
Texture2D<float4> gSceneTex : register(t1);

// Usually writes to a tiny top left portion
// Given it does 16 linear samples, 1 would be enough to scale to 50%, 4 would be enough to 25%, so 16 means it scales to 12.5% (8 times smaller on each axis)
void main(
  float v0 : SV_ClipDistance0,
  float w0 : SV_CullDistance0,
  float4 v1 : SV_Position0,
  float2 v2 : TEXCOORD0,
  float2 w2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;

  bool forceVanilla = ShouldForceSDR(v2.xy);

  float3 sceneColor = 0.0;
  uint4 r0i = 0;
  while (r0i.w < samples)
  {
    float2 uv = v2.xy + gTexelDown4Offsets[r0i.w].xy;
    float3 tempColor = gSceneTex.Sample(gSceneSampler_s, uv).xyz;
    if (forceVanilla)
      tempColor = saturate(tempColor);
    else // Luma: fix NaNs from FLOAT RTs
    {
      tempColor = IsNaN_Strict(tempColor) ? 0.0 : tempColor;
      tempColor = IsInfinite_Strict(tempColor) ? 0.0 : tempColor;
    }
    sceneColor += tempColor;
    r0i.w++;
  }
  sceneColor /= float(samples);
  float3 scaledSceneColor = gMiddleGrayOverLuminance_WhiteCutoffSq.x * sceneColor;
  r1.xyz = (scaledSceneColor / gMiddleGrayOverLuminance_WhiteCutoffSq.y) + 1.0;
  r2.xyz = scaledSceneColor * r1.xyz - 0.5;
  r0.xyz = scaledSceneColor * r1.xyz + 0.5;
  o0.xyz = r2.xyz / r0.xyz;
  
  // TODO: clamp this to +0? Review this and the other darkening shader... Is the code above safe to not create nans?
  // Luma: emulate UNORM
  o0.xyz = max(o0.xyz, 0.0);

  if (forceVanilla)
    o0.xyz = saturate(o0.xyz);

  o0.w = 1;
}