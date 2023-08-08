Shader "Unlit/OutlineShader"
{
    Properties
    {   
        _MainTex("Texture",2D) =  "White"{}
        _Scale ("Scale", float) = 1
        _OutlineColor("Outline Color", COLOR) = (0,0,0,0)
        _NormalThreshold("Normal Threshold", Range(0,1))= 1
        _DepthThreshold("Depth Threshold",float)= 0.04

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

            CGPROGRAM
            #pragma vertex Vert
            #pragma fragment frag
            
            #include "Assets\VkevShaderLib.cginc" 

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenSpace: TEXCOORD1;
                float3 normal: TEXCOORD2;
                float3 wPos:TEXCOORD3;
            };
                
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            sampler2D _CameraDepthTexture,_CameraDepthNormalsTexture;

            float4 _OutlineColor;
            float _Scale,_NormalThreshold,_DepthThreshold;

            float4x4 _MatrixHClipToWorld;
            v2f Vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenSpace = ComputeScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenSpaceUV = i.screenSpace.xy/i.screenSpace.w;// screenSpace UV
                float3 mainTex = tex2D(_MainTex,screenSpaceUV);
                float depthTex = tex2D(_CameraDepthTexture,screenSpaceUV);
                float depth = 1- Linear01Depth(depthTex);
                float halfScaleFloor = floor(_Scale * 0.5);
                float halfScaleCeil = ceil(_Scale * 0.5);
                 
                //depth shader
                //get neighbor pixel uv
                float2 bottomLeftScreenUV = screenSpaceUV - float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleFloor;
                float2 topRightScreenUV =screenSpaceUV + float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleCeil;  
                float2 bottomRightScreenUV = screenSpaceUV + float2(_MainTex_TexelSize.x * halfScaleCeil, -_MainTex_TexelSize.y * halfScaleFloor);
                float2 topLeftScreenUV = screenSpaceUV + float2(-_MainTex_TexelSize.x * halfScaleFloor, _MainTex_TexelSize.y * halfScaleCeil);

                
                //get neighbor depth value
                float depth0 = 1- Linear01Depth(tex2D(_CameraDepthTexture,bottomLeftScreenUV));
                float depth1 = 1- Linear01Depth(tex2D(_CameraDepthTexture,topRightScreenUV));
                float depth2 = 1- Linear01Depth(tex2D(_CameraDepthTexture,bottomRightScreenUV));
                float depth3 = 1- Linear01Depth(tex2D(_CameraDepthTexture,topLeftScreenUV));

                //compare depth different between 2 oposite pixel
                float depthFiniteDifference0 = depth1 - depth0;
                float depthFiniteDifference1 = depth3 - depth2;
                float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
                

                //Fresnel camera Texture:
                float fresnel;
                float3 screenSpaceNormal =  DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, screenSpaceUV)) ;

                if(depth >0){
                    //convert screenspace position to world position base on depth
                    float3 worldPos = ComputeWorldSpacePosition(screenSpaceUV, depthTex, _MatrixHClipToWorld) *float3(1,-1,1) ;

                    //convert view space normal of caemra to world space normal
                    float3 worldSpaceNormal = mul(unity_WorldToCamera,screenSpaceNormal)* float3(1,1,-1);

                    
                    float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                    fresnel =saturate( dot(viewDir,worldSpaceNormal));
                }else{
                    fresnel =0;
                }
                
                float normalThreshold = 1 + fresnel*(1-_NormalThreshold);
                float depthThreshold = _DepthThreshold*( 1 + fresnel) * depth ;



                //set depth value in only 1 and 0
 
                edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

                //get neighbor pixel normal value
                float3 screenSpaceNormal0 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, bottomLeftScreenUV));
                float3 screenSpaceNormal1 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, topRightScreenUV));
                float3 screenSpaceNormal2 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, bottomRightScreenUV));
                float3 screenSpaceNormal3 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, topLeftScreenUV));

                //compare normal different between 2 oposite pixel
                float3 normalFiniteDifference0 = screenSpaceNormal1 - screenSpaceNormal0;
                float3 normalFiniteDifference1 = screenSpaceNormal3 - screenSpaceNormal2;
                float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
               

                //set edge normal to onlyy 1 and 0
                edgeNormal = edgeNormal > normalThreshold ? 1 : 0;
                
                
                //merge btw edge normal and edge depth
                float edge = max(edgeDepth, edgeNormal);

                //merge camera scene texture and colorOutline with camera outline texture
                float3 col = lerp(mainTex,_OutlineColor.rgb,edge.xxx);

                

                

                return float4(col, 1);  
                
            }
            ENDCG
        }

    }
}