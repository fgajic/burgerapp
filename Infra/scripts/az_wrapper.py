import argparse
import subprocess
import logging
import os
from typing_extensions import List
from pathlib import Path
import json
import tempfile
import yaml
import datetime

TOP_LEVEL = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    text=True,
    check=True,
    stdout=subprocess.PIPE,
).stdout.strip()
DEVELOPMENT_RESOURCE_GROUP = "hes-development"
SKIP_CONTAINER_NAMES = ["admin-tools"]

FAILED_LOGIN = 100
FAILED_LIST_CONTAINER_APPS = 101
FAILED_JSON_DESERIALIZE = 102
FAILED_LOAD_FILE = 103
MALFORMED_ENV_FILE = 104
FAILED_LIST_CONTAINER_APP_REVISION = 105
FAILED_TO_APPLY_VERSIONS = 106

"""
Utility for the commands
"""


def find(arr, condition):
    return next((elem for elem in arr if condition(elem)), None)


def get_logger():
    FORMAT = f"[%(asctime)s] %(levelname)-8s %(message)s"
    logging.basicConfig(format=FORMAT, level=logging.INFO)
    return logging.getLogger("terraform")


def discover_env_files(env_files_dir: str) -> List[dict]:
    dir = Path(TOP_LEVEL) / env_files_dir

    return [
        {"name": os.path.basename(file).replace(".env", ""), "path": file.absolute()}
        for file in dir.iterdir()
        if file.is_file() and os.path.basename(file).endswith(".env")
    ]


def az_login(user, password, tenant, logger: logging.Logger):
    output = subprocess.run(
        [
            "az",
            "login",
            "--service-principal",
            "-u",
            user,
            "-p",
            password,
            "--tenant",
            tenant,
        ],
        text=True,
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
    )

    if output.returncode != 0:
        logger.error("Failed to login. Reason: %s", output.stderr)
        exit(FAILED_LOGIN)

    logger.info("Successful login!")
    logger.info("az output:\n%s" % output.stdout)


def fetch_latest_revision(
    logger: logging.Logger, container_name: str, resource_group: str
) -> str:
    output = subprocess.run(
        [
            "az",
            "containerapp",
            "revision",
            "list",
            "-n",
            container_name,
            "-g",
            resource_group,
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if output.returncode != 0:
        logger.error(
            "Failed to list container app revision for %s.\n%s",
            container_name,
            output.stderr,
        )
        exit(FAILED_LIST_CONTAINER_APP_REVISION)

    try:
        parsed = json.loads(output.stdout)
    except Exception:
        logger.error(
            "Failed to deserialize az output. Expected json. Got:\n%s", output.stdout
        )
        exit(FAILED_JSON_DESERIALIZE)

    sorted_revisions = sorted(
        parsed,
        key=lambda x: datetime.datetime.fromisoformat(x["properties"]["createdTime"]),
    )
    last = sorted_revisions[-1]
    last["name"] = container_name

    return last["properties"]["template"]["containers"][0]["image"]


def fetch_containers(logger: logging.Logger) -> List[tuple[dict, str]]:
    output = subprocess.run(
        ["az", "containerapp", "list", "-g", DEVELOPMENT_RESOURCE_GROUP],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if output.returncode != 0:
        logger.error("Failed to list container apps.\n%s", output.stderr)
        exit(FAILED_LIST_CONTAINER_APPS)

    try:
        parsed = json.loads(output.stdout)
    except Exception:
        logger.error(
            "Failed to deserialize az output. Expected json. Got:\n%s", output.stdout
        )
        exit(FAILED_JSON_DESERIALIZE)

    return [
        (
            container,
            fetch_latest_revision(
                logger, container["name"], DEVELOPMENT_RESOURCE_GROUP
            ),
        )
        for container in parsed
        if container["resourceGroup"] == DEVELOPMENT_RESOURCE_GROUP
    ]


def load_env_file(path, logger: logging.Logger) -> List[dict]:
    try:
        contents = ""
        with open(path, "r") as file:
            contents = file.readlines()
    except Exception as e:
        logger.error("Failed to load file %s, Error:\n%s" % (path, e))
        exit(FAILED_LOAD_FILE)

    # Removing comments from .env file
    contents = [
        line for line in contents if line.strip() and not line.strip().startswith("#")
    ]
    try:
        env = [
            {
                "name": line.split("=", maxsplit=1)[0].strip(),
                "value": line.split("=", maxsplit=1)[1].strip(),
            }
            for line in contents
        ]
    except Exception:
        logger.error("Malformed .env file %s" % path)
        exit(MALFORMED_ENV_FILE)

    return env


def update_container(container, logger: logging.Logger) -> bool:
    temp_file = tempfile.NamedTemporaryFile()
    logger.info("Tmp file path %s" % temp_file.name)
    try:
        contents = yaml.dump(container)
    except Exception as e:
        logging.error("Failed to serialize dict to yaml:\n%s" % e)
        return False

    temp_file.write(contents.encode())
    temp_file.flush()
    output = subprocess.run(
        [
            "az",
            "containerapp",
            "update",
            "--name",
            container["name"],
            "--resource-group",
            DEVELOPMENT_RESOURCE_GROUP,
            "--yaml",
            temp_file.name,
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if output.returncode != 0:
        logger.error(
            "Failed to update container app %s. Reason:\n%s"
            % (container["name"], output.stderr)
        )
        logger.error("Generated yaml:\n%s" % contents)
        return False

    return True


"""
Top level commands
"""


def deploy_containers(args):
    logger = get_logger()
    logger.info("Will deploy version '%s'" % args.version)
    files = discover_env_files(args.env_var_dir)
    containers = fetch_containers(logger)
    logger.info(
        "Found containers %s" % [container["name"] for (container, _) in containers]
    )

    to_update = []
    for container, latest_version in containers:
        latest_version = latest_version.split(":")[1]
        if latest_version == args.version:
            logger.info(
                "Container %s is already on version %s"
                % (container["name"], args.version)
            )
            continue
        if container["name"] in SKIP_CONTAINER_NAMES:
            logger.info("Container %s is explicitly skipped" % container["name"])
            continue
        logger.info(
            "Updating container %s from %s to %s",
            container["name"],
            latest_version,
            args.version,
        )
        to_update.append(container)

    for container in to_update:
        logger.info("Preparing container %s" % container["name"])
        file = find(files, lambda file: file["name"] == container["name"])
        if file is None:
            logger.warning(
                "Didn't find variable file for container %s" % container["name"]
            )
            logger.warning("Will just copy the existing variables")
        else:
            loaded_env = load_env_file(file["path"], logger)
            if len(loaded_env) != 0:
                container["properties"]["template"]["containers"][0]["env"] = loaded_env

        curr_image = str(container["properties"]["template"]["containers"][0]["image"])
        container["properties"]["template"]["containers"][0]["image"] = (
            curr_image.split(":")[0] + ":" + args.version
        )

    if args.dry_run:
        print(json.dumps(to_update, indent=4))
    else:
        outputs = [update_container(container, logger) for container in to_update]
        if not all(outputs):
            logger.error("Some container updates failed. Check the logs.")
            exit(FAILED_TO_APPLY_VERSIONS)


def login(args):
    logger = get_logger()
    az_login(args.username, args.password, args.tenant, logger)


def args():
    parser = argparse.ArgumentParser(
        "az-wrapper",
        description="Tool for automated operations with azure using az cli",
    )

    subparsers = parser.add_subparsers(
        title="subcomands", description="valid subcommands", help="sub-command help"
    )

    # Create revision for the container apps
    parser_apply = subparsers.add_parser(
        "create-revision",
        help="Create new revision for container apps in Development resource group",
    )
    parser_apply.add_argument(
        "version", help="Version to deploy to the containers", type=str
    )
    parser_apply.add_argument(
        "--env-file-dir",
        help="Environment file directory",
        default="Infra/dev-environment-variables",
        dest="env_var_dir",
    )
    parser_apply.add_argument(
        "--dry-run",
        help="Don't apply, just dump what would be applied",
        default=False,
        dest="dry_run",
        action="store_true",
    )
    parser_apply.set_defaults(func=deploy_containers)

    # Login with service principal to azure. Used in CI
    parser_login = subparsers.add_parser(
        "login", help="Login to azure using this wrapper"
    )
    parser_login.add_argument("username", help="Username for the account")
    parser_login.add_argument("password", help="Password for the account")
    parser_login.add_argument(
        "--tenant",
        help="Tenant to log into",
        dest="tenant",
        default="2852bfe7-c0a2-425e-96c2-033844a1d369",
    )
    parser_login.set_defaults(func=login)

    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    args()
