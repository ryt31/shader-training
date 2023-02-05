using UnityEngine;

public class CameraDirectionControl : MonoBehaviour
{
    private Camera _camera;
    
    private void Start()
    {
        _camera = GetComponent<Camera>();
        Cursor.visible = false;
    }

    private void Update()
    {
        var mousePos = Input.mousePosition;
        var target = _camera.ScreenToWorldPoint(new Vector3(mousePos.x, mousePos.y, 0.1f));
        transform.LookAt(new Vector3(target.x, target.y, 0) * 10.0f);
    }
}
