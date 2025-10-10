#!/usr/bin/python3
import requests
import argparse

parser = argparse.ArgumentParser(description="Manage GitHub Actions runners")
subparsers = parser.add_subparsers(dest="command", required=True)


get_parser = subparsers.add_parser("get", help="List all GitHub Actions runners")
get_parser.add_argument(
    "--token", required=True, help="GitHub token for authentication"
)
get_parser.add_argument("--org", default="BPSAfrica", help="GitHub organization name")
get_parser.add_argument("--runner_group", default="4", help="GitHub runner group ID")

delete_parser = subparsers.add_parser(
    "delete", help="Delete offline GitHub Actions runners"
)
delete_parser.add_argument(
    "--token", required=True, help="GitHub token for authentication"
)
delete_parser.add_argument(
    "--org", default="BPSAfrica", help="GitHub organization name"
)
delete_parser.add_argument("--runner_group", default="4", help="GitHub runner group ID")

args = parser.parse_args()

GITHUB_TOKEN = args.token
ORG_NAME = args.org
RUNNER_GROUP = args.runner_group


def fetch_all_runners():
    """Fetch all GitHub Actions runners."""
    url = f"https://api.github.com/orgs/{ORG_NAME}/actions/runner-groups/{RUNNER_GROUP}/runners"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
    }

    runners = []
    page_number = 1

    while url:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            fetched_runners = data.get("runners", [])
            runners.extend(fetched_runners)

            if "Link" in response.headers:
                links = response.headers["Link"]
                next_link = None
                for link in links.split(","):
                    if 'rel="next"' in link:
                        next_link = link[link.find("<") + 1 : link.find(">")]
                        break
                url = next_link
            else:
                url = None

            page_number += 1
        else:
            print(f"Failed to fetch runners. Status code: {response.status_code}")
            break

    return runners


def fetch_offline_runners():
    # Fetch only offline GitHub Actions runners
    all_runners = fetch_all_runners()
    offline_runners = [
        runner for runner in all_runners if runner["status"] == "offline"
    ]

    return offline_runners


def delete_runner(runner_id, headers):
    # Delete a specified GitHub Actions runner
    url = f"https://api.github.com/orgs/{ORG_NAME}/actions/runners/{runner_id}"
    response = requests.delete(url, headers=headers)
    if response.status_code == 204:
        print(f"Successfully deleted offline runner ID: {runner_id}")
    else:
        print(
            f"Failed to delete runner ID: {runner_id}. Status code: {response.status_code}"
        )


def main():
    if args.command == "get":
        all_runners = fetch_all_runners()
        for runner in all_runners:
            status = runner["status"]
            name = runner["name"]
            runner_id = runner["id"]
            print(f"  - {name} (ID: {runner_id}) - Status: {status}")

    elif args.command == "delete":
        offline_runners = fetch_offline_runners()

        if not offline_runners:
            print("No offline runners found to delete.")
            exit(0)
        print(f"Found {len(offline_runners)} offline runners to delete.")
        for runner in offline_runners:
            delete_runner(
                runner["id"], headers={"Authorization": f"token {GITHUB_TOKEN}"}
            )


if __name__ == "__main__":
    main()
