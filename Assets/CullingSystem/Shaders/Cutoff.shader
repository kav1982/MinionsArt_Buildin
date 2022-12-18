Shader "Custom/Cutoff"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)       
        _MainTex ("Albedo (RGB)", 2D) = "white" {}     
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _PosSlider ("Slider", float) = 0.0
        _Stretch ("Stretch", float) = 7
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        //  Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert keepalpha  

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 localPos;
            float vFace : VFACE; 
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _PosSlider;
        half _Stretch;
        
        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.localPos = v.vertex.xyz;
            
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
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            
            //  the object position and a slider that moves over the object
            float objectPosSliding = IN.localPos.y  + _PosSlider;

            // the cutoff that will be clipped
            float cutoff = step(objectPosSliding, 0.5);
            // lerp the color of the albedo towards the cutoff point
            c = lerp(c, _Color, saturate(objectPosSliding * _Stretch));
            // 
            float4 final = (IN.vFace>0) ? c : _Color;
            o.Albedo = final;
            //
            float4 e = lerp(0, _Color, saturate(objectPosSliding * _Stretch));
            // color the backfaces in _Color, and the the rest in the f
            o.Emission = (IN.vFace>0) ? e : _Color;
            // clip everything above the cutoff;
            clip(cutoff - 0.06);
            
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha =1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
