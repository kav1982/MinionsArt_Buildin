
Shader "Particles/VertexColorAnim" {
    Properties {
        [Header(Base)]
        _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("Particle Texture", 2D) = "white" {}
        _Alpha ("Alpha", Range(0,1)) =1

        [Space]
        [Header(Rim)]
        [Toggle(RIM)] _RIM("Rim Light", Float) = 1
        _RimColor ("Rim Color", Color) = (1,0,0,0.5)
        _RimPower("Rimpower", Range(0,10)) = 2

        [Space]
        [Header(Animation)]       
        _Rigidness("Rigidness", Range(0.01,10)) = 0.5
        _Speed("Speed", Range(0,10)) = 0.5
        _Length("Length", Range(0,10)) = 2

        [Space]
        [Header(Rotation Fix)]
        _Rotation("Rotation", Range(0,360.0)) = 0
        _Axis("Axis", Vector) = (0,1,0)
        
    }
    
    Category {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"   }
        Blend One OneMinusSrcAlpha
        ZWrite On   
        
        CGINCLUDE
        
        sampler2D _MainTex;
        fixed4 _TintColor,_RimColor;
        
        struct appdata_t {
            float4 vertex : POSITION;
            fixed4 color : COLOR;
            float4 texcoord : TEXCOORD0;
            float4 velocity : TEXCOORD1;
            float4 uv : TEXCOORD2;
            float3 normal : NORMAL;
            float3 viewDir : TEXCOORD4;
            float4 rotation : TEXCOORD3;
        };
        
        float4 _MainTex_ST;
        float _Rotation;
        float _Speed, _Rigidness,_Length;
        float _RimPower;
        float _Alpha;
        float3 _Axis;
        
        float3 Unity_RotateAboutAxis_Degrees_float(float3 In, float3 Axis, float Rotation)
        {
            Rotation = radians(Rotation);
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);
            float3x3 rot_mat = 
            {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
                one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
                one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
            };
            return mul(rot_mat,  In);
        }
        ENDCG
        
        SubShader {
            Pass {
                
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 2.0
                #pragma multi_compile_particles
                #pragma shader_feature RIM
                #include "UnityCG.cginc"
                
                struct v2f {
                    float4 vertex : POSITION;                  
                    float2 texcoord : TEXCOORD2;
                    float3 normal : NORMAL;
                    float3 viewDir : TEXCOORD4;                
                };
                
                
                v2f vert (appdata_t v)
                {
                    // particle scale
                    float scale = v.texcoord.w;

                    //randomisation
                    float random =  v.uv.w;

                    float4 pos = v.vertex;
                    // center
                    float3 pivot = v.texcoord.xyz; 

                    //Move to root
                    pos.xyz -= pivot;
                    //Rotate on velocity
                    float3 crossVel = cross(normalize(v.velocity),_Axis);
                    pos.xyz = Unity_RotateAboutAxis_Degrees_float(pos.xyz,crossVel, _Rotation);

                    // add sine wave
                    float y = sin( _Rigidness + (_Time.y * (_Speed + random)))*( _Length * scale);// z axis movements
                    float x = sin( pos.z  / _Rigidness + (_Time.y * (_Speed + random )))*( _Length * scale);// z axis movements
                    float y2 = sin( 2/ _Rigidness + ((_Time.y)  * (_Speed+ random)))*( _Length * scale);// z axis movements

                    // move vertices               
                    pos.y += y * v.color.r;
                    pos.y += y2 * v.color.g;
                    pos.x += x * v.color.b;

                    //Rotate back
                    pos.xyz = Unity_RotateAboutAxis_Degrees_float(pos.xyz,crossVel,- _Rotation);
                    //Move it back
                    pos.xyz += pivot;
                    
                    v2f o;
                    o.vertex = UnityObjectToClipPos(pos);                 
                    o.texcoord = v.uv.yz;
                    o.normal = v.normal;
                    o.viewDir = ObjSpaceViewDir(pos);
                    return o;
                }
                
                
                fixed4 frag (v2f i) : SV_Target
                {
                    float rim = 1.0 - saturate(dot (normalize(i.viewDir), i.normal));
                    float4 tex = tex2D(_MainTex, i.texcoord);
                    #if RIM
                        float  fresnel =  pow(rim, _RimPower);
                        float4 result = lerp(tex * _TintColor,_RimColor, fresnel);
                    #else
                        float4 result = tex * _TintColor;
                    #endif
                    return float4(result.rgb, _Alpha);
                }
                ENDCG
            }

            Pass
            {
                Tags {"LightMode"="ShadowCaster"}

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_shadowcaster
                #include "UnityCG.cginc"

                struct v2f { 
                    V2F_SHADOW_CASTER;
                };

                

                v2f vert(appdata_t v)
                {
                    // particle scale
                    float scale = v.texcoord.w;

                    //randomisation
                    float random =  v.uv.w;

                    float4 pos = v.vertex;
                    // center
                    float3 pivot = v.texcoord.xyz; 

                    //Move to root
                    pos.xyz -= pivot;
                    //Rotate on velocity
                    float3 crossVel = cross(normalize(v.velocity),_Axis);
                    pos.xyz = Unity_RotateAboutAxis_Degrees_float(pos.xyz,crossVel, _Rotation);

                    // add sine wave
                    float y = sin( _Rigidness + (_Time.y * (_Speed + random)))*( _Length * scale);// z axis movements
                    float x = sin( pos.z  / _Rigidness + (_Time.y * (_Speed + random )))*( _Length * scale);// z axis movements
                    float y2 = sin( 2/ _Rigidness + ((_Time.y)  * (_Speed+ random)))*( _Length * scale);// z axis movements
                    
                    // move vertices               
                    pos.y += y * v.color.r;
                    pos.y += y2 * v.color.g;
                    pos.x += x * v.color.b;

                    //Rotate back
                    pos.xyz = Unity_RotateAboutAxis_Degrees_float(pos.xyz,crossVel,- _Rotation);
                    //Move it back
                    pos.xyz += pivot;

                    v.vertex.xyz = pos.xyz;
                    v2f o;
                    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                    return o;
                }

                float4 frag(v2f i) : SV_Target
                {
                    SHADOW_CASTER_FRAGMENT(i)
                }
                ENDCG
            }
        }
        
    }
}
