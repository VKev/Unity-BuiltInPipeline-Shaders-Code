


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #define TAU 6.28318531
            #define PI 3.1415926535

            float InverseLerp(float A, float B, float T){
{
                return (T - A)/(B - A);
            }
}

            float2 dirToRectilinear(float3 dir){
                float x = atan2(dir.z,dir.x)/TAU + 0.5;
                float y = dir.y*0.5 +0.5;
                return float2(x,y);
            }

            float2 RotateVector2(float2 v, float angle){
                float ca= cos(angle);
                float sa = sin(angle);
                return float2(ca+v.x-sa*v.y, sa*v.x+ca*v.y);
            }
            
            float3 DeffuseLight(float3 normal,float3 wPos){
                float3 N = normalize( normal);
                float3 L = normalize(UnityWorldSpaceLightDir(wPos)); // UnityWorldSpaceDir take wPos and return the vector from that pixel wpos to lightsrc
                float lambert =  clamp(  dot (N,L),0,1);
                float3 deffuseLight = lambert*_LightColor0.xyz;
                return deffuseLight;
            }
            float3 SpecularLight(float3 normal,float3 wPos, float _Gloss){
                float3 N = normalize( normal);
                float3 L = normalize(UnityWorldSpaceLightDir(wPos)); 
                float lambert =  clamp(  dot (N,L),0,1);
                float3 V= normalize(_WorldSpaceCameraPos - wPos);
                float3 H = normalize(L+V);
                float specularExponent = exp2(_Gloss*11)+2;
                float3 specularLight = saturate(dot(H,N))*(lambert>0);
                specularLight = pow(specularLight,specularExponent)*_LightColor0.xyz;
                return specularLight;
            }

