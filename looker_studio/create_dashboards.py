"""
Intelia Looker Studio Dashboard Creator
Copies the reference template three times (CCO, CPO, CTO) using Drive API,
then prints the edit URLs for each copy so you can update the data source.

Prerequisites:
  gcloud auth login --enable-gdrive-access
  pip install google-auth google-auth-httplib2 google-api-python-client

Usage:
  python looker_studio/create_dashboards.py
"""

import subprocess
import sys
import json

TEMPLATE_ID = "0dcc27d8-13a8-4025-b9dd-a09e1dd78bf1"
PROJECT_ID   = "vishal-sandpit-474523"

DASHBOARDS = [
    {
        "name":      "Intelia CCO Dashboard — Customer Health & Revenue",
        "bq_table":  "gold.rpt_cco_dashboard",
        "create_url": (
            "https://lookerstudio.google.com/c/reporting/create"
            "?c.mode=CREATE&ds.connector=BIG_QUERY&ds.type=TABLE"
            f"&ds.projectId={PROJECT_ID}&ds.datasetId=gold"
            "&ds.tableId=rpt_cco_dashboard"
            "&r.reportName=Intelia+CCO+Dashboard"
        ),
    },
    {
        "name":      "Intelia CPO Dashboard — Product Performance & Upsell",
        "bq_table":  "gold.rpt_cpo_dashboard",
        "create_url": (
            "https://lookerstudio.google.com/c/reporting/create"
            "?c.mode=CREATE&ds.connector=BIG_QUERY&ds.type=TABLE"
            f"&ds.projectId={PROJECT_ID}&ds.datasetId=gold"
            "&ds.tableId=rpt_cpo_dashboard"
            "&r.reportName=Intelia+CPO+Dashboard"
        ),
    },
    {
        "name":      "Intelia CTO Dashboard — Pipeline Health & Data Quality",
        "bq_table":  "governance.rpt_cto_dashboard",
        "create_url": (
            "https://lookerstudio.google.com/c/reporting/create"
            "?c.mode=CREATE&ds.connector=BIG_QUERY&ds.type=TABLE"
            f"&ds.projectId={PROJECT_ID}&ds.datasetId=governance"
            "&ds.tableId=rpt_cto_dashboard"
            "&r.reportName=Intelia+CTO+Dashboard"
        ),
    },
]


def get_token():
    result = subprocess.run(
        "gcloud auth print-access-token",
        shell=True,
        capture_output=True, text=True
    )
    return result.stdout.strip()


def copy_report(token, name):
    import urllib.request
    url = f"https://www.googleapis.com/drive/v3/files/{TEMPLATE_ID}/copy"
    body = json.dumps({"name": name}).encode()
    req = urllib.request.Request(
        url, data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return {"error": e.read().decode()}


def main():
    token = get_token()
    if not token:
        print("ERROR: Could not get access token. Run: gcloud auth login --enable-gdrive-access")
        sys.exit(1)

    print("\n=== Intelia Looker Studio Dashboard Creator ===\n")
    print("Attempting to copy reference template …")
    print(f"Template ID: {TEMPLATE_ID}\n")

    results = []
    for db in DASHBOARDS:
        resp = copy_report(token, db["name"])
        file_id = resp.get("id")
        error   = resp.get("error")

        if file_id:
            edit_url = f"https://lookerstudio.google.com/reporting/{file_id}/page/p_1"
            results.append({"name": db["name"], "id": file_id, "url": edit_url, "status": "copied"})
            print(f"  ✓ {db['name']}")
            print(f"    Report ID : {file_id}")
            print(f"    Edit URL  : {edit_url}")
            print(f"    BQ Table  : {db['bq_table']}")
            print()
        else:
            # Fall back to create URL (blank canvas connected to correct BQ table)
            results.append({"name": db["name"], "url": db["create_url"], "status": "create_url"})
            print(f"  ✗ {db['name']} — copy failed ({error})")
            print(f"    Use this 1-click URL instead (creates blank report with correct data source):")
            print(f"    {db['create_url']}")
            print()

    copied = [r for r in results if r["status"] == "copied"]
    if copied:
        print("─" * 70)
        print("NEXT STEP for copied reports:")
        print("  In Looker Studio: Resource > Manage added data sources > Edit")
        print(f"  Change data source to BigQuery > {PROJECT_ID} > [dataset] > [table]")
        print("  Then follow looker_studio/dashboards.yaml for chart specifications.")
    else:
        print("─" * 70)
        print("Template copy not available (Drive scope or sharing permissions).")
        print("Use the 1-click URLs above — each opens a blank canvas connected")
        print("to the correct BigQuery view, ready to add charts per dashboards.yaml")


if __name__ == "__main__":
    main()
