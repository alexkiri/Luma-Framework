cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m0 : packoffset(c0);
    uint4 cb0_m1 : packoffset(c1);
    uint4 cb0_m2 : packoffset(c2);
    uint4 cb0_m3 : packoffset(c3);
    uint4 cb0_m4 : packoffset(c4);
    uint4 cb0_m5 : packoffset(c5);
    uint4 cb0_m6 : packoffset(c6);
    uint4 cb0_m7 : packoffset(c7);
    uint4 cb0_m8 : packoffset(c8);
    uint4 cb0_m9 : packoffset(c9);
    uint4 cb0_m10 : packoffset(c10);
    uint4 cb0_m11 : packoffset(c11);
    uint4 cb0_m12 : packoffset(c12);
    uint4 cb0_m13 : packoffset(c13);
    uint4 cb0_m14 : packoffset(c14);
    uint2 cb0_m15 : packoffset(c15);
    int2 cb0_m16 : packoffset(c15.z);
    uint4 cb0_m17 : packoffset(c16);
    uint4 cb0_m18 : packoffset(c17);
    float4 cb0_m19 : packoffset(c18);
};

Texture2D<float4> t0 : register(t0);
RWTexture2D<float4> u0 : register(u0);

static uint3 gl_GlobalInvocationID;
struct SPIRV_Cross_Input
{
    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;
};

float dp2_f32(float2 a, float2 b)
{
    precise float _46 = a.x * b.x;
    return mad(a.y, b.y, _46);
}

void comp_main()
{
    uint2 _60 = uint2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);
    float4 _61 = t0.Load(int3(_60, 0u));
    uint _71;
    uint _74;
    uint _76;
    uint _78;
    _71 = asuint(_61.w);
    _74 = asuint(_61.z);
    _76 = asuint(_61.y);
    _78 = asuint(_61.x);
    uint _81;
    uint _72;
    uint _75;
    uint _77;
    uint _79;
    uint _80 = 4294967292u;
    for (;;)
    {
        int _84 = int(_80);
        if (_84 > 4)
        {
            break;
        }
        bool _89 = _80 == 0u;
        _72 = _71;
        _75 = _74;
        _77 = _76;
        _79 = _78;
        uint _91;
        uint _93;
        uint _94;
        uint _95;
        uint _200;
        int _96 = -4;
        for (;;)
        {
            if (_96 > 4)
            {
                break;
            }
            if (_89 && (uint(_96) == 0u))
            {
                _200 = 1u;
                _95 = _79;
                _94 = _77;
                _93 = _75;
                _91 = _72;
                int _97 = int(_200);
                _72 = _91;
                _75 = _93;
                _77 = _94;
                _79 = _95;
                _96 = _97;
                continue;
            }
            else
            {
            }
            uint _109 = gl_GlobalInvocationID.x + _80;
            int _111 = int(gl_GlobalInvocationID.y) + _96;
            int _113 = int(_109);
            if (!(((_111 < cb0_m16.y) && (_111 >= 0)) && ((_113 < cb0_m16.x) && (_113 >= 0))))
            {
                _200 = uint(_96 + 1);
                _95 = _79;
                _94 = _77;
                _93 = _75;
                _91 = _72;
                int _97 = int(_200);
                _72 = _91;
                _75 = _93;
                _77 = _94;
                _79 = _95;
                _96 = _97;
                continue;
            }
            float4 _133 = t0.Load(int3(uint2(_109, uint(_111)), 0u));
            float _134 = _133.x;
            float _136 = _133.z;
            float _137 = _133.w;
            float _145 = _136 * cb0_m19.z;
            float _146 = _137 * cb0_m19.z;
            float2 _147 = float2(_145, _146);
            float _148 = dp2_f32(_147, _147);
            float _153 = asfloat(1597463007 - (asint(_148 + 9.9999999392252902907785028219223e-09f) >> int(1u)));
            float _155 = _145 * _153;
            float _156 = _153 * _146;
            float _159 = abs(_156) + abs(_155);
            float2 _166 = float2(float(_84), float(_96));
            bool _175 = (abs(dp2_f32(float2(-_156, _155), _166)) < mad(_159, 0.9900000095367431640625f, 0.0f)) && (((_159 * 0.9900000095367431640625f) + (_148 * _153)) > abs(dp2_f32(float2(_155, _156), _166)));
            float2 _178 = float2(asfloat(_79), asfloat(_77));
            float2 _180 = float2(_134, _133.y);
            float2 _186 = float2(asfloat(_75), asfloat(_72));
            float2 _188 = float2(_136, _137);
            bool _192 = (!(dp2_f32(_178, _178) < dp2_f32(_180, _180))) && _175;
            bool _195 = (!(dp2_f32(_186, _186) > dp2_f32(_188, _188))) && _175;
            _200 = uint(_96 + 1);
            _95 = _192 ? asuint(_134) : _79;
            _94 = _192 ? asuint(_133.y) : _77;
            _93 = _195 ? asuint(_136) : _75;
            _91 = _195 ? asuint(_137) : _72;
            int _97 = int(_200);
            _72 = _91;
            _75 = _93;
            _77 = _94;
            _79 = _95;
            _96 = _97;
            continue;
        }
        _81 = _80 + 1u;
        _71 = _72;
        _74 = _75;
        _76 = _77;
        _78 = _79;
        _80 = _81;
        continue;
    }
    if ((gl_GlobalInvocationID.x < uint(cb0_m16.x)) && (gl_GlobalInvocationID.y < uint(cb0_m16.y)))
    {
        u0[_60] = float4(asfloat(_78), asfloat(_76), asfloat(_74), asfloat(_71));
    }
}

[numthreads(16, 16, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;
    comp_main();
}
