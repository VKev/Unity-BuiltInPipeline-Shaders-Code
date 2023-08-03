Shader "Unlit/OutlineShader"
{
    Properties
    {   
        _MainTex("Texture",2D) = "White"{}
        _Scale ("Scale", float) = 1
        _CameraFarPlaneDistance("Camera Far-Plane distance",float)=100
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
            };
                
            sampler2D _MainTex,_CameraDepthTexture;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _Scale,_CameraFarPlaneDistance;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenSpace = ComputeScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenSpaceUV = i.screenSpace.xy/i.screenSpace.w;// screenSpace UV
                float3 tex = tex2D(_MainTex,i.uv);
                float halfScaleFloor = floor(_Scale * 0.5);
                float halfScaleCeil = ceil(_Scale * 0.5);

                float2 bottomLeftScreenUV = screenSpaceUV - float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleFloor;
                float2 topRightScreenUV =screenSpaceUV + float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleCeil;  
                float2 bottomRightScreenUV = screenSpaceUV + float2(_MainTex_TexelSize.x * halfScaleCeil, -_MainTex_TexelSize.y * halfScaleFloor);
                float2 topLeftScreenUV = screenSpaceUV + float2(-_MainTex_TexelSize.x * halfScaleFloor, _MainTex_TexelSize.y * halfScaleCeil);

                float depth0 = 1- Linear01Depth(tex2D(_CameraDepthTexture,bottomLeftScreenUV));
                float depth1 = 1- Linear01Depth(tex2D(_CameraDepthTexture,topRightScreenUV));
                float depth2 = 1- Linear01Depth(tex2D(_CameraDepthTexture,bottomRightScreenUV));
                float depth3 = 1- Linear01Depth(tex2D(_CameraDepthTexture,topLeftScreenUV));

                float depthFiniteDifference0 = depth1 - depth0;
                float depthFiniteDifference1 = depth3 - depth2;
                float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
                float depthThreshold = 1.5 * depth0;
                edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

                return float4(edgeDepth.xxx,0);
            }
            ENDCG
        }
    }
}