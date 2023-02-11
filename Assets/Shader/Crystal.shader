Shader "Custom/Crystal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Color1", Color) = (1, 1, 1, 1)
        _Color2 ("Color2", Color) = (1, 1, 1, 1)
        _GradOffset ("Grad Offset", Range(0, 0.99)) = 0
        _RefractionStrength ("Refraction Strength", float) = 1
        _FresnelStrength ("Fresnel Strength", float) = 1
        _Opacity ("Opacity", Range(0, 1)) = 1
        _Glow ("Glow", float) = 1
        _Alpha ("Alpha", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #define F0 0.2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 positionOBJ : TEXCOORD2;
                float3 normal: TEXCOORD3;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color1;
            float4 _Color2;
            float _GradOffset;
            float _RefractionStrength;
            float _FresnelStrength;
            float _Opacity;
            float _Glow;
            float _Alpha;
            CBUFFER_END

            float fresnelEffect(float vdotn)
            {
                return F0 + (1.0f - F0) * pow(1.0f - vdotn, 5);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.positionOBJ = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorld(v.normal);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float inverseLerp = (i.positionOBJ.g - (1.0f - _GradOffset)) / (0.0f - (1.0f - _GradOffset));
                float4 gradCol = lerp(_Color1, _Color2, saturate(inverseLerp));

                float2 screenPos = GetNormalizedScreenSpaceUV(i.vertex);
                float3 viewDir = normalize(i.vertex - TransformObjectToWorld(GetCurrentViewPosition()));
                float fresnel = fresnelEffect(dot(viewDir, i.normal));
                float3 refraction = mul(-mul(TransformWorldToView(i.normal), fresnel + 0.1f), _RefractionStrength);
                screenPos += refraction;
                float3 sceneColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenPos);

                float opacity = saturate(mul(fresnel, _FresnelStrength) + _Opacity);

                float3 col = mul(lerp(sceneColor, gradCol, opacity), _Glow);

                // apply fog
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return float4(col, _Alpha);
            }
            ENDHLSL
        }
    }
}