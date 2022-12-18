using UnityEngine;
using UnityEngine.AI;
using UnityEngine.UI;

public class ClickToMove : MonoBehaviour
{
    NavMeshAgent agent;
    public LayerMask layerMask;

    public GameObject clickEffect;

    GameObject clickEffectSpawned;

    Animator anim;
    void Start()
    {
        agent = GetComponent<NavMeshAgent>();
        anim = GetComponent<Animator>();
    }

    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            RaycastHit hit;

            if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit, 100, layerMask))
            {

                agent.destination = hit.point;
                if (clickEffectSpawned == null)
                {
                    clickEffectSpawned = Instantiate(clickEffect);


                }
                clickEffectSpawned.transform.position = hit.point;
                clickEffectSpawned.SetActive(true);

            }


        }

        anim.SetFloat("velx", agent.velocity.magnitude);
    }
}