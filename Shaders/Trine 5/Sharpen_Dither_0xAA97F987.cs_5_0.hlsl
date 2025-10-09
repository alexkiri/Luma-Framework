cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m0 : packoffset(c0);
    uint2 cb0_m1 : packoffset(c1);
    uint2 cb0_m2 : packoffset(c1.z);
    uint2 cb0_m3 : packoffset(c2);
    uint2 cb0_m4 : packoffset(c2.z);
};

Texture2D<float4> t0 : register(t0);
Texture2D<float4> t3 : register(t3);
RWTexture2D<float4> u0 : register(u0);

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
    uint _56 = spvBitfieldUExtract(vThreadIDInGroup.x, 1u, 3u) + (vThreadGroupID.x * 16u);
    uint _57 = spvBitfieldInsert(vThreadIDInGroup.x >> 3u, vThreadIDInGroup.x, 0u, 1u) + (vThreadGroupID.y * 16u);
    uint _67 = (_57 + cb0_m2.y) & 63u;
    float4 _70 = t3.Load(int3(uint2((_56 + cb0_m2.x) & 63u, _67), 0u));
    float _75 = mad(_70.x, 2.0f, -1.0f);
    float _77 = mad(_70.y, 2.0f, -1.0f);
    float _78 = mad(_70.z, 2.0f, -1.0f);
    float4 _119 = t0.Load(int3(uint2(_56, _57), 0u));
    float _120 = _119.x;
    float _121 = _119.y;
    float _122 = _119.z;
    float _123 = _120 * _120;
    float _124 = _121 * _121;
    float _125 = _122 * _122;
    float _132 = exp2(log2(_123) * 0.4166666567325592041015625f);
    float _133 = exp2(log2(_124) * 0.4166666567325592041015625f);
    float _134 = exp2(log2(_125) * 0.4166666567325592041015625f);
    uint _164 = _57 + cb0_m3.y;
    uint _165 = _56 + 8u;
    uint _166 = _57 + 8u;
    u0[uint2(_56 + cb0_m3.x, _164)] = float4(mad((1.0f - sqrt(1.0f - abs(_75))) * float(int(((_75 < 0.0f) ? 4294967295u : 0u) + uint(_75 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_123, 12.9200000762939453125f, mad(-_132, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_123 <= 0.003130800090730190277099609375f), mad(_132, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_77 > 0.0f) + ((_77 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_77))), 0.0078740157186985015869140625f, mad(float(_124 <= 0.003130800090730190277099609375f), mad(_124, 12.9200000762939453125f, mad(-_133, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_133, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_78 > 0.0f) + ((_78 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_78))), 0.0078740157186985015869140625f, mad(float(_125 <= 0.003130800090730190277099609375f), mad(_125, 12.9200000762939453125f, mad(-_134, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_134, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
    uint _172 = (_165 + cb0_m2.x) & 63u;
    uint _173 = (_166 + cb0_m2.y) & 63u;
    float4 _175 = t3.Load(int3(uint2(_172, _67), 0u));
    float _179 = mad(_175.x, 2.0f, -1.0f);
    float _180 = mad(_175.y, 2.0f, -1.0f);
    float _181 = mad(_175.z, 2.0f, -1.0f);
    float4 _219 = t0.Load(int3(uint2(_165, _57), 0u));
    float _220 = _219.x;
    float _221 = _219.y;
    float _222 = _219.z;
    float _223 = _220 * _220;
    float _224 = _221 * _221;
    float _225 = _222 * _222;
    float _232 = exp2(log2(_223) * 0.4166666567325592041015625f);
    float _233 = exp2(log2(_224) * 0.4166666567325592041015625f);
    float _234 = exp2(log2(_225) * 0.4166666567325592041015625f);
    uint _259 = _165 + cb0_m3.x;
    u0[uint2(_259, _164)] = float4(mad((1.0f - sqrt(1.0f - abs(_179))) * float(int(((_179 < 0.0f) ? 4294967295u : 0u) + uint(_179 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_223, 12.9200000762939453125f, mad(-_232, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_223 <= 0.003130800090730190277099609375f), mad(_232, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_180 > 0.0f) + ((_180 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_180))), 0.0078740157186985015869140625f, mad(float(_224 <= 0.003130800090730190277099609375f), mad(_224, 12.9200000762939453125f, mad(-_233, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_233, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_181 > 0.0f) + ((_181 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_181))), 0.0078740157186985015869140625f, mad(float(_225 <= 0.003130800090730190277099609375f), mad(_225, 12.9200000762939453125f, mad(-_234, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_234, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
    float4 _263 = t0.Load(int3(uint2(_165, _166), 0u));
    float _264 = _263.x;
    float _265 = _263.y;
    float _266 = _263.z;
    float _267 = _264 * _264;
    float _268 = _265 * _265;
    float _269 = _266 * _266;
    float _276 = exp2(log2(_267) * 0.4166666567325592041015625f);
    float _277 = exp2(log2(_268) * 0.4166666567325592041015625f);
    float _278 = exp2(log2(_269) * 0.4166666567325592041015625f);
    float4 _301 = t3.Load(int3(uint2(_172, _173), 0u));
    float _305 = mad(_301.x, 2.0f, -1.0f);
    float _306 = mad(_301.y, 2.0f, -1.0f);
    float _307 = mad(_301.z, 2.0f, -1.0f);
    uint _347 = _166 + cb0_m3.y;
    uint _348 = _165 - 8u;
    u0[uint2(_259, _347)] = float4(mad((1.0f - sqrt(1.0f - abs(_305))) * float(int(((_305 < 0.0f) ? 4294967295u : 0u) + uint(_305 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_267, 12.9200000762939453125f, mad(-_276, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_267 <= 0.003130800090730190277099609375f), mad(_276, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_306 > 0.0f) + ((_306 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_306))), 0.0078740157186985015869140625f, mad(float(_268 <= 0.003130800090730190277099609375f), mad(_268, 12.9200000762939453125f, mad(-_277, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_277, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_307 > 0.0f) + ((_307 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_307))), 0.0078740157186985015869140625f, mad(float(_269 <= 0.003130800090730190277099609375f), mad(_269, 12.9200000762939453125f, mad(-_278, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_278, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
    float4 _354 = t3.Load(int3(uint2((_348 + cb0_m2.x) & 63u, _173), 0u));
    float _358 = mad(_354.x, 2.0f, -1.0f);
    float _359 = mad(_354.y, 2.0f, -1.0f);
    float _360 = mad(_354.z, 2.0f, -1.0f);
    float4 _398 = t0.Load(int3(uint2(_348, _166), 0u));
    float _399 = _398.x;
    float _400 = _398.y;
    float _401 = _398.z;
    float _403 = _399 * _399;
    float _404 = _400 * _400;
    float _405 = _401 * _401;
    float _412 = exp2(log2(_403) * 0.4166666567325592041015625f);
    float _413 = exp2(log2(_404) * 0.4166666567325592041015625f);
    float _414 = exp2(log2(_405) * 0.4166666567325592041015625f);
    u0[uint2(_348 + cb0_m3.x, _347)] = float4(mad((1.0f - sqrt(1.0f - abs(_358))) * float(int(((_358 < 0.0f) ? 4294967295u : 0u) + uint(_358 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_403, 12.9200000762939453125f, mad(-_412, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_403 <= 0.003130800090730190277099609375f), mad(_412, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_359 > 0.0f) + ((_359 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_359))), 0.0078740157186985015869140625f, mad(mad(_404, 12.9200000762939453125f, mad(-_413, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_404 <= 0.003130800090730190277099609375f), mad(_413, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_360 > 0.0f) + ((_360 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_360))), 0.0078740157186985015869140625f, mad(mad(_405, 12.9200000762939453125f, mad(-_414, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_405 <= 0.003130800090730190277099609375f), mad(_414, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
}