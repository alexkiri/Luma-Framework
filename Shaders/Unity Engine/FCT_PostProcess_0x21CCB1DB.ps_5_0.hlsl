#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2DArray<float4> t2 : register(t2);
Texture2DArray<float4> t1 : register(t1);
Texture2DArray<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[43];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[6];
}

// Runs after tonemapping/grading shader. This is the final shader before UI.
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xy = v1.xy * cb0[3].xy + cb0[3].zw;
  r0.xy = cb0[2].xy * r0.xy;
  r0.z = cb0[2].z;
  r0.x = t1.Sample(s0_s, r0.xyz).w;
  r0.x = r0.x * 2 + -1;
  r0.y = 1 + -abs(r0.x);
  r0.x = (r0.x >= 0);
  r0.x = r0.x ? 1 : -1;
  r0.y = sqrt(r0.y);
  r0.y = 1 + -r0.y;
  r0.x = r0.x * r0.y;
  r0.yz = cb1[42].xy * v1.xy;
  uint2 r0yzu = (uint2)r0.yz;
  r0.yz = (float2)r0yzu;
  r1.xy = float2(-1,-1) + cb1[42].xy;
  r1.xy = cb0[3].zw * r1.xy;
  r0.yz = r0.yz * cb0[3].xy + r1.xy;
  uint4 r1u;
  r1u.xy = (uint2)r0.yz;
  r1u.zw = 0;
  r0.yzw = t0.Load(r1u.xyww).xyz;
  r1.x = t2.Load(r1u.xyzw).x;
#if 0 // Luma: removed saturate
  r0.yzw = saturate(r0.yzw);
#endif
  r1.yzw = log2(r0.yzw);
  r1.yzw = float3(0.416666657,0.416666657,0.416666657) * r1.yzw;
  r1.yzw = exp2(r1.yzw);
  r1.yzw = r1.yzw * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r2.xyz = float3(12.9200001,12.9200001,12.9200001) * r0.yzw;
  r0.yzw = (float3(0.00313080009,0.00313080009,0.00313080009) >= r0.yzw);
  r0.yzw = r0.yzw ? r2.xyz : r1.yzw;
  r0.xyz = r0.xxx * float3(0.00392156886,0.00392156886,0.00392156886) + r0.yzw;
  r1.yzw = float3(0.0549999997,0.0549999997,0.0549999997) + r0.xyz;
  r1.yzw = float3(0.947867334,0.947867334,0.947867334) * r1.yzw;
  r1.yzw = log2(abs(r1.yzw));
  r1.yzw = float3(2.4000001,2.4000001,2.4000001) * r1.yzw;
  r1.yzw = exp2(r1.yzw);
  r2.xyz = float3(0.0773993805,0.0773993805,0.0773993805) * r0.xyz;
  r0.xyz = (float3(0.0404499993,0.0404499993,0.0404499993) >= r0.xyz);
  o0.xyz = r0.xyz ? r2.xyz : r1.yzw;
  r0.x = (cb0[5].x == 1.0);
  o0.w = r0.x ? r1.x : 1;
  
#if 1 // Luma
  DICESettings config = DefaultDICESettings();
  config.Type = DICE_TYPE_BY_CHANNEL_PQ; // Do DICE by channel to desaturate highlights and keep the SDR range unotuched
  float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
  float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  o0.rgb = DICETonemap(o0.rgb * paperWhite, peakWhite, config) / paperWhite;
#endif
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
	ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, VANILLA_ENCODING_TYPE, GAMMA_CORRECTION_TYPE, true);
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
	ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, GAMMA_CORRECTION_TYPE, VANILLA_ENCODING_TYPE, true);
#endif
}