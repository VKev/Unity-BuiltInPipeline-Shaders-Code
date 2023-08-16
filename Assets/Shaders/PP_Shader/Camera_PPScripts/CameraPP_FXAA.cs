
using System;
using UnityEngine;

public class CameraPP_FXAA : MonoBehaviour
{
	public Material FXAAMat;
	private Camera cam;

    private void Awake()
    {
        cam = GetComponent<Camera>();
        if (FXAAMat == null)
        {
            FXAAMat = new Material(Shader.Find("MyCustomShader/PP_FXAA"));
        }
    }

    public void OnRenderImage( RenderTexture source, RenderTexture destination )
	{
		float rcpWidth = 1.0f / Screen.width;
		float rcpHeight = 1.0f / Screen.height;

        FXAAMat.SetVector( "_rcpFrame", new Vector4( rcpWidth, rcpHeight, 0, 0 ) );
        FXAAMat.SetVector( "_rcpFrameOpt", new Vector4( rcpWidth * 2, rcpHeight * 2, rcpWidth * 0.5f, rcpHeight * 0.5f ) );

		Graphics.Blit( source, destination, FXAAMat);
	}
}



