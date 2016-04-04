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

static int NUM_BUCKETS = 32;
static int ITER_PER_BUCKET = 1024;
static float HIST_SCALE = 8.0;

static float NUM_BUCKETS_F = float(32);
static float ITER_PER_BUCKET_F = float(1024);


//note: uniformly distributed, normalized rand, [0;1[
float nrand(float2 n)
{
	return frac(sin(dot(n.xy, float2(12.9898, 78.233)))* 43758.5453);
}
//note: remaps v to [0;1] in interval [a;b]
float remap(float a, float b, float v)
{
	return clamp((v - a) / (b - a), 0.0, 1.0);
}
//note: quantizes in l levels
float trunc(float a, float l)
{
	return floor(a*l) / l;
}

float n1rand(float2 n)
{
	float t = frac(gTime);
	float nrnd0 = nrand(n + 0.07*t);
	return nrnd0;
}
float n2rand(float2 n)
{
	float t = frac(gTime);
	float nrnd0 = nrand(n + 0.07*t);
	float nrnd1 = nrand(n + 0.11*t);
	return (nrnd0 + nrnd1) / 2.0;
}
float n3rand(float2 n)
{
	float t = frac(gTime);
	float nrnd0 = nrand(n + 0.07*t);
	float nrnd1 = nrand(n + 0.11*t);
	float nrnd2 = nrand(n + 0.13*t);
	return (nrnd0 + nrnd1 + nrnd2) / 3.0;
}
float n4rand(float2 n)
{
	float t = frac(gTime);
	float nrnd0 = nrand(n + 0.07*t);
	float nrnd1 = nrand(n + 0.11*t);
	float nrnd2 = nrand(n + 0.13*t);
	float nrnd3 = nrand(n + 0.17*t);
	return (nrnd0 + nrnd1 + nrnd2 + nrnd3) / 4.0;
}

float n8rand(float2 n)
{
	float t = frac(gTime);
	float nrnd0 = nrand(n + 0.07*t);
	float nrnd1 = nrand(n + 0.11*t);
	float nrnd2 = nrand(n + 0.13*t);
	float nrnd3 = nrand(n + 0.17*t);

	float nrnd4 = nrand(n + 0.19*t);
	float nrnd5 = nrand(n + 0.23*t);
	float nrnd6 = nrand(n + 0.29*t);
	float nrnd7 = nrand(n + 0.31*t);

	return (nrnd0 + nrnd1 + nrnd2 + nrnd3 + nrnd4 + nrnd5 + nrnd6 + nrnd7) / 8.0;
}

float n4rand_inv(float2 n)
{
	float t = frac(1.0f);
	float nrnd0 = nrand(n + 0.07*t);
	float nrnd1 = nrand(n + 0.11*t);
	float nrnd2 = nrand(n + 0.13*t);
	float nrnd3 = nrand(n + 0.17*t);
	float nrnd4 = nrand(n + 0.19*t);
	float v1 = (nrnd0 + nrnd1 + nrnd2 + nrnd3) / 4.0;
	float v2 = 0.5 * remap(0.0, 0.5, v1) + 0.5;
	float v3 = 0.5 * remap(0.5, 1.0, v1);
	return (nrnd4<0.5) ? v2 : v3;
}

//alternative Gaussian,
//thanks to @self_shadow
//see http://www.dspguide.com/ch2/6.htm
float n4rand_ss(float2 n)
{
	float nrnd0 = nrand(n + 0.07*frac(gTime));
	float nrnd1 = nrand(n + 0.11*frac(gTime + 0.573953));
	return 0.23*sqrt(-log(nrnd0 + 0.00001))*cos(2.0*3.141592*nrnd1) + 0.5;
}

float histogram(int iter, float2 uv, float2 interval, float height, float scale)
{
	float t = remap(interval.x, interval.y, uv.x);
	float2 bucket = float2(trunc(t, NUM_BUCKETS_F), trunc(t, NUM_BUCKETS_F) + 1.0 / NUM_BUCKETS_F);
	float bucketval = 0.0;
	for (int i = 0; i<ITER_PER_BUCKET; ++i)
	{
		float seed = float(i) / ITER_PER_BUCKET_F;

		float r;
		if (iter < 2)
			r = n1rand(float2(uv.x, 0.5) + seed);
		else if (iter<3)
			r = n2rand(float2(uv.x, 0.5) + seed);
		else if (iter<4)
			r = n4rand(float2(uv.x, 0.5) + seed);
		else
			r = n8rand(float2(uv.x, 0.5) + seed);

		bucketval += step(bucket.x, r) * step(r, bucket.y);
	}
	bucketval /= ITER_PER_BUCKET_F;
	bucketval *= scale;

	float v0 = step(uv.y / height, bucketval);
	float v1 = step((uv.y - 1.0 / 800.0f) / height, bucketval);
	float v2 = step((uv.y + 1.0 / 600.0f) / height, bucketval);
	return 0.5 * v0 + v1 - v2;
}

float4 PS(float4 fragCoord:SV_POSITION) : SV_Target
{
	float2 uv = fragCoord.xy / 1400.0f;

	float o;
	int idx;
	float2 uvrange;
	if (uv.x < 1.0 / 4.0)
	{
		o = n1rand(uv);
		idx = 1;
		uvrange = float2(0.0 / 4.0, 1.0 / 4.0);
	}
	else if (uv.x < 2.0 / 4.0)
	{
		o = n2rand(uv);
		idx = 2;
		uvrange = float2(1.0 / 4.0, 2.0 / 4.0);
	}
	else if (uv.x < 3.0 / 4.0)
	{
		o = n4rand(uv);
		idx = 3;
		uvrange = float2(2.0 / 4.0, 3.0 / 4.0);
	}
	else
	{
		o = n8rand(uv);
		idx = 4;
		uvrange = float2(3.0 / 4.0, 4.0 / 4.0);
	}

	//display histogram
	if (uv.y < 1.0 / 4.0)
		o = 0.125 + histogram(idx, uv, uvrange, 1.0 / 4.0, HIST_SCALE);

	//display lines
	if (abs(uv.x - 1.0 / 4.0) < 0.002) o = 0.0;
	if (abs(uv.x - 2.0 / 4.0) < 0.002) o = 0.0;
	if (abs(uv.x - 3.0 / 4.0) < 0.002) o = 0.0;
	if (abs(uv.y - 1.0 / 4.0) < 0.002) o = 0.0;

	return float4(float3 (o, o, o), 1.0);
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