
Shader "Particles/Fire"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Noise ("Noise Texture", 2D) = "white" {}
		_Distort("Second Noise Texture", 2D) = "white" {}
		_Scale("Noise Scale", Range(0,2)) = 0.5
		_DistortScale("Distort Scale", Range(0,2)) = 0.5
		_Tint("Tint", Color) = (1,1,0,0) // Color of the dissolve Line
		_EdgeColor("Edge", Color) = (1,0.5,0,0) // Color of the dissolve Line)
		_Cutoff("Cutoff Smoothness", Range(0,1)) = 0.2
		_Speed("Speed", Range(-10,10)) = 2
		_Brightness("Brightness", Range(0,2)) = 0.6
		_Stretch("Stretch", Range(0,2)) = 1
		_EdgeWidth("EdgeWidth", Range(-2,2)) = 0.4
		_Particle("Density", Range(-2,2)) = 0
		[Toggle(MULTIPLY)] _MULTIPLY("Multiply Noise?", Float) = 1
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Op", Int) = 0// 0 = add, 4 = max, other ones won't look good
		
	}


	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
		Blend One OneMinusSrcAlpha
		ColorMask RGB
		Cull Off Lighting Off ZWrite Off
		BlendOp [_BlendOp]
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma shader_feature MULTIPLY

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 uv : TEXCOORD0;// .z has particle age
				float4 color : COLOR;
				float4 normal :NORMAL;
			};

			struct v2f
			{
				float3 uv : TEXCOORD0; // .z has particle age
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 color: COLOR;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;

			};

			sampler2D _MainTex,_Noise, _Distort;
			float4 _MainTex_ST, _Noise_ST, _Tint, _EdgeColor;
			float _Scale, _DistortScale, _Cutoff, _Speed, _Brightness, _Stretch, _EdgeWidth, _Particle;
			v2f vert (appdata v)
			{
				v2f o;
				o.worldNormal = mul(unity_ObjectToWorld,v.normal);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
				o.worldPos = mul (unity_ObjectToWorld, v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				o.uv.z = v.uv.z; 
				o.color = v.color;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture

				float3 blendNormal = saturate(pow(i.worldNormal * 1.4,4));

				float flowspeed = _Time.y * _Speed;

				i.worldPos.y -= flowspeed;
				i.worldPos.y *= _Stretch;

				// normal distort triplanar for x, y, z sides
				float xd = tex2D(_Distort, i.worldPos.zy * _DistortScale);
				float zd = tex2D(_Distort, i.worldPos.xy * _DistortScale);

				// lerped together all sides for distort texture
				float distorttexture = zd;
				distorttexture = lerp(distorttexture, xd, blendNormal.x);


				// normal noise triplanar for x, y, z sides
				float xn = tex2D(_Noise, (i.worldPos.zy * _Scale));
				float zn = tex2D(_Noise, (i.worldPos.xy  * _Scale) );

				// lerped together all sides for noise texture
				float noisetexture = zn;
				noisetexture = lerp(noisetexture, xn, blendNormal.x);

				float particleAgePercent = i.uv.z;
				particleAgePercent -= _Particle;
				
				float finalNoise;
				#if MULTIPLY
					finalNoise = noisetexture * distorttexture * 2;
				#else
					finalNoise = (noisetexture + distorttexture)*2 ;
				#endif

				// particle shape
				float4 shape = tex2D(_MainTex, i.uv);

				
				
				float4 result = smoothstep(particleAgePercent - _Cutoff,particleAgePercent, finalNoise* shape.a);
				float edge = result * step(finalNoise * shape.a, particleAgePercent + _EdgeWidth) * shape.a;// edge multiplied by particle shape  alpha
				result -= edge;
				result *= shape.a;// use particle texture
				result += (result * _Brightness);// extra brightness

				result *=  _Tint;// tint
				result *= i.color.a; // particle alpha
				result += (edge * _EdgeColor);// add colored edge
				result *= i.color;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, result);
				return result;

			}
			ENDCG
		}
	}
}
