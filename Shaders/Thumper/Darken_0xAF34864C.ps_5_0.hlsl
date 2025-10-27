#include "../Includes/Common.hlsl"

cbuffer BrightPassConstants : register(b5)
{
  float4 gMiddleGrayOverLuminance_WhiteCutoffSq : packoffset(c0);
}

SamplerState gAuxSampler_s : register(s0);
Texture2D<float4> gAuxTex : register(t0);

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

  float3 sceneColor = gAuxTex.Sample(gAuxSampler_s, v2.xy).xyz;
  if (forceVanilla)
    sceneColor = saturate(sceneColor);
  else // Luma: fix NaNs from FLOAT RTs
  {
    sceneColor = IsNaN_Strict(sceneColor) ? 0.0 : sceneColor;
    sceneColor = IsInfinite_Strict(sceneColor) ? 0.0 : sceneColor;
  }
  float3 scaledSceneColor = gMiddleGrayOverLuminance_WhiteCutoffSq.x * sceneColor;
  r1.xyz = (scaledSceneColor / gMiddleGrayOverLuminance_WhiteCutoffSq.y) + 1.0;
  r2.xyz = scaledSceneColor * r1.xyz + float3(-0.5,-0.5,-0.5);
  r0.xyz = scaledSceneColor * r1.xyz + float3(0.5,0.5,0.5);
  o0.xyz = r2.xyz / r0.xyz;
  
  // Luma: emulate UNORM, without this, darkening goes negative and ends up spreading invalid colors
  o0.xyz = max(o0.xyz, 0.0);

  o0.w = 1;
}