using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraSync : MonoBehaviour
{
    private Camera cam;
    public Camera syncCam;
    void Awake()
    {
        cam = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        cam.fieldOfView = syncCam.fieldOfView;
        cam.transform.position =syncCam.transform.position;
        cam.transform .rotation =syncCam.transform.rotation;
    }
}
