// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "HalfToneImageEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ScreenSize ("Screen Size", Vector) = (0, 0, 0, 0)
		_Frequency ("Frequency", Float) = 40
		_BlackThresh ("Black Threshold", Float) = 0.5
		_Width ("Line Width", Float) = .1
		_LineThresh ("Line Threshold", Float) = .5
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
			
			float Cos30 = .8660;
			float Cos60 = .5;
			float Sin30 = .5;
			float Sin60 = .8660;
			float sin45 = .7071;
			
			sampler2D _MainTex;
			float _Width;
			float _LineThresh;
			
			void SampleNeighbors(float2 uv, float n, out float3 sample[16])
			{
				float n_width = (n / 50.0) + _Width;
				float stepWidth = n_width / 2.0;
				
				[unroll]
				for (int i = 0; i < 2; i++)
				{
					int step = i * 8;
					float width = stepWidth * i;
					sample[step + 0] = tex2D(_MainTex, uv + float2(width, 0));
					sample[step + 1] = tex2D(_MainTex, uv + float2(width * sin45, width * sin45));
					sample[step + 2] = tex2D(_MainTex, uv + float2(0, width));
					sample[step + 3] = tex2D(_MainTex, uv + float2(-1 * width * sin45, 1 * width * sin45));
					sample[step + 4] = tex2D(_MainTex, uv + float2(-1 * width, 0));
					sample[step + 5] = tex2D(_MainTex, uv + float2(-1 * width * sin45, -1 * width * sin45));
					sample[step + 6] = tex2D(_MainTex, uv + float2(0, -1 * width));
					sample[step + 7] = tex2D(_MainTex, uv + float2(1 * width * sin45, -1 * width * sin45));
				}
			}
			
			float CalculateContour(float2 uv, float n)
			{
				float3 sample[16];
				SampleNeighbors(uv, n, sample);
				
				float3 color = tex2D(_MainTex, uv);
			
				float finalValue = 0.0;
				
				[unroll]
				for (int i = 0; i < 16; i++)
				{
					float diff = length(sample[i] - color);
					float value = aastep(_LineThresh, diff);
					finalValue = lerp(finalValue, value, step(finalValue, value));
				}
				
				return finalValue;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			float2 _ScreenSize;
			float _Frequency;
			float _BlackThresh;

			fixed4 frag (v2f i) : SV_Target
			{
				//float2 uv2 = mul(float2x2(0.707, -0.707, 0.707, 0.707), i.uv);
				
				float n = 0.2 * snoise(i.uv * 200.0); // Fractal noise
				n = n + 0.1 * snoise(i.uv * 400.0);
				n = n + 0.05 * snoise(i.uv * 800.0);
				
				float n_white = n * .5 + .98;
				float n_black = n + .1;
				float3 white = float3(n_white, n_white, n_white);
				float3 black = float3(n_black, n_black, n_black);
				
				float3 col = tex2D(_MainTex, i.uv);
				
				// Perform a rough RGB-to-CMYK conversion
				float4 cmyk;
				cmyk.rgb = 1.0 - col;
				cmyk.a = min(cmyk.r, min(cmyk.g, cmyk.b)); // Create K
				cmyk.rgb -= cmyk.a; // Subtract K equivalent from CMY
			 
				// Distance to nearest point in a grid of
				// (frequency x frequency) points over the unit square
				float2 Kst = mul(mul(_Frequency, float2x2(0.707, -0.707, 0.707, 0.707)), i.uv);
				float2 Kuv = 2.0 * frac(Kst) - 1.0;
				float k = aastep(0.0, sqrt(cmyk.a) - length(Kuv) + n);
				
				float2 Cst = mul(mul(_Frequency, float2x2(0.966, -0.259, 0.259, 0.966)), i.uv);
				float2 Cuv = 2.0 * frac(Cst) - 1.0;
				float c = aastep(0.0, sqrt(cmyk.r) - length(Cuv) + n);
				
				float2 Mst = mul(mul(_Frequency, float2x2(0.966, 0.259, -0.259, 0.966)), i.uv);
				float2 Muv = 2.0 * frac(Mst) - 1.0;
				float m = aastep(0.0, sqrt(cmyk.g) - length(Muv) + n);
				
				float2 Yst = mul(_Frequency, i.uv); // 0 deg
				float2 Yuv = 2.0 * frac(Yst) - 1.0;
				float y = aastep(0.0, sqrt(cmyk.b) - length(Yuv) + n);
			 
				float3 rgbscreen = 1.0 - 0.9 * float3(c,m,y) + n;
				rgbscreen = lerp(rgbscreen, black, 0.85*k + 0.3*n);
				
				// Create solid black areas where the luminance is low enough
				float3 kFilledColor = lerp(black, rgbscreen, aastep(_BlackThresh, n/50 + CalcLuminance(col)));
				
				// Override with black if a line should be here
				float contour = CalculateContour(i.uv, n);
				float3 finalColor = lerp(kFilledColor, black, contour);
	
				return float4(finalColor, 1.0);
			}
			ENDCG
		}
	}
}
