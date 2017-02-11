Shader "MangaImageEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				float frequency = 200.0;
				float2 nearest = 2.0 * frac(frequency * i.uv) - 1.0;
				float dist = length(nearest);
				float radius = 0.7;
				float3 white = float3(1.0, 1.0, 1.0);
				float3 black = float3(0.0, 0.0, 0.0);
				float3 fragcolor = lerp(black, white, step(radius, dist));
				return float4(fragcolor, 1.0);
				
				//fixed4 col = tex2D(_MainTex, i.uv);
				// just invert the colors
				//col = 1 - col;
				//return col;
			}
			ENDCG
		}
	}
}
