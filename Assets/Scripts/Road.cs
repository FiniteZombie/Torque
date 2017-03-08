using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Road : MonoBehaviour {

    public GameObject Light;
    public float Speed;
    public int LightCount;

    private GameObject[] _lights;
    private Renderer _renderer;
    private float _offset;

    private float _lightSpeed;
    private float _lightOffset;

    // Use this for initialization
    void Start () {
        _renderer = GetComponent<Renderer>();

        _lights = new GameObject[LightCount];
        _lights[0] = Light;

        for (int i = 1; i < LightCount; i++) {
            _lights[i] = Instantiate(Light);
        }
	}

    void FixedUpdate() {
        _offset -= Speed;

        if (_offset < 0f) {
            _offset = 1f;
        }

        _lightSpeed = 2f * Speed;
        _lightOffset -= _lightSpeed;

        if (_lightOffset < 0f) {
            _lightOffset = 1f;
        }
    }
	
	// Update is called once per frame
	void Update () {
        _renderer.material.SetTextureOffset("_MainTex", new Vector2(0, _offset));
        var lightMaxDistance = 50f;

        var worldOffset = _lightOffset * lightMaxDistance;
        var interval = lightMaxDistance / (LightCount - 1);

        for (int i = 0; i < LightCount; i++) {
            var position = Light.transform.position;
            var location = i * interval;
            var newPos = location + worldOffset;

            if (newPos > lightMaxDistance) {
                newPos = newPos - lightMaxDistance;
            }

            //Light.transform.position = new Vector3(position.x, position.y, worldOffset - 10f);
            _lights[i].transform.position = new Vector3(position.x, position.y, newPos - 10f);
        }
    }
}
