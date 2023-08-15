using JetBrains.Annotations;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CameraPP_Outline : MonoBehaviour
{
    public Material OutlineMat;
    private Camera cam;
    private void Awake()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        float rcpWidth = 1.0f / Screen.width;
        float rcpHeight = 1.0f / Screen.height;

        Matrix4x4 matrixCameraToWorld = cam.cameraToWorldMatrix;
        Matrix4x4 matrixProjectionInverse = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false).inverse;
        Matrix4x4 matrixHClipToWorld = matrixCameraToWorld * matrixProjectionInverse;

        Shader.SetGlobalMatrix("_MatrixHClipToWorld", matrixHClipToWorld);
        Graphics.Blit(source, destination, OutlineMat);
    }
    
}
