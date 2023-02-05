Shader "Custom/Holo"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainBackgroundColor ("Main Background Color", Color) = (1, 1, 1, 1)
        _EdgeColor ("Edge Color", Color) = (1, 1, 1, 1)
        _HolographicTex ("Holographic Texture", 2D) = "white" {} // ホロのテクスチャ
        _HolographicGradationTex ("Holographic Gradation Texture", 2D) = "white" {}
        _MaskTexture ("Mask Texture", 2D) = "white" {}
        _Strength ("Strength", Float) = 1 // 模様の強さ
        _Tiling ("Tiling", Float) = 1
        _RotateCenterX ("CenterX", Float) = 0.5
        _RotateCenterY ("CenterY", Float) = 0.5
        _RotationDegree ("Rotation Degree", Float) = 45
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
            // Blend OneMinusDstColor One

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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 toEyeTS: TEXCOORD2;
                float3 normal: TEXCOORD3;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_HolographicTex);
            SAMPLER(sampler_HolographicTex);
            TEXTURE2D(_HolographicGradationTex);
            SAMPLER(sampler_HolographicGradationTex);
            TEXTURE2D(_MaskTexture);
            SAMPLER(sampler_MaskTexture);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _HolographicTex_ST;
            float _Strength;
            float _Tiling;
            float _RotateCenterX;
            float _RotateCenterY;
            float _RotationDegree;
            float4 _Color;
            float4 _MainBackgroundColor;
            float4 _EdgeColor;
            CBUFFER_END

            // タイリング・オフセット関数
            float2 TilingAndOffset(float2 uv, float2 tiling, float2 offset)
            {
                return uv * tiling + offset;
            }

            float3 Parallax(float tiling, float3 viewDirTS)
            {
                return mul(-tiling, viewDirTS);
            }

            float2 RotateDegree(float2 uv, float2 center, float rotationDegree)
            {
                float rotation = rotationDegree * (PI / 180.0f);
                uv -= center;
                float2x2 rotateMatrix = float2x2(cos(rotation), -sin(rotation), sin(rotation), cos(rotation));
                rotateMatrix *= 0.5;
                rotateMatrix += 0.5;
                rotateMatrix = rotateMatrix * 2 - 1;
                uv = mul(uv, rotateMatrix);
                uv += center;
                return uv;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorld(v.normal);
                float3 tangent = TransformObjectToWorld(v.tangent);
                float3 binormal = normalize(cross(v.normal, v.tangent) * v.tangent.w);
                binormal = TransformObjectToWorld(binormal);
                float3 toEyeWS = normalize(GetCameraPositionWS() - TransformObjectToWorld(o.vertex));
                float3x3 tangentToWorld = transpose(half3x3(tangent, binormal, o.normal));
                o.toEyeTS = TransformWorldToTangent(toEyeWS, tangentToWorld);
                
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // メインテクスチャをグレスケ変換し色を乗せる
                float4 main = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                const float grey = 0.298912f * main.r + 0.586611f * main.g + 0.114478f * main.b;
                main.rgb = grey * _Color;

                // ホロ部分
                float4 col = SAMPLE_TEXTURE2D(_HolographicTex, sampler_HolographicTex, TilingAndOffset(i.uv.xy, _HolographicTex_ST.xy, _HolographicTex_ST.zw));
                float3 distortion = _Strength * col;
                float3 distortion_paralax = distortion + Parallax(_Tiling, i.toEyeTS);
                float2 center = float2(_RotateCenterX, _RotateCenterY);
                float2 rainbowUv = RotateDegree(distortion_paralax.xy, center, _RotationDegree);
                float4 gradCol = SAMPLE_TEXTURE2D(_HolographicGradationTex, sampler_HolographicTex, rainbowUv.xy);

                // マスク画像を利用しパーツを判断
                float4 mask = SAMPLE_TEXTURE2D(_MaskTexture, sampler_MaskTexture, i.uv);
                /** マスクテクスチャからパーツを判断し色を決定
                 * 黒：カードのメインビジュアル部分
                 * 白：カードの枠部分
                 * その他：カードの土台
                 */
                float4 result =
                    mask.r <= 0 ? _MainBackgroundColor + gradCol * 0.02f:
                mask.r >= 1 ? _EdgeColor + gradCol: main + gradCol * 0.1f;
                
                // apply fog
                result.rgb = MixFog(result.rgb, i.fogFactor);
                return result;
            }
            ENDHLSL
        }
    }
}
