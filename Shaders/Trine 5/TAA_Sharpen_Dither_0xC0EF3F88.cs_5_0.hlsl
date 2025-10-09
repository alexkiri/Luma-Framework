#include "Includes/Common.hlsl"

#define NEW_IMPLEMENTATION 0

#if NEW_IMPLEMENTATION
cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}
#else
cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m0 : packoffset(c0);
    uint2 cb0_m1 : packoffset(c1);
    uint2 cb0_m2 : packoffset(c1.z);
    uint2 cb0_m3 : packoffset(c2);
    uint2 cb0_m4 : packoffset(c2.z);
};
#endif

Texture2D<unorm float4> t3 : register(t3); // Film grain / noise / dither
Texture2D<unorm float> t2 : register(t2); // Scene Y (luminance)
Texture2D<snorm float2> t1 : register(t1); // Scene Co/Cg
#if 1 // LUMA
Texture2D<float4> t0 : register(t0); // Input Scene (unused)
RWTexture2D<float4> u0 : register(u0); // Output
#else
Texture2D<unorm float4> t0 : register(t0); // Input Scene (unused)
RWTexture2D<unorm float4> u0 : register(u0); // Output
#endif

#define cmp

uint spvBitfieldInsert(uint Base, uint Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint2 spvBitfieldInsert(uint2 Base, uint2 Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint3 spvBitfieldInsert(uint3 Base, uint3 Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint4 spvBitfieldInsert(uint4 Base, uint4 Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint spvBitfieldUExtract(uint Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

uint2 spvBitfieldUExtract(uint2 Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

uint3 spvBitfieldUExtract(uint3 Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

uint4 spvBitfieldUExtract(uint4 Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

int spvBitfieldSExtract(int Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int2 spvBitfieldSExtract(int2 Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int2 Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int3 spvBitfieldSExtract(int3 Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int3 Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int4 spvBitfieldSExtract(int4 Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int4 Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

[numthreads(64, 1, 1)]
void main(uint3 vThreadGroupID : SV_GroupID, uint3 vThreadIDInGroup : SV_GroupThreadID)
{
	float whiteRatio = 1.0;
#if 1 // Luma: scale the luminance stored in the sharpen preparation Y texture by the peak brightness (range would have been 0-1 in SDR, but now it'd clip). It's ok as the texture is 16 bit so there's quality for it.
	whiteRatio = LumaSettings.PeakWhiteNits / LumaSettings.GamePaperWhiteNits;
#endif

#if NEW_IMPLEMENTATION // Cleaner decompile // TODO: broken

  float4 r0,r1,r2,r3,r4,r5;
#if 1
  uint _59 = spvBitfieldUExtract(vThreadIDInGroup.x, 1u, 3u) + (vThreadGroupID.x * 16u);
  uint _60 = spvBitfieldInsert(vThreadIDInGroup.x >> 3u, vThreadIDInGroup.x, 0u, 1u) + (vThreadGroupID.y * 16u);
  r0.xz = asfloat(uint2(_59, _60));
#else
  uint4 r0i;
  uint4 bitmask;
  r0i.x = (uint)vThreadIDInGroup.x >> 3;
  bitmask.y = ((~(-1 << 1)) << 0) & 0xffffffff;  r0i.y = (((uint)vThreadIDInGroup.x << 0) & bitmask.y) | ((uint)r0i.x & ~bitmask.y);
  if (3 == 0) r0i.x = 0; else if (3+1 < 32) {   r0i.x = (uint)vThreadIDInGroup.x << (32-(3 + 1)); r0i.x = (uint)r0i.x >> (32-3);  } else r0i.x = (uint)vThreadIDInGroup.x >> 1;
  r0.xz = asfloat(vThreadGroupID.xy * int2(16,16) + asint(r0i.xy)); // imad
#endif
  r0.yw = float2(0,0);
  r1.x = t2.Load(asint(r0.xzw)).x * whiteRatio;
  r1.yz = t1.Load(asint(r0.xzy)).xy;
  r1.w = -r1.y * 0.5 + r1.x;
  r2.yw = r1.zy * float2(0.5,0.5) + r1.xx;
  r2.z = -r1.z * 0.5 + r1.w;
  r2.x = -r1.z * 0.5 + r2.w;
#if 0 // Linear to sRGB
  r2.xyz = saturate(r2.xyz);
  r1.xyz = log2(r2.xyz);
  r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r2.xyz * float3(12.9200001,12.9200001,12.9200001) + -r1.xyz;
  r2.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r2.xyz);
  r2.xyz = asfloat(asint(r2.xyz) & 0x3f800000);
  r1.xyz = r2.xyz * r3.xyz + r1.xyz;
#else
  r1.xyz = r2.xyz;
#endif
  r2.xy = asfloat(asint(r0.xz) + asint(cb0[1].zw));
  r2.xy = asfloat(asint(r2.xy) & int2(63,63));
  r2.zw = float2(0,0);
  r2.xyz = t3.Load(asint(r2.xyz)).xyz;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.xyz = cmp(float3(0,0,0) < r2.xyz);
  r4.xyz = cmp(r2.xyz < float3(0,0,0));
  r2.xyz = float3(1,1,1) + -abs(r2.xyz);
  r2.xyz = sqrt(r2.xyz);
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r3.xyz = (float3)(asint(r4.xyz) - asint(r3.xyz));
  r2.xyz = r3.xyz * r2.xyz;
  r1.xyz = r2.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r1.xyz; // TODO: 7 bit dithering? Or some UNORM scaling? Or encoding (e.g. that square root above, or multiplication)?
  r1.w = 1;
  r2.xy = asfloat(asint(r0.xz) + asint(cb0[2].xy));
  r0.xy = asfloat(asint(r0.xz) + int2(8,8));
  u0[asint(r2.xy)] = r1.xyzw;
  r1.x = t2.Load(asint(r0.xzw)).x * whiteRatio;
  r1.yz = t1.Load(asint(r0.xzw)).xy;
  r1.w = -r1.y * 0.5 + r1.x;
  r2.yw = r1.zy * float2(0.5,0.5) + r1.xx;
  r2.z = -r1.z * 0.5 + r1.w;
  r2.x = -r1.z * 0.5 + r2.w;
#if 0 // Linear to sRGB
  r2.xyz = saturate(r2.xyz);
  r1.xyz = log2(r2.xyz);
  r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r2.xyz * float3(12.9200001,12.9200001,12.9200001) + -r1.xyz;
  r2.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r2.xyz);
  r2.xyz = asfloat(asint(r2.xyz) & 0x3f800000);
  r1.xyz = r2.xyz * r3.xyz + r1.xyz;
#else
  r1.xyz = r2.xyz;
#endif
  r2.zw = float2(0,0);
  r3.xyzw = asfloat(asint(r0.xzxy) + asint(cb0[1].zwzw));
  r2.xy = asfloat(asint(r3.xy) & int2(63,63));
  r3.xy = asfloat(asint(r3.zw) & int2(63,63));
  r2.xyz = t3.Load(asint(r2.xyz)).xyz;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyz = cmp(float3(0,0,0) < r2.xyz);
  r5.xyz = cmp(r2.xyz < float3(0,0,0));
  r2.xyz = float3(1,1,1) + -abs(r2.xyz);
  r2.xyz = sqrt(r2.xyz);
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r4.xyz = (float3)(asint(r5.xyz) - asint(r4.xyz));
  r2.xyz = r4.xyz * r2.xyz;
  r1.xyz = r2.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r1.xyz;
  r1.w = 1;
  r2.xy = asfloat(asint(r0.xz) + asint(cb0[2].xy));
  u0[asint(r2.xy)] = r1.xyzw;
  r0.z = t2.Load(asint(r0.xyw)).x * whiteRatio;
  r1.xy = t1.Load(asint(r0.xyw)).xy;
  r2.yzw = r0.yww;
  r0.w = -r1.x * 0.5 + r0.z;
  r4.yw = r1.yx * float2(0.5,0.5) + r0.zz;
  r4.z = -r1.y * 0.5 + r0.w;
  r4.x = -r1.y * 0.5 + r4.w;
#if 0 // Linear to sRGB
  r4.xyz = saturate(r4.xyz);
  r1.xyz = log2(r4.xyz);
  r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r5.xyz = r4.xyz * float3(12.9200001,12.9200001,12.9200001) + -r1.xyz;
  r4.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r4.xyz);
  r4.xyz = asfloat(asint(r4.xyz) & 0x3f800000);
  r1.xyz = r4.xyz * r5.xyz + r1.xyz;
#else
  r1.xyz = r4.xyz;
#endif
  r3.zw = float2(0,0);
  r3.xyz = t3.Load(asint(r3.xyz)).xyz;
  r3.xyz = r3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyz = cmp(float3(0,0,0) < r3.xyz);
  r5.xyz = cmp(r3.xyz < float3(0,0,0));
  r3.xyz = float3(1,1,1) + -abs(r3.xyz);
  r3.xyz = sqrt(r3.xyz);
  r3.xyz = float3(1,1,1) + -r3.xyz;
  r4.xyz = (float3)(asint(r5.xyz) - asint(r4.xyz));
  r3.xyz = r4.xyz * r3.xyz;
  r1.xyz = r3.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r1.xyz;
  r1.w = 1;
  r3.xy = asfloat(asint(r0.xy) + asint(cb0[2].xy));
  r2.x = asfloat(asint(r0.x) - 8);
  u0[asint(r3.xy)] = r1.xyzw;
  r0.x = t2.Load(asint(r2.xyw)).x * whiteRatio;
  r0.yz = t1.Load(asint(r2.xyz)).xy;
  r0.w = -r0.y * 0.5 + r0.x;
  r1.yw = r0.zy * float2(0.5,0.5) + r0.xx;
  r1.z = -r0.z * 0.5 + r0.w;
  r1.x = -r0.z * 0.5 + r1.w;
#if 0 // Linear to sRGB
  r1.xyz = saturate(r1.xyz);
  r0.xyz = log2(r1.xyz);
  r0.xyz = float3(0.416666657,0.416666657,0.416666657) * r0.xyz;
  r0.xyz = exp2(r0.xyz);
  r0.xyz = r0.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r1.xyz * float3(12.9200001,12.9200001,12.9200001) + -r0.xyz;
  r1.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r1.xyz);
  r1.xyz = asfloat(asint(r1.xyz) & 0x3f800000);
  r0.xyz = r1.xyz * r3.xyz + r0.xyz;
#else
  r0.xyz = r1.xyz;
#endif
  r1.xy = asfloat(asint(r2.xy) + asint(cb0[1].zw));
  r2.xy = asfloat(asint(r2.xy) + asint(cb0[2].xy));
  r1.xy = asfloat(asint(r1.xy) & int2(63,63));
  r1.zw = float2(0,0);
  r1.xyz = t3.Load(asint(r1.xyz)).xyz;
  r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.xyz = cmp(float3(0,0,0) < r1.xyz);
  r4.xyz = cmp(r1.xyz < float3(0,0,0));
  r1.xyz = float3(1,1,1) + -abs(r1.xyz);
  r1.xyz = sqrt(r1.xyz);
  r1.xyz = float3(1,1,1) + -r1.xyz;
  r3.xyz = (float3)(asint(r4.xyz) - asint(r3.xyz));
  r1.xyz = r3.xyz * r1.xyz;
  r0.xyz = r1.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r0.xyz;
  r0.w = 1;
  u0[asint(r2.xy)] = r0.xyzw;

#else

    uint _59 = spvBitfieldUExtract(vThreadIDInGroup.x, 1u, 3u) + (vThreadGroupID.x * 16u);
    uint _60 = spvBitfieldInsert(vThreadIDInGroup.x >> 3u, vThreadIDInGroup.x, 0u, 1u) + (vThreadGroupID.y * 16u);
    uint2 _62 = uint2(_59, _60);
    float _63 = t2.Load(int3(_62, 0u)) * whiteRatio;
    float _65 = _63.x;
    float2 _67 = t1.Load(int3(_62, 0u));
    float _68 = _67.x;
    float _69 = _67.y;
    float3 encodedColor;
#if 1 // Luma: skip linear to sRGB encodes
    encodedColor.x = mad(_69, -0.5f, mad(_68, 0.5f, _65));
    encodedColor.y = mad(_69, 0.5f, _65);
    encodedColor.z = mad(_69, -0.5f, mad(_68, -0.5f, _65));
#else
    float _76 = clamp(mad(_69, -0.5f, mad(_68, 0.5f, _65)), 0.0f, 1.0f);
    float _77 = clamp(mad(_69, 0.5f, _65), 0.0f, 1.0f);
    float _78 = clamp(mad(_69, -0.5f, mad(_68, -0.5f, _65)), 0.0f, 1.0f);
    float _85 = exp2(log2(_76) * 0.4166666567325592041015625f);
    float _86 = exp2(log2(_77) * 0.4166666567325592041015625f);
    float _87 = exp2(log2(_78) * 0.4166666567325592041015625f);
    encodedColor.x = mad(mad(_76, 12.9200000762939453125f, mad(-_85, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_76 <= 0.003130800090730190277099609375f), mad(_85, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.y = mad(float(_77 <= 0.003130800090730190277099609375f), mad(_77, 12.9200000762939453125f, mad(-_86, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_86, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.z = mad(float(_78 <= 0.003130800090730190277099609375f), mad(_78, 12.9200000762939453125f, mad(-_87, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_87, 1.05499994754791259765625f, -0.054999999701976776123046875f));
#endif
    uint _119 = (_60 + cb0_m2.y) & 63u;
    float4 _122 = t3.Load(int3(uint2((_59 + cb0_m2.x) & 63u, _119), 0u));
    float _126 = mad(_122.x, 2.0f, -1.0f);
    float _127 = mad(_122.y, 2.0f, -1.0f);
    float _128 = mad(_122.z, 2.0f, -1.0f);
    uint _174 = _60 + cb0_m3.y;
    uint _175 = _59 + 8u;
    uint _176 = _60 + 8u;
    u0[uint2(_59 + cb0_m3.x, _174)] = float4(mad((1.0f - sqrt(1.0f - abs(_126))) * float(int(((_126 < 0.0f) ? 4294967295u : 0u) + uint(_126 > 0.0f))), 0.0078740157186985015869140625f, encodedColor.x), mad(float(int(uint(_127 > 0.0f) + ((_127 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_127))), 0.0078740157186985015869140625f, encodedColor.y), mad(float(int(uint(_128 > 0.0f) + ((_128 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_128))), 0.0078740157186985015869140625f, encodedColor.z), 1.0f);
    uint2 _180 = uint2(_175, _60);
    float _181 = t2.Load(int3(_180, 0u)) * whiteRatio;
    float _182 = _181.x;
    float2 _183 = t1.Load(int3(_180, 0u));
    float _184 = _183.x;
    float _185 = _183.y;
#if 1
    encodedColor.x = mad(_185, -0.5f, mad(_184, 0.5f, _182));
    encodedColor.y = mad(_185, 0.5f, _182);
    encodedColor.z = mad(_185, -0.5f, mad(_184, -0.5f, _182));
#else
    float _191 = clamp(mad(_185, -0.5f, mad(_184, 0.5f, _182)), 0.0f, 1.0f);
    float _192 = clamp(mad(_185, 0.5f, _182), 0.0f, 1.0f);
    float _193 = clamp(mad(_185, -0.5f, mad(_184, -0.5f, _182)), 0.0f, 1.0f);
    float _200 = exp2(log2(_191) * 0.4166666567325592041015625f);
    float _201 = exp2(log2(_192) * 0.4166666567325592041015625f);
    float _202 = exp2(log2(_193) * 0.4166666567325592041015625f);
    encodedColor.x = mad(mad(_191, 12.9200000762939453125f, mad(-_200, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_191 <= 0.003130800090730190277099609375f), mad(_200, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.y = mad(float(_192 <= 0.003130800090730190277099609375f), mad(_192, 12.9200000762939453125f, mad(-_201, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_201, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.z = mad(float(_193 <= 0.003130800090730190277099609375f), mad(_193, 12.9200000762939453125f, mad(-_202, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_202, 1.05499994754791259765625f, -0.054999999701976776123046875f));
#endif
    uint _226 = (_175 + cb0_m2.x) & 63u;
    uint _227 = (_176 + cb0_m2.y) & 63u;
    float4 _229 = t3.Load(int3(uint2(_226, _119), 0u));
    float _233 = mad(_229.x, 2.0f, -1.0f);
    float _234 = mad(_229.y, 2.0f, -1.0f);
    float _235 = mad(_229.z, 2.0f, -1.0f);
    uint _275 = _175 + cb0_m3.x;
    u0[uint2(_275, _174)] = float4(mad((1.0f - sqrt(1.0f - abs(_233))) * float(int(((_233 < 0.0f) ? 4294967295u : 0u) + uint(_233 > 0.0f))), 0.0078740157186985015869140625f, encodedColor.x), mad(float(int(uint(_234 > 0.0f) + ((_234 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_234))), 0.0078740157186985015869140625f, encodedColor.y), mad(float(int(uint(_235 > 0.0f) + ((_235 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_235))), 0.0078740157186985015869140625f, encodedColor.z), 1.0f);
    uint2 _278 = uint2(_175, _176);
    float _279 = t2.Load(int3(_278, 0u)) * whiteRatio;
    float _280 = _279.x;
    float2 _281 = t1.Load(int3(_278, 0u));
    float _282 = _281.x;
    float _283 = _281.y;
#if 1
    encodedColor.x = mad(_283, -0.5f, mad(_282, 0.5f, _280));
    encodedColor.y = mad(_283, 0.5f, _280);
    encodedColor.z = mad(_283, -0.5f, mad(_282, -0.5f, _280));
#else
    float _289 = clamp(mad(_283, -0.5f, mad(_282, 0.5f, _280)), 0.0f, 1.0f);
    float _290 = clamp(mad(_283, 0.5f, _280), 0.0f, 1.0f);
    float _291 = clamp(mad(_283, -0.5f, mad(_282, -0.5f, _280)), 0.0f, 1.0f);
    float _298 = exp2(log2(_289) * 0.4166666567325592041015625f);
    float _299 = exp2(log2(_290) * 0.4166666567325592041015625f);
    float _300 = exp2(log2(_291) * 0.4166666567325592041015625f);
    encodedColor.x = mad(mad(_289, 12.9200000762939453125f, mad(-_298, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_289 <= 0.003130800090730190277099609375f), mad(_298, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.y = mad(float(_290 <= 0.003130800090730190277099609375f), mad(_290, 12.9200000762939453125f, mad(-_299, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_299, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.z = mad(float(_291 <= 0.003130800090730190277099609375f), mad(_291, 12.9200000762939453125f, mad(-_300, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_300, 1.05499994754791259765625f, -0.054999999701976776123046875f));
#endif
    float4 _323 = t3.Load(int3(uint2(_226, _227), 0u));
    float _327 = mad(_323.x, 2.0f, -1.0f);
    float _328 = mad(_323.y, 2.0f, -1.0f);
    float _329 = mad(_323.z, 2.0f, -1.0f);
    uint _369 = _176 + cb0_m3.y;
    uint _370 = _175 - 8u;
    u0[uint2(_275, _369)] = float4(mad((1.0f - sqrt(1.0f - abs(_327))) * float(int(((_327 < 0.0f) ? 4294967295u : 0u) + uint(_327 > 0.0f))), 0.0078740157186985015869140625f, encodedColor.x), mad(float(int(uint(_328 > 0.0f) + ((_328 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_328))), 0.0078740157186985015869140625f, encodedColor.y), mad(float(int(uint(_329 > 0.0f) + ((_329 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_329))), 0.0078740157186985015869140625f, encodedColor.z), 1.0f);
    uint2 _373 = uint2(_370, _176);
    float _374 = t2.Load(int3(_373, 0u)) * whiteRatio;
    float _375 = _374.x;
    float2 _376 = t1.Load(int3(_373, 0u));
    float _377 = _376.x;
    float _378 = _376.y;
#if 1
    encodedColor.x = mad(_378, -0.5f, mad(_377, 0.5f, _375));
    encodedColor.y = mad(_378, 0.5f, _375);
    encodedColor.z = mad(_378, -0.5f, mad(_377, -0.5f, _375));
#else
    float _384 = clamp(mad(_378, -0.5f, mad(_377, 0.5f, _375)), 0.0f, 1.0f);
    float _385 = clamp(mad(_378, 0.5f, _375), 0.0f, 1.0f);
    float _386 = clamp(mad(_378, -0.5f, mad(_377, -0.5f, _375)), 0.0f, 1.0f);
    float _393 = exp2(log2(_384) * 0.4166666567325592041015625f);
    float _394 = exp2(log2(_385) * 0.4166666567325592041015625f);
    float _395 = exp2(log2(_386) * 0.4166666567325592041015625f);
    encodedColor.x = mad(mad(_384, 12.9200000762939453125f, mad(-_393, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_384 <= 0.003130800090730190277099609375f), mad(_393, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.y = mad(mad(_385, 12.9200000762939453125f, mad(-_394, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_385 <= 0.003130800090730190277099609375f), mad(_394, 1.05499994754791259765625f, -0.054999999701976776123046875f));
    encodedColor.z = mad(mad(_386, 12.9200000762939453125f, mad(-_395, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_386 <= 0.003130800090730190277099609375f), mad(_395, 1.05499994754791259765625f, -0.054999999701976776123046875f));
#endif
    float4 _421 = t3.Load(int3(uint2((_370 + cb0_m2.x) & 63u, _227), 0u));
    float _425 = mad(_421.x, 2.0f, -1.0f);
    float _426 = mad(_421.y, 2.0f, -1.0f);
    float _427 = mad(_421.z, 2.0f, -1.0f);
    u0[uint2(_370 + cb0_m3.x, _369)] = float4(mad((1.0f - sqrt(1.0f - abs(_425))) * float(int(((_425 < 0.0f) ? 4294967295u : 0u) + uint(_425 > 0.0f))), 0.0078740157186985015869140625f, encodedColor.x), mad(float(int(uint(_426 > 0.0f) + ((_426 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_426))), 0.0078740157186985015869140625f, encodedColor.y), mad(float(int(uint(_427 > 0.0f) + ((_427 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_427))), 0.0078740157186985015869140625f, encodedColor.z), 1.0f);

#endif
}