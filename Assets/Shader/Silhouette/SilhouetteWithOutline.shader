Shader "Custom/SilhouetteWithOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SilhouetteColor ("SilhouetteColor", Color) = (1, 1, 1, 1)
        _OutLineOffset ("OutLineOffset", Range(0, 0.1)) = 0.02
        _OutLineColor ("OutlineColor", Color) = (0, 0, 0, 1)
        _ScrollSpeed("ScrollSpeed", float) = 1
        _ScrollX("ScrollX", Range(-1, 1)) = 1
        _ScrollY("ScrollY", Range(-1, 1)) = 0.5
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100
        
        Pass {
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float _OutLineOffset;
            float4 _OutLineColor;
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz + v.normal * _OutLineOffset);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return _OutLineColor;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _SilhouetteColor;
            float _ScrollSpeed;
            float _ScrollX;
            float _ScrollY;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 scroll = float2(_ScrollX, _ScrollY) * _Time.x * _ScrollSpeed;
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + scroll);

                // テクスチャのカラーと NTSC 係数の内積をとることでグレースケール画像を取得
                float gray = dot(col.rgb, float3(0.298912, 0.586611, 0.114478));
                float4 finalColor = _SilhouetteColor * gray;
                
                // apply fog
                finalColor.rgb = MixFog(finalColor.rgb, i.fogFactor);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
