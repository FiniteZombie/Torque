Shader "HalfToneImageEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ScreenSize ("Screen Size", Vector) = (0, 0, 0, 0)
		_Frequency ("Frequency", Float) = 40
		_LumThresh1 ("Lum Threshold Low", Float) = 0
		_LumThresh2 ("Lum Threshold High", Float) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			float aastep(float threshold, float value)
			{
				float afwidth = 0.7 * length(float2(ddx(value), ddy(value)));
				return smoothstep(threshold-afwidth, threshold+afwidth, value);
			}
			
			float CalcLuminance(float3 color)
			{
				return dot(color, float3(0.299, 0.587, 0.114));
			}
			
			// Description : Array- and textureless GLSL 2D simplex noise.
			// Author : Ian McEwan, Ashima Arts. Version: 20110822
			// Copyright (C) 2011 Ashima Arts. All rights reserved.
			// Distributed under the MIT License. See LICENSE file.
			// https://github.com/ashima/webgl-noise
			 
			float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
			float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
			float3 permute(float3 x) { return mod289((( x * 34.0) + 1.0) * x); }
			 
			float snoise(float2 v)
			{
				const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
								  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
								 -0.577350269189626,  // -1.0 + 2.0 * C.x
								  0.024390243902439); // 1.0 / 41.0

				// First corner
				float2 i = floor(v + dot(v, C.yy) );
				float2 x0 = v - i + dot(i, C.xx);
				
				// Other corners
				float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				
				// Permutations
				i = mod289(i); // Avoid truncation effects in permutation
				float3 p = permute( permute( i.y + float3(0.0, i1.y, 1.0 ))
									   + i.x + float3(0.0, i1.x, 1.0 ));
				float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy),
									  dot(x12.zw,x12.zw)), 0.0);
				m = m*m; m = m*m;
				
				// Gradients
				float3 x = 2.0 * frac(p * C.www) - 1.0;
				float3 h = abs(x) - 0.5;
				float3 a0 = x - floor(x + 0.5);
				
				// Normalise gradients implicitly by scaling m
				m *= 1.792843 - 0.853735 * ( a0*a0 + h*h );
				
				// Compute final noise value at P
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot(m, g);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			float2 _ScreenSize;
			float _Frequency;
			float _LumThresh1;
			float _LumThresh2;

			fixed4 frag (v2f i) : SV_Target
			{
				matrix <float, 2, 2> fMat = {0.707, -0.707, 0.707, 0.707};
				float2 uv2 = mul(fMat, i.uv);
				
				float n = 0.2 * snoise(uv2 * 200.0); // Fractal noise
				n = n + 0.1 * snoise(uv2 * 400.0);
				n = n + 0.05 * snoise(uv2 * 800.0);
				
				float n_white = n * .5 + .98;
				float n_black = n + .1;
				float3 white = float3(n_white, n_white, n_white);
				float3 black = float3(n_black, n_black, n_black);
				
				float3 col = tex2D(_MainTex, i.uv);
				
				float lum = CalcLuminance(col);
				//lum = lerp(_LumThresh1, lum, step(lum, _LumThresh1));
				//lum = lerp(lum, _LumThresh2, step(lum, _LumThresh2));
				float radius = sqrt(1 - lum);
				
				float2 nearest = 2.0 * frac(_Frequency * uv2) - 1.0;
				float dist = length(nearest);
				
				float3 fragcolor = lerp(black, white, aastep(radius, dist + n));
				return float4(fragcolor, 1.0);
			}
			ENDCG
		}
	}
}
