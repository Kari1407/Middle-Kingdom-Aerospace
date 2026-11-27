Shader "Kari1407/PackedMask"
{
    // This is a modified version of the PackedMetal shader from resurfaced to allow it to load custom mask maps with Smoothness, AO and Metallic outside the base texture (not compatible with stock shaders)
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)

        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,1)) = 1.0

        _MaskMap("MaskMap", 2D) = "white" {}

        _MetalRedMult("Metalness Red Multiplier", Range(0,1)) = 0.0
        _MetalGreenMult("Metalness Green Multiplier", Range(0,1)) = 0.0
        _MetalBlueMult("Metalness Blue Multiplier", Range(0,1)) = 0.0

        _SmoothRedMult("Smoothness Red Multiplier", Range(0,1)) = 0.0
        _SmoothGreenMult("Smoothness Green Multiplier", Range(0,1)) = 0.0
        _SmoothBlueMult("Smoothness Blue Multiplier", Range(0,1)) = 0.0

        _AOMap("AOMap", 2D) = "white" {}
        _AOStrength("AO Strength", Range(0,2)) = 1.0
        _AOAlbedoBlend("AO Albedo Blend", Range(0,1)) = 0.25
        _AORedMult("AO Red Multiplier", Range(0,1)) = 0.0
        _AOGreenMult("AO Green Multiplier", Range(0,1)) = 0.0
        _AOBlueMult("AO Blue Multiplier", Range(0,1)) = 0.0

        _BumpMap ("Bumpmap", 2D) = "normal" {}
        _DetailBumpMap ("Detail Bumpmap", 2D) = "normal" {}
        _DetailBumpScale ("Detail Bump Scale", Range(0,2)) = 0.25

        _Emissive("Emission",2D) = "black" {}
        _EmissiveColor("Emission Color",Color) = (0,0,0,0)

        _RimColor("Rim Color",Color) = (0,0,0,0)
        _TemperatureColor("Temperature Color",Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Stencil
        {
            Ref 1
            Comp Always
            Pass Replace
        }

        CGPROGRAM

        #include "LightingKSP.cginc"

        #pragma surface surf StandardKSP fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _MaskMap;
        sampler2D _AOMap;
        sampler2D _BumpMap;
        sampler2D _DetailBumpMap;
        sampler2D _Emissive;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float2 uv_DetailBumpMap;

            half4 color : COLOR;

            float3 viewDir;
        };

        half _Smoothness;
        half _MetalRedMult;
        half _MetalGreenMult;
        half _MetalBlueMult;
        half _AOStrength;
        half _AOAlbedoBlend;
        half _AORedMult;
        half _AOGreenMult;
        half _AOBlueMult;
        half _SmoothRedMult;
        half _SmoothGreenMult;
        half _SmoothBlueMult;
        half _DetailBumpScale;

        fixed4 _EmissiveColor;
        fixed4 _RimColor;
        fixed4 _TemperatureColor;

        #define RIM_MULT 0.5

        half SamplePackedRGB(fixed4 s, half rMult, half gMult, half bMult)
        {
            return saturate((s.r * rMult) + (s.g * gMult) + (s.b * bMult));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            fixed4 m = tex2D (_MaskMap, IN.uv_MainTex);
            fixed4 e = tex2D (_Emissive, IN.uv_MainTex) * _EmissiveColor;
            fixed4 ao = tex2D (_AOMap, IN.uv_MainTex);

            half3 mainNormal = UnpackNormalDXT5nm (tex2D (_BumpMap, IN.uv_BumpMap));
            half3 detailNormal = UnpackNormalDXT5nm (tex2D (_DetailBumpMap, IN.uv_DetailBumpMap));
            detailNormal.xy *= _DetailBumpScale;
            detailNormal = normalize(detailNormal);

            o.Normal = normalize(BlendNormals(mainNormal, detailNormal));
            o.Metallic = SamplePackedRGB(m, _MetalRedMult, _MetalGreenMult, _MetalBlueMult);
            o.Smoothness = SamplePackedRGB(m, _SmoothRedMult, _SmoothGreenMult, _SmoothBlueMult) * _Smoothness;

            half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
            half aoChannel = SamplePackedRGB(ao, _AORedMult, _AOGreenMult, _AOBlueMult);
            half aoApplied = saturate(lerp(1.0, aoChannel, _AOStrength));

            half3 baseAlbedo = c.rgb * IN.color.rgb;
            o.Albedo = lerp(baseAlbedo, baseAlbedo * aoChannel, _AOAlbedoBlend);
            o.Emission = (e.rgb * e.a) + (_RimColor.rgb * rim * RIM_MULT * _RimColor.a) + (_TemperatureColor.rgb * _TemperatureColor.a);
            o.Alpha = c.a;
            o.Occlusion = aoApplied;
        }
        ENDCG
    }
    FallBack "Diffuse"
}