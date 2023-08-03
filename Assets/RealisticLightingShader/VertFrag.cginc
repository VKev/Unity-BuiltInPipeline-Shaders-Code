
 

struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
                float4 tangent : TANGENT;
            };




struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:TEXCOORD1;
                float3 wPos:TEXCOORD2;
                LIGHTING_COORDS(3,4)
                float3 tangent: TEXCOORD5;
                float3 biTangent: TEXCOORD6;
            };




sampler2D _MainTex;
sampler2D _NormalMap,_HeightMap;
sampler2D _DiffuseIBL,_SpecularIBL;

float4 _MainTex_ST;

float _Gloss;
float _ReflectionIntensity,_NormalIntensity,_HeightIntensity,_SpecularIBLIntensity;




v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);

                float heightMap = (tex2Dlod(_HeightMap, float4(o.uv,0,0)).rgb.x)*_HeightIntensity; 
                v.vertex.xyz += v.normal*heightMap;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);//convert normal to world space in vert shader
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz);// convert tangent to world space  in vert shader
                o.biTangent = cross(o.normal, o.tangent)* (v.tangent.w) * (unity_WorldTransformParams.w);// bitangent vector in world space
                                                                        //unity worldtransformparams is the transform component of mesh,
                                                                        //if we scale the mesh down to negative value, the param will return -1;

                o.wPos = mul(unity_ObjectToWorld,v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)// tranfer lighting data from vert shader to frag shader
                return o;
            }



float4 frag (v2f i) : SV_Target
            {
                float3 tex = tex2D(_MainTex,i.uv).rgb; 

                //convert the tangent space normal to world space normal
                float3 tangentSpace_Normal = UnpackNormal( tex2D(_NormalMap,i.uv));
                tangentSpace_Normal = normalize( lerp(float3(0,0,1),tangentSpace_Normal,_NormalIntensity));//float3(0,0,1) is normal vector up
                float3x3 matrixTangentToWorld = {
                    i.tangent.x, i.biTangent.x, i.normal.x,
                    i.tangent.y, i.biTangent.y, i.normal.y,
                    i.tangent.z, i.biTangent.z, i.normal.z

                };
                float3 worldSpace_Normal = mul(matrixTangentToWorld,tangentSpace_Normal);
                //end convertion
                
                
                float attenuation = LIGHT_ATTENUATION(i);// the value decrease if lightsrc is far away, if light src is DIRECTIONAL value is 1
               
                #ifdef IS_IN_BASE_PASS
                    float3 V = normalize(_WorldSpaceCameraPos - i.wPos);
                    float fresnel = pow( 1-saturate(dot(V,worldSpace_Normal)) , 5 );
                    float mipLevel = (1-_Gloss)*6;
                    float3 viewReflection = reflect(-V,worldSpace_Normal);
                    float3 specularIBL = tex2Dlod(_SpecularIBL, float4(dirToRectilinear( viewReflection),mipLevel,mipLevel) ).xyz;
                    specularIBL *= fresnel*_SpecularIBLIntensity;

                    float3 diffuseIBL = tex2Dlod(_DiffuseIBL, float4(dirToRectilinear( worldSpace_Normal),0,0) ).xyz;
                #else
                    float3 diffuseIBL = float3(0,0,0);
                    float3 specularIBL = float3(0,0,0);
                #endif
                
                float3 blinnPhong = (SpecularLight(worldSpace_Normal,i.wPos,_Gloss)+specularIBL)*_Gloss*_ReflectionIntensity 
                                  + (DeffuseLight(worldSpace_Normal,i.wPos)+diffuseIBL)*tex;
                blinnPhong *=attenuation;
                                   
                return float4(blinnPhong,1);
            }