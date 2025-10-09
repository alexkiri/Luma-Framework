cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m0 : packoffset(c0);
    uint2 cb0_m1 : packoffset(c1);
    uint2 cb0_m2 : packoffset(c1.z);
    uint2 cb0_m3 : packoffset(c2);
    uint2 cb0_m4 : packoffset(c2.z);
    uint4 cb0_m5 : packoffset(c3);
    float4 cb0_m6 : packoffset(c4);
};

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t2 : register(t2);
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
    uint _68 = spvBitfieldUExtract(vThreadIDInGroup.x, 1u, 3u) + (vThreadGroupID.x * 16u);
    uint _69 = spvBitfieldInsert(vThreadIDInGroup.x >> 3u, vThreadIDInGroup.x, 0u, 1u) + (vThreadGroupID.y * 16u);
    uint2 _71 = uint2(_68, _69);
    float4 _72 = t2.Load(int3(_71, 0u));
    float _73 = _72.x;
    float4 _75 = t1.Load(int3(_71, 0u));
    float _76 = _75.x;
    float _77 = _75.y;
    float _85 = clamp(mad(_77, 0.5f, _73), 0.0f, 1.0f);
    uint _87 = _69 + 1u;
    uint2 _89 = uint2(_68 + 1u, _69);
    float4 _90 = t2.Load(int3(_89, 0u));
    float _91 = _90.x;
    float4 _92 = t1.Load(int3(_89, 0u));
    float _93 = _92.x;
    float _94 = _92.y;
    float _101 = clamp(mad(_94, 0.5f, _91), 0.0f, 1.0f);
    uint _104 = _69 - 1u;
    uint2 _106 = uint2(_68 - 1u, _69);
    float4 _107 = t2.Load(int3(_106, 0u));
    float _108 = _107.x;
    float4 _109 = t1.Load(int3(_106, 0u));
    float _110 = _109.x;
    float _111 = _109.y;
    float _118 = clamp(mad(_111, 0.5f, _108), 0.0f, 1.0f);
    uint2 _121 = uint2(_68, _104);
    float4 _122 = t2.Load(int3(_121, 0u));
    float _123 = _122.x;
    float4 _124 = t1.Load(int3(_121, 0u));
    float _125 = _124.x;
    float _126 = _124.y;
    float _133 = clamp(mad(_126, 0.5f, _123), 0.0f, 1.0f);
    uint2 _135 = uint2(_68, _87);
    float4 _136 = t2.Load(int3(_135, 0u));
    float _137 = _136.x;
    float4 _138 = t1.Load(int3(_135, 0u));
    float _139 = _138.x;
    float _140 = _138.y;
    float _147 = clamp(mad(_140, 0.5f, _137), 0.0f, 1.0f);
    float _154 = max(max(max(_101, _85), _118), max(_147, _133));
    float _170 = asfloat((asuint(clamp(min(min(min(min(_101, _85), _118), min(_147, _133)), 1.0f - _154) * asfloat(2129690299u - asuint(_154)), 0.0f, 1.0f)) >> 1u) + 532432441u) * cb0_m6.x;
    float _186 = mad(_170, 4.0f, 1.0f);
    float _192 = asfloat(2129764351u - asuint(_186));
    float _195 = _192 * mad(-_186, _192, 2.0f);
    float _199 = clamp((clamp(mad(_77, -0.5f, mad(_76, 0.5f, _73)), 0.0f, 1.0f) + mad(clamp(mad(_140, -0.5f, mad(_139, 0.5f, _137)), 0.0f, 1.0f), _170, mad(clamp(mad(_94, -0.5f, mad(_93, 0.5f, _91)), 0.0f, 1.0f), _170, (clamp(mad(_111, -0.5f, mad(_110, 0.5f, _108)), 0.0f, 1.0f) * _170) + (clamp(mad(_126, -0.5f, mad(_125, 0.5f, _123)), 0.0f, 1.0f) * _170)))) * _195, 0.0f, 1.0f);
    float _200 = clamp(_195 * (_85 + mad(_170, _147, mad(_101, _170, (_170 * _133) + (_170 * _118)))), 0.0f, 1.0f);
    float _201 = clamp(_195 * (clamp(mad(_77, -0.5f, mad(_76, -0.5f, _73)), 0.0f, 1.0f) + mad(_170, clamp(mad(_140, -0.5f, mad(_139, -0.5f, _137)), 0.0f, 1.0f), mad(clamp(mad(_94, -0.5f, mad(_93, -0.5f, _91)), 0.0f, 1.0f), _170, (_170 * clamp(mad(_126, -0.5f, mad(_125, -0.5f, _123)), 0.0f, 1.0f)) + (_170 * clamp(mad(_111, -0.5f, mad(_110, -0.5f, _108)), 0.0f, 1.0f))))), 0.0f, 1.0f);
    float _208 = exp2(log2(_199) * 0.4166666567325592041015625f);
    float _209 = exp2(log2(_200) * 0.4166666567325592041015625f);
    float _210 = exp2(log2(_201) * 0.4166666567325592041015625f);
    uint _241 = (_69 + cb0_m2.y) & 63u;
    float4 _244 = t3.Load(int3(uint2((_68 + cb0_m2.x) & 63u, _241), 0u));
    float _248 = mad(_244.x, 2.0f, -1.0f);
    float _249 = mad(_244.y, 2.0f, -1.0f);
    float _250 = mad(_244.z, 2.0f, -1.0f);
    uint _296 = _69 + cb0_m3.y;
    u0[uint2(_68 + cb0_m3.x, _296)] = float4(mad((1.0f - sqrt(1.0f - abs(_248))) * float(int(((_248 < 0.0f) ? 4294967295u : 0u) + uint(_248 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_199, 12.9200000762939453125f, mad(-_208, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_199 <= 0.003130800090730190277099609375f), mad(_208, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_249 > 0.0f) + ((_249 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_249))), 0.0078740157186985015869140625f, mad(float(_200 <= 0.003130800090730190277099609375f), mad(_200, 12.9200000762939453125f, mad(-_209, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_209, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_250 > 0.0f) + ((_250 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_250))), 0.0078740157186985015869140625f, mad(float(_201 <= 0.003130800090730190277099609375f), mad(_201, 12.9200000762939453125f, mad(-_210, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_210, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
    uint _300 = _68 + 8u;
    uint _301 = _69 + 8u;
    uint _302 = _300 + 1u;
    uint2 _303 = uint2(_302, _69);
    float4 _304 = t2.Load(int3(_303, 0u));
    float _305 = _304.x;
    float4 _306 = t1.Load(int3(_303, 0u));
    float _307 = _306.x;
    float _308 = _306.y;
    float _315 = clamp(mad(_308, 0.5f, _305), 0.0f, 1.0f);
    uint2 _317 = uint2(_300, _69);
    float4 _318 = t2.Load(int3(_317, 0u));
    float _319 = _318.x;
    float4 _320 = t1.Load(int3(_317, 0u));
    float _321 = _320.x;
    float _322 = _320.y;
    float _329 = clamp(mad(_322, 0.5f, _319), 0.0f, 1.0f);
    uint _332 = _300 - 1u;
    uint2 _333 = uint2(_332, _69);
    float4 _334 = t2.Load(int3(_333, 0u));
    float _335 = _334.x;
    float4 _336 = t1.Load(int3(_333, 0u));
    float _337 = _336.x;
    float _338 = _336.y;
    float _345 = clamp(mad(_338, 0.5f, _335), 0.0f, 1.0f);
    uint2 _348 = uint2(_300, _104);
    float4 _349 = t2.Load(int3(_348, 0u));
    float _350 = _349.x;
    float4 _351 = t1.Load(int3(_348, 0u));
    float _352 = _351.x;
    float _353 = _351.y;
    float _360 = clamp(mad(_353, 0.5f, _350), 0.0f, 1.0f);
    uint2 _362 = uint2(_300, _87);
    float4 _363 = t2.Load(int3(_362, 0u));
    float _364 = _363.x;
    float4 _365 = t1.Load(int3(_362, 0u));
    float _366 = _365.x;
    float _367 = _365.y;
    float _374 = clamp(mad(_367, 0.5f, _364), 0.0f, 1.0f);
    float _381 = max(max(max(_329, _315), _345), max(_374, _360));
    float _393 = asfloat((asuint(clamp(min(min(min(min(_329, _315), _345), min(_374, _360)), 1.0f - _381) * asfloat(2129690299u - asuint(_381)), 0.0f, 1.0f)) >> 1u) + 532432441u) * cb0_m6.x;
    float _409 = mad(_393, 4.0f, 1.0f);
    float _415 = asfloat(2129764351u - asuint(_409));
    float _418 = _415 * mad(-_409, _415, 2.0f);
    float _422 = clamp((clamp(mad(_322, -0.5f, mad(_321, 0.5f, _319)), 0.0f, 1.0f) + mad(clamp(mad(_367, -0.5f, mad(_366, 0.5f, _364)), 0.0f, 1.0f), _393, mad(clamp(mad(_308, -0.5f, mad(_307, 0.5f, _305)), 0.0f, 1.0f), _393, (clamp(mad(_338, -0.5f, mad(_337, 0.5f, _335)), 0.0f, 1.0f) * _393) + (clamp(mad(_353, -0.5f, mad(_352, 0.5f, _350)), 0.0f, 1.0f) * _393)))) * _418, 0.0f, 1.0f);
    float _423 = clamp(_418 * (mad(_393, _374, mad(_393, _315, (_393 * _360) + (_393 * _345))) + _329), 0.0f, 1.0f);
    float _424 = clamp(_418 * (mad(_393, clamp(mad(_367, -0.5f, mad(_366, -0.5f, _364)), 0.0f, 1.0f), mad(_393, clamp(mad(_308, -0.5f, mad(_307, -0.5f, _305)), 0.0f, 1.0f), (_393 * clamp(mad(_353, -0.5f, mad(_352, -0.5f, _350)), 0.0f, 1.0f)) + (_393 * clamp(mad(_338, -0.5f, mad(_337, -0.5f, _335)), 0.0f, 1.0f)))) + clamp(mad(_322, -0.5f, mad(_321, -0.5f, _319)), 0.0f, 1.0f)), 0.0f, 1.0f);
    float _431 = exp2(log2(_422) * 0.4166666567325592041015625f);
    float _432 = exp2(log2(_423) * 0.4166666567325592041015625f);
    float _433 = exp2(log2(_424) * 0.4166666567325592041015625f);
    uint _457 = _300 + cb0_m3.x;
    uint _458 = (_300 + cb0_m2.x) & 63u;
    uint _459 = (_301 + cb0_m2.y) & 63u;
    float4 _461 = t3.Load(int3(uint2(_458, _241), 0u));
    float _465 = mad(_461.x, 2.0f, -1.0f);
    float _466 = mad(_461.y, 2.0f, -1.0f);
    float _467 = mad(_461.z, 2.0f, -1.0f);
    u0[uint2(_457, _296)] = float4(mad((1.0f - sqrt(1.0f - abs(_465))) * float(int(((_465 < 0.0f) ? 4294967295u : 0u) + uint(_465 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_422, 12.9200000762939453125f, mad(-_431, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_422 <= 0.003130800090730190277099609375f), mad(_431, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_466 > 0.0f) + ((_466 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_466))), 0.0078740157186985015869140625f, mad(float(_423 <= 0.003130800090730190277099609375f), mad(_423, 12.9200000762939453125f, mad(-_432, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_432, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_467 > 0.0f) + ((_467 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_467))), 0.0078740157186985015869140625f, mad(float(_424 <= 0.003130800090730190277099609375f), mad(_424, 12.9200000762939453125f, mad(-_433, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_433, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
    uint2 _509 = uint2(_300, _301);
    float4 _510 = t2.Load(int3(_509, 0u));
    float _511 = _510.x;
    float4 _512 = t1.Load(int3(_509, 0u));
    float _513 = _512.x;
    float _514 = _512.y;
    float _521 = clamp(mad(_514, 0.5f, _511), 0.0f, 1.0f);
    uint _523 = _301 + 1u;
    uint2 _524 = uint2(_302, _301);
    float4 _525 = t2.Load(int3(_524, 0u));
    float _526 = _525.x;
    float4 _527 = t1.Load(int3(_524, 0u));
    float _528 = _527.x;
    float _529 = _527.y;
    float _536 = clamp(mad(_529, 0.5f, _526), 0.0f, 1.0f);
    uint _539 = _301 - 1u;
    uint2 _540 = uint2(_332, _301);
    float4 _541 = t2.Load(int3(_540, 0u));
    float _542 = _541.x;
    float4 _543 = t1.Load(int3(_540, 0u));
    float _544 = _543.x;
    float _545 = _543.y;
    float _552 = clamp(mad(_545, 0.5f, _542), 0.0f, 1.0f);
    uint2 _555 = uint2(_300, _539);
    float4 _556 = t2.Load(int3(_555, 0u));
    float _557 = _556.x;
    float4 _558 = t1.Load(int3(_555, 0u));
    float _559 = _558.x;
    float _560 = _558.y;
    float _567 = clamp(mad(_560, 0.5f, _557), 0.0f, 1.0f);
    uint2 _569 = uint2(_300, _523);
    float4 _570 = t2.Load(int3(_569, 0u));
    float _571 = _570.x;
    float4 _572 = t1.Load(int3(_569, 0u));
    float _573 = _572.x;
    float _574 = _572.y;
    float _581 = clamp(mad(_574, 0.5f, _571), 0.0f, 1.0f);
    float _588 = max(max(max(_536, _521), _552), max(_581, _567));
    float _600 = asfloat((asuint(clamp(min(min(min(min(_536, _521), _552), min(_581, _567)), 1.0f - _588) * asfloat(2129690299u - asuint(_588)), 0.0f, 1.0f)) >> 1u) + 532432441u) * cb0_m6.x;
    float _616 = mad(_600, 4.0f, 1.0f);
    float _622 = asfloat(2129764351u - asuint(_616));
    float _625 = _622 * mad(-_616, _622, 2.0f);
    float _629 = clamp((clamp(mad(_514, -0.5f, mad(_513, 0.5f, _511)), 0.0f, 1.0f) + mad(clamp(mad(_574, -0.5f, mad(_573, 0.5f, _571)), 0.0f, 1.0f), _600, mad(clamp(mad(_529, -0.5f, mad(_528, 0.5f, _526)), 0.0f, 1.0f), _600, (clamp(mad(_545, -0.5f, mad(_544, 0.5f, _542)), 0.0f, 1.0f) * _600) + (clamp(mad(_560, -0.5f, mad(_559, 0.5f, _557)), 0.0f, 1.0f) * _600)))) * _625, 0.0f, 1.0f);
    float _630 = clamp(_625 * (mad(_600, _581, mad(_600, _536, (_600 * _567) + (_600 * _552))) + _521), 0.0f, 1.0f);
    float _631 = clamp(_625 * (mad(_600, clamp(mad(_574, -0.5f, mad(_573, -0.5f, _571)), 0.0f, 1.0f), mad(_600, clamp(mad(_529, -0.5f, mad(_528, -0.5f, _526)), 0.0f, 1.0f), (_600 * clamp(mad(_560, -0.5f, mad(_559, -0.5f, _557)), 0.0f, 1.0f)) + (_600 * clamp(mad(_545, -0.5f, mad(_544, -0.5f, _542)), 0.0f, 1.0f)))) + clamp(mad(_514, -0.5f, mad(_513, -0.5f, _511)), 0.0f, 1.0f)), 0.0f, 1.0f);
    float _638 = exp2(log2(_629) * 0.4166666567325592041015625f);
    float _639 = exp2(log2(_630) * 0.4166666567325592041015625f);
    float _640 = exp2(log2(_631) * 0.4166666567325592041015625f);
    float4 _663 = t3.Load(int3(uint2(_458, _459), 0u));
    float _667 = mad(_663.x, 2.0f, -1.0f);
    float _668 = mad(_663.y, 2.0f, -1.0f);
    float _669 = mad(_663.z, 2.0f, -1.0f);
    uint _709 = _301 + cb0_m3.y;
    u0[uint2(_457, _709)] = float4(mad((1.0f - sqrt(1.0f - abs(_667))) * float(int(((_667 < 0.0f) ? 4294967295u : 0u) + uint(_667 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_629, 12.9200000762939453125f, mad(-_638, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_629 <= 0.003130800090730190277099609375f), mad(_638, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_668 > 0.0f) + ((_668 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_668))), 0.0078740157186985015869140625f, mad(float(_630 <= 0.003130800090730190277099609375f), mad(_630, 12.9200000762939453125f, mad(-_639, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_639, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_669 > 0.0f) + ((_669 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_669))), 0.0078740157186985015869140625f, mad(float(_631 <= 0.003130800090730190277099609375f), mad(_631, 12.9200000762939453125f, mad(-_640, 1.05499994754791259765625f, 0.054999999701976776123046875f)), mad(_640, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
    uint _712 = _300 - 8u;
    uint2 _713 = uint2(_712, _523);
    float4 _714 = t2.Load(int3(_713, 0u));
    float _715 = _714.x;
    float4 _716 = t1.Load(int3(_713, 0u));
    float _717 = _716.x;
    float _718 = _716.y;
    float _725 = clamp(mad(_718, 0.5f, _715), 0.0f, 1.0f);
    uint2 _727 = uint2(_712, _539);
    float4 _728 = t2.Load(int3(_727, 0u));
    float _729 = _728.x;
    float4 _730 = t1.Load(int3(_727, 0u));
    float _731 = _730.x;
    float _732 = _730.y;
    float _739 = clamp(mad(_732, 0.5f, _729), 0.0f, 1.0f);
    uint2 _744 = uint2(_300 - 7u, _301);
    float4 _745 = t2.Load(int3(_744, 0u));
    float _746 = _745.x;
    float4 _747 = t1.Load(int3(_744, 0u));
    float _748 = _747.x;
    float _749 = _747.y;
    float _756 = clamp(mad(_749, 0.5f, _746), 0.0f, 1.0f);
    uint2 _758 = uint2(_712, _301);
    float4 _759 = t2.Load(int3(_758, 0u));
    float _760 = _759.x;
    float4 _761 = t1.Load(int3(_758, 0u));
    float _762 = _761.x;
    float _763 = _761.y;
    float _770 = clamp(mad(_763, 0.5f, _760), 0.0f, 1.0f);
    uint2 _773 = uint2(_300 - 9u, _301);
    float4 _774 = t2.Load(int3(_773, 0u));
    float _775 = _774.x;
    float4 _776 = t1.Load(int3(_773, 0u));
    float _777 = _776.x;
    float _778 = _776.y;
    float _785 = clamp(mad(_778, 0.5f, _775), 0.0f, 1.0f);
    float _792 = max(max(_739, _725), max(_785, max(_770, _756)));
    float _804 = asfloat((asuint(clamp(min(min(min(_739, _725), min(_785, min(_770, _756))), 1.0f - _792) * asfloat(2129690299u - asuint(_792)), 0.0f, 1.0f)) >> 1u) + 532432441u) * cb0_m6.x;
    float _820 = mad(_804, 4.0f, 1.0f);
    float _826 = asfloat(2129764351u - asuint(_820));
    float _829 = _826 * mad(-_820, _826, 2.0f);
    float _833 = clamp((clamp(mad(_763, -0.5f, mad(_762, 0.5f, _760)), 0.0f, 1.0f) + mad(clamp(mad(_718, -0.5f, mad(_717, 0.5f, _715)), 0.0f, 1.0f), _804, mad(clamp(mad(_749, -0.5f, mad(_748, 0.5f, _746)), 0.0f, 1.0f), _804, (clamp(mad(_778, -0.5f, mad(_777, 0.5f, _775)), 0.0f, 1.0f) * _804) + (clamp(mad(_732, -0.5f, mad(_731, 0.5f, _729)), 0.0f, 1.0f) * _804)))) * _829, 0.0f, 1.0f);
    float _834 = clamp((mad(_725, _804, mad(_756, _804, (_739 * _804) + (_785 * _804))) + _770) * _829, 0.0f, 1.0f);
    float _835 = clamp((mad(clamp(mad(_718, -0.5f, mad(_717, -0.5f, _715)), 0.0f, 1.0f), _804, mad(clamp(mad(_749, -0.5f, mad(_748, -0.5f, _746)), 0.0f, 1.0f), _804, (clamp(mad(_732, -0.5f, mad(_731, -0.5f, _729)), 0.0f, 1.0f) * _804) + (clamp(mad(_778, -0.5f, mad(_777, -0.5f, _775)), 0.0f, 1.0f) * _804))) + clamp(mad(_763, -0.5f, mad(_762, -0.5f, _760)), 0.0f, 1.0f)) * _829, 0.0f, 1.0f);
    float _842 = exp2(log2(_833) * 0.4166666567325592041015625f);
    float _843 = exp2(log2(_834) * 0.4166666567325592041015625f);
    float _844 = exp2(log2(_835) * 0.4166666567325592041015625f);
    float4 _870 = t3.Load(int3(uint2((_712 + cb0_m2.x) & 63u, _459), 0u));
    float _874 = mad(_870.x, 2.0f, -1.0f);
    float _875 = mad(_870.y, 2.0f, -1.0f);
    float _876 = mad(_870.z, 2.0f, -1.0f);
    u0[uint2(_712 + cb0_m3.x, _709)] = float4(mad((1.0f - sqrt(1.0f - abs(_874))) * float(int(((_874 < 0.0f) ? 4294967295u : 0u) + uint(_874 > 0.0f))), 0.0078740157186985015869140625f, mad(mad(_833, 12.9200000762939453125f, mad(-_842, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_833 <= 0.003130800090730190277099609375f), mad(_842, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_875 > 0.0f) + ((_875 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_875))), 0.0078740157186985015869140625f, mad(mad(_834, 12.9200000762939453125f, mad(-_843, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_834 <= 0.003130800090730190277099609375f), mad(_843, 1.05499994754791259765625f, -0.054999999701976776123046875f))), mad(float(int(uint(_876 > 0.0f) + ((_876 < 0.0f) ? 4294967295u : 0u))) * (1.0f - sqrt(1.0f - abs(_876))), 0.0078740157186985015869140625f, mad(mad(_835, 12.9200000762939453125f, mad(-_844, 1.05499994754791259765625f, 0.054999999701976776123046875f)), float(_835 <= 0.003130800090730190277099609375f), mad(_844, 1.05499994754791259765625f, -0.054999999701976776123046875f))), 1.0f);
}