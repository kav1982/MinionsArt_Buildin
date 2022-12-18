Shader "FX/After Image Effect" {
	Properties{
		_Color("Extra Color", Color) = (1,1,1,1)		
		_RimColor("Rim Color", Color) = (0,1,1,1)
		_MainTex("Main Texture", 2D) = "black" {}
		_RimPower("Rim Power", Range(1,50)) = 20
		[PerRendererData]_Fade("Fade Amount", Range(0,1)) = 1
		_Grow("Grow", Range(0,1)) = 0.05
	}
	
	Category{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "PreviewType" = "Sphere" }
		Blend SrcAlpha One 
		Zwrite Off
		Cull Back 
		SubShader{
			Pass{
				
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing 
				#pragma target 3.0							
				#include "UnityCG.cginc"
				
				sampler2D _MainTex;
				fixed4 _RimColor;
				
				
				struct appdata_t {
					float4 vertex : POSITION;				
					float2 texcoord : TEXCOORD0;
					float3 normal : NORMAL; // vertex normal
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				
				struct v2f {
					float4 vertex : SV_POSITION;
					float2 texcoord : TEXCOORD0;
					float3 wpos : TEXCOORD1; // worldposition
					float3 normalDir : TEXCOORD2; // normal direction for rimlighting
					UNITY_VERTEX_INPUT_INSTANCE_ID
					
				};
				
				float4 _MainTex_ST;
				float _RimPower;
				float _Grow;

				UNITY_INSTANCING_BUFFER_START(Props)
				UNITY_DEFINE_INSTANCED_PROP(float, _Fade)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
				UNITY_INSTANCING_BUFFER_END(Props)

				v2f vert(appdata_t v)
				{
					v2f o;
					
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					
					// grow based on normals and fade property
					v.vertex.xyz += v.normal * saturate(1- UNITY_ACCESS_INSTANCED_PROP(Props, _Fade)) * _Grow;
					o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
					o.vertex = UnityObjectToClipPos(v.vertex);
					
					// world position and normal direction for fresnel
					o.wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);					
					return o;
				}
				
				fixed4 frag(v2f i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i);
					float4 text = tex2D(_MainTex, i.texcoord);// texture
					
					// rim lighting
					float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
					// fresnel based on view and normal
					half rim = 1.0 - saturate(dot(viewDirection, i.normalDir));
					rim = pow(rim, _RimPower);									
					
					// end result color 	
					fixed4 col = (text * UNITY_ACCESS_INSTANCED_PROP(Props, _Color)) +(rim * _RimColor);			
					col.a *=  UNITY_ACCESS_INSTANCED_PROP(Props, _Color).a;
					col.a *= (text.r + text.g + text.b) * 0.33f;
					col.a += rim;

					// quick smoothstep to make the fade more interesting
					col.a = smoothstep( col.a ,col.a + 0.05 ,UNITY_ACCESS_INSTANCED_PROP(Props, _Fade));					
					col = saturate(col);
					
					return col;
				}
				ENDCG
			}
		}
	}
}