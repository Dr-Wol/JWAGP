//***************************************************************************************
// color.fx by Frank Luna (C) 2011 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************

cbuffer cbPerObject
{
	float4x4 gWorldViewProj;
	float gTime;
};

struct VertexIn
{
	float3 PosL  : POSITION;
	float4 Color : COLOR;
};

struct VertexOut
{
	float4 PosH  : SV_POSITION;
	float4 Color : COLOR;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;

	// Transform to homogeneous clip space.
	vout.PosH = mul(float4(vin.PosL, 1.0f), gWorldViewProj);

	// Just pass vertex color into the pixel shader.
	vout.Color = vin.Color;

	return vout;
}

float4 PS(float4 pixCoords:SV_POSITION) : SV_Target
{
	float circleX = 800.0f / 2.0;
	float circleY = 600.0f / 2.0;
	float deltaX = pixCoords.x - circleX;
	float deltaY = pixCoords.y - circleY;
	float dist = sqrt(deltaX*deltaX + deltaY*deltaY);
	float light = 0.5*cos(dist*0.5 - gTime*80.0) + 0.5;



	return float4(light, light, light, 1.0);
}

technique11 ColorTech
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, VS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, PS()));
	}
}





