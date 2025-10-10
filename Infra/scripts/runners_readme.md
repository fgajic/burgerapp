**Explanation of runner.py script usage**

The script has two arguments: get and delete and 3 flags: --token(required), --org(optional), --runner\_group(optional)



**Usage:**&#x20;

* **get:**

```txt
python runners.py get --token <token_value> --org(optional) --runner_group(optional)
```

* The script will list all runners with their container ID, runner ID and status in this manner:&#x9;

```txt
- <container_id1> (ID: <runner1_ID>) - Status: {online|offline}
- <container_id2> (ID: <runner2_ID>) - Status: {online|offline}
- <container_id3> (ID: <runner3_ID>) - Status: {online|offline}
```

* **delete:**

```txt
python runners.py delete --token <token_value> --org(optional) --runner_group(optional)
```

* The script will delete all runners with offline status and list them in this manner:

```txt
Successfully deleted offline runner ID: <runner1_ID>
Successfully deleted offline runner ID: <runner2_ID>
Successfully deleted offline runner ID: <runner3_ID>
```
