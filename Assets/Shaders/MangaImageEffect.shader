Shader "MangaImageEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ScreenSize ("Screen Size", Vector) = (0, 0, 0, 0)
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
				return dot(color, float3(0.299f, 0.587f, 0.114f));
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

			fixed4 frag (v2f i) : SV_Target
			{
				float frequency = 10.0;
				float radius = 0.7;
				float3 white = float3(1.0, 1.0, 1.0);
				float3 black = float3(0.0, 0.0, 0.0);
				
				float ratio = _ScreenSize[1] / _ScreenSize[0];
				i.uv[1] = i.uv[1] * ratio;
				
				matrix <float, 2, 2> fMat = {0.707, -0.707, 0.707, 0.707};
				float2 uv2 = mul(fMat, i.uv);
				
				float3 col = tex2D(_MainTex, i.uv);
				float lum = CalcLuminance(col);
				float2 nearest = 2.0 * frac(frequency * uv2) - 1.0;
				float dist = length(nearest);
				
				float3 fragcolor = lerp(black, white, aastep(lum * radius, dist));
				return float4(fragcolor, 1.0);
			}
			ENDCG
		}
	}
}
