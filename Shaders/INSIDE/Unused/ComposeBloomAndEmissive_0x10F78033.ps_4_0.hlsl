#include "../Includes/Common.hlsl"
#include "../Includes/Reinhard.hlsl"

static const float3 _72[10] = { float3(-1.0f, 1.0f, 0.0625f), float3(0.0f, 1.0f, 0.125f), float3(1.0f, 1.0f, 0.0625f), float3(-1.0f, 0.0f, 0.125f), float3(0.0f, 0.0f, 0.25f), float3(1.0f, 0.0f, 0.125f), float3(-1.0f, -1.0f, 0.0625f), float3(0.0f, -1.0f, 0.125f), float3(1.0f, -1.0f, 0.0625f), 0.0f.xxx };

cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m0 : packoffset(c0);
    uint4 cb0_m1 : packoffset(c1);
    uint4 cb0_m2 : packoffset(c2);
    float3 cb0_m3 : packoffset(c3);
    float cb0_m4 : packoffset(c3.w);
    uint4 cb0_m5 : packoffset(c4);
    uint4 cb0_m6 : packoffset(c5);
    float2 cb0_m7 : packoffset(c6);
    uint2 cb0_m8 : packoffset(c6.z);
    float4 cb0_m9 : packoffset(c7);
    float4 cb0_m10 : packoffset(c8);
};

cbuffer cb1_buf : register(b1)
{
    uint4 cb1_m0 : packoffset(c0);
    float4 cb1_m1 : packoffset(c1);
};

SamplerState s0 : register(s0);
SamplerState s1 : register(s1);
SamplerState s2 : register(s2);
Texture2D<float4> t0 : register(t0); // Bloom
Texture2D<float4> t1 : register(t1); // Emissive Raw
Texture2D<float4> t2 : register(t2); // Emissive Bloomed

float dp2_f32(precise float2 a, precise float2 b)
{
    precise float _86 = a.x * b.x;
    return mad(a.y, b.y, _86);
}

float4 main(float4 v0 : SV_POSITION0, float2 v1 : TEXCOORD0) : SV_Target0
{
    precise float2 _101 = float2(v1.x, v1.y);
    precise float4 _104 = t0.Sample(s2, _101);
    precise float _105 = _104.x;
    precise float _106 = _104.y;
    precise float _107 = _104.z;
    precise float _108 = _105 * _105;
    precise float _109 = _106 * _106;
    precise float _110 = _107 * _107;
    precise float4 _114 = t1.Sample(s0, _101);
    //_114.rgb = Reinhard::ReinhardRange(_114.rgb, 0.5, -1.0, 0.5); // Moved to happen before bloom generation, for Vanilla consistenty
    precise float _115 = _114.x;
    precise float _116 = _114.y;
    precise float _117 = _114.z;
    precise float _118 = _115 - 1.0f;
    precise float _119 = _116 - 1.0f;
    precise float _120 = _117 - 1.0f;
    precise float _130 = _115 * asfloat(2129859010u - asuint(_118));
    precise float _131 = _116 * asfloat(2129859010u - asuint(_119));
    precise float _132 = _117 * asfloat(2129859010u - asuint(_120));
    precise float _137 = cb0_m9.y * _108;
    precise float _138 = cb0_m9.y * _109;
    precise float _139 = cb0_m9.y * _110;
    float _141;
    float _144;
    float _146;
    _141 = _139;
    _144 = _138;
    _146 = _137;
    precise float _142;
    precise float _145;
    precise float _147;
    uint _149;
    uint _148 = 0u;
    for (;;)
    {
        if (int(_148) >= 9)
        {
            break;
        }
        uint _162 = min(_148, 9u);
        precise float _172 = cb0_m7.x * _72[_162].x;
        precise float _173 = _72[_162].y * cb0_m7.y;
        precise float _174 = v1.x + _172;
        precise float _175 = v1.y + _173;
        precise float4 _180 = t2.Sample(s1, float2(_174, _175));
        //_180.rgb = Reinhard::ReinhardRange(_180.rgb, 0.5, -1.0, 0.5);
        precise float _181 = _180.x;
        precise float _182 = _180.y;
        precise float _183 = _180.z;
        precise float _184 = _181 - 1.0f;
        precise float _185 = _182 - 1.0f;
        precise float _186 = _183 - 1.0f;
        precise float _196 = _181 * asfloat(2129859010u - asuint(_184));
        precise float _197 = _182 * asfloat(2129859010u - asuint(_185));
        precise float _198 = _183 * asfloat(2129859010u - asuint(_186));
        precise float _202 = _196 * _72[_162].z;
        precise float _203 = _197 * _72[_162].z;
        precise float _204 = _198 * _72[_162].z;
        _147 = _146 - _202;
        _145 = _144 - _203;
        _142 = _141 - _204;
        _149 = _148 + 1u;
        _141 = _142;
        _144 = _145;
        _146 = _147;
        _148 = _149;
        continue;
    }
    precise float _207 = _130 * cb0_m9.z;
    precise float _208 = cb0_m9.z * _131;
    precise float _209 = cb0_m9.z * _132;
    precise float _210 = _146 - _207;
    precise float _211 = _144 - _208;
    precise float _212 = _141 - _209;
    precise float _213 = clamp(_210, 0.0f, 1.0f);
    precise float _214 = clamp(_211, 0.0f, 1.0f);
    precise float _215 = clamp(_212, 0.0f, 1.0f);
    precise float _222 = cb0_m3.x * _213;
    precise float _223 = cb0_m3.y * _214;
    precise float _224 = cb0_m3.z * _215;
    precise float _225 = _222 + _223;
    precise float _226 = _222 + _224;
    precise float _229 = cb0_m3.z * _215;
    precise float _230 = _225 + _229;
    precise float _231 = _226 * _223;
    precise float _238 = _230 + dp2_f32(cb0_m4.xx, sqrt(_231).xx);
    precise float _239 = _213 - _238;
    precise float _240 = _214 - _238;
    precise float _241 = _215 - _238;
    precise float _244 = _239 * cb0_m10.y;
    precise float _245 = cb0_m10.y * _240;
    precise float _246 = cb0_m10.y * _241;
    precise float _247 = _238 + _244;
    precise float _248 = _238 + _245;
    precise float _249 = _238 + _246;
    precise float _250 = _247 * 0.5f;
    precise float _251 = _248 * 0.5f;
    precise float _252 = _249 * 0.5f;
    precise float _262 = asfloat(1597463174 - (asint(_247) >> int(1u)));
    precise float _263 = asfloat(1597463174 - (asint(_248) >> int(1u)));
    precise float _264 = asfloat(1597463174 - (asint(_249) >> int(1u)));
    precise float _265 = _262 * _262;
    precise float _266 = _263 * _263;
    precise float _267 = _264 * _264;
    precise float _268 = _265 * _250;
    precise float _269 = _266 * _251;
    precise float _270 = _267 * _252;
    precise float _271 = 1.5f - _268;
    precise float _272 = 1.5f - _269;
    precise float _273 = 1.5f - _270;
    precise float _274 = _262 * _271;
    precise float _275 = _263 * _272;
    precise float _276 = _264 * _273;
    precise float _280 = v1.x + cb1_m1.x;
    precise float _281 = v1.y + cb1_m1.x;
    precise float _282 = _280 + 0.957400023937225341796875f;
    precise float _283 = _281 + 0.957400023937225341796875f;
    precise float _284 = _282 * 5.398700237274169921875f;
    precise float _285 = _283 * 5.442100048065185546875f;
    precise float _286 = frac(_284);
    precise float _287 = frac(_285);
    precise float _288 = _286 + 21.5351009368896484375f;
    precise float _289 = _287 + 14.3136997222900390625f;
    float _292 = dp2_f32(float2(_287, _286), float2(_288, _289));
    precise float _293 = _286 + _292;
    precise float _294 = _287 + _292;
    precise float _295 = _294 * _293;
    precise float _296 = _295 * 95.43070220947265625f;
    precise float _297 = _295 * 97.5901031494140625f;
    precise float _298 = _295 * 93.8368988037109375f;
    precise float _302 = _295 * 75.0490875244140625f;
    precise float _303 = _295 * 75.04956817626953125f;
    precise float _304 = _295 * 75.0496063232421875f;
    precise float _308 = frac(_296) + frac(_302);
    precise float _309 = frac(_303) + frac(_297);
    precise float _310 = frac(_304) + frac(_298);
    precise float _311 = _308 - 0.5f;
    precise float _312 = _309 - 0.5f;
    precise float _313 = _310 - 0.5f;
    precise float _314 = _311 * 0.5f;
    precise float _315 = _312 * 0.5f;
    precise float _316 = _313 * 0.5f;
    precise float _317 = _314 - 0.25f;
    precise float _318 = _315 - 0.25f;
    precise float _319 = _316 - 0.25f;
    precise float _322 = cb0_m10.z * _317;
    precise float _323 = _318 * cb0_m10.z;
    precise float _324 = _319 * cb0_m10.z;
    precise float _325 = _247 * _274;
    precise float _326 = _275 * _248;
    precise float _327 = _276 * _249;
    precise float _328 = _322 + _325;
    precise float _329 = _326 + _323;
    precise float _330 = _327 + _324;
    float4 SV_Target;
    SV_Target.x = _328;
    SV_Target.y = _329;
    SV_Target.z = _330;
    SV_Target.w = 1.0f;
    return SV_Target;
}