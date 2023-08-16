            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                 
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST,_MainTex_TexelSize;

            float _EdgeThresholdMax,_EdgeThresholdMin,_SubPixelQuality;

            float _BlurSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                return o;
            }

            float Quality(int i){
                if(i==2){
                    return 1.5;
                }
                else if(i>2 && i <=6){
                    return 2;
                }else if(i >6 && i <7){
                    return 4;
                }
                return 8;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 centerCol = tex2D(_MainTex,i.uv);

                //calcualte the luminosity of current pixel
                float centerLuma = rgb2luma(centerCol);


                //get neightbor UV coord
                float2 bottomScreenUV = i.uv - float2(0, _MainTex_TexelSize.y)*_BlurSize;
                float2 topScreenUV =i.uv + float2(0, _MainTex_TexelSize.y)*_BlurSize;  
                float2 rightScreenUV = i.uv + float2(_MainTex_TexelSize.x ,0)*_BlurSize;
                float2 leftScreenUV = i.uv - float2(-_MainTex_TexelSize.x ,0)*_BlurSize;

                float2 bottomLeftScreenUV =  i.uv - float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y)*_BlurSize ;
                float2 topRightScreenUV = i.uv + float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y)*_BlurSize ;  
                float2 bottomRightScreenUV =  i.uv + float2(_MainTex_TexelSize.x , -_MainTex_TexelSize.y )*_BlurSize;
                float2 topLeftScreenUV =  i.uv + float2(-_MainTex_TexelSize.x , _MainTex_TexelSize.y )*_BlurSize;

                //calculate luma of neightbor pixel
                float topLuma = rgb2luma(tex2D(_MainTex,topScreenUV));
                float bottomLuma = rgb2luma(tex2D(_MainTex,bottomScreenUV));
                float rightLuma = rgb2luma(tex2D(_MainTex,rightScreenUV));
                float leftLuma = rgb2luma(tex2D(_MainTex,leftScreenUV));
                    
                float bottomTopLuma = bottomLuma + topLuma;
                float leftRightLuma = leftLuma + rightLuma;

                // Find the maximum and minimum luma around the current fragment
                float lumaMin = min( centerLuma, min( min(bottomLuma,topLuma),  min(leftLuma,rightLuma) ) );
                float lumaMax = max( centerLuma, max( max(bottomLuma,topLuma),  max(leftLuma,rightLuma) ) );

                // Compute the difference btw min and max luma
                float lumaRange = lumaMax - lumaMin;

                //get only the luma of the edge pixel
                bool islumaEdge = lumaRange < max(_EdgeThresholdMin,lumaMax*_EdgeThresholdMax)? 1 : 0;

                float3 finalColor;
                if(islumaEdge){
                
                    float bottomLeftLuma = rgb2luma(tex2D(_MainTex, bottomLeftScreenUV));
                    float bottomRightLuma = rgb2luma(tex2D(_MainTex, bottomRightScreenUV));
                    float topLeftLuma = rgb2luma(tex2D(_MainTex, topLeftScreenUV));
                    float topRightLuma = rgb2luma(tex2D(_MainTex, topRightScreenUV));

                    float leftCornerLuma = bottomLeftLuma + topLeftLuma;
                    float bottomCornerLuma = bottomLeftLuma + bottomRightLuma;
                    float rightCornerLuma = bottomRightLuma + topRightLuma;
                    float topCornerLuma = topRightLuma + topLeftLuma;

                    // detect vertical edge or horizontal edge
                    float edgeHorizontal =  abs(-2.0 * leftLuma + leftCornerLuma)  
                                          + abs(-2.0 * centerLuma + bottomTopLuma ) * 2.0    
                                          + abs(-2.0 * rightLuma + rightCornerLuma);
                    float edgeVertical =    abs(-2.0 * topLuma + topCornerLuma)      
                                          + abs(-2.0 * centerLuma + leftRightLuma) * 2.0  
                                          + abs(-2.0 * bottomLuma + bottomCornerLuma);

                    bool isHorizontal = (edgeHorizontal >= edgeVertical);
                

                    //detect if current pixel is horizontal? if it is, luma1 and luma2 will be the vertical luma
                    //                                       else , luma1 and luma2 will be the horizontal luma
                    float luma1 = isHorizontal ? bottomLuma : leftLuma;
                    float luma2 = isHorizontal ? topLuma : rightLuma;

                    // find difference of luminosity of the luma1 and luma2
                    float gradient1 = luma1 - centerLuma;
                    float gradient2 = luma2 - centerLuma;

                    // find greater difference of gradient1 and gradient2?
                    bool is1Steepest = abs(gradient1) >= abs(gradient2);

                    // normalize the max gradient.
                    float gradientScaled = 0.25*max(abs(gradient1),abs(gradient2));

                    // Choose the step size (one pixel) according to the edge direction.
                    // can also call the blur size
                    float stepLength = isHorizontal ? _MainTex_TexelSize.y*_BlurSize : _MainTex_TexelSize.x*_BlurSize;

                    // Average luma in the correct direction.
                    float lumaLocalAverage = 0.0;

                    if(is1Steepest){
                        // Switch the direction
                        stepLength = - stepLength;
                        lumaLocalAverage = 0.5*(luma1 + centerLuma);
                    } else {
                        lumaLocalAverage = 0.5*(luma2 + centerLuma);
                    }
                
                    float2 currentUV = i.uv;
                    if(isHorizontal){
                        currentUV.y += stepLength * 0.5;
                    } else {
                        currentUV.x += stepLength * 0.5;
                    }


                    float2 _Offset = isHorizontal ? float2(_MainTex_TexelSize.x,0) : float2(0,_MainTex_TexelSize.y);
                    // Compute UVs to explore on each side of the edge, orthogonally. The QUALITY allows us to step faster.
                    float2 uv1 = currentUV - _Offset;
                    float2 uv2 = currentUV + _Offset;

                    // Read the lumas at both current extremities of the exploration segment, and compute the delta wrt to the local average luma.
                    float lumaEnd1 = rgb2luma(tex2D(_MainTex,uv1));
                    float lumaEnd2 = rgb2luma(tex2D(_MainTex,uv2));
                    lumaEnd1 -= lumaLocalAverage;
                    lumaEnd2 -= lumaLocalAverage;
                
                    bool reached1 = abs(lumaEnd1) >= gradientScaled;
                    bool reached2 = abs(lumaEnd2) >= gradientScaled;
                    bool reachedBoth = reached1 && reached2;

                    // If the side is not reached, we continue to explore in this direction.
                    if(!reached1){
                        uv1 -= _Offset;
                    }
                    if(!reached2){
                        uv2 += _Offset;
                    } 

                    if(!reachedBoth){

                        for(int i = 2; i < ITERATIONS; i++){
                            // If needed, read luma in 1st direction, compute delta.
                            if(!reached1){
                                lumaEnd1 = rgb2luma(tex2D(_MainTex,uv1));
                                lumaEnd1 -= lumaLocalAverage;
                            }
                            // If needed, read luma in opposite direction, compute delta.
                            if(!reached2){
                                lumaEnd2 = rgb2luma(tex2D(_MainTex,uv2));
                                lumaEnd2 -= lumaLocalAverage;
                            }
                            // If the luma deltas at the current extremities is larger than the local gradient, we have reached the side of the edge.
                            reached1 = abs(lumaEnd1) >= gradientScaled;
                            reached2 = abs(lumaEnd2) >= gradientScaled;
                            reachedBoth = reached1 && reached2;

                            // If the side is not reached, we continue to explore in this direction, with a variable quality.
                            if(!reached1){
                                uv1 -= _Offset * Quality(i);
                            }
                            if(!reached2){
                                uv2 += _Offset * Quality(i);
                            }

                            // If both sides have been reached, stop the exploration.
                            if(reachedBoth){ 
                                break;
                            }
                        }
                    }

                    // Compute the distances to each extremity of the edge.
                    float distance1 = isHorizontal ? (i.uv.x - uv1.x) : (i.uv.y - uv1.y);
                    float distance2 = isHorizontal ? (uv2.x - i.uv.x) : (uv2.y - i.uv.y);

                    // In which direction is the extremity of the edge closer ?
                    bool isDirection1 = distance1 < distance2;
                    float distanceFinal = min(distance1, distance2);

                    // Length of the edge.
                    float edgeThickness = (distance1 + distance2);

                    // UV offset: read in the direction of the closest side of the edge.
                    float pixelOffset = - distanceFinal / edgeThickness + 0.5;

                    // Is the luma at center smaller than the local average ?
                    bool isLumaCenterSmaller = centerLuma < lumaLocalAverage;

                    // If the luma at center is smaller than at its neighbour, the delta luma at each end should be positive (same variation).
                    // (in the direction of the closer side of the edge.)
                    bool correctVariation = ((isDirection1 ? lumaEnd1 : lumaEnd2) < 0.0) != isLumaCenterSmaller;

                    // If the luma variation is incorrect, do not offset.
                    float finalOffset = correctVariation ? pixelOffset : 0;

                    float lumaAverage = (1.0/12.0) * (2.0 * (bottomTopLuma + leftRightLuma) + leftCornerLuma + rightCornerLuma);
                    // Ratio of the delta between the global average and the center luma, over the luma range in the 3x3 neighborhood.
                    float subPixelOffset1 = clamp(abs(lumaAverage - centerLuma)/lumaRange, 0, 1);
                    float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
                    // Compute a sub-pixel offset based on this delta.
                    float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * _SubPixelQuality;

                    // Pick the biggest of the two offsets.
                    finalOffset = max(finalOffset,subPixelOffsetFinal);

                    float2 finalUV = i.uv;
                    if(isHorizontal){
                        finalUV.y += finalOffset * stepLength;
                    } else {
                        finalUV.x += finalOffset * stepLength;
                    }

                    finalColor = tex2D(_MainTex,finalUV);
                }else{
                    finalColor = tex2D(_MainTex,i.uv);
                }
                return fixed4(finalColor,1);
          }