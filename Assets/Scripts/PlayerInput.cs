using UnityEngine;

public class PlayerInput : MonoBehaviour {
    
    public float RoadSize;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        if (Input.touchCount > 0) {
            var touch = Input.GetTouch(0);
            Touch(touch.position);
        }

        if (Input.GetMouseButton(0)) {
            Touch(Input.mousePosition);
        }
	}

    public void Touch(Vector2 touchPosition) {
        var position = transform.position;
        var viewPos = touchPosition.x / Screen.width;
        var roadPos = 2 * (viewPos - .5f);
        position.x = RoadSize * roadPos;
        transform.position = position;
    }
}
