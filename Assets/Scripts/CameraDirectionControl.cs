using UnityEngine;

public class CameraDirectionControl : MonoBehaviour
{
    private Camera _camera;
    
    private Vector3 angle;

    private Vector3 primary_angle;

    
    private void Start()
    {
        _camera = GetComponent<Camera>();
        Cursor.visible = false;
        
        angle = this.gameObject.transform.localEulerAngles;

        primary_angle = this.gameObject.transform.localEulerAngles;
    }

    private void Update()
    {
        angle.y += Input.GetAxis("Mouse X");

        if ( angle.y <= primary_angle.y - 30f ) {
            angle.y = primary_angle.y - 30f;
        }
        if ( angle.y >= primary_angle.y + 30f ) {
            angle.y = primary_angle.y + 30f;
        }

        angle.x -= Input.GetAxis("Mouse Y");

        if ( angle.x <= primary_angle.x - 20f ) {
            angle.x = primary_angle.x - 20f;
        }
        if ( angle.x >= primary_angle.x + 20f ) {
            angle.x = primary_angle.x + 20f;
        }

        this.gameObject.transform.localEulerAngles = angle;
    }
}
