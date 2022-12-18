using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class AfterImage : MonoBehaviour
{
    [SerializeField]
    bool RandomColor;
    [SerializeField]
    float delay;
    [SerializeField]
    string fadeProperty = "_Fade";
    [SerializeField]
    GameObject presetObj;
    [SerializeField]
    int poolSize = 1000;
    [SerializeField]
    Rigidbody rb;
    Renderer[] renderers;
    [SerializeField]
    float fadeSpeed = 3f;
    float[] fadeTimers;
    float timer;
    SkinnedMeshRenderer[] skinRenderers;
    MeshRenderer[] meshRenderers;
    MaterialPropertyBlock props;
    Matrix4x4 matrix;
    CombineInstance[] combine;
    List<GameObject> objectPool;
    MeshFilter[] poolMeshFilters;
    MeshFilter[] meshFilters;


    void Start()
    {
        SetUpRenderers();

        // create a pool for all the objects for the trail
        objectPool = new List<GameObject>();
        poolMeshFilters = new MeshFilter[poolSize];
        renderers = new Renderer[poolSize];
        props = new MaterialPropertyBlock();
        fadeTimers = new float[poolSize];

        // instantiate the pool of objects
        for (int i = 0; i < poolSize; i++)
        {
            GameObject obj = Instantiate(presetObj);
            poolMeshFilters[i] = obj.GetComponent<MeshFilter>();
            renderers[i] = obj.GetComponent<Renderer>();
            // renderers[i].material = dodgeMat;
            obj.SetActive(false);
            objectPool.Add(obj);
        }
    }

    void SetUpRenderers()
    {
        // get the skinned mesh renderers
        skinRenderers = transform.GetComponentsInChildren<SkinnedMeshRenderer>();
        // get normal mesh renderers and their filters
        meshRenderers = transform.GetComponentsInChildren<MeshRenderer>();
        meshFilters = new MeshFilter[meshRenderers.Length];
        for (int i = 0; i < meshRenderers.Length; i++)
        {
            meshFilters[i] = meshRenderers[i].GetComponent<MeshFilter>();
        }
        // create combineinstances for every mesh we need to grab
        combine = new CombineInstance[skinRenderers.Length + meshRenderers.Length];
    }



    void Update()
    {

        timer -= Time.deltaTime;

        // only create image if moving and timer is down
        if (timer < 0 && rb.velocity.magnitude > 0.1f)
        {
            timer = delay;
            CreateAfterImage();
        }

        // fade the property block
        for (int i = 0; i < poolSize; i++)
        {
            fadeTimers[i] -= Time.deltaTime * fadeSpeed;
            renderers[i].GetPropertyBlock(props);
            props.SetFloat(fadeProperty, fadeTimers[i]);
            renderers[i].SetPropertyBlock(props);

        }

    }



    // get a gameobject from the pool, and its index
    public (GameObject, int) GetPooledObject()
    {
        for (int i = 0; i < objectPool.Count; i++)
        {
            if (!objectPool[i].activeInHierarchy)
            {
                return (objectPool[i], i);
            }
        }
        return (null, -1);
    }

    void CreateAfterImage()
    {
        // grab a pooled object
        (GameObject, int) obj = GetPooledObject();
        // if no object to assign, return
        if (obj.Item1 == null)
        {
            return;
        }
        // current transform matrix
        matrix = transform.worldToLocalMatrix;
        //  create mesh snapshot for all skinned meshes       
        for (int i = 0; i < skinRenderers.Length; i++)
        {
            Mesh mesh = new Mesh();
            skinRenderers[i].BakeMesh(mesh);
            combine[i].mesh = mesh;
            combine[i].transform = matrix * skinRenderers[i].localToWorldMatrix;
        }
        // also add normal meshes
        for (int i = 0; i < meshRenderers.Length; i++)
        {
            combine[skinRenderers.Length + i].mesh = meshFilters[i].sharedMesh;
            combine[skinRenderers.Length + i].transform = matrix * meshRenderers[i].transform.localToWorldMatrix;
        }

        // set property block
        fadeTimers[obj.Item2] = 1f;
        renderers[obj.Item2].GetPropertyBlock(props);
        props.SetFloat(fadeProperty, fadeTimers[obj.Item2]);
        if (RandomColor)
        {
            props.SetColor("_Color", Random.ColorHSV(0, 1, 0.5f, 1, 1, 1));
        }

        renderers[obj.Item2].SetPropertyBlock(props);

        // combine meshes into the right instance
        poolMeshFilters[obj.Item2].mesh.CombineMeshes(combine);

        // set object to transform and active
        obj.Item1.transform.position = transform.position;
        obj.Item1.transform.rotation = transform.rotation;
        obj.Item1.SetActive(true);

        StartCoroutine(DisableClone(obj.Item1));

    }
    IEnumerator DisableClone(GameObject objec)
    {
        yield return new WaitForSeconds(3f);
        objec.SetActive(false);
    }

}
