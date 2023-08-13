Shader "MyCustomShader/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", COLOR)= (0.6,0.6,0.6,1)
        _RimSize("Rim Size", Range(0,1))=0.2
        _RimBlur("Rim Blur", Range(0,0.1))= 0.01
        _RimThreshold("Rim Threshold", Range(0.01,10))= 2
        _SpecularBlur("Specular Blur",Range(0.005,0.1)) =  0.01
        _DeffuseBlur("Deffuse Blur",Range(0,0.1)) =  0.01
        _AmbientLight("Ambient Light", COLOR) = (0.3,0.3,0.3,1)
        _Gloss("Gloss", float) = 0.8
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //this toonshader only work for 1 DIRECTIONAL light in scene
        //base pass
        Pass
        {
            Tags{
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define IS_IN_BASE_PASS
            #include "Assets\VkevShaderLib.cginc" 
            #pragma multi_compile_fwdbase


            #include "VertFrag.cginc"
            ENDCG
        }

        //add pass
        Pass{
            Tags {"LightMode"= "ForwardAdd"}
            ZWrite Off Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows

            //my library
            #include "Assets\VkevShaderLib.cginc" 

            //vert and frag shader func
            #include "VertFrag.cginc"
            
            
            
            ENDCG
        } 
        
    }
    FallBack "Diffuse"
}
