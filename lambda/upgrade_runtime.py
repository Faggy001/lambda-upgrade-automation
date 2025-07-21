import boto3
import logging
import argparse
import json
import os

OUTDATED_RUNTIMES = {
    "python3.9": "python3.11",
    "nodejs12.x": "nodejs20.x"
}

def setup_logging():
    logging.basicConfig(
        format="%(asctime)s [%(levelname)s] %(message)s",
        level=logging.INFO
    )

def list_lambda_functions(region):
    client = boto3.client("lambda", region_name=region)
    paginator = client.get_paginator("list_functions")
    functions = []
    for page in paginator.paginate():
        functions.extend(page["Functions"])
    return functions

def update_runtime(function_name, new_runtime, region, dry_run=True):
    client = boto3.client("lambda", region_name=region)
    if dry_run:
        logging.info(f"[DRY-RUN] Would update {function_name} to {new_runtime}")
    else:
        client.update_function_configuration(
            FunctionName=function_name,
            Runtime=new_runtime
        )
        logging.info(f"✅ Updated {function_name} to {new_runtime}")

def run(region, dry_run):
    setup_logging()
    functions = list_lambda_functions(region)

    before = []
    after = []

    for fn in functions:
        current_runtime = fn["Runtime"]
        if current_runtime in OUTDATED_RUNTIMES:
            new_runtime = OUTDATED_RUNTIMES[current_runtime]
            before.append({
                "FunctionName": fn["FunctionName"],
                "OldRuntime": current_runtime
            })
            update_runtime(fn["FunctionName"], new_runtime, region, dry_run)
            after.append({
                "FunctionName": fn["FunctionName"],
                "NewRuntime": new_runtime
            })

    with open("/tmp/before.json", "w") as f:
        json.dump(before, f, indent=2)
    with open("/tmp/after.json", "w") as f:
        json.dump(after, f, indent=2)

    logging.info("📝 Saved before.json to /tmp/before.json")
    logging.info("📝 Saved after.json to /tmp/after.json")

    if functions and not before:
        logging.info("✅ Found %d Lambda functions — all up to date!", len(functions))
    elif before:
        logging.info("===== BEFORE UPDATE =====\n%s", json.dumps(before, indent=2))
        logging.info("===== AFTER UPDATE =====\n%s", json.dumps(after, indent=2))
    else:
        logging.warning("⚠️ No Lambda functions found in region: %s", region)


# 🔹 Lambda handler
def lambda_handler(event, context):
    region = os.environ.get("AWS_REGION", "ca-central-1")
    dry_run = event.get("dry_run", False) if isinstance(event, dict) else False
    run(region, dry_run)
    return {
        "statusCode": 200,
        "body": "Runtime check complete. Check CloudWatch Logs for results."
    }

# 🔹 CLI mode
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--region", default="ca-central-1", help="AWS region")
    parser.add_argument("--dry-run", action="store_true", help="Run without making changes")
    args = parser.parse_args()
    run(args.region, args.dry_run)
