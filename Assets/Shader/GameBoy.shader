Shader "Custom/GameBoy"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PixelSize ("Pixel Size", Range(0.001, 0.1)) = 1.0
        _Color1 ("Color1", Color) = (1, 1, 1, 1)
        _Color2 ("Color2", Color) = (1, 1, 1, 1)
        _Color3 ("Color3", Color) = (1, 1, 1, 1)
        _Color4 ("Color4", Color) = (1, 1, 1, 1)
        _Alpha ("Alpha", Range(0, 1)) = 1
        _ScanLines ("Scan Lines", Range(0, 50)) = 30
        _ScanLineSpeed ("Scan Line Speed", Range(0, 20)) = 1
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
            float _PixelSize;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
            float _Alpha;
            float _ScanLines;
            float _ScanLineSpeed;
            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float ratioX = (int)(i.uv.x / _PixelSize) * _PixelSize;
                float ratioY = (int)(i.uv.y / _PixelSize) * _PixelSize;
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(ratioX, ratioY));

                // グレスケ変換
                const float grey = dot(col.rgb, float3(0.299, 0.587, 0.114));

                if (grey <= 0.25f)
                {
                    col = float4(_Color1.rgb, _Alpha);
                }

                if (0.25f < grey && grey <= 0.5f)
                {
                    col = float4(_Color2.rgb, _Alpha);
                }

                if (0.5f < grey && grey <= 0.75f)
                {
                    col = float4(_Color3.rgb, _Alpha);
                }

                if (0.75 < grey)
                {
                    col = float4(_Color4.rgb, _Alpha);
                }

                col *= abs(mul(frac(_Time.y * _ScanLineSpeed - i.uv.y * _ScanLines), 2) - 1);

                // apply fog
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
