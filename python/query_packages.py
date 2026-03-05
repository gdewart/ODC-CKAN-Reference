import ckanapi
import json
from pathlib import Path

BASE_URL = "https://data.ontario.ca/"
ORG_ID = "solicitor-general"

# Where to save the JSON results (edit the filename if needed)
OUTPUT_JSON = Path("latest_open_datasets.json")

# Create anonymous CKAN client for public data access
ckan = ckanapi.RemoteCKAN(BASE_URL)

try:
    # Primary search:
    # Retrieves the *most recently updated* open dataset from the target ministry.
    # - q="*" provides a broad match
    # - fq restricts to the ministry AND access_level=open
    # - rows=1 returns only the top record after sorting
    # - sort=metadata_modified desc orders newest → oldest
    resp = ckan.action.package_search(
        q="*",
        fq=f'organization:"{ORG_ID}" +access_level:"open"',
        rows=1,
        start=0,
        sort="metadata_modified desc",
        include_private=False
    )

    print("count:", resp["count"])               # Total items matching filter
    print("len(results):", len(resp["results"])) # Items returned (max 1 here)

    # Output minimal dataset objects for interoperability
    packages = [{"title": p["title"], "id": p["id"]} for p in resp["results"]]
    print(json.dumps(packages, indent=2))

    # --- Save JSON locally ---
    OUTPUT_JSON.write_text(json.dumps(packages, indent=2), encoding="utf-8")
    print(f"Saved JSON → {OUTPUT_JSON.resolve()}")

    # Fallback: if zero results appear (rare), re-run using only the essential filter.
    # This removes sorting and q=* to avoid edge-case behaviour in CKAN.
    if len(resp["results"]) == 0:
        print("No results. Retrying with minimal params…")

        resp = ckan.action.package_search(
            fq=f'organization:"{ORG_ID}" +access_level:"open"',
            rows=50     # Return more rows to ensure visibility
        )

        print("count:", resp["count"])
        print("len(results):", len(resp["results"]))

        packages = [{"title": p["title"], "id": p["id"]} for p in resp["results"]]
        print(json.dumps(packages, indent=2))

        # --- Save fallback JSON locally ---
        OUTPUT_JSON.write_text(json.dumps(packages, indent=2), encoding="utf-8")
        print(f"Saved fallback JSON → {OUTPUT_JSON.resolve()}")

finally:
    # Close client session
    ckan.close()