"""
intro_ckan_ontario_metadata.py

Streamlined intro for learning how to query metadata from Ontario’s CKAN (https://data.ontario.ca).
Focus: clear concepts, minimal code, ready to run once you drop real IDs.

What you’ll learn (in order):
  1) CKAN core PACKAGE metadata (dataset-level, via package_show)
  2) CKAN core RESOURCE metadata (file/endpoint-level, via resource_show)
  3) Ontario custom PACKAGE metadata (extra fields, via package_search)
  4) Ontario custom RESOURCE metadata (extra fields, via resource_show)

How to use:
  • Replace the example IDs at the bottom and run the file.
  • Functions return raw dicts; use the brief_* helpers to see the essentials.
"""

import ckanapi
from typing import Dict, Any, List


# ================================================================
# CKAN client (Ontario public instance)
# ================================================================

BASE_URL = "https://data.ontario.ca/"


def _client() -> ckanapi.RemoteCKAN:
    """Create an anonymous CKAN Action API client."""
    return ckanapi.RemoteCKAN(BASE_URL)


# ================================================================
# 1) CKAN core: PACKAGE metadata (dataset)
# ================================================================

def get_core_package(package_id_or_name: str) -> Dict[str, Any]:
    """
    Fetch a dataset by id or slug.
    Typical fields: id, name, title, notes, metadata_created/modified,
    license_id, owner_org, organization{...}, tags[], groups[], resources[], extras
    """
    c = _client()
    try:
        return c.action.package_show(id=package_id_or_name)
    finally:
        c.close()


# ================================================================
# 2) CKAN core: RESOURCE metadata (file/endpoint)
# ================================================================

def get_core_resource(resource_id: str) -> Dict[str, Any]:
    """
    Fetch a resource by id.
    Typical fields: id, package_id, name, description, format, mimetype, url,
    size, created, last_modified, language, state, extras
    """
    c = _client()
    try:
        return c.action.resource_show(id=resource_id)
    finally:
        c.close()


# ================================================================
# 3) Ontario custom: PACKAGE metadata via search
# ================================================================

def search_ontario_packages(
    org_slug: str,
    rows: int = 10,
    open_only: bool = True
) -> List[Dict[str, Any]]:
    """
    Search Ontario packages for a ministry.
    Ontario extra fields often present: access_level, opened_date, current_as_of,
    update_frequency, geographic_coverage, access_instructions, maintainer_branch,
    exemption, exemption_rationale
    """
    c = _client()
    try:
        fq_parts = [f'organization:"{org_slug}"']
        if open_only:
            fq_parts.append('access_level:"open"')
        resp = c.action.package_search(
            q="*",
            fq=" +".join(fq_parts),
            sort="metadata_modified desc",
            rows=rows,
            include_private=False
        )
        return resp.get("results", [])
    finally:
        c.close()


# ================================================================
# 4) Ontario custom: RESOURCE metadata
#    (same call as core; Ontario fields appear inline if present)
# ================================================================

def get_ontario_resource(resource_id: str) -> Dict[str, Any]:
    """
    Fetch a resource; Ontario extra fields (if present): data_range_start,
    data_range_end, date_publicly_available, data_last_updated, created, type
    """
    return get_core_resource(resource_id)


# ================================================================
# Compact, readable summaries for quick learning
# ================================================================

def brief_package(pkg: Dict[str, Any]) -> Dict[str, Any]:
    org = pkg.get("organization") or {}
    return {
        # Core
        "id": pkg.get("id"),
        "name": pkg.get("name"),
        "title": pkg.get("title"),
        "organization": org.get("title"),
        "license_id": pkg.get("license_id"),
        "metadata_modified": pkg.get("metadata_modified"),
        "resource_count": len(pkg.get("resources", [])),
        # Ontario custom (may be absent)
        "access_level": pkg.get("access_level"),
        "opened_date": pkg.get("opened_date"),
        "current_as_of": pkg.get("current_as_of"),
        "update_frequency": pkg.get("update_frequency"),
    }


def brief_resource(res: Dict[str, Any]) -> Dict[str, Any]:
    return {
        # Core
        "id": res.get("id"),
        "package_id": res.get("package_id"),
        "name": res.get("name"),
        "format": res.get("format"),
        "url": res.get("url"),
        "size": res.get("size"),
        "created": res.get("created"),
        "last_modified": res.get("last_modified"),
        "language": res.get("language"),
        # Ontario custom (may be absent)
        "data_last_updated": res.get("data_last_updated"),
        "data_range_start": res.get("data_range_start"),
        "data_range_end": res.get("data_range_end"),
        "date_publicly_available": res.get("date_publicly_available"),
        "type": res.get("type"),
    }


# ================================================================
# Walkthrough — replace IDs and run
# ================================================================

if __name__ == "__main__":
    # Replace with real values before running:
    example_package_id = "your-package-id"     # dataset UUID or slug
    example_resource_id = "your-resource-id"   # resource UUID
    example_org_slug = "solicitor-general"     # ministry/org slug

    # 1) CKAN core package
    # pkg = get_core_package(example_package_id)
    # print("CKAN CORE PACKAGE\n", brief_package(pkg))

    # 2) CKAN core resource
    # res = get_core_resource(example_resource_id)
    # print("CKAN CORE RESOURCE\n", brief_resource(res))

    # 3) Ontario package search (top 3 newest open datasets for org)
    # pkgs = search_ontario_packages(example_org_slug, rows=3, open_only=True)
    # print("ONTARIO PACKAGE SEARCH")
    # for p in pkgs:
    #     print(brief_package(p))

    # 4) Ontario resource (Ontario fields appear if set)
    # ores = get_ontario_resource(example_resource_id)
    # print("ONTARIO RESOURCE\n", brief_resource(ores))

    pass