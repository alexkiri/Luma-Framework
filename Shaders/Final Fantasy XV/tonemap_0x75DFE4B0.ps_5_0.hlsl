// ---- Created with 3Dmigoto v1.3.16 on Sat Aug 02 01:21:22 2025
#include "../Includes/Common.hlsl"
#include "../Includes/Color.hlsl"
#include "../Includes/Tonemap.hlsl"
#include "./common.hlsl"

// LumaSettings

cbuffer COLOR_FILTER_PARMS : register(b0)
{
  float WhiteX : packoffset(c0);
  float WhiteY : packoffset(c0.y);
  float WhiteZ : packoffset(c0.z);
  float HighRange : packoffset(c0.w);
  float TenPowLogHighRangePlusContrastMinusOne : packoffset(c1);
  float TenPowDispositionTimesTwoPowHighRange_PlusOne_Log_Inverse : packoffset(c1.y);
  float ZeroSlopeByTenPowDispositionPlusOne : packoffset(c1.z);
  float Param_n37 : packoffset(c1.w);
  float Param_n46 : packoffset(c2);
  float Param_n49 : packoffset(c2.y);
  float rotM : packoffset(c2.z);
  float rotY : packoffset(c2.w);
  float rotG : packoffset(c3);
  float rotB : packoffset(c3.y);
  float sAllsMExp2 : packoffset(c3.z);
  float sAllsYExp2 : packoffset(c3.w);
  float sAllsGExp2 : packoffset(c4);
  float sAllsBExp2 : packoffset(c4.y);
  float scAllscM : packoffset(c4.z);
  float scAllscY : packoffset(c4.w);
  float scAllscG : packoffset(c5);
  float scAllscB : packoffset(c5.y);
  float sM0Final : packoffset(c5.z);
  float sM1Final : packoffset(c5.w);
  float sM2Final : packoffset(c6);
  float sM3Final : packoffset(c6.y);
  float sM4Final : packoffset(c6.z);
  float sY0Final : packoffset(c6.w);
  float sY1Final : packoffset(c7);
  float sY2Final : packoffset(c7.y);
  float sY3Final : packoffset(c7.z);
  float sY4Final : packoffset(c7.w);
  float sG0Final : packoffset(c8);
  float sG1Final : packoffset(c8.y);
  float sG2Final : packoffset(c8.z);
  float sG3Final : packoffset(c8.w);
  float sG4Final : packoffset(c9);
  float sB0Final : packoffset(c9.y);
  float sB1Final : packoffset(c9.z);
  float sB2Final : packoffset(c9.w);
  float sB3Final : packoffset(c10);
  float sB4Final : packoffset(c10.y);
  bool CAT : packoffset(c10.z);
  bool HDR : packoffset(c10.w);
  bool Gamma : packoffset(c11);
  bool Dither : packoffset(c11.y);
  bool EnabledToneCurve : packoffset(c11.z);
  bool EnabledHue : packoffset(c11.w);
  bool EnabledSaturationALL : packoffset(c12);
  bool EnabledSaturation : packoffset(c12.y);
  bool EnabledSaturationClamp : packoffset(c12.z);
  bool EnabledSaturationByKido : packoffset(c12.w);
  bool EnabledTemporalAACheckerboard : packoffset(c13);
  float HDRGamutRatio : packoffset(c13.y);
  float ToneCurveInterpolation : packoffset(c13.z);
}

SamplerState g_sSampler_s : register(s0);
Texture2D<float4> g_tTex : register(t0);


// 3Dmigoto declarations
#define cmp -


float3 toneMapLogContrast(float3 color)  {
  float4 r0, r1;
  r0.rgb = color;

  r1.x = dot(r0.xyz, float3(0.542472005, 0.439283997, 0.0182429999));
  r1.y = dot(r0.xyz, float3(0.0426700003, 0.941115022, 0.0162140001));
  r1.z = dot(r0.xyz, float3(0.0173160005, 0.0949679986, 0.887715995));
  r0.xyz = float3(WhiteX, WhiteY, WhiteZ) * r1.xyz;

  r1.x = dot(r0.xyz, float3(0.720840991, 0.267010987, 0.0121480003));
  r1.y = dot(r0.xyz, float3(0.0496839993, 0.943306983, 0.00700900005));
  r1.z = dot(r0.xyz, float3(0.00642100023, 0.0243079998, 0.969271004));
  r0.xyz = r1.xyz * float3(39.8107185, 39.8107185, 39.8107185) + ZeroSlopeByTenPowDispositionPlusOne;

  // ln(color) * constant
  r0.xyz = log2(r0.xyz);
  r0.xyz = TenPowDispositionTimesTwoPowHighRange_PlusOne_Log_Inverse * r0.xyz;
  r0.xyz = float3(0.693147182, 0.693147182, 0.693147182) * r0.xyz;

  r0.xyz = log2(r0.xyz);
  r0.xyz = Param_n37 * r0.xyz;
  r0.xyz = exp2(r0.xyz);

  r0.xyz = r0.xyz * TenPowLogHighRangePlusContrastMinusOne + float3(1, 1, 1);
  r0.xyz = log2(r0.xyz);
  r0.xyz = Param_n46 * r0.xyz;
  r0.xyz = r0.xyz * float3(0.693147182, 0.693147182, 0.693147182) + -Param_n49;
  r0.xyz = max(float3(0, 0, 0), r0.xyz);
  r0.xyz = EnabledToneCurve ? r0.xyz : r1.xyz;

  return r0.rgb;
}


float3 colorGrade(float3 color) {
  float4 r0, r1, r2, r3, r4, r5;
  float4 signs;
  r0.rgb = color;


  r1.x = dot(r0.xyz, float3(1.41498101, -0.400139987, -0.0148409996));
  r1.y = dot(r0.xyz, float3(-0.0744709969, 1.081357, -0.00688599981));
  r1.z = dot(r0.xyz, float3(-0.00750700012, -0.0244679991, 1.03197396));

  r0.x = dot(r1.xyz, float3(0.343300015, 0.593299985, 0.0634000003)); // luminance
  r2.x = dot(r1.xyz, float3(0.40959999, -0.453200012, 0.0436000004)); // magenta (red + blue) vs green
  r2.y = dot(r1.xyz, float3(0.286799997, 0.211300001, -0.498100013)); // yellow (red + green) vs blue
  r2.zw = -r2.xy;

  r1.xyzw = max(float4(0, 0, 0, 0), r2.xyzw);
  
  // r1.x = magenta
  // r1.y = yellow
  // r1.z = green
  // r1.w = blue

  r1.zw = float2(rotG, rotB) * r1.zw;  // scale green and blue
  r1.xy = r1.xy * float2(rotM, rotY) + -r1.zw; // scale magenta/yellow and blend back
  r1.z = -r1.y; // r1.z = blue vs yellow
  r1.yz = r2.xy + r1.zx; 
  // magenta vs green - blue vs yellow
  // yellow vs blue + magenta vs green
  r1.xw = -r1.yz;

  r2.xyzw = max(float4(0, 0, 0, 0), r1.yzxw);
  r2.zw *= float2(sAllsGExp2, sAllsBExp2);
  r0.yz = r2.xy * float2(sAllsMExp2, sAllsYExp2) + -r2.zw;
  r1.x = r0.x;
  r0.xyz = EnabledSaturation ? r0.xyz : r1.xyz;

  r1.xyzw = float4(1, 1, -1, -1) * r0.yzyz;

  r1.xyzw = max(float4(0, 0, 0, 0), r1.xyzw);
  r2.xy = float2(scAllscM, scAllscM);
  r2.zw = float2(scAllscG, scAllscB);
  r3.xyzw = r2.xyzw + r1.xyzw;
  r1.xyzw = r1.xyzw / r3.xyzw;
  r1.zw = r1.zw * r2.zw;
  r1.yz = r1.xy * r2.xy + -r1.zw;
  r1.x = r0.x;
  r0.xyz = EnabledSaturationALL ? r1.xyz : r0.xyz;

  // spline design
  float peak = LumaSettings.PeakWhiteNits / LumaSettings.GamePaperWhiteNits;
  // if (RENODX_TONE_MAP_TYPE > 1.f)
  //   peak = RENODX_PEAK_WHITE_NITS / RENODX_DIFFUSE_WHITE_NITS;
  r1.xyzw = max(float4(0, 0.0199999996, 0.180000007, 0.5), r0.xxxx);
  r1.xyzw = min(float4(0.0199999996, 0.180000007, 0.5, peak), r1.xyzw);

  // four bins
  // [0, 0.02]
  // [0.02, 0.18]
  // [0.18, 0.5]
  // [0.5, 1]
  r1.xyzw = float4(-0, -0.0199999996, -0.180000007, -0.5) + r1.xyzw;

  // scale the last band for HDR. From 1.0 we might use PQ-scale instead of linear to avoid oversaturation
  // float lum = r0.x;
  // float pq = PQEncode(lum * RENODX_DIFFUSE_WHITE_NITS, 10000.f);
  // float pq_one = PQEncode(1.0f * RENODX_DIFFUSE_WHITE_NITS, 10000.f);
  // float pq_peak = PQEncode(RENODX_PEAK_WHITE_NITS, 10000.f);
  // r1.w = 1.0f + (pq - pq_one) / (pq_peak - pq_one) ;
    // weight4 = saturate((lum - 0.5f) / 0.5f);  // original behavior
  // scale them back to zero

  r2.x = sM2Final * r1.y;
  r2.y = sY2Final * r1.y;
  r2.z = sG2Final * r1.y;
  r2.w = sB2Final * r1.y;
  r3.x = sM3Final * r1.z;
  r3.y = sY3Final * r1.z;
  r3.z = sG3Final * r1.z;
  r3.w = sB3Final * r1.z;
  r4.x = sM4Final * r1.w;
  r4.y = sY4Final * r1.w;
  r4.z = sG4Final * r1.w;
  r4.w = sB4Final * r1.w;
  r5.x = r1.x * sM1Final + sM0Final;
  r5.y = r1.x * sY1Final + sY0Final;
  r5.z = r1.x * sG1Final + sG0Final;
  r5.w = r1.x * sB1Final + sB0Final;
  r1.xyzw = r5.xyzw + r2.xyzw;
  r1.xyzw = r1.xyzw + r3.xyzw;
  r1.xyzw = r1.xyzw + r4.xyzw;

  r1.xyzw = max(float4(0, 0, 0, 0), r1.xyzw);
  r2.xyzw = float4(1, 1, -1, -1) * r0.yzyz;
  r2.xyzw = max(float4(0, 0, 0, 0), r2.xyzw);
  r1.zw = r2.zw * r1.zw;
  r1.yz = r2.xy * r1.xy + -r1.zw;
  r1.x = r0.x;
  r0.xyz = EnabledSaturationByKido ? r1.xyz : r0.xyz;

  r1.x = dot(r0.xyz, float3(1, 1.42680001, 0.252200007));
  r1.y = dot(r0.xyz, float3(1, -0.87379998, 0.0509000011));
  r1.z = dot(r0.xyz, float3(1, 0.450800002, -1.84089994));

  r0.x = dot(r1.xyz, float3(1.91424894, -0.891185999, -0.0230620001)); // Luminace 
  r0.y = dot(r1.xyz, float3(-0.0863080025, 1.10471201, -0.0184039995)); // A
  r0.z = dot(r1.xyz, float3(-0.0281070005, -0.100798003, 1.12890506));  // B

  if (HDR != 0) {
      // push colors a bit towards BT2020?
      r1.xyz = float3(0.329299986, 0.919499993, 0.0879999995) * r0.yyy;
      r1.xyz = r0.xxx * float3(0.627399981, 0.0691, 0.0164000001) + r1.xyz;
      r1.xyz = r0.zzz * float3(0.0432999991, 0.0114000002, 0.895600021) + r1.xyz;
      r2.xyz = -r1.xyz + r0.xyz;
      r0.xyz = HDRGamutRatio * r2.xyz + r1.xyz;
    }

  r0.rgb = BT709_To_BT2020(r0.rgb);
  r0.rgb = max(0.f, r0.rgb);
  r0.rgb = BT2020_To_BT709(r0.rgb);

  return r0.rgb;
}


void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2,r3,r4,r5;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyzw = g_tTex.SampleLevel(g_sSampler_s, v1.xy, 0).xyzw;
  // r1.x = dot(r0.xyz, float3(0.542472005,0.439283997,0.0182429999));
  // r1.y = dot(r0.xyz, float3(0.0426700003,0.941115022,0.0162140001));
  // r1.z = dot(r0.xyz, float3(0.0173160005,0.0949679986,0.887715995));
  // r0.xyz = WhiteX * r1.xyz;
  // r1.x = dot(r0.xyz, float3(0.720840991,0.267010987,0.0121480003));
  // r1.y = dot(r0.xyz, float3(0.0496839993,0.943306983,0.00700900005));
  // r1.z = dot(r0.xyz, float3(0.00642100023,0.0243079998,0.969271004));
  // r0.xyz = r1.xyz * float3(39.8107185,39.8107185,39.8107185) + ZeroSlopeByTenPowDispositionPlusOne;
  // r0.xyz = log2(r0.xyz);
  // r0.xyz = TenPowDispositionTimesTwoPowHighRange_PlusOne_Log_Inverse * r0.xyz;
  // r0.xyz = float3(0.693147182,0.693147182,0.693147182) * r0.xyz;
  // r0.xyz = log2(r0.xyz);
  // r0.xyz = Param_n37 * r0.xyz;
  // r0.xyz = exp2(r0.xyz);
  // r0.xyz = r0.xyz * TenPowLogHighRangePlusContrastMinusOne + float3(1,1,1);
  // r0.xyz = log2(r0.xyz);
  // r0.xyz = Param_n46 * r0.xyz;
  // r0.xyz = r0.xyz * float3(0.693147182,0.693147182,0.693147182) + -Param_n49;
  // r0.xyz = max(float3(0,0,0), r0.xyz);
  // r0.xyz = Gamma ? r0.xyz : r1.xyz;
  float3 untonemapped = r0.xyz;

  r0.xyz = toneMapLogContrast(r0.xyz);

  // r1.x = dot(r0.xyz, float3(1.41498101,-0.400139987,-0.0148409996));
  // r1.y = dot(r0.xyz, float3(-0.0744709969,1.081357,-0.00688599981));
  // r1.z = dot(r0.xyz, float3(-0.00750700012,-0.0244679991,1.03197396));
  // r0.x = dot(r1.xyz, float3(0.343300015,0.593299985,0.0634000003));
  // r2.x = dot(r1.xyz, float3(0.40959999,-0.453200012,0.0436000004));
  // r2.y = dot(r1.xyz, float3(0.286799997,0.211300001,-0.498100013));
  // r2.zw = -r2.xy;
  // r1.xyzw = max(float4(0,0,0,0), r2.xyzw);
  // r1.zw = rotG * r1.zw;
  // r1.xy = r1.xy * rotM + -r1.zw;
  // r1.z = -r1.y;
  // r1.yz = r2.xy + r1.zx;
  // r1.xw = -r1.yz;
  // r2.xyzw = max(float4(0,0,0,0), r1.yzxw);
  // r2.zw = sAllsGExp2 * r2.zw;
  // r0.yz = r2.xy * sAllsMExp2 + -r2.zw;
  // r1.x = r0.x;
  // r0.xyz = EnabledSaturationALL ? r0.xyz : r1.xyz;
  // r1.xyzw = float4(1,1,-1,-1) * r0.yzyz;
  // r1.xyzw = max(float4(0,0,0,0), r1.xyzw);
  // r2.xy = scAllscM;
  // r2.zw = scAllscG;
  // r3.xyzw = r2.xyzw + r1.xyzw;
  // r1.xyzw = r1.xyzw / r3.xyzw;
  // r1.zw = r1.zw * r2.zw;
  // r1.yz = r1.xy * r2.xy + -r1.zw;
  // r1.x = r0.x;
  // r0.xyz = EnabledSaturationALL ? r1.xyz : r0.xyz;
  // r1.xyzw = max(float4(0,0.0199999996,0.180000007,0.5), r0.xxxx);
  // r1.xyzw = min(float4(0.0199999996,0.180000007,0.5,1), r1.xyzw);
  // r1.xyzw = float4(-0,-0.0199999996,-0.180000007,-0.5) + r1.xyzw;
  // r2.x = sM2Final * r1.y;
  // r2.y = sY2Final * r1.y;
  // r2.z = sG2Final * r1.y;
  // r2.w = sB2Final * r1.y;
  // r3.x = sM3Final * r1.z;
  // r3.y = sY3Final * r1.z;
  // r3.z = sG3Final * r1.z;
  // r3.w = sB3Final * r1.z;
  // r4.x = sM4Final * r1.w;
  // r4.y = sY4Final * r1.w;
  // r4.z = sG4Final * r1.w;
  // r4.w = sB4Final * r1.w;
  // r5.x = r1.x * sM1Final + sM0Final;
  // r5.y = r1.x * sY1Final + sY0Final;
  // r5.z = r1.x * sG1Final + sG0Final;
  // r5.w = r1.x * sB1Final + sB0Final;
  // r1.xyzw = r5.xyzw + r2.xyzw;
  // r1.xyzw = r1.xyzw + r3.xyzw;
  // r1.xyzw = r1.xyzw + r4.xyzw;
  // r1.xyzw = max(float4(0,0,0,0), r1.xyzw);
  // r2.xyzw = float4(1,1,-1,-1) * r0.yzyz;
  // r2.xyzw = max(float4(0,0,0,0), r2.xyzw);
  // r1.zw = r2.zw * r1.zw;
  // r1.yz = r2.xy * r1.xy + -r1.zw;
  // r1.x = r0.x;
  // r0.xyz = EnabledSaturationALL ? r1.xyz : r0.xyz;
  // r1.x = dot(r0.xyz, float3(1,1.42680001,0.252200007));
  // r1.y = dot(r0.xyz, float3(1,-0.87379998,0.0509000011));
  // r1.z = dot(r0.xyz, float3(1,0.450800002,-1.84089994));
  // r0.x = dot(r1.xyz, float3(1.91424894,-0.891185999,-0.0230620001));
  // r0.y = dot(r1.xyz, float3(-0.0863080025,1.10471201,-0.0184039995));
  // r0.z = dot(r1.xyz, float3(-0.0281070005,-0.100798003,1.12890506));
  // if (HDR != 0) {
  //   r1.xyz = float3(0.329299986,0.919499993,0.0879999995) * r0.yyy;
  //   r1.xyz = r0.xxx * float3(0.627399981,0.0691,0.0164000001) + r1.xyz;
  //   r1.xyz = r0.zzz * float3(0.0432999991,0.0114000002,0.895600021) + r1.xyz;
  //   r2.xyz = -r1.xyz + r0.xyz;
  //   r0.xyz = EnabledTemporalAACheckerboard * r2.xyz + r1.xyz;
  // }
  // TODO: tonemapping

  float3 ungraded_sdr = r0.rgb;

  float3 neutral_sdr = NeutralSDR(untonemapped);
  float3 ungraded_untonemapped = UpgradeToneMap(untonemapped, neutral_sdr, ungraded_sdr);

  // float3 ungraded_hdr = ToneMapReinhard(ungraded_untonemapped, false);
  DICESettings settings = DefaultDICESettings();
  settings.Type = DICE_TYPE_BY_LUMINANCE_PQ;
	// return DICETonemap(color * paperWhite, peakWhite, settings);
  // float3 ungraded_hdr = Tonemap_DICE(ungraded_untonemapped, LumaSettings.PeakWhiteNits / LumaSettings.GamePaperWhiteNits);
  float3 ungraded_hdr = DICETonemap(ungraded_untonemapped, LumaSettings.PeakWhiteNits / LumaSettings.GamePaperWhiteNits, settings);

  float3 graded_hdr = colorGrade(ungraded_hdr);
  float3 graded_sdr = colorGrade(ungraded_sdr);
  graded_sdr = max(graded_sdr, 0.f);

  graded_hdr = RestoreHueAndChrominance(graded_hdr, graded_sdr, 1.0f, 0.0f);

  r0.rgb = graded_hdr * LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits; // TODO: fix gamma correction with UI scaling

  // r0.xyz = max(float3(0,0,0), r0.xyz);
  // r1.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r0.xyz);
  // r2.xyz = float3(12.9200001,12.9200001,12.9200001) * r0.xyz;
  // r3.xyz = log2(r0.xyz);
  // r3.xyz = float3(0.416666657,0.416666657,0.416666657) * r3.xyz;
  // r3.xyz = exp2(r3.xyz);
  // r3.xyz = r3.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  // r1.xyz = r1.xyz ? r2.xyz : r3.xyz;
  o0.xyz = Gamma ? linear_to_sRGB_gamma(r0.rgb, GCT_POSITIVE) : r0.xyz;
  o0.w = r0.w;
  return;
}