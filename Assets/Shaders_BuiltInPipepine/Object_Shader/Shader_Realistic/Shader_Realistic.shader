Shader "MyCustomShader/RealisticShader"
{
    Properties
    {
        _MainTex("Texure",2D) = "White"{}
        [NoScaleOffset]_NormalMap("Normal Map",2D) = "bump"{}
        _NormalIntensity("Normal Intensity", Range(0,1)) = 1
        [NoScaleOffset]_HeightMap("Height Map",2D) = "Gray"{}
        _HeightIntensity("Height Intensity", Range(0,0.3)) = 0.1
        [NoScaleOffset]_DiffuseIBL("Diffuse IBL Rectilinear Texture",2D) = "Black"{}
        [NoScaleOffset]_SpecularIBL("Specular IBL Rectilinear Texture",2D) = "Black"{}
        _SpecularIBLIntensity("SpecularIBL Intensity",Range(0,1))=1
        _Gloss("Glossiness", Range(0,1))= 1
        _ReflectionIntensity("Reflection Intensity",Range(0,5))=1
        _Animation("Animation speed", Range(-0.5,0.5)) = 0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //base pass
        Pass
        {
            Tags {"LightMode"= "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define IS_IN_BASE_PASS

            //my library
            #include "Assets\VkevShaderLib.cginc" 

            //vert and frag shader func
            #include "Realistic_VertFrag.cginc"


            
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
            #include "Realistic_VertFrag.cginc"
            
            
            
            ENDCG
        }

        
    }
}
