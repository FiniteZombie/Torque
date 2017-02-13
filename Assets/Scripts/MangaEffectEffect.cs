using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MangaEffect : MonoBehaviour {
    public Material Material;
    [Range(0, 200)]
    public float Frequency = 40;

    private Vector2 _screenSize = new Vector2();

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        _screenSize.x = src.width;
        _screenSize.y = src.height;
        Material.SetVector("_ScreenSize", _screenSize);
        Material.SetFloat("_Frequency", Frequency);
        Graphics.Blit(src, dest, Material);
    }
}
