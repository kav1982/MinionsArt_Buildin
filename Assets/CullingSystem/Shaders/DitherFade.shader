Shader "Custom/DitherFade"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)        
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Noise ("Noise (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _PosSlider ("Cutoff Slider", float) = 0.0
        _Dither("Dither", float) = 0.0
        _AlphaThreshold("Alphacutoff", Range(0,1)) = 0.0
        _Fade("Fade", Range(0,10)) = 5

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        //  Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.0

        sampler2D _MainTex, _Noise;

        struct Input
        {
            float2 uv_MainTex;
            float3 localPos;
            float vFace : VFACE; 
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _PosSlider;
        float _Dither;
        float _AlphaThreshold,_Fade;
        
        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);        
            o.localPos = v.vertex.xyz;
        }

        float4 Unity_Dither_float4(float4 In, float4 ScreenPosition)
        {
            float2 coords = ScreenPosition.xy / ScreenPosition.w;
            float2 uv = coords * _ScreenParams.xy;
            float DITHER_THRESHOLDS[16] =
            {
                1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
                13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
                4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
                16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
            };
            uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
            return In - DITHER_THRESHOLDS[index];
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c;
             //  the object position and a slider that moves over the object
            float objectPosSliding = IN.localPos.y  + _PosSlider;
            // the dither effect, adding in the cutoff
            float ditheredCutoff = Unity_Dither_float4(_Dither, IN.screenPos).r + (1-(saturate(objectPosSliding)) * _Fade) ;
            // discard pixels based on dither
            clip(ditheredCutoff - _AlphaThreshold);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
