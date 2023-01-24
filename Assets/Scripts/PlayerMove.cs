using System.Collections.Generic;
using UnityEngine;

public class PlayerMove : MonoBehaviour
{
    [SerializeField]
    private List<Transform> points;
    [SerializeField] private float speed;
    private int _destIndex = 1;
    private Vector3 _destPos;
    
    private void Start()
    {
        transform.position = points[0].position;
        _destPos = points[_destIndex].position;
    }
    
    private void Update()
    {
        if (Vector3.Distance(_destPos, transform.position) >= 0.1)
        {
            var direction = Vector3.Normalize(_destPos - transform.position);
            transform.position += new Vector3(direction.x, 0.0f, direction.z) * speed; 
        }
        else
        {
            _destIndex++;
            _destPos = points[_destIndex % 3].position;
        }
    }
}
