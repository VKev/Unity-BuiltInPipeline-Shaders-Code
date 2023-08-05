Shader "Unlit/OutlineShader"
{
    Properties
    {   
        _MainTex("Texture",2D) =  "White"{}
        _Scale ("Scale", float) = 1
        _OutlineColor("Outline Color", COLOR) = (0,0,0,0)
        _OutlineThreshold("Outline Threshold",float)= 1.5
        _NormalThreshold("Normal Threshold",float)= 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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
                float3 viewPos:TEXCOORD4;
            };
                
            sampler2D _MainTex,_CameraDepthTexture,_CameraDepthNormalsTexture;
            float4 _MainTex_ST,_OutlineColor;
            float4 _MainTex_TexelSize;
            float _Scale,_OutlineThreshold,_NormalThreshold;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenSpace = ComputeScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld,v.vertex);
                o.viewPos = WorldSpaceViewDir(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenSpaceUV = i.screenSpace.xy/i.screenSpace.w;// screenSpace UV
                float3 mainTex = tex2D(_MainTex,screenSpaceUV);
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
                
                //set depth value in only 1 and 0
                float depthThreshold = _OutlineThreshold * depth0;
                edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

                //get neighbor pixel normal value
                float3 normal0 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, bottomLeftScreenUV));
                float3 normal1 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, topRightScreenUV));
                float3 normal2 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, bottomRightScreenUV));
                float3 normal3 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, topLeftScreenUV));

                //compare normal different between 2 oposite pixel
                float3 normalFiniteDifference0 = normal1 - normal0;
                float3 normalFiniteDifference1 = normal3 - normal2;
                float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
               
                //set edge normal to onlyy 1 and 0
                edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;
                
                
                //merge btw edge normal and edge depth
                float edge = max(edgeDepth, edgeNormal);

                //merge camera scene texture and colorOutline with camera outline texture
                float3 col = lerp(mainTex,_OutlineColor.rgb,edge.xxx);

                return float4(col,0);
                
            }
            ENDCG
        }
    }
}