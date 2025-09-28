#include "includes/common.hlsl"
#include "includes/Tonemap.hlsl"
#include "includes/renodx/effects.hlsl"
#include "../Includes/Color.hlsl"

// _922A71D1 standard HDR output
// _A8EB118F low hp vignette version
// _3A4D858E chapter 2 specific? effect
// _D950DA01 video playback
// _5CD12E67 fog overlay

#if _922A71D1 || _D950DA01 || _5CD12E67 || _3B489929
Texture3D<float4> ditherTex : register(t0); // noise
Texture2D<float4> colorTex : register(t1); // scene color
Texture3D<float4> lut1Tex : register(t2); // lut1
Texture3D<float4> lut2Tex : register(t3); // lut2
Texture2D<float4> uiTex : register(t4); // ui overlay

SamplerState colorSampler : register(s0);
SamplerState lutSampler : register(s1);
SamplerState uiSampler : register(s2);
#endif

#if _D950DA01
Texture2D<float4> videoTex : register(t5); // video color
SamplerState videoSampler : register(s3);
#elif _3B489929
Texture2D<float4> videoTex : register(t6); // video color
SamplerState videoSampler : register(s4);
#endif

#if _5CD12E67 || _3B489929
Texture2D<float4> fogTex : register(t5);
SamplerState fogSampler : register(s3);
#endif

#if _A8EB118F
Texture3D<float4> ditherTex : register(t0); // noise
Texture2D<float4> colorTex : register(t1); // scene color
Texture2D<float4> vignetteTex : register(t2); // vignette
Texture3D<float4> lut1Tex : register(t3); // lut1
Texture3D<float4> lut2Tex : register(t4); // lut2
Texture3D<float4> lut3Tex : register(t5); // lut3
Texture2D<float4> uiTex : register(t6); // ui overlay

SamplerState colorSampler : register(s0);
SamplerState vignetteSampler : register(s1);
SamplerState lutSampler : register(s2);
SamplerState uiSampler : register(s3);
#endif

#if _3A4D858E
Texture3D<float4> ditherTex : register(t0); // dither noise
Texture2D<float4> colorTex : register(t1); // scene color
Texture3D<float4> lut1Tex : register(t2); // lut1
Texture3D<float4> lut2Tex : register(t3); // lut2
Texture2D<float4> noiseTex : register(t4); // chapter 2 noise post process effect
Texture2D<float4> uiTex : register(t5); // ui overlay

SamplerState colorSampler : register(s0);
SamplerState lutSampler : register(s1);
SamplerState uiSampler : register(s2);
#endif

Texture2D<float2> dummyFloat2Texture : register(t8);

cbuffer cb0 : register(b0) {
  float4 cb0[39];
}

cbuffer cb1 : register(b1) {
  float4 cb1[140];
}

#define cmp -

float3 SampleLUT(Texture3D<float4> lut, float3 color)
{
    float4 r0;
    uint w, h, d;
    lut.GetDimensions(w, h, d);
    r0.w = (w == 32 && h == 32 && d == 32) ? 32 : 0;
    r0.z = r0.w ? 31 : 0;
    r0.xy = r0.ww ? float2(0.03125,0.015625) : float2(1,0.5);
    r0.w = r0.x * r0.z;
    float3 coord = color.xyz * r0.www + r0.yyy;

    return lut.SampleLevel(lutSampler, coord, 0).xyz;
}

float3 LUT_PQ_to_Linear(float3 color)
{
  float3 r3, r4;
  r3.xyz = PQ_to_Linear(color.xyz);
  r3.xyz = float3(10000,10000,10000) * r3.xyz;
  return r3.xyz;
}

float getMidGray() {
  float3 lutInputColor = saturate(Linear_to_PQ(0.18f / (100.f)));
  float3 lutResult = SampleLUT(lut2Tex, lutInputColor);
  float3 lutOutputColor_bt2020 = PQ_to_Linear(lutResult) * 250.f;

  return GetLuminance(lutOutputColor_bt2020, CS_BT2020);
}

#if _D950DA01 || _3B489929
float3 SampleVideoTexture(float2 pos, float2 v0) {
  float4 r0, r1, r2, r3, r4, r5, r6;
  r1.z = cmp(cb0[24].y != 0.000000);
  r3.xz = saturate(cb0[24].xz);
  r4.xyz = videoTex.SampleLevel(videoSampler, pos, 0).xyz;
  r4.xyz = r4.xyz * r3.zzz;
  if (r1.z != 0) {
    r1.z = 0.00999999978 * r4.x;
    r1.z = max(0, r1.z);
    r1.z = log2(r1.z);
    r1.z = 0.159301758 * r1.z;
    r1.z = exp2(r1.z);
    r1.zw = r1.zz * float2(18.8515625,18.6875) + float2(0.8359375,1);
    r1.w = rcp(r1.w);
    r1.z = r1.z * r1.w;
    r1.z = log2(r1.z);
    r1.z = 78.84375 * r1.z;
    r1.z = exp2(r1.z);
    r5.x = min(1, r1.z);
    r6.xyzw = float4(0.00999999978,0.00999999978,0.00999999978,0.00999999978) * r4.yyzz;
    r6.xyzw = max(float4(0,0,0,0), r6.xyzw);
    r6.xyzw = log2(r6.xyzw);
    r6.xyzw = float4(0.159301758,0.159301758,0.159301758,0.159301758) * r6.xyzw;
    r6.xyzw = exp2(r6.xyzw);
    r6.xyzw = r6.xyzw * float4(18.8515625,18.6875,18.8515625,18.6875) + float4(0.8359375,1,0.8359375,1);
    r1.zw = rcp(r6.yw);
    r1.zw = r6.xz * r1.zw;
    r1.zw = log2(r1.zw);
    r1.zw = float2(78.84375,78.84375) * r1.zw;
    r1.zw = exp2(r1.zw);
    r5.yz = min(float2(1,1), r1.zw);
    // r3.yzw = r5.xyz * r0.www + r3.yyy;
    // r3.yzw = lut2Tex.SampleLevel(lutSampler, r3.yzw, 0).xyz;
    r3.yzw = SampleLUT(lut2Tex, r5.xyz);
    r3.yzw = LUT_PQ_to_Linear(r3.yzw);
    // r3.yzw = saturate(r3.yzw);
    // r3.yzw = log2(r3.yzw);
    // r3.yzw = float3(0.0126833133,0.0126833133,0.0126833133) * r3.yzw;
    // r3.yzw = exp2(r3.yzw);
    // r5.xyz = float3(-0.8359375,-0.8359375,-0.8359375) + r3.yzw;
    // r3.yzw = -r3.yzw * float3(18.6875,18.6875,18.6875) + float3(18.8515625,18.8515625,18.8515625);
    // r3.yzw = rcp(r3.yzw);
    // r3.yzw = r5.xyz * r3.yzw;
    // r3.yzw = max(float3(0,0,0), r3.yzw);
    // r3.yzw = log2(r3.yzw);
    // r3.yzw = float3(6.27739477,6.27739477,6.27739477) * r3.yzw;
    // r3.yzw = exp2(r3.yzw);
    // r3.yzw = float3(10000,10000,10000) * r3.yzw;
    r5.xyz = r4.xyz * float3(100,100,100) + -r3.yzw;
    r3.yzw = cb0[26].zzz * r5.xyz + r3.yzw;
  } else {
    r5.xyz = cmp(r4.xyz < float3(0.00313080009,0.00313080009,0.00313080009));
    r6.xyz = float3(12.9200001,12.9200001,12.9200001) * r4.xyz;
    r4.xyz = log2(r4.xyz);
    r4.xyz = float3(0.416666657,0.416666657,0.416666657) * r4.xyz;
    r4.xyz = exp2(r4.xyz);
    r4.xyz = r4.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
    r4.xyz = r5.xyz ? r6.xyz : r4.xyz;
    r4.xyz = log2(r4.xyz);
    r4.xyz = float3(2.20000005,2.20000005,2.20000005) * r4.xyz;
    r4.xyz = exp2(r4.xyz);
    r4.xyz = gamma_sRGB_to_linear(r4.xyz);
    if (LumaSettings.GameSettings.custom_hdr_videos.x != 0.f) {
      float target_max_luminance = min(LumaSettings.PeakWhiteNits, pow(10.f, ((log10(LumaSettings.GamePaperWhiteNits) - 0.03460730900256) / 0.757737096673107)));
      target_max_luminance = lerp(1.f, target_max_luminance, .5f);
      r4.xyz = PumboAutoHDR(r4.xyz, target_max_luminance, LumaSettings.GamePaperWhiteNits);
    }
    if (LumaSettings.GameSettings.custom_film_grain_strength.x != 0.f) {
      r4.xyz = renodx::effects::ApplyFilmGrain(r4.xyz, 
        v0.xy,         
        LumaSettings.GameSettings.custom_random.x,
        LumaSettings.GameSettings.custom_film_grain_strength.x * 0.03f,
        1.f);
    }
    r5.x = dot(float3(0.627403915,0.329282999,0.0433131009), r4.xyz);
    r5.y = dot(float3(0.0690973029,0.919540584,0.0113623003), r4.xyz);
    r5.z = dot(float3(0.0163914002,0.0880132988,0.895595312), r4.xyz);
    r3.yzw = LumaSettings.GamePaperWhiteNits * r5.xyz;
  }
  return r3.yzw;
}
#endif

#if _3A4D858E
float SampleNoiseTexture(float3 color, float4 pos) {
  float4 r0, r1, r2, r3, r4, r5;
  r0.w = cb0[34].z + -cb0[34].x;
  r0.w = max(0, r0.w);
  r0.w = 0.00026041668 * r0.w;
  r0.w = min(1, r0.w);
  r1.z = saturate(cb0[29].x);
  r3.xy = trunc(pos.xy);
  r3.yz = float2(0.618034005,0.618034005) * r3.xy;
  r1.w = dot(r3.yz, r3.yz);
  r1.w = sqrt(r1.w);
  sincos(r1.w, r4.x, r5.x);
  r1.w = r4.x / r5.x;
  r1.w = r1.w * r3.x;
  r1.w = frac(r1.w);
  r1.w = max(1.00000001e-07, r1.w);
  r2.w = frac(cb0[29].y);
  r2.w = 24 * r2.w;
  r2.w = floor(r2.w);
  r3.x = r2.w * 63.1312447 + r1.w;
  r3.x = frac(r3.x);
  r3.x = r3.x * 2 + -1;
  r2.w = 1 + r2.w;
  r1.w = r2.w * 63.1312447 + r1.w;
  r1.w = frac(r1.w);
  r1.w = r1.w * 2 + -1;
  r2.w = cmp(abs(r1.w) < abs(r3.x));
  r1.w = r2.w ? r3.x : r1.w;
  r1.z = 0.5 * r1.z;
  r2.w = 1 + -abs(r1.w);
  r0.w = r0.w * r0.w;
  r2.w = log2(r2.w);
  r0.w = r2.w * r0.w;
  r0.w = exp2(r0.w);
  r0.w = 1 + -r0.w;
  r0.w = r1.z * r0.w;
  r1.z = cmp(0 < r1.w);
  r1.w = cmp(r1.w < 0);
  r1.z = (int)-r1.z + (int)r1.w;
  r1.z = (int)r1.z;
  r0.w = r0.w * r1.z + 1;
  r3.x = saturate(0.5 * r0.w);
  r0.w = dot(color.xyz, float3(0.262699991,0.677999973,0.0593000017));
  r0.w = 9.99999975e-05 * r0.w;
  r0.w = max(0, r0.w);
  r0.w = log2(r0.w);
  r0.w = 0.159301758 * r0.w;
  r0.w = exp2(r0.w);
  r1.zw = r0.ww * float2(18.8515625,18.6875) + float2(0.8359375,1);
  r0.w = rcp(r1.w);
  r0.w = r1.z * r0.w;
  r0.w = log2(r0.w);
  r0.w = 78.84375 * r0.w;
  r0.w = exp2(r0.w);
  r3.y = min(1, r0.w);
  r1.zw = r3.xy * float2(0.96875,0.96875) + float2(0.015625,0.015625);
  return noiseTex.SampleLevel(lutSampler, r1.zw, 0).x;
}
#endif

#if _5CD12E67 || _3B489929
float3 SampleFogTexture(float3 color, float2 pos) {
  float4 r0, r1, r2, r3, r4, r5;
  r2.xyz = color.xyz;
  r3.xyzw = fogTex.SampleLevel(fogSampler, pos.xy, 0).xyzw;
  r0.w = saturate(cb0[23].x);
  r3.xyzw = float4(-0,-0,-0,-1) + r3.xyzw;
  r3.xyzw = r0.wwww * r3.xyzw + float4(0,0,0,1);
  r4.xyz = r2.xyz * float3(0.00400000019,0.00400000019,0.00400000019) + float3(1,1,1);
  r4.xyz = rcp(r4.xyz);
  r0.w = r3.w * r3.w;
  r5.xyz = float3(1,1,1) + -r4.xyz;
  r4.xyz = r0.www * r5.xyz + r4.xyz;
  r2.xyz = r4.xyz * r2.xyz;
  r4.xyz = cmp(r3.xyz < float3(0.00313080009,0.00313080009,0.00313080009));
  r5.xyz = float3(12.9200001,12.9200001,12.9200001) * r3.xyz;
  r3.xyz = log2(r3.xyz);
  r3.xyz = float3(0.416666657,0.416666657,0.416666657) * r3.xyz;
  r3.xyz = exp2(r3.xyz);
  r3.xyz = r3.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r4.xyz ? r5.xyz : r3.xyz;
  r3.xyz = log2(r3.xyz);
  r3.xyz = float3(2.20000005,2.20000005,2.20000005) * r3.xyz;
  r3.xyz = exp2(r3.xyz);
  r4.x = dot(float3(0.627403915,0.329282999,0.0433131009), r3.xyz);
  r4.y = dot(float3(0.0690973029,0.919540584,0.0113623003), r3.xyz);
  r4.z = dot(float3(0.0163914002,0.0880132988,0.895595312), r3.xyz);
  r3.xyz = float3(250,250,250) * r4.xyz;
  r2.xyz = r2.xyz * r3.www + r3.xyz;
  return r2.xyz;
}
#endif

void main(
  float4 v0 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  uint4 bitmask, uiDest;
  float4 fDest;

  if ((cb0[34].x < v0.x && v0.x < cb0[34].z)
      && (cb0[34].y < v0.y && v0.y < cb0[34].w)) {
    int2 v0xy = int2(v0.xy);
    int2 cb034xy = asint(cb0[34].xy);
    r0.xy = (int2)v0.xy;
    r1.xy = asint(cb0[34].xy);

    r1.xy = int2(v0.xy - cb034xy) + float2(0.5, 0.5);
    r1.zw = cb0[35].zw * r1.xy;
    r2.xy = cb0[35].xy * cb0[35].wz;
    r1.xy = r1.xy * cb0[35].zw + float2(-0.5,-0.5);
    r2.xy = float2(0.5625,1.77777779) * r2.xy;
    r2.xy = min(float2(1,1), r2.xy);
    r1.xy = r1.xy * r2.xy + float2(0.5,0.5);
    r1.zw = r1.zw * cb0[31].xy + cb0[30].xy;
    r1.zw = cb0[0].zw * r1.zw;

    float2 pixelPos = r1.xy;
    float2 uvCoord = r1.zw;

    r2.xyz = colorTex.SampleLevel(colorSampler, uvCoord, 0).xyz;
    if (LumaData.GameData.DrewUpscaling && LumaSettings.GameSettings.custom_sharpness_strength != 0.f) {
      r2.xyz = RCAS(int2(v0.xy), 0, 0x7FFFFFFF, LumaSettings.GameSettings.custom_sharpness_strength, colorTex, dummyFloat2Texture, 1.f, true , float4(r2.xyz, 1.0f)).rgb;
    }

    float3 colorSample = r2.xyz;
    float3 pqColor = Linear_to_PQ(colorSample / 100.f);
    r4.xyz = pqColor;

    r3.xyz = SampleLUT(lut1Tex, pqColor);

// not sure what this does.
    r2.xyz = saturate(colorSample);
    r2.xyz = log2(r2.xyz);
    r2.xyz = float3(0.454545438,0.454545438,0.454545438) * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    r4.xyz = cmp(r2.xyz < float3(0.100000001,0.100000001,0.100000001));
    r5.xyz = float3(0.699999988,0.699999988,0.699999988) * r2.xyz;
    r6.xyz = cmp(r2.xyz < float3(0.200000003,0.200000003,0.200000003));
    r7.xyz = r2.xyz * float3(0.899999976,0.899999976,0.899999976) + float3(-0.0199999996,-0.0199999996,-0.0199999996);
    r8.xyz = cmp(r2.xyz < float3(0.300000012,0.300000012,0.300000012));
    r9.xyz = r2.xyz * float3(1.10000002,1.10000002,1.10000002) + float3(-0.0599999987,-0.0599999987,-0.0599999987);
    r10.xyz = cmp(r2.xyz < float3(0.5,0.5,0.5));
    r11.xyz = r2.xyz * float3(1.14999998,1.14999998,1.14999998) + float3(-0.075000003,-0.075000003,-0.075000003);
    r2.xyz = r10.xyz ? r11.xyz : r2.xyz;
    r2.xyz = r8.xyz ? r9.xyz : r2.xyz;
    r2.xyz = r6.xyz ? r7.xyz : r2.xyz;
    r2.xyz = r4.xyz ? r5.xyz : r2.xyz;
    r0.w = cmp(0 < cb0[38].x);

    float3 lut1Sample = r3.xyz;
    float3 clippedSDR = r2.xyz;
  
    r2.xyz = r0.www ? r2.xyz : r3.xyz;
    float3 lut1Output = r2.xyz; // r2
    float3 gradedAces;

#if _A8EB118F // low hp vignette case
    float3 lut3Sample = SampleLUT(lut3Tex, lut1Output);

    float3 lut3Linear = LUT_PQ_to_Linear(lut3Sample);
    r3.xyz = lut3Linear;

    float3 lut1OutputLinear = LUT_PQ_to_Linear(lut1Output) - r3.xyz;
    r2.xyz = lut1OutputLinear;

    r2.xyz = cb0[26].zzz * lut1OutputLinear + lut3Linear; // blend LUT3 vs pre-LUT3
    
    r1.zw = cb0[21].xy * r1.xy;
    r1.zw = max(cb0[22].xy, r1.zw);
    r1.zw = min(cb0[22].zw, r1.zw);
    r3.xyzw = vignetteTex.SampleLevel(vignetteSampler, r1.zw, 0).xyzw;

    // 10) Vignette intensity (cb0[20].x) and pre-bias so that zero intensity yields neutral (0,0,0,1)
    r0.w = saturate(cb0[20].x);
    r3.xyzw = float4(-0,-0,-0,-1) + r3.xyzw;
    r3.xyzw = r0.wwww * r3.xyzw + float4(0,0,0,1);

    float3 pq = Linear_to_PQ(r2.xyz / 10000.f); // r2
    // 11) Forward PQ encode current scene (r2) to use as coord into LUT2 (t4)
    float3 lut2Sample = SampleLUT(lut2Tex, pq.xyz); // r4
    r4.xyz = lut2Sample.xyz;

    r5.xyz = cmp(r4.xyz < float3(0.0404499993,0.0404499993,0.0404499993));
    r6.xyz = float3(0.0773993805,0.0773993805,0.0773993805) * r4.xyz; // linear under toe
    r4.xyz = float3(0.0549999997,0.0549999997,0.0549999997) + r4.xyz;
    r4.xyz = float3(0.947867334,0.947867334,0.947867334) * r4.xyz;
    r4.xyz = log2(r4.xyz);
    r4.xyz = float3(2.4000001,2.4000001,2.4000001) * r4.xyz; // raise to 2.4 (gamma)
    r4.xyz = exp2(r4.xyz);
    r4.xyz = r5.xyz ? r6.xyz : r4.xyz;
    r0.w = dot(r4.xyz, float3(0.212599993,0.715200007,0.0722000003)); // luminance of LUT2 sample

    r1.z = 1 + -r3.w;
    r0.w = r1.z * r0.w;
    r3.xyz = r3.xyz * r0.www;

    // r0.w = rcp(cb0[26].y);
    r0.w = rcp(LumaSettings.UIPaperWhiteNits); // use UI paper white instead of cb0[26].y
    r4.xyz = r2.xyz * r0.www + float3(1,1,1);
    r4.xyz = rcp(r4.xyz);
    r1.z = r3.w * r3.w; // vignette alpha squared
    r5.xyz = float3(1,1,1) + -r4.xyz;
    r4.xyz = r1.zzz * r5.xyz + r4.xyz;
    r2.xyz = r4.xyz * r2.xyz; // apply compression to scene radiance
    float3 lut2output = r2.xyz;

    r4.xyz = cmp(r3.xyz < float3(0.00313080009,0.00313080009,0.00313080009));
    r5.xyz = float3(12.9200001,12.9200001,12.9200001) * r3.xyz;
    r3.xyz = log2(r3.xyz);
    r3.xyz = float3(0.416666657,0.416666657,0.416666657) * r3.xyz;
    r3.xyz = exp2(r3.xyz);
    r3.xyz = r3.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
    r3.xyz = r4.xyz ? r5.xyz : r3.xyz;
    r3.xyz = log2(r3.xyz);
    r3.xyz = float3(2.20000005,2.20000005,2.20000005) * r3.xyz;
    r3.xyz = exp2(r3.xyz);

    float3 vignetteGamma = r3.xyz;

    r4.x = dot(float3(0.627403915,0.329282999,0.0433131009), r3.xyz);
    r4.y = dot(float3(0.0690973029,0.919540584,0.0113623003), r3.xyz);
    r4.z = dot(float3(0.0163914002,0.0880132988,0.895595312), r3.xyz);
    // r3.xyz = cb0[26].yyy * r4.xyz;
    r3.xyz = LumaSettings.UIPaperWhiteNits * r4.xyz; // use UI paper white instead of cb0[26].y
    r2.xyz = r2.xyz * r3.www + r3.xyz;
    gradedAces.xyz = r2.xyz;
//upgrade tonemap

    r2.xyz = extractColorGradeAndApplyTonemap(colorSample, gradedAces, getMidGray(), v0.xy / cb0[34].zw);

    r2.w = dot(r2.xyz, float3(0.262699991,0.677999973,0.0593000017)); // scene luma
    r0.w = 1;
    // r2.xyz = r2.xyz + -r2.www;              // chroma = scene - luma
    // r2.xyz = cb0[25].xxx * r2.xyz + r2.www; // adjust chroma contrast threshold
#else

    r3.xyz = SampleLUT(lut2Tex, lut1Sample);

    float3 lut2Sample = r3.xyz;
    float3 lut2Linear = LUT_PQ_to_Linear(lut2Sample);

    r3.xyz = lut2Linear;

    float3 lut1Linear = LUT_PQ_to_Linear(lut1Output);
    r2.xyz = lut1Linear;

    r2.xyz = cb0[26].zzz * lut1Linear + lut2Linear;

#if _5CD12E67
    r2.xyz = SampleFogTexture(r2.xyz, pixelPos.xy);
#endif

    gradedAces = r2.xyz;
    r2.xyz = extractColorGradeAndApplyTonemap(colorSample, gradedAces, getMidGray(), v0.xy / cb0[34].zw);

#if _3A4D858E // Chapter 2 specific effect?
    r0.w = SampleNoiseTexture(gradedAces, v0);
    r3.xyz = gradedAces * r0.www;
    r2.w = dot(r3.xyz, float3(0.262699991,0.677999973,0.0593000017));
    // r2.xyz = r2.xyz * r0.www + -r2.www;
#elif _D950DA01 || _3B489929
    float3 videoColor = SampleVideoTexture(pixelPos.xy, v0.xy / cb0[34].zw);

    // this seems entirely pointless, but whatever.
    r3.xyz = videoColor + -r2.xyz;
    float2 blendFactor = saturate(cb0[24].xz);
    r2.xyz = r3.xyz * blendFactor.x + r2.xyz;
#if _3B489929
    r2.xyz = SampleFogTexture(r2.xyz, pixelPos.xy);
#endif
    r2.w = dot(r2.xyz, float3(0.262699991,0.677999973,0.0593000017));
    r0.w = 1;  
#else
    r3.xyz = gradedAces;
    r2.w = dot(r2.xyz, float3(0.262699991,0.677999973,0.0593000017));
    r0.w = 1;
#endif

#endif //3 lut branch

    r1.xyzw = uiTex.SampleLevel(uiSampler, pixelPos.xy, 0).xyzw;
    // r2.w = dot(r3.xyz, float3(0.262699991,0.677999973,0.0593000017));
    r2.xyz = r2.xyz * r0.www + -r2.www;
    r2.xyz = cb0[25].xxx * r2.xyz + r2.www;
    r3.xyz = cb0[26].www * r2.xyz;
    r3.xyz = cmp(float3(0,0,0) < r3.xyz);
    r3.xyz = r3.xyz ? cb0[26].xxx : 0;
    r2.xyz = r2.xyz * cb0[26].www + r3.xyz;
    r0.w = cb0[25].y * r1.w;
    // r1.w = rcp(cb0[26].y);
    r1.w = rcp(LumaSettings.UIPaperWhiteNits); // use UI paper white instead of cb0[26].y
    r3.xyz = r2.xyz * r1.www + float3(1,1,1);
    r3.xyz = rcp(r3.xyz);
    r1.w = r0.w * r0.w;
    r4.xyz = float3(1,1,1) + -r3.xyz;
    r3.xyz = r1.www * r4.xyz + r3.xyz;
    r2.xyz = r3.xyz * r2.xyz;
    r3.xyz = cmp(r1.xyz < float3(0.00313080009,0.00313080009,0.00313080009));
    r4.xyz = float3(12.9200001,12.9200001,12.9200001) * r1.xyz;
    r1.xyz = log2(r1.xyz);
    r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
    r1.xyz = r3.xyz ? r4.xyz : r1.xyz;
    r1.xyz = log2(r1.xyz);
    r1.xyz = float3(2.20000005,2.20000005,2.20000005) * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r3.x = dot(float3(0.627403915,0.329282999,0.0433131009), r1.xyz);
    r3.y = dot(float3(0.0690973029,0.919540584,0.0113623003), r1.xyz);
    r3.z = dot(float3(0.0163914002,0.0880132988,0.895595312), r1.xyz);
    // r1.xyz = cb0[26].yyy * r3.xyz;
    r1.xyz = LumaSettings.UIPaperWhiteNits * r3.xyz; // use UI paper white instead of cb0[26].y
    r1.xyz = r2.xyz * r0.www + r1.xyz;
    float3 color = Linear_to_PQ(r1.xyz / 10000.f);
    r1.xy = color.xy;
    r0.w = color.z;
  if (LumaSettings.GameSettings.custom_film_grain_strength.x == 0.f)
  {
    r0.z = asuint(cb1[139].z) << 3;
    r2.xyz = (int3)r0.xyz & int3(63,63,63);
    r2.w = 0;
    r0.x = ditherTex.Load(r2.xyzw).x;
    r0.x = r0.x * 2 + -1;
    r0.y = cmp(0 < r0.x);
    r0.z = cmp(r0.x < 0);
    r0.y = (int)-r0.y + (int)r0.z;
    r0.y = (int)r0.y;
    r0.x = 1 + -abs(r0.x);
    r0.x = sqrt(r0.x);
    r0.x = 1 + -r0.x;
    r0.x = r0.y * r0.x;
    r0.yz = r1.xy * float2(2,2) + float2(-1,-1);
    r0.yz = float2(-0.998044968,-0.998044968) + abs(r0.yz);
    r0.yz = cmp(r0.yz < float2(0,0));
    r1.zw = r0.xx * float2(0.000977517106,0.000977517106) + r1.xy;
    color.xy = saturate(r0.yz ? r1.zw : r1.xy);
    r0.y = r0.w * 2 + -1;
    r0.y = -0.998044968 + abs(r0.y);
    r0.y = cmp(r0.y < 0);
    r0.x = r0.x * 0.000977517106 + r0.w;
    color.z = saturate(r0.y ? r0.x : r0.w);
  }
    
#if EARLY_DISPLAY_ENCODING //scRGB OUTPUT
    color = PQ_to_Linear(color);
    color *= (HDR10_MaxWhiteNits / sRGB_WhiteLevelNits);
    color = BT2020_To_BT709(color);
#endif
    o0 = float4(color, 1);

  } else {
    o0.xyzw = float4(0,0,0,0);
  }
}