import argparse
import logging
import subprocess
from pathlib import Path
import json
from typing_extensions import List
import os

TEMPLATE_PREFIX = "template_"
BASE_PATH = "Infra/IaaC/9_realms"

INIT_ERROR = 100
GET_PLAN_ERROR = 101
FAILED_APPLY = 102

"""
Utility for the commands
"""


def get_logger():
    FORMAT = f"[%(asctime)s] %(levelname)-8s %(message)s"
    logging.basicConfig(format=FORMAT, level=logging.INFO)
    return logging.getLogger("terraform")


def get_all_realms(base_path, logger: logging.Logger):
    realms = [
        {"name": d.name, "path": d.absolute()}
        for d in Path(base_path).iterdir()
        if d.is_dir() and not d.name.startswith(TEMPLATE_PREFIX)
    ]
    logger.debug("Found %s realms" % len(realms))

    for realm in realms:
        env = [e.name for e in realm["path"].iterdir() if e.is_dir()]
        logger.debug("Found %s environments for %s realm" % (len(env), realm["name"]))
        realm["envs"] = env

    return realms


def parse_skip(args: list[str]) -> list[tuple[str, str]]:
    if not args or len(args) == 0:
        return []

    parsed = []
    realms = get_all_realms(BASE_PATH, get_logger())

    for arg in args:
        split = arg.split(",")
        if len(split) != 2:
            raise Exception(f"Expected format `realm,env` got: {arg}")

        realm = split[0]
        env = split[1]

        found_realm = next(filter(lambda r: r["name"] == realm, realms), None)
        if found_realm is None:
            raise Exception(
                f"Unknown realm `{realm}`. Expected one of: {', '.join([realm['name'] for realm in realms])}"
            )

        found_env = next(filter(lambda e: e == env, found_realm["envs"]), None)
        if found_env is None:
            raise Exception(
                f"Unknown env `{env}` for realm `{realm}`. Expected one of: {', '.join([env for env in found_realm['envs']])}"
            )

        parsed.append((realm, env))

    return parsed


def init_env(env) -> subprocess.CompletedProcess[str]:
    args = ["terraform", "init"]
    return subprocess.run(
        args, text=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE, cwd=env
    )


def get_plan(env) -> subprocess.CompletedProcess[str]:
    args = [
        "terraform",
        "plan",
        "-no-color",
        "-detailed-exitcode",
        "-input=false",
        "-lock=false",
    ]
    return subprocess.run(
        args, text=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE, cwd=env
    )


def init_realms_with_exit(realms, logger: logging.Logger):
    logger.info("Running initializations...")
    all_failed_envs = []
    for realm in realms:
        for index, env in enumerate(realm["envs"]):
            logger.info(
                "%s. Initializing realm '%s' env '%s'" % (index, realm["name"], env)
            )
            output = init_env(realm["path"] / env)
            if output.returncode == 1:
                all_failed_envs.append((realm, env, output.stderr))

    if len(all_failed_envs) != 0:
        for realm, env, output in all_failed_envs:
            logger.error(
                "Failed to init realm %s for env '%s', reason:\n%s"
                % (realm["name"], env, output)
            )
        exit(INIT_ERROR)
    logger.info("Done initializing.")


def get_plans(realms, logger: logging.Logger) -> List[tuple[str, str, str]]:
    logger.info("Getting plans...")
    failed_envs = []
    successful_plans = []
    for realm in realms:
        for index, env in enumerate(realm["envs"]):
            logger.info(
                "%s. Calculating plan for realm '%s' env '%s'"
                % (index, realm["name"], env)
            )
            output = get_plan(realm["path"] / env)
            if output.returncode == 1:
                failed_envs.append((realm, env, output.stderr))
                continue
            elif output.returncode == 0:
                successful_plans.append((realm["name"], env, "No diff"))
            elif output.returncode == 2:
                successful_plans.append((realm["name"], env, output.stdout))

    if len(failed_envs) != 0:
        for realm, env, output in failed_envs:
            logger.error(
                "Failed to get plan for realm '%s' env '%s', reason:\n%s"
                % (realm["name"], env, output)
            )
        exit(GET_PLAN_ERROR)

    logger.info("Done getting plans.")
    return successful_plans


def get_filtered_realms(
    base_path,
    logger: logging.Logger,
    filter_realm: str | None,
    filter_env: str | None,
    skip: list[tuple[str, str]],
):
    realms = get_all_realms(BASE_PATH, logger)
    if filter_realm is not None:
        skip = []
        realms = [realm for realm in realms if realm["name"] == filter_realm]

    if filter_env is not None:
        skip = []
        for realm in realms:
            realm["envs"] = [env for env in realm["envs"] if env == filter_env]
        realms = [realm for realm in realms if len(realm["envs"]) != 0]

    for skip_realm, skip_env in skip:
        realm = next(filter(lambda realm: realm["name"] == skip_realm, realms), None)
        if realm is None:
            continue
        realm["envs"] = [env for env in realm["envs"] if env != skip_env]

    return realms


def apply_env(env) -> subprocess.CompletedProcess[str]:
    args = [
        "terraform",
        "apply",
        "-auto-approve=true",
        "-lock-timeout=30s",
        "-input=false",
    ]

    return subprocess.run(args, cwd=env, text=True)


"""
Top level commands
"""


def list(args):
    logger = get_logger()
    realms = get_all_realms(BASE_PATH, logger)
    if args.format == "json":
        print(json.dumps(realms, indent=4, sort_keys=True, default=str))
    elif args.format == "txt":
        for realm in realms:
            print(f"Realm {realm['name']} (abs path: {realm['path']})")
            for env in realm["envs"]:
                print(f"\t- Env: {env}")


def check(args):
    logger = get_logger()
    realms = get_filtered_realms(
        BASE_PATH, logger, args.realm, args.env, parse_skip(args.skip)
    )

    # First we init all realms. If we cannot init
    # all realms no need to proceed
    init_realms_with_exit(realms, logger)
    plans = get_plans(realms, logger)
    content = ""
    if args.format == "json":
        comapct = [
            {"realm": realm, "env": env, "diff": diff} for (realm, env, diff) in plans
        ]
        content = json.dumps(comapct, indent=4)
    elif args.format == "md":
        content = """## Terraform plans
{}
""".format(
            "\n".join(
                [
                    """### Realm `{}`, env `{}`
<details>

```bash
{}
```

</details>
""".format(
                        realm_name, env, output
                    )
                    for (realm_name, env, output) in plans
                ]
            )
        )

    print(content)


def apply(args):
    logger = get_logger()
    realms = get_filtered_realms(
        BASE_PATH, logger, args.realm, args.env, parse_skip(args.skip)
    )

    # First we init all realms. If we cannot init
    # all realms no need to proceed
    init_realms_with_exit(realms, logger)

    succeeded = 0
    failed = 0
    for realm in realms:
        for index, env in enumerate(realm["envs"]):
            logger.info(
                "%s. Applying realm '%s' env '%s' ..." % (index, realm["name"], env)
            )
            output = apply_env(realm["path"] / env)
            if output.returncode == 0:
                succeeded += 1
            else:
                logger.error(
                    "Failed applying realm '%s' env '%s' ..." % (realm["name"], env)
                )
                failed += 1

    logger.info("Total succeeded: %s", succeeded)
    logger.info("Total failed: %s", failed)
    if failed != 0:
        exit(FAILED_APPLY)


"""
Commands setup
"""


def args():
    parser = argparse.ArgumentParser(
        "terraform-ci",
        description="Tool for managing our infrastructure setup across multiple realms",
    )

    subparsers = parser.add_subparsers(
        title="subcomands", description="valid subcommands", help="sub-command help"
    )

    # Setup list command
    parser_list = subparsers.add_parser("list", help="Display all realms")
    parser_list.add_argument(
        "--format",
        choices=["json", "txt"],
        default="json",
        help="The format of the display",
        dest="format",
        type=str,
    )
    parser_list.set_defaults(func=list)

    realm_choices = [realm["name"] for realm in get_all_realms(BASE_PATH, get_logger())]

    # Setup check diff command
    parser_check_diff = subparsers.add_parser(
        "check-diff", help="Check which realms have diff which can be applied"
    )
    parser_check_diff.set_defaults(func=check)
    parser_check_diff.add_argument(
        "--realm",
        help="Run check for single realm, if `None` will run for all realms",
        default=None,
        choices=realm_choices,
        dest="realm",
    )
    parser_check_diff.add_argument(
        "--env",
        help="Run check for environments, if `None` will run for all environments",
        default=None,
        dest="env",
    )
    parser_check_diff.add_argument(
        "--format",
        help="Format used to dump the output",
        choices=["md", "json"],
        default="md",
        dest="format",
    )
    parser_check_diff.add_argument(
        "--skip",
        help="Skip `realm,env` pair. Conflicts with `--env` and `--realm`",
        default=[],
        dest="skip",
        action="append",
    )

    # Setup apply command
    parser_apply = subparsers.add_parser("apply", help="Apply the realms")
    parser_apply.set_defaults(func=apply)
    parser_apply.add_argument(
        "--realm",
        help="Run check for single realm, if `None` will run for all realms",
        default=None,
        choices=realm_choices,
        dest="realm",
    )
    parser_apply.add_argument(
        "--env",
        help="Run check for environments, if `None` will run for all environments",
        default=None,
        dest="env",
    )
    parser_apply.add_argument(
        "--skip",
        help="Skip `realm,env` pair. Conflicts with `--env` and `--realm`",
        default=[],
        dest="skip",
        action="append",
    )

    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    args()
