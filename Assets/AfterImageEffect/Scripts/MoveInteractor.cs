using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveInteractor : MonoBehaviour
{

    Vector3 moveDirection;
    float horizontal;
    float vertical;
    Rigidbody rb;
    [SerializeField]
    float moveSpeed;

    [SerializeField]
    Animator animator;
    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        moveDirection = Vector3.zero;
        // get vertical and horizontal movement input (controller and WASD/ Arrow Keys)
        vertical = Input.GetAxis("Vertical");
        horizontal = Input.GetAxis("Horizontal");
        Vector3 correctedVertical = vertical * Camera.main.transform.forward;
        Vector3 correctedHorizontal = horizontal * Camera.main.transform.right;

        Vector3 combinedInput = correctedHorizontal + correctedVertical;
        moveDirection = new Vector3((combinedInput).normalized.x, 0, (combinedInput).normalized.z);


        RotateToDir();
        if (animator != null)
        {
            animator.SetFloat("Velocity", Mathf.Lerp(animator.GetFloat("Velocity"), rb.velocity.magnitude, Time.deltaTime * 10f));
        }
    }

    void RotateToDir()
    {
        Vector3 targetDir = moveDirection;
        targetDir.y = 0;

        if (targetDir == Vector3.zero)
        {
            targetDir = transform.forward;
        }
        Quaternion tr = Quaternion.LookRotation(targetDir);

        Quaternion targetRotation = Quaternion.Slerp(transform.rotation, tr, Time.deltaTime * 10f);
        transform.rotation = targetRotation;
    }

    private void FixedUpdate()
    {
        rb.velocity = (moveDirection * moveSpeed);
    }
}
