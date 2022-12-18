Shader "Custom/GlitchWireframeEffect"
{
    Properties
    {
        [Header(Vertex Displacement)]
        _Intensity ("Vertex Intensity", Range(0,1)) = 0.3
        _Width("Pulse Width", Range(0,1)) = 0.5
        _PulseFreq("Pulse Freq", Range(0,1)) = 0.2
        _Scale("Pulse Scale", Range(0,5)) = 2 
        _Speed("Speed", Range(-5,5)) = 0.3
        _Random("Random Offset", Range(0,5)) = 0.0
        
        [Header(Tinting)]
        _TintingBrightness("Tinting Brightness", Range(0,5)) = 1.0
        _Stretch("Stretch Tinting Gradient", Range(0,5)) = 2
        _Tinting("Albedo Tinting", Color) = (0,0,1,1)
        _Tinting2("Albedo Tinting 2", Color) = (0,0,0,1)
        
        [Header(Backfaces)]
        _Brightness ("Backface Brightness", Range(0,5)) = 4
        _BackfaceCol ("Backface Color", Color) = (0,0.5,1,1)
        _BackfaceCol2 ("Backface Color2", Color) = (0,1,1,1)
        _StretchBackface("Stretch BackFace Gradient", Range(0,5)) = 0.0
        
        [Header(Rim)]
        _RimBrightness("Rim Brightness", Range(0,20)) = 5
        _RimPower("RImPOwer", Range(0,20)) = 10
        _StretchRim("Stretch Rim Gradient", Range(0,5)) = 2
        _RimCol ("Rim Color", Color) = (1,0,1,1)
        _RimCol2 ("Rim Color 2", Color) = (1,1,1,1)
        
        [Header(Other)]
        _Clipping("Front Face Clipping", Range(0,1)) = 0.0
        _Distortion("Distortion", Range(0,1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+2"}
        LOD 200
        Cull Off
        GrabPass { "_GrabTex" }
        CGPROGRAM
        #include "UnityCG.cginc"
        
        
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Simple vertex:vert addshadow 
        
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.0
        
        
        sampler2D _GrabTex;
        float4 _GrabTex_TexelSize;
        
        
        #pragma lighting Simple exclude_path:prepass
        inline half4 LightingSimple(SurfaceOutput s, half3 lightDir, half atten)
        {
            half4 c;
            c.rgb = s.Albedo * _LightColor0.rgb *atten; 
            c.a = s.Alpha;
            return c;
        }
        
        struct Input
        {
            float4 screenPos;
            float facing : VFACE;
            float3 viewDir;
            float3 worldPos;
            float glitchPosFront;
            float glitchPos;      
        };
        
        fixed4 _BackfaceCol2, _BackfaceCol;
        fixed4 _Tinting, _Tinting2;
        fixed4 _RimCol,_RimCol2;
        float _Intensity,_Width, _PulseFreq;
        float _Stretch, _StretchBackface, _StretchRim;
        float _Random,_Scale,_Speed;
        float _Brightness,_TintingBrightness,_RimBrightness;
        float _RimPower;
        sampler2D _CameraDepthTexture;
        float _Distortion;
        float _Clipping;
        
        float rand(float n)
        {
            return frac(sin(n) * 43758.5453123);
        }
        
        
        
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT (Input, o);
            
            // vertex y position, with optional randomness
            float randomPos = (rand(v.texcoord.x) * _Random ) + (v.vertex.y * _Scale);
            float moveSpeed = _Time.y * _Speed;
            
            // repeat position on model, and move it up/down
            float glitchPos = frac((randomPos +moveSpeed ) * _PulseFreq)  ;// position on model
            
            // clamp the width with a smoothstep
            float glitchPosClamped =  smoothstep(glitchPos , glitchPos + 1, _Width );
            
            // only split on the camera viewing part
            float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
            float frontFacing =saturate(dot(normalize(v.normal), normalize(viewDir))) ;
            frontFacing = step(0.1, frontFacing);
            
            // move vertices outward based on the glitchy position
            v.vertex.xyz += (glitchPosClamped * normalize(v.normal)) * _Intensity * frontFacing;
            
            // send positions through to the fragment function
            o.glitchPos = glitchPos;
            o.glitchPosFront = glitchPosClamped* frontFacing;
        }
        
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
        
        float3 GetFaceNormal(float3 position) {
            float3 dx = ddx(position);
            float3 dy = ddy(position);
            return normalize(cross(dy, dx));
        }
        
        void surf (Input IN, inout SurfaceOutput o)
        {
            // grabtex uv
            float2 uv = IN.screenPos.xy / IN.screenPos.w;
            
            // get an evened out facenormal, will make the distortions move more with the vertex movement
            float3 faceNormal = GetFaceNormal(IN.worldPos.xyz);
            
            // distorted uv 
            float2 distortedUV = lerp(uv, (faceNormal + uv) * 0.5,  _Distortion) ;
            // grabtex
            float4 grabPassTex = tex2D (_GrabTex, distortedUV );
            
            //base albedo is the grabtex
            o.Albedo =  grabPassTex.rgb ;
            
            // backfaces colors, lerped over glitchpos
            float3 backGlitchCol = lerp(_BackfaceCol2, _BackfaceCol, saturate(IN.glitchPos*  _StretchBackface));
            
            // tinted grabtex colors, lerped over glitchpos
            float3 albedoTinting = lerp( _Tinting, _Tinting2,saturate(IN.glitchPos* _Stretch));
            albedoTinting *=  grabPassTex.rgb;
            // add tinting
            o.Albedo += (albedoTinting * _TintingBrightness) ;
            
            // use vface to only add color to the front faces
            o.Albedo = (IN.facing>0) ? o.Albedo : 0;
            
            // create a rim
            float Rim = 1.0 - saturate(dot(normalize(faceNormal), normalize(IN.viewDir)));
            float softRim = pow(Rim, _RimPower)  ;
            
            
            // color rim based on glitchpos
            float3 rimCol = lerp(_RimCol, _RimCol2,  saturate(IN.glitchPos * _StretchRim) );
            
            // rimcol on frontfacing, backglithcol on backfacing
            o.Emission = ((IN.facing>0) ?  ( rimCol * _RimBrightness) * softRim: backGlitchCol * _Brightness ) ;
            
            // clip front to show into the mesh more
            clip( ((1-IN.glitchPosFront)- _Clipping));
            
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
