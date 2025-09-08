#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"

cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m[17] : packoffset(c0);
};

Texture2D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);

SamplerState s0 : register(s0);
SamplerState s1 : register(s1);

// This is the last shader, it applies a CRT color filter
void main(
  float4 v0 : SV_POSITION0,
  float2 TEXCOORD : TEXCOORD0,
  float2 TEXCOORD1 : TEXCOORD1,
  out float4 SV_Target : SV_Target0)
{
#if 0 // Old decompile, just won't work, I haven't figure out why, but the code is nicer.

  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9;
  r0.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  bool enabled = cb0[16].w == 0.0;
  // Chromatic aberration (4 times)
  if (enabled) {
    r1.xyzw = t1.Sample(s1_s, w1.xy).xyzw;
  } else {
    r2.x = cb0[16].w * -cb0[4].x;
    r2.yw = float2(0,0);
    r2.xy = w1.xy + r2.xy;
    r3.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r4.xyzw = t1.Sample(s1_s, w1.xy).xyzw;
    r2.z = cb0[16].w * cb0[4].x;
    r2.xy = w1.xy + r2.zw;
    r1.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r1.x = r3.x;
    r1.y = r4.y;
    r1.w = 1; // Weird that this is only done on the first sample
  }
  r2.xy = cb0[4].ww * cb0[4].yx;
  r2.z = 0;
  r2.xw = w1.xy + r2.zx;
  if (enabled) {
    r3.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
  } else {
    r4.x = cb0[16].w * -cb0[4].x;
    r4.yw = float2(0,0);
    r4.xy = r4.xy + r2.xw;
    r5.xyzw = t1.Sample(s1_s, r4.xy).xyzw;
    r6.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r4.z = cb0[16].w * cb0[4].x;
    r2.xw = r4.zw + r2.xw;
    r3.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r3.x = r5.x;
    r3.y = r6.y;
  }
  r4.xy = -cb0[4].ww * cb0[4].yx;
  r4.z = 0;
  r2.xw = w1.xy + r4.zx;
  if (enabled) {
    r5.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
  } else {
    r6.x = cb0[16].w * -cb0[4].x;
    r6.yw = float2(0,0);
    r4.xw = r6.xy + r2.xw;
    r7.xyzw = t1.Sample(s1_s, r4.xw).xyzw;
    r8.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r6.z = cb0[16].w * cb0[4].x;
    r2.xw = r6.zw + r2.xw;
    r5.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r5.x = r7.x;
    r5.y = r8.y;
  }
  r2.xy = w1.xy + r2.yz;
  if (enabled) {
    r6.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
  } else {
    r7.x = cb0[16].w * -cb0[4].x;
    r2.z = w1.y;
    r7.yw = float2(0,0);
    r4.xw = r7.xy + r2.xz;
    r8.xyzw = t1.Sample(s1_s, r4.xw).xyzw;
    r9.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r7.z = cb0[16].w * cb0[4].x;
    r2.xy = r7.zw + r2.xz;
    r6.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r6.x = r8.x;
    r6.y = r9.y;
  }
  r2.xy = w1.xy + r4.yz;
  if (enabled) {
    r4.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
  } else {
    r7.x = cb0[16].w * -cb0[4].x;
    r2.z = w1.y;
    r7.yw = float2(0,0);
    r7.xy = r7.xy + r2.xz;
    r8.xyzw = t1.Sample(s1_s, r7.xy).xyzw;
    r9.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r7.z = cb0[16].w * cb0[4].x;
    r2.xy = r7.zw + r2.xz;
    r4.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r4.x = r8.x;
    r4.y = r9.y;
  }
  r2.xyz = max(r5.xyz, r3.xyz);
  r3.xyz = max(r6.xyz, r4.xyz);
  r2.xyz = max(r3.xyz, r2.xyz);
  r0.w = r0.y + r0.z;
  r0.w = -0.1 + r0.w;
  r0.w = cmp(r0.w >= r0.x);
  r2.w = max(r1.x, r0.x);
  r0.xyz = r0.www ? r2.www : r0.xyz;
  r3.xy = float2(1,1) + -cb0[5].yx;
  r0.w = r1.w * r3.x + cb0[5].y;
  r1.xyz = r1.xyz * r1.www;
  r1.xyz = r1.xyz * r3.xxx;
  r0.xyz = r0.xyz * cb0[5].yyy + r1.xyz;
  r0.xyz = r0.xyz / r0.www;
  r1.xyz = max(r2.xyz, r0.xyz);
  r0.xyz = r0.xyz * r3.yyy;
  r0.xyz = r1.xyz * cb0[5].xxx + r0.xyz;
  r0.w = 0.0166666675 * cb0[4].z;
  r1.w = cmp(r0.w >= -r0.w);
  r0.w = frac(abs(r0.w));
  r0.w = r1.w ? r0.w : -r0.w;
  r1.w = 60 * r0.w;
  r2.xy = v1.xy / cb0[4].xy;
  r2.yz = sin(r2.xy);
  r3.xy = v1.yx * r2.yz;
  r3.xy = r3.xy / cb0[4].yx;
  r3.xy = r0.ww * float2(60,60) + r3.xy;
  r3.xy = float2(89.4199982,89.4199982) * r3.xy;
  r3.xy = cos(r3.xy);
  r3.xy = float2(343.420013,343.420013) * r3.xy;
  r3.xy = frac(r3.xy);
  r0.w = r2.y * r2.z + r1.w;
  r0.w = 89.4199982 * r0.w;
  r0.w = cos(r0.w);
  r0.w = 343.420013 * r0.w;
  r3.z = frac(r0.w);
  r2.yzw = r3.xyz + r0.xyz;
  r4.xyz = -r3.xyz + r0.xyz;
  r5.xyz = r3.xyz * r0.xyz;
  r6.xyz = r0.xyz / r3.xyz;
  r7.xyzw = (asint(cb0[6].yyyy) == int4(1,2,3,4));
  r8.xyz = max(r3.xyz, r0.xyz);
  r9.xyzw = (asint(cb0[6].ywww) == int4(5,1,2,3));
  r3.yzw = min(r3.xyz, r0.xyz);
  r1.xyz = r9.xxx ? r3.yzw : r1.xyz;
  r1.xyz = r7.www ? r8.xyz : r1.xyz;
  r1.xyz = r7.zzz ? r6.xyz : r1.xyz;
  r1.xyz = r7.yyy ? r5.xyz : r1.xyz;
  r1.xyz = r7.xxx ? r4.xyz : r1.xyz;
  r1.xyz = (cb0[6].yyy ? r1.xyz : r2.yzw); // Luma: removed saturate (it doesn't seem to make a difference)
  r2.yz = float2(1,1) + -cb0[6].zx;
  r0.xyz = r2.yyy * r0.xyz;
  r0.xyz = r1.xyz * cb0[6].zzz + r0.xyz;
  r3.yzw = r0.xyz + r3.xxx;
  r4.xyz = r0.xyz + -r3.xxx;
  r5.xyz = r0.xyz * r3.xxx;
  r6.xyz = r0.xyz / r3.xxx;
  r7.xyz = max(r3.xxx, r0.xyz);
  r2.yw = (asint(cb0[6].ww) == int2(4,5));
  r8.xyz = min(r3.xxx, r0.xyz);
  r1.xyz = r2.www ? r8.xyz : r1.xyz;
  r1.xyz = r2.yyy ? r7.xyz : r1.xyz;
  r1.xyz = r9.www ? r6.xyz : r1.xyz;
  r1.xyz = r9.zzz ? r5.xyz : r1.xyz;
  r1.xyz = r9.yyy ? r4.xyz : r1.xyz;
  r1.xyz = (cb0[6].www ? r1.xyz : r3.yzw); // Luma: removed saturate (it doesn't seem to make a difference)
  r0.w = 1 + -cb0[7].y;
  r0.xyz = r0.xyz * r0.www;
  r0.xyz = r1.xyz * cb0[7].yyy + r0.xyz;
  r0.w = 0.333333343 * r2.x;
  r1.x = cmp(r0.w >= -r0.w);
  r0.w = frac(abs(r0.w));
  r0.w = r1.x ? r0.w : -r0.w;
  r0.w = 3.0 * r0.w;
  r0.w = floor(r0.w);
  r1.xy = cmp(r0.ww == float2(0,1));
  r0.w = cb0[5].z * cb0[5].w;
  r1.z = -cb0[5].z * cb0[5].w + r0.x;
  r0.w = -r0.w * 2 + r0.x;
  r0.w = r1.y ? r1.z : r0.w;
  r0.w = r1.x ? r0.x : r0.w;
  r0.xyz = r0.xyz * r2.zzz;
  r0.xyz = r0.www * cb0[6].xxx + r0.xyz;
  r0.w = cb0[15].w * cb0[4].y;
  r0.w = v1.y / r0.w;
  r1.xy = cb0[16].zx * cb0[4].yz + r0.ww;
  r1.x = cb0[16].x * cb0[4].z + r1.x;
  r1.x = sin(r1.x);
  r0.x = (r1.x * cb0[16].y + r0.x); // Luma: removed saturate
  r1.x = sin(r1.y);
  r0.y = (r1.x * cb0[16].y + r0.y); // Luma: removed saturate
  r0.w = -cb0[16].z + r0.w;
  r0.w = cb0[16].x * cb0[4].z + r0.w;
  r0.w = sin(r0.w);
  r0.z = (r0.w * cb0[16].y + r0.z); // Luma: removed saturate
  r1.xyzw = cb0[9].xyzw * r0.yyyy;
  r1.xyzw = cb0[8].xyzw * r0.xxxx + r1.xyzw;
  r0.xyzw = cb0[10].xyzw * r0.zzzz + r1.xyzw;
  r0.xyzw = cb0[11].xyzw + r0.xyzw;
  r1.xyz = cb0[13].xyz + -cb0[12].xyz;
  r0.xyz = r0.xyz / r1.xyz;
  r0.xyz = cb0[12].xyz + r0.xyz;
  float _675 = r0.x;
  float _676 = r0.y;
  float _677 = r0.z;

#else

    precise float4 _85 = t0.Sample(s0, float2(TEXCOORD.x, TEXCOORD.y));
    precise float _86 = _85.x;
    precise float _87 = _85.y;
    precise float _88 = _85.z;
    precise float _93 = asfloat(cb0_m[16u].w);
    bool _94 = _93 == 0.0f;
    float _137;
    float _138;
    float _139;
    float _140;
    // Chromatic aberration (4 times)
    if (_94)
    {
        precise float4 _107 = t1.Sample(s1, float2(TEXCOORD1.x, TEXCOORD1.y));
        _137 = _107.z;
        _138 = _107.y;
        _139 = _107.w;
        _140 = _107.x;
    }
    else
    {
        precise float _115 = _93 * asfloat(cb0_m[4u].x);
        precise float _120 = TEXCOORD1.x - _115;
        precise float _121 = TEXCOORD1.y + 0.0f;
        precise float _132 = _115 + TEXCOORD1.x;
        _137 = t1.Sample(s1, float2(_132, _121)).z;
        _138 = t1.Sample(s1, float2(TEXCOORD1.x, TEXCOORD1.y)).y;
        _139 = 1.0f; // Weird that this is only done on the first sample
        _140 = t1.Sample(s1, float2(_120, _121)).x;
    }
    precise float _146 = asfloat(cb0_m[4u].x);
    precise float _147 = asfloat(cb0_m[4u].y);
    precise float _150 = asfloat(cb0_m[4u].w);
    precise float _151 = _147 * _150;
    precise float _152 = _146 * _150;
    precise float _157 = TEXCOORD1.x + 0.0f;
    precise float _158 = _151 + TEXCOORD1.y;
    float _191;
    float _192;
    float _193;
    if (_94)
    {
        precise float4 _166 = t1.Sample(s1, float2(_157, _158));
        _191 = _166.z;
        _192 = _166.y;
        _193 = _166.x;
    }
    else
    {
        precise float _173 = _93 * asfloat(cb0_m[4u].x);
        precise float _174 = _157 - _173;
        precise float _175 = _158 + 0.0f;
        precise float _186 = _157 + _173;
        _191 = t1.Sample(s1, float2(_186, _175)).z;
        _192 = t1.Sample(s1, float2(_157, _158)).y;
        _193 = t1.Sample(s1, float2(_174, _175)).x;
    }
    precise float _194 = TEXCOORD1.y - _151;
    float _227;
    float _228;
    float _229;
    if (_94)
    {
        precise float4 _202 = t1.Sample(s1, float2(_157, _194));
        _227 = _202.z;
        _228 = _202.y;
        _229 = _202.x;
    }
    else
    {
        precise float _209 = _93 * asfloat(cb0_m[4u].x);
        precise float _210 = _157 - _209;
        precise float _211 = _194 + 0.0f;
        precise float _222 = _157 + _209;
        _227 = t1.Sample(s1, float2(_222, _211)).z;
        _228 = t1.Sample(s1, float2(_157, _194)).y;
        _229 = t1.Sample(s1, float2(_210, _211)).x;
    }
    precise float _230 = TEXCOORD1.x + _152;
    precise float _231 = TEXCOORD1.y + 0.0f;
    float _263;
    float _264;
    float _265;
    if (_94)
    {
        precise float4 _239 = t1.Sample(s1, float2(_230, _231));
        _263 = _239.z;
        _264 = _239.y;
        _265 = _239.x;
    }
    else
    {
        precise float _246 = _93 * asfloat(cb0_m[4u].x);
        precise float _247 = _230 - _246;
        precise float _258 = _230 + _246;
        _263 = t1.Sample(s1, float2(_258, _231)).z;
        _264 = t1.Sample(s1, float2(_230, _231)).y;
        _265 = t1.Sample(s1, float2(_247, _231)).x;
    }
    precise float _266 = TEXCOORD1.x - _152;
    float _298;
    float _299;
    float _300;
    if (_94)
    {
        precise float4 _274 = t1.Sample(s1, float2(_266, _231));
        _298 = _274.z;
        _299 = _274.y;
        _300 = _274.x;
    }
    else
    {
        precise float _281 = _93 * asfloat(cb0_m[4u].x);
        precise float _282 = _266 - _281;
        precise float _293 = _266 + _281;
        _298 = t1.Sample(s1, float2(_293, _231)).z;
        _299 = t1.Sample(s1, float2(_266, _231)).y;
        _300 = t1.Sample(s1, float2(_282, _231)).x;
    }
    precise float _311 = _87 + _88;
    precise float _312 = _311 - 0.100000001490116119384765625f;
    bool _313 = _86 <= _312;
    precise float _314 = max(_86, _140);
    precise float _324 = 1.0f - asfloat(cb0_m[5u].y);
    precise float _325 = 1.0f - asfloat(cb0_m[5u].x);
    precise float _328 = asfloat(cb0_m[5u].y);
    precise float _329 = _324 * _139;
    precise float _330 = _328 + _329;
    precise float _331 = _139 * _140;
    precise float _332 = _139 * _138;
    precise float _333 = _139 * _137;
    precise float _334 = _324 * _331;
    precise float _335 = _332 * _324;
    precise float _336 = _333 * _324;
    precise float _337 = _328 * (_313 ? _314 : _86);
    precise float _338 = _328 * (_313 ? _314 : _87);
    precise float _339 = _328 * (_313 ? _314 : _88);
    precise float _340 = _334 + _337;
    precise float _341 = _338 + _335;
    precise float _342 = _339 + _336;
    precise float _343 = _340 / _330;
    precise float _344 = _341 / _330;
    precise float _345 = _342 / _330;
    precise float _346 = max(max(max(_229, _193), max(_265, _300)), _343);
    precise float _347 = max(_344, max(max(_264, _299), max(_192, _228)));
    precise float _348 = max(_345, max(max(_227, _191), max(_263, _298)));
    precise float _349 = _325 * _343;
    precise float _350 = _344 * _325;
    precise float _351 = _345 * _325;
    precise float _354 = asfloat(cb0_m[5u].x);
    precise float _355 = _346 * _354;
    precise float _356 = _347 * _354;
    precise float _357 = _348 * _354;
    precise float _358 = _349 + _355;
    precise float _359 = _356 + _350;
    precise float _360 = _357 + _351;
    precise float _363 = asfloat(cb0_m[4u].z);
    precise float _364 = _363 * 0.01666666753590106964111328125f;
    precise float _368 = frac(abs(_364));
    precise float _371 = ((_364 >= (-_364)) ? _368 : (-_368)) * 60.0f;
    precise float _372 = TEXCOORD.x / _146;
    precise float _373 = TEXCOORD.y / _147;
    precise float _374 = sin(_372);
    precise float _375 = sin(_373);
    precise float _376 = TEXCOORD.y * _374;
    precise float _377 = TEXCOORD.x * _375;
    precise float _378 = _376 / _147;
    precise float _379 = _377 / _146;
    precise float _380 = _371 + _378;
    precise float _381 = _379 + _371;
    precise float _382 = _380 * 89.4199981689453125f;
    precise float _383 = _381 * 89.4199981689453125f;
    precise float _386 = cos(_382) * 343.420013427734375f;
    precise float _387 = cos(_383) * 343.420013427734375f;
    precise float _388 = frac(_386);
    precise float _389 = frac(_387);
    precise float _390 = _374 * _375;
    precise float _391 = _371 + _390;
    precise float _392 = _391 * 89.4199981689453125f;
    precise float _394 = cos(_392) * 343.420013427734375f;
    precise float _395 = frac(_394);
    precise float _396 = _358 + _388;
    precise float _397 = _389 + _359;
    precise float _398 = _360 + _395;
    precise float _399 = _358 - _388;
    precise float _400 = _359 - _389;
    precise float _401 = _360 - _395;
    precise float _402 = _358 * _388;
    precise float _403 = _389 * _359;
    precise float _404 = _360 * _395;
    precise float _405 = _358 / _388;
    precise float _406 = _359 / _389;
    precise float _407 = _360 / _395;
    bool _410 = cb0_m[6u].y == 1u;
    bool _411 = cb0_m[6u].y == 2u;
    bool _412 = cb0_m[6u].y == 3u;
    bool _413 = cb0_m[6u].y == 4u;
    bool _419 = cb0_m[6u].y == 5u;
    bool _420 = cb0_m[6u].w == 1u;
    bool _421 = cb0_m[6u].w == 2u;
    bool _422 = cb0_m[6u].w == 3u;
    bool _441 = cb0_m[6u].y != 0u;
#if 0 // Luma: removing saturate makes the image have white flickering dots
    precise float _445 = (_441 ? (_410 ? _399 : (_411 ? _402 : (_412 ? _405 : (_413 ? max(_358, _388) : (_419 ? min(_358, _388) : _346))))) : _396);
    precise float _446 = (_441 ? (_410 ? _400 : (_411 ? _403 : (_412 ? _406 : (_413 ? max(_389, _359) : (_419 ? min(_389, _359) : _347))))) : _397);
    precise float _447 = (_441 ? (_410 ? _401 : (_411 ? _404 : (_412 ? _407 : (_413 ? max(_360, _395) : (_419 ? min(_360, _395) : _348))))) : _398);
#else
    precise float _445 = clamp(_441 ? (_410 ? _399 : (_411 ? _402 : (_412 ? _405 : (_413 ? max(_358, _388) : (_419 ? min(_358, _388) : _346))))) : _396, 0.0f, 1.0f);
    precise float _446 = clamp(_441 ? (_410 ? _400 : (_411 ? _403 : (_412 ? _406 : (_413 ? max(_389, _359) : (_419 ? min(_389, _359) : _347))))) : _397, 0.0f, 1.0f);
    precise float _447 = clamp(_441 ? (_410 ? _401 : (_411 ? _404 : (_412 ? _407 : (_413 ? max(_360, _395) : (_419 ? min(_360, _395) : _348))))) : _398, 0.0f, 1.0f);
#endif
    precise float _452 = asfloat(cb0_m[6u].x);
    precise float _453 = asfloat(cb0_m[6u].z);
    precise float _454 = 1.0f - _453;
    precise float _455 = 1.0f - _452;
    precise float _456 = _358 * _454;
    precise float _457 = _359 * _454;
    precise float _458 = _360 * _454;
    precise float _459 = _445 * _453;
    precise float _460 = _453 * _446;
    precise float _461 = _453 * _447;
    precise float _462 = _456 + _459;
    precise float _463 = _460 + _457;
    precise float _464 = _461 + _458;
    precise float _465 = _388 + _462;
    precise float _466 = _388 + _463;
    precise float _467 = _388 + _464;
    precise float _468 = _462 - _388;
    precise float _469 = _463 - _388;
    precise float _470 = _464 - _388;
    precise float _471 = _388 * _462;
    precise float _472 = _388 * _463;
    precise float _473 = _388 * _464;
    precise float _474 = _462 / _388;
    precise float _475 = _463 / _388;
    precise float _476 = _464 / _388;
    bool _480 = cb0_m[6u].w == 4u;
    bool _481 = cb0_m[6u].w == 5u;
    bool _500 = cb0_m[6u].w != 0u;
    precise float _509 = asfloat(cb0_m[7u].y);
    precise float _510 = 1.0f - _509;
    precise float _511 = _462 * _510;
    precise float _512 = _510 * _463;
    precise float _513 = _510 * _464;
#if 0 // Luma: removing saturate makes the image have white flickering dots
    precise float _514 = (_500 ? (_420 ? _468 : (_421 ? _471 : (_422 ? _474 : (_480 ? max(_388, _462) : (_481 ? min(_388, _462) : _445))))) : _465) * _509;
    precise float _515 = _509 * (_500 ? (_420 ? _469 : (_421 ? _472 : (_422 ? _475 : (_480 ? max(_388, _463) : (_481 ? min(_388, _463) : _446))))) : _466);
    precise float _516 = _509 * (_500 ? (_420 ? _470 : (_421 ? _473 : (_422 ? _476 : (_480 ? max(_388, _464) : (_481 ? min(_388, _464) : _447))))) : _467);
#else
    precise float _514 = clamp(_500 ? (_420 ? _468 : (_421 ? _471 : (_422 ? _474 : (_480 ? max(_388, _462) : (_481 ? min(_388, _462) : _445))))) : _465, 0.0f, 1.0f) * _509;
    precise float _515 = _509 * clamp(_500 ? (_420 ? _469 : (_421 ? _472 : (_422 ? _475 : (_480 ? max(_388, _463) : (_481 ? min(_388, _463) : _446))))) : _466, 0.0f, 1.0f);
    precise float _516 = _509 * clamp(_500 ? (_420 ? _470 : (_421 ? _473 : (_422 ? _476 : (_480 ? max(_388, _464) : (_481 ? min(_388, _464) : _447))))) : _467, 0.0f, 1.0f);
#endif
    precise float _517 = _511 + _514;
    precise float _518 = _515 + _512;
    precise float _519 = _516 + _513;
    precise float _520 = _372 * 0.3333333432674407958984375f;
    precise float _524 = frac(abs(_520));
    precise float _527 = ((_520 >= (-_520)) ? _524 : (-_524)) * 3.0f;
    precise float _528 = floor(_527);
    precise float _537 = asfloat(cb0_m[5u].w) * asfloat(cb0_m[5u].z);
    precise float _538 = _517 - _537;
    precise float _539 = _537 * (-2.0f);
    precise float _540 = _517 + _539;
    precise float _543 = _517 * _455;
    precise float _544 = _518 * _455;
    precise float _545 = _519 * _455;
    precise float _546 = _452 * ((_528 == 0.0f) ? _517 : ((_528 == 1.0f) ? _538 : _540));
    precise float _547 = _543 + _546;
    precise float _548 = _544 + _546;
    precise float _549 = _545 + _546;
    precise float _556 = asfloat(cb0_m[4u].y) * asfloat(cb0_m[15u].w);
    precise float _557 = TEXCOORD.y / _556;
    precise float _562 = asfloat(cb0_m[16u].x);
    precise float _563 = asfloat(cb0_m[16u].z);
    precise float _566 = _147 * _563;
    precise float _567 = _562 * asfloat(cb0_m[4u].z);
    precise float _568 = _566 + _557;
    precise float _569 = _567 + _557;
    precise float _570 = _363 * _562;
    precise float _571 = _568 + _570;
    precise float _575 = asfloat(cb0_m[16u].y);
    precise float _576 = sin(_571) * _575;
    precise float _577 = _547 + _576;
    precise float _578 = (_577); // Luma: removed saturate
    precise float _580 = _575 * sin(_569);
    precise float _581 = _548 + _580;
    precise float _582 = (_581); // Luma: removed saturate
    precise float _583 = _557 - _563;
    precise float _584 = _570 + _583;
    precise float _586 = _575 * sin(_584);
    precise float _587 = _549 + _586;
    precise float _588 = (_587); // Luma: removed saturate
    precise float _599 = _582 * asfloat(cb0_m[9u].x);
    precise float _600 = _582 * asfloat(cb0_m[9u].y);
    precise float _601 = _582 * asfloat(cb0_m[9u].z);
    precise float _602 = _582 * asfloat(cb0_m[9u].w);
    precise float _613 = _578 * asfloat(cb0_m[8u].x);
    precise float _614 = _578 * asfloat(cb0_m[8u].y);
    precise float _615 = _578 * asfloat(cb0_m[8u].z);
    precise float _616 = _578 * asfloat(cb0_m[8u].w);
    precise float _617 = _599 + _613;
    precise float _618 = _614 + _600;
    precise float _619 = _615 + _601;
    precise float _620 = _616 + _602;
    precise float _631 = _588 * asfloat(cb0_m[10u].x);
    precise float _632 = _588 * asfloat(cb0_m[10u].y);
    precise float _633 = _588 * asfloat(cb0_m[10u].z);
    precise float _634 = _588 * asfloat(cb0_m[10u].w);
    precise float _635 = _617 + _631;
    precise float _636 = _632 + _618;
    precise float _637 = _633 + _619;
    precise float _638 = _634 + _620;
    precise float _649 = _635 + asfloat(cb0_m[11u].x);
    precise float _650 = _636 + asfloat(cb0_m[11u].y);
    precise float _651 = _637 + asfloat(cb0_m[11u].z);
    precise float _652 = _638 + asfloat(cb0_m[11u].w);
    precise float _658 = asfloat(cb0_m[12u].x);
    precise float _659 = asfloat(cb0_m[12u].y);
    precise float _660 = asfloat(cb0_m[12u].z);
    precise float _669 = asfloat(cb0_m[13u].x) - _658;
    precise float _670 = asfloat(cb0_m[13u].y) - _659;
    precise float _671 = asfloat(cb0_m[13u].z) - _660;
    precise float _672 = _649 / _669;
    precise float _673 = _650 / _670;
    precise float _674 = _651 / _671;
    precise float _675 = _658 + _672;
    precise float _676 = _673 + _659;
    precise float _677 = _674 + _660;
    
#endif

#if 1 // Luma: remove min/max clamping, which allows HDR output
    SV_Target.xyz = float3(_675, _676, _677);
  
    DICESettings config = DefaultDICESettings(DICE_TYPE_BY_CHANNEL_PQ); // Do DICE by channel to desaturate highlights and keep the SDR range unotuched
    float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
    float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
    SV_Target.rgb = DICETonemap(SV_Target.rgb * paperWhite, peakWhite, config) / paperWhite;
  
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
    ColorGradingLUTTransferFunctionInOutCorrected(SV_Target.rgb, VANILLA_ENCODING_TYPE, GAMMA_CORRECTION_TYPE, true);
    SV_Target.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
    ColorGradingLUTTransferFunctionInOutCorrected(SV_Target.rgb, GAMMA_CORRECTION_TYPE, VANILLA_ENCODING_TYPE, true);
#endif
#else
    SV_Target.x = clamp(_675, asfloat(cb0_m[14u].x), asfloat(cb0_m[15u].x));
    SV_Target.y = clamp(_676, asfloat(cb0_m[14u].y), asfloat(cb0_m[15u].y));
    SV_Target.z = clamp(_677, asfloat(cb0_m[14u].z), asfloat(cb0_m[15u].z));
#endif
    SV_Target.w = _652;
}