Shader "Custom/LightUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RefrectPower ("Refrect Power", Range(0.00001, 20.0)) = 5.0
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
                float3 toEye: TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _RefrectPower;
            float _EnviromentLight;
            CBUFFER_END

            float3 CalcLambertDiffuse(float3 normal, float3 lightDir, float3 lightColor)
            {
                float t = dot(normal, lightDir);
                t = max(0.0f, t);
                return lightColor * t;
            }

            float3 CalcPhongSpecular(float3 lightDir, float3 normal, float3 toEye,float3 lightColor)
            {
                float3 refVec = reflect(lightDir, normal);
                float t = dot(refVec, toEye);
                t = max(0, t);
                t = pow(t, _RefrectPower);
                return lightColor * t;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.toEye = normalize(GetWorldSpaceViewDir(TransformObjectToWorld(v.vertex.xyz)));
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                const Light light = GetMainLight();
                float3 diffuseLig = CalcLambertDiffuse(i.normal, light.direction, light.color);
                float3 specularLig = CalcPhongSpecular(-light.direction, i.normal, i.toEye, light.color);
                col.xyz *= diffuseLig + specularLig + float3(_EnviromentLight,_EnviromentLight,_EnviromentLight);
                // apply fog
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
