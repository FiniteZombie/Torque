using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Road : MonoBehaviour {

    [Range (-1f, 0f)]
    public float Offset;

    private Renderer _renderer;

    // Use this for initialization
    void Start () {
        _renderer = GetComponent<Renderer>();
	}
	
	// Update is called once per frame
	void Update () {
        _renderer.material.SetTextureOffset("_MainTex", new Vector2(0, Offset));
    }
}
