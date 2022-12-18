using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CullingManager : MonoBehaviour
{

    public float m_occlusionCapsuleHeight = 0f;

    public float m_occlusionCapsuleRadius = 1f;

    // list of objects that will trigger the culling effect
    public List<GameObject> m_importantObjects = new List<GameObject>();

    // include the mouse in the important objects
    public bool m_includeMouse;

    public LayerMask m_layerMask;


    // List of all the objects that we've set to occluding state
    private List<Cullable> m_occludingObjects = new List<Cullable>();

    
    List<Cullable> cullableList = new List<Cullable>();


    

    // Update is called once per frame // Handle per frame logic
    public void Update()
    {
        // Can only do occlusion checks if we have a camera
        if (Camera.main != null)
        {
            // This is the list of positions we're trying not to occlude
            List<Vector3> importantPositions = FindImportantPositions();

            // This is the list of objects whihc are in the way
            List<Cullable> newOccludingObjects = FindOccludingObjects(importantPositions);

            SetOccludingObjects(newOccludingObjects);
        }
    }

    private List<Vector3> FindImportantPositions()
    {
        List<Vector3> positions = new List<Vector3>();


        // All units are important
        foreach (GameObject unit in m_importantObjects)
        {
            positions.Add(unit.transform.position);
        }


        if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out RaycastHit hit, 100, m_layerMask) && m_includeMouse)
        {
            Vector3 mousePos = hit.point;
            if (!positions.Contains(mousePos))
            {
                positions.Add(mousePos);
            }
        }

        return positions;
    }

    // Update the stored list of occluding objects
    private void SetOccludingObjects(List<Cullable> newList)
    {
        foreach (Cullable cullable in newList)
        {
            int foundIndex = m_occludingObjects.IndexOf(cullable);

            if (foundIndex < 0)
            {
                // This object isnt in the old list, so we need to mark it as occluding
                cullable.Occluding = true;
            }
            else
            {
                // This object was already in the list, so remove it from the old list
                m_occludingObjects.RemoveAt(foundIndex);
            }
        }

        // Any object left in the old list, was not in the new list, so it's no longer occludding
        foreach (Cullable cullable in m_occludingObjects)
        {
            cullable.Occluding = false;
        }

        m_occludingObjects = newList;
    }

    private List<Cullable> FindOccludingObjects(List<Vector3> importantPositions)
    {
        List<Cullable> occludingObjects = new List<Cullable>();


        Camera camera = Camera.main;

        // We want to do a capsule check from each position to the camera, any cullable object we hit should be culled
        foreach (Vector3 pos in importantPositions)
        {
            Vector3 capsuleStart = (pos);
            capsuleStart.y += m_occlusionCapsuleHeight;

            Collider[] colliders = Physics.OverlapCapsule(capsuleStart, camera.transform.position, m_occlusionCapsuleRadius, m_layerMask, QueryTriggerInteraction.Ignore);

            // Add cullable objects we found to the list
            foreach (Collider collider in colliders)
            {
                Cullable cullable = collider.GetComponent<Cullable>();
                Debug.Assert(cullable != null, "Found an object on the occlusion layer without the occlusion component!");

                if (!occludingObjects.Contains(cullable))
                {
                    occludingObjects.Add(cullable);
                }
            }
        }

        return occludingObjects;
    }
}
