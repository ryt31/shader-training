Shader "Custom/Shadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowTex ("Shadow Texture", 2D) = "white" {}
        _ShadowColor ("Shadow Color", Color) = (1, 1, 1, 1)
        _ScrollX("ScrollX", Range(-1, 1)) = 1
        _ScrollY("ScrollY", Range(-1, 1)) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
                float3 posWS: TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_ShadowTex);
            SAMPLER(sampler_ShadowTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _ShadowColor;
            float _ScrollX;
            float _ScrollY;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                const float2 scroll = float2(_ScrollX, _ScrollY) * _Time.x; // スクロール方向のベクトル
                float4 shadowTex = SAMPLE_TEXTURE2D(_ShadowTex, sampler_ShadowTex, i.uv + scroll);
                const float4 shadowCoord = TransformWorldToShadowCoord(i.posWS); // シャドウマップの uv を取得
                
                // シャドウマップをサンプリング
                ShadowSamplingData lightShadowSamplingData = GetMainLightShadowSamplingData();
                half4 shadowParams = GetMainLightShadowParams();
                float4 shadow = SampleShadowmap(
                    TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture),
                    shadowCoord, lightShadowSamplingData, shadowParams, false);
                
                if (shadow.r < 1)
                {
                    const float grey = 0.298912f * shadowTex.r + 0.586611 * shadowTex.g + 0.114478 * shadowTex.b;
                    shadow.rgb = grey * _ShadowColor;
                }
                
                // apply fog
                col.rgb = MixFog(col.rgb, i.fogFactor);
                
                return col * shadow;
            }
            ENDHLSL
        }
    }
}
