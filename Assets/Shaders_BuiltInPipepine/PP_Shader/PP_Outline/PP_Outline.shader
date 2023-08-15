Shader "MyCustomShader/PP_Outline"
{
    Properties
    {   
        _MainTex("Texture",2D) =  "White"{}
        _Scale ("Scale", float) = 1
        _OutlineColor("Outline Color", COLOR) = (0.5625,0.5625,0.5625,1)
        _NormalThreshold("Normal Threshold", Range(0,1))= 0.3
        _DepthThreshold("Depth Threshold",float)= 0.05

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
            #define IS_IN_BASE_PASS
            #define SAMPLES 10
            #define PI 3.14159265359
			#define E 2.71828182846
            #include "Assets\VkevShaderLib.cginc" 

            #include "Outline_VertFrag.cginc"
            ENDCG
        }
        
        

    }
}