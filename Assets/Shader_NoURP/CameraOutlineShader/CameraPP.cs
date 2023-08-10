using JetBrains.Annotations;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CameraPP : MonoBehaviour
{
    public Material OutlineMat;
    public Camera cam;

    Vector3 cameraAwakePos;
    private void Awake()
    {
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
        cameraAwakePos = transform.position;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        
        Matrix4x4 matrixCameraToWorld = cam.cameraToWorldMatrix;
        Matrix4x4 matrixProjectionInverse = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false).inverse;
        Matrix4x4 matrixHClipToWorld = matrixCameraToWorld * matrixProjectionInverse;

        Shader.SetGlobalMatrix("_MatrixHClipToWorld", matrixHClipToWorld);
        Graphics.Blit(source, destination, OutlineMat);
    }
    
}
