import argparse
import json
import logging
import os
import sys
from typing import Dict, List


logging.basicConfig(
    stream=sys.stderr,
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)


def generate_matrix(
    realms_dir: str, skip_realms: List[str], skip_envs: Dict[str, List[str]]
):
    matrix = {"include": []}

    logging.info(f"Scanning realms directory: {realms_dir}")

    for realm in os.listdir(realms_dir):
        realm_path = os.path.join(realms_dir, realm)

        if not os.path.isdir(realm_path):
            logging.warning(f"Skipping file {realm_path}, not a directory.")
            continue

        if realm in skip_realms:
            logging.info(f"Skipping realm: {realm}")
            continue

        for env in os.listdir(realm_path):
            env_path = os.path.join(realm_path, env)

            if not os.path.isdir(env_path):
                logging.warning(f"Skipping file {env_path}, not a directory.")
                continue

            if realm in skip_envs and env in skip_envs[realm]:
                logging.info(f"Skipping {env} environment for realm {realm}")
                continue

            logging.debug(f"Adding realm={realm}, environment={env} to matrix.")
            matrix["include"].append({"realm": realm, "environment": env})

    logging.info(f"Generated matrix with {len(matrix['include'])} items.")
    print(json.dumps(matrix, separators=(",", ":")))


def parse_skipped_envs(skip_envs: List[str]) -> Dict[str, List[str]]:
    skip = {}
    for entry in skip_envs:
        if "=" not in entry:
            logging.error(
                f"Invalid format for --skip-envs: '{entry}'. Expected 'realm=env1,env2'."
            )
            exit(1)

        try:
            realm, envs = entry.split("=")
            skip[realm] = envs.split(",")
        except ValueError:
            logging.error(
                f"Failed to parse --skip-envs: '{entry}'. Ensure correct format 'realm=env1,env2'."
            )
            exit(1)
    return skip


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Terraform Matrix strategy")
    parser.add_argument("--realms-dir", required=True, help="Path to realms directory")
    parser.add_argument(
        "--skip-realms",
        default=[],
        nargs="+",
        help="List of realms to skip (space-separated)",
    )
    parser.add_argument(
        "--skip-envs",
        default=[],
        nargs="+",
        help="List of env to skip (space-separated) format 'realm=env1,env2'",
    )

    args = parser.parse_args()

    if not os.path.isdir(args.realms_dir):
        logging.error(f"Invalid realms directory: {args.realms_dir}")
        exit(1)

    skip_envs = parse_skipped_envs(args.skip_envs)

    try:
        generate_matrix(args.realms_dir, args.skip_realms, skip_envs)
    except Exception as e:
        logging.critical(f"Unexpected error: {e}", exc_info=True)
        exit(1)
