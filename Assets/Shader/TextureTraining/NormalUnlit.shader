Shader "Custom/NormalUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal] _NormalTex("Normal Map", 2D) = "bump" {}
        _AmbientLight ("Ambient Light", Range(0, 0.3)) = 0.3
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
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
                float3 normal: NORMAL;
                float3 tangent: TEXCOORD1;
                float3 biNormal: TEXCOORD2;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normal: NORMAL;
                float3 tangent: TEXCOORD2;
                float3 biNormal: TEXCOORD3;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _AmbientLight;
            CBUFFER_END

            float3 CalcLambertDiffuse(float3 normal, float3 lightDir, float3 lightColor)
            {
                float t = dot(normal, lightDir);
                t = max(0.0f, t);
                return t * lightColor;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.tangent = normalize(TransformObjectToWorld(v.tangent));
                o.biNormal = normalize(TransformObjectToWorld(v.biNormal));
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // normal map
                float3 normal = i.normal;
                float3 localNormal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv));
                normal = i.tangent * localNormal.x + i.biNormal * localNormal.y + normal * localNormal.z;

                // light
                const Light light = GetMainLight();
                float3 diffuse = CalcLambertDiffuse(normal, light.direction, light.color);
                col.xyz *= diffuse + _AmbientLight;

                // apply fog
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
