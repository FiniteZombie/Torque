using UnityEngine;

public class PlayerInput : MonoBehaviour {
    
    public float RoadSize;
    public float WheelPosition = .75f;
    public float WheelSize = .4f;
    public float Handling = 1f;
    public float MaxTurnAngle = 45f;

    private float hSpeed;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        var wheelPos = 0f;

        if (Input.touchCount > 0) {
            var touch = Input.GetTouch(0);
            wheelPos = GetWheelPosition(touch.position);
        }

        if (Input.GetMouseButton(0)) {
            wheelPos = GetWheelPosition(Input.mousePosition);
        }

        Steer(wheelPos);
	}

    void FixedUpdate() {
        var position = transform.position;
        position.x += hSpeed;
        position.x = Mathf.Clamp(position.x, -.5f * RoadSize, .5f * RoadSize);

        transform.position = position;
    }

    public float GetWheelPosition(Vector2 touchPosition) {
        var viewPos = touchPosition.x / Screen.width;
        var val = viewPos - WheelPosition;
        return val / WheelSize;
    }

    public void Steer(float amount) {
        hSpeed = Handling * amount;

        var turnAngle = MaxTurnAngle * amount;
        var carAngle = -90f + turnAngle;
        var rotation = Quaternion.Euler(0, carAngle, 0);
        transform.rotation = rotation;
    }
}
