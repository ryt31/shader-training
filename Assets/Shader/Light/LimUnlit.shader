Shader "Custom/LimUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Power ("Power", float) = 1.3
        _EnviromentLight ("Enviroment Light", Range(0, 0.3)) = 0.3
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normal: NORMAL;
                float3 eyeDir: TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Power;
            float _EnviromentLight;
            CBUFFER_END

            float3 CalcLambertDiffuse(float3 normal, float3 lightDir, float3 lightColor)
            {
                float t = dot(normal, lightDir);
                t = max(0.0f, t);
                return lightColor * t;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.eyeDir = normalize(GetViewForwardDir());
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                const Light light = GetMainLight();
                float power1 = 1.0f - max(0.0f, dot(normalize(-GetViewForwardDir()), i.normal));
                float power2 = 1.0f - max(0.0f, dot(-i.eyeDir, i.normal));
                float limPower = power1 * power2;
                limPower = pow(limPower, _Power);
                float3 limColor = limPower * light.color;
                float3 diffuse = CalcLambertDiffuse(i.normal, light.direction, light.color);
                col.xyz *= diffuse + _EnviromentLight + limColor;

                // apply fog
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
