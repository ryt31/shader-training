Shader "Custom/PBRUnlit"
{
    Properties
    {
        _AlberoTex ("Albero Tex", 2D) = "white" {}
        _MetallicMap ("Metallic Map", 2D) = "white" {}
        _SmoothMap ("_Smooth Map", 2D) = "white" {}
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
                float3 toEye: TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normal: NORMAL;
                float3 toEye: TEXCOORD2;
            };

            TEXTURE2D(_AlberoTex);
            SAMPLER(sampler_AlberoTex);

            TEXTURE2D(_MetallicMap);
            SAMPLER(sampler_MetallicMap);

            TEXTURE2D(_SmoothMap);
            SAMPLER(sampler_SmoothMap);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _AlberoTex_ST;
            float _AmbientLight;
            CBUFFER_END

            float3 CalcDiffuseFromFresnel(float3 normal, float3 lightDir, float3 toEye)
            {
                float dotNL = saturate(dot(normal, lightDir));
                float dotNV = saturate(dot(normal, toEye));
                return (dotNL*dotNV);
            }

            // ベックマン分布の計算
            float Beckmann(float m, float t)
            {
                float t2 = t * t;
                float t4 = t * t * t * t;
                float m2 = m * m;
                float D = 1.0f / (4.0f * m2 * t4);
                D *= exp((-1.0f / m2) * (1.0f-t2)/ t2);
                return D;
            }

            // フレネルを計算
            float SpcFresnel(float f0, float u)
            {
                // from Schlick
                return f0 + (1-f0) * pow(1-u, 5);
            }

            float CookTorranceSpecular(float3 lightDir, float3 toEye, float3 noral, float metallic)
            {
                float microfacet = 0.76f;
                // 金属度を垂直入射の時のフレネル反射率として扱う
                // 金属度が高いほどフレネル反射は大きくなる
                float f0 = metallic;

                // ライトに向かうベクトルと視線に向かうベクトルのハーフベクトルを求める
                float3 H = normalize(lightDir + toEye);

                // 各種ベクトルがどれくらい似ているかを内積を利用して求める
                float NdotH = saturate(dot(noral, H));
                float VdotH = saturate(dot(toEye, H));
                float NdotL = saturate(dot(noral, lightDir));
                float NdotV = saturate(dot(noral, toEye));

                // D項をベックマン分布を用いて計算する
                float D = Beckmann(microfacet, NdotH);

                // F項をSchlick近似を用いて計算する
                float F = SpcFresnel(f0, VdotH);

                // G項を求める
                float G = min(1.0f, min(2*NdotH*NdotV/VdotH, 2*NdotH*NdotL/VdotH));

                // m項を求める
                float m = PI * NdotV * NdotH;

                // ここまで求めた、値を利用して、Cook-Torranceモデルの鏡面反射を求める
                return max(F * D * G / m, 0.0);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _AlberoTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.toEye = normalize(GetWorldSpaceViewDir(TransformObjectToWorld(v.vertex.xyz)));
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 albedoColor = SAMPLE_TEXTURE2D(_AlberoTex, sampler_AlberoTex, i.uv);
                float3 specColor = albedoColor;
                float metallic = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.uv).r;
                float smooth = SAMPLE_TEXTURE2D(_SmoothMap, sampler_SmoothMap, i.uv).r;

                Light light = GetMainLight();
                float3 lig = 0;
                float3 diffuseFromFrenel = CalcDiffuseFromFresnel(i.normal, light.direction, i.toEye);
                float NdotL = saturate(dot(i.normal, light.direction));
                float3 lambertDiffuse = light.color * NdotL / PI;
                float3 diffuse = albedoColor * diffuseFromFrenel * lambertDiffuse;
                float3 spec = CookTorranceSpecular(light.direction, i.toEye, i.normal, smooth) * light.color;
                spec *= lerp(float3(1.0f, 1.0f, 1.0f), specColor, metallic);
                lig += diffuse * (1.0f - smooth) + spec;
                lig += _AmbientLight * albedoColor;

                float4 finalColor = 1.0f;
                finalColor.xyz = lig;
                
                // apply fog
                finalColor.rgb = MixFog(finalColor.rgb, i.fogFactor);
                
                return finalColor;
            }
            ENDHLSL
        }
    }
}
