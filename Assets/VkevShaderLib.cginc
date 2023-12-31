


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #define TAU 6.28318531
            #define PI 3.1415926535

            float InverseLerp(float4 A, float4 B, float4 T){
{
                return (T - A)/(B - A);
            }

}           float rgb2luma(float3 rgb){
                return sqrt(dot(rgb, float3(0.299, 0.587, 0.114)));//get luminosity of pixel
}
            float4 ShadowCoordCompute (float4 p)//p is world vertex ( UnityObjectToClipPos(v.vertex) ), this function same as ComputeScreenPos 
            {
                float4 o = p * 0.5;
                return float4(float2(o.x, o.y*_ProjectionParams.x) + o.w, p.zw);
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
                float lambert =  saturate(  dot (N,L));
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


            float4 ComputeClipSpacePosition(float2 positionNDC, float deviceDepth)
            {
                float4 positionCS = float4(positionNDC * 2.0 - 1.0, deviceDepth, 1.0);

                #if UNITY_UV_STARTS_AT_TOP
                // Our world space, view space, screen space and NDC space are Y-up.
                // Our clip space is flipped upside-down due to poor legacy Unity design.
                // The flip is baked into the projection matrix, so we only have to flip
                // manually when going from CS to NDC and back.
                positionCS.y = -positionCS.y;
                #endif

                return positionCS;
            }

            // device depth is float depth = tex2D(_CameraDepthTexture , screenUV)
            float3 ComputeWorldSpacePosition(float2 positionNDC, float deviceDepth, float4x4 invViewProjMatrix)
{
                float4 positionCS  = ComputeClipSpacePosition(positionNDC, deviceDepth);
                float4 hpositionWS = mul(invViewProjMatrix, positionCS);
                return hpositionWS.xyz / hpositionWS.w;
            }

            //return whether pixel is luma edge or not
            bool isLumaEdge(float2 uv, float scale,sampler2D mainTex,float4 mainTexTexelSize, float EdgeThresholdMin, float EdgeThresholdMax){
                float3 centerCol = tex2D(mainTex,uv);

                //calcualte the luminosity of current pixel
                float centerLuma = rgb2luma(centerCol);


                float ScaleFloor = floor(scale);


                //get neightbor UV coord
                float2 bottomScreenUV = uv - float2(0, mainTexTexelSize.y)*ScaleFloor;
                float2 topScreenUV =uv + float2(0, mainTexTexelSize.y)*ScaleFloor;  
                float2 rightScreenUV = uv + float2(mainTexTexelSize.x ,0)*ScaleFloor;
                float2 leftScreenUV = uv - float2(-mainTexTexelSize.x ,0)*ScaleFloor;

                float2 bottomLeftScreenUV =  uv - float2(mainTexTexelSize.x, mainTexTexelSize.y)*ScaleFloor ;
                float2 topRightScreenUV = uv + float2(mainTexTexelSize.x, mainTexTexelSize.y)*ScaleFloor ;  
                float2 bottomRightScreenUV =  uv + float2(mainTexTexelSize.x , -mainTexTexelSize.y )*ScaleFloor;
                float2 topLeftScreenUV =  uv + float2(-mainTexTexelSize.x , mainTexTexelSize.y )*ScaleFloor;

                //calculate luma of neightbor pixel
                float topLuma = rgb2luma(tex2D(mainTex,topScreenUV));
                float bottomLuma = rgb2luma(tex2D(mainTex,bottomScreenUV));
                float rightLuma = rgb2luma(tex2D(mainTex,rightScreenUV));
                float leftLuma = rgb2luma(tex2D(mainTex,leftScreenUV));
                    
                float bottomTopLuma = bottomLuma + topLuma;
                float leftRightLuma = leftLuma + rightLuma;

                // Find the maximum and minimum luma around the current fragment
                float lumaMin = min( centerLuma, min( min(bottomLuma,topLuma),  min(leftLuma,rightLuma) ) );
                float lumaMax = max( centerLuma, max( max(bottomLuma,topLuma),  max(leftLuma,rightLuma) ) );

                // Compute the difference btw min and max luma
                float lumaRange = lumaMax - lumaMin;

                //get only the luma of the edge pixel
                bool islumaEdge = lumaRange < max(EdgeThresholdMin,lumaMax*EdgeThresholdMax)? 1 : 0;
                return islumaEdge;
            }
