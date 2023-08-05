using JetBrains.Annotations;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CameraPP : MonoBehaviour
{
    public Material OutlineMat;
    public Camera cam;
    private void Awake()
    {
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        
        Graphics.Blit(source, destination, OutlineMat);
    }
}
