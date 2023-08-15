using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using static UnityEngine.GraphicsBuffer;

public class CameraMovement : MonoBehaviour
{
    public float speed;
    public Transform target;

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKey(KeyCode.A))
            transform.RotateAround(target.position, transform.up, 1 * speed*Time.deltaTime);
        else if (Input.GetKey(KeyCode.D))
            transform.RotateAround(target.position, transform.up, -1 * speed * Time.deltaTime);

        if (Input.GetKey(KeyCode.W))
            GetComponent<Camera>().fieldOfView -= 1 * speed * Time.deltaTime;
        else if (Input.GetKey(KeyCode.S))
            GetComponent<Camera>().fieldOfView += 1 * speed * Time.deltaTime;
    }
}
