using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class HalfToneEffect : MonoBehaviour {
    public Material Material;
    [Range(0, 200)]
    public float Frequency = 40;
    [Range(0, 1)]
    public float LowThresh = 0;
    [Range(0, 1)]
    public float HighThresh = 1;


    private Vector2 _screenSize = new Vector2();

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        _screenSize.x = src.width;
        _screenSize.y = src.height;
        Material.SetVector("_ScreenSize", _screenSize);
        Material.SetFloat("_Frequency", Frequency);
        Material.SetFloat("_LumThresh1", LowThresh);
        Material.SetFloat("_LumThresh2", HighThresh);
        Graphics.Blit(src, dest, Material);
    }
}
