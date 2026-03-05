import ckanapi
import json
from pathlib import Path

BASE_URL = "https://data.ontario.ca/"
ORG_ID = "solicitor-general"  # replace as needed

# Local JSON output path (edit filename/path as needed)
OUTPUT_JSON = Path("ontario_pkg_with_resources.json")

ckan = ckanapi.RemoteCKAN(BASE_URL)

def normalize_resource(res):
    """Safely extract core resource metadata."""
    if not isinstance(res, dict):
        return {}
    return {
        "id": res.get("id"),
        "name": res.get("name") or res.get("title"),
        "format": res.get("format"),
        "mimetype": res.get("mimetype"),
        "language": res.get("language"),
        "url": res.get("url"),
        "size": res.get("size"),
        "last_modified": res.get("last_modified"),
        "state": res.get("state"),
        "created": res.get("created"),
        "description": res.get("description"),
    }

def summarize_package(pkg):
    """Summarize dataset + all resource metadata."""
    if not isinstance(pkg, dict):
        return {}
    org = pkg.get("organization") or {}
    return {
        "package": {
            "id": pkg.get("id"),
            "title": pkg.get("title"),
            "organization_id": org.get("id"),
            "organization_title": org.get("title"),
            "access_level": pkg.get("access_level"),
            "license_id": pkg.get("license_id"),
            "opened_date": pkg.get("opened_date"),
            "metadata_modified": pkg.get("metadata_modified"),
        },
        "resources": [normalize_resource(r) for r in pkg.get("resources", [])],
    }

try:
    # Primary search: latest open dataset in the org (newest first)
    resp = ckan.action.package_search(
        q="*",
        fq=f'organization:"{ORG_ID}" +access_level:"open"',
        rows=1,
        start=0,
        sort="metadata_modified desc",
        include_private=False,
    )

    print("count:", resp.get("count"))
    print("len(results):", len(resp.get("results", [])))

    results = resp.get("results", [])

    # Fallback: if nothing returned, try a minimal filter with more rows
    if len(results) == 0:
        print("No results. Retrying with minimal params…")
        resp = ckan.action.package_search(
            fq=f'organization:"{ORG_ID}" +access_level:"open"',
            rows=50
        )
        results = resp.get("results", [])
        print("count:", resp.get("count"))
        print("len(results):", len(results))

    # Build dataset + resource metadata structure
    output = [summarize_package(p) for p in results]

    # Print to console (human-readable)
    print(json.dumps(output, indent=2))

    # Save to local JSON file
    OUTPUT_JSON.write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(f"Saved JSON → {OUTPUT_JSON.resolve()}")

finally:
    ckan.close()