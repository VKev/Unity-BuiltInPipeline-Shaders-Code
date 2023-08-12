
            //unlit shader
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
                float3 normal:TEXCOORD1;
                float3 wPos:TEXCOORD2;
                #ifdef IS_IN_BASE_PASS
                   
                #else
                    LIGHTING_COORDS(3,4)
                #endif
            };
            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _AmbientLight,_Color;
            float _Gloss; 
            float _RimSize,_RimThreshold,_RimBlur;
            float _DeffuseBlur,_SpecularBlur;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wPos = mul( unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                #ifdef IS_IN_BASE_PASS
                     
                #else
                     TRANSFER_VERTEX_TO_FRAGMENT(o);// transfer light data to frag shader
                #endif
                return o;
            }


            float4 frag (v2f i) : SV_Target
            {
                float attenuation = 1;
                float3 N = normalize( i.normal);
                float3 V= normalize(_WorldSpaceCameraPos - i.wPos);
                float3 L = normalize(UnityWorldSpaceLightDir(i.wPos)); 
                float3 fresnel = 1-saturate(dot(N,V));
                float3 rim = smoothstep((1-_RimSize) - _RimBlur, (1-_RimSize) +_RimBlur, fresnel);
                rim *= fresnel*pow( saturate(dot(N,L)),_RimThreshold);

                float3 deffuseLight =  DeffuseLight(i.normal,i.wPos);
                deffuseLight = smoothstep(0,_DeffuseBlur, deffuseLight );
                
                #ifdef IS_IN_BASE_PASS
                    
                #else
                    attenuation = LIGHT_ATTENUATION(i);
                #endif
                
                

                float3 specularLight = SpecularLight(i.normal,i.wPos,_Gloss)*_Gloss;
                specularLight = smoothstep(0.005,_SpecularBlur,specularLight);



                float3 mainTex = tex2D(_MainTex, i.uv).rgb;
                float3 CelShading = _Color*(
                                    deffuseLight*mainTex*attenuation
                                    + _AmbientLight
                                    + specularLight*_Gloss*attenuation 
                                    + rim*attenuation                   ); 

               return float4(CelShading,1);


            }