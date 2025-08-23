#include "Includes/Common.hlsl"

// TODO: move to c++!!!
float4x4 InverseMatrix(float4x4 m)
{
    float4x4 r;

    float a00 = m[0][0], a01 = m[0][1], a02 = m[0][2], a03 = m[0][3];
    float a10 = m[1][0], a11 = m[1][1], a12 = m[1][2], a13 = m[1][3];
    float a20 = m[2][0], a21 = m[2][1], a22 = m[2][2], a23 = m[2][3];
    float a30 = m[3][0], a31 = m[3][1], a32 = m[3][2], a33 = m[3][3];

    float b00 = a00 * a11 - a01 * a10;
    float b01 = a00 * a12 - a02 * a10;
    float b02 = a00 * a13 - a03 * a10;
    float b03 = a01 * a12 - a02 * a11;
    float b04 = a01 * a13 - a03 * a11;
    float b05 = a02 * a13 - a03 * a12;
    float b06 = a20 * a31 - a21 * a30;
    float b07 = a20 * a32 - a22 * a30;
    float b08 = a20 * a33 - a23 * a30;
    float b09 = a21 * a32 - a22 * a31;
    float b10 = a21 * a33 - a23 * a31;
    float b11 = a22 * a33 - a23 * a32;

    float det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
    float invDet = 1.0 / det;

    r[0][0] = ( a11 * b11 - a12 * b10 + a13 * b09) * invDet;
    r[0][1] = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet;
    r[0][2] = ( a31 * b05 - a32 * b04 + a33 * b03) * invDet;
    r[0][3] = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet;
    r[1][0] = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet;
    r[1][1] = ( a00 * b11 - a02 * b08 + a03 * b07) * invDet;
    r[1][2] = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet;
    r[1][3] = ( a20 * b05 - a22 * b02 + a23 * b01) * invDet;
    r[2][0] = ( a10 * b10 - a11 * b08 + a13 * b06) * invDet;
    r[2][1] = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet;
    r[2][2] = ( a30 * b04 - a31 * b02 + a33 * b00) * invDet;
    r[2][3] = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet;
    r[3][0] = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet;
    r[3][1] = ( a00 * b09 - a01 * b07 + a02 * b06) * invDet;
    r[3][2] = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet;
    r[3][3] = ( a20 * b03 - a21 * b01 + a22 * b00) * invDet;

    return r;
}

float2 CurrentToPreviousNDC(float2 ndc, float depth)
{
    float4x4 reprojectionMatrix = mul(LumaData.GameData.PreviousViewProjectionMatrix, InverseMatrix(LumaData.GameData.ViewProjectionMatrix));
	const float4 vPosHPrev = mul(reprojectionMatrix, float4(ndc, depth, 1.0));
	return vPosHPrev.xy / vPosHPrev.w;
}

float2 main(float4 pos : SV_Position0) : SV_Target0
{
	float depth = 0.f; // Sky is at maximum distance (inverse depth)

	const float2 uv = pos.xy * LumaSettings.GameSettings.InvOutputRes;
	float2 ndc;
	ndc.x = uv.x * 2.0 - 1.0;
	ndc.y = (1.0 - uv.y) * 2.0 - 1.0; // flip Y for DX NDC

	float2 prevNDC = CurrentToPreviousNDC(ndc, depth);

	float2 velocity = prevNDC - ndc;
	return velocity; // TODO: scale these... this is the formula of Prey, we don't do this
}