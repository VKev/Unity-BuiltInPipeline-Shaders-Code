Shader "Unlit/PP_FXAA_"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeThresholdMax("Edge threshold max", float) = 0.125
        _EdgeThresholdMin("Edge threshold min", float) = 0.0312
        _SubPixelQuality("SubPixel Quality", float) = 0.75
        _BlurSize ("Blur Size", float) = 1
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

            #define ITERATIONS 12

            #include "Assets/VkevShaderLib.cginc"

            #include "FXAA_LagVersion_VertFrag.cginc"
            ENDCG
        }
    }
}
