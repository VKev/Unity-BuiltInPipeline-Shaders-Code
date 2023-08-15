            float2 dirToRectilinear(float3 dir){
                float x = atan2(dir.z,dir.x)/TAU + 0.5;
                float y = dir.y*0.5 +0.5;
                return float2(x,y);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float3 viewDir : TEXCOORD0;
            };

            struct v2f
            {
                float3 viewDir : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewDir = v.viewDir;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2Dlod(_MainTex, float4(dirToRectilinear(i.viewDir),0,0));
                return col;
            }