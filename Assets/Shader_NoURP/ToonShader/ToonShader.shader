Shader "Unlit/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", COLOR)= (1,1,1,1)
        _RimSize("Rim Size", Range(0,1))=0.05
        _RimBlur("Rim Blur", Range(0,0.1))= 0.01
        _RimThreshold("Rim Threshold", Range(0.01,2))= 1
        _SpecularBlur("Specular Blur",Range(0.005,0.1)) =  0.01
        _DeffuseBlur("Deffuse Blur",Range(0,0.1)) =  0.01
        _AmbientLight("Ambient Light", COLOR) = (0.4,0.4,0.4,1)
        _Gloss("Gloss", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        
        //base pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define IS_IN_BASE_PASS
            //#pragma multi_compile_fwdbase

            #include "Assets\VkevShaderLib.cginc" 

            #include "VertFrag.cginc"
            ENDCG
        }

        //add pass
        Pass{
            Tags {"LightMode"= "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            //my library
            #include "Assets\VkevShaderLib.cginc" 

            //vert and frag shader func
            #include "VertFrag.cginc"
            
            
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
