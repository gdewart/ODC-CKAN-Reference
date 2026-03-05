filename: README.md
content: |
  # Ontario Open Data CKAN Query Helpers

  A compact Python + R toolkit for querying Ontario’s CKAN-powered Open Data Catalogue. It helps you retrieve datasets (packages) and files/endpoints (resources) and provides a tight schema reference for consistent queries.

  ---

  ## What is CKAN?

  CKAN is an open-source data portal platform with:
  - **Action API** for metadata (e.g., `package_show`, `resource_show`, `package_search`)
  - **Datastore API** for tabular sql data (e.g., `datastore_search`, `datastore_search_sql`)

  Terminology:
  - **Package (Dataset):** Top-level record describing a dataset (title, description, organization, tags, licence). Each package contains resources.
  - **Resource (File/Endpoint):** An individual file or access link (CSV/XLSX/JSON/PDF/WEB) that belongs to a package.
  - **Datastore:** CKAN’s table backend for resources; supports queries, filters, and SQL-like access.

  Ontario Open Data (https://data.ontario.ca) runs on CKAN and includes Ontario-specific fields (e.g., `access_level`, `opened_date`, `current_as_of`) alongside core CKAN fields.

  ---

  ## Key Terminology

- **Package (Dataset):** Descriptive record; includes a `resources` list.
- **Resource (File/Endpoint):** File or link; often includes `format`, `url`, `size`, `last_modified`.
- **Organization (Publisher):** Ministry/agency; filter with `organization:"{org_slug}"`.
- **Core fields (CKAN):** Standard fields like `id`, `name`, `title`, `metadata_modified`, `license_id`.
- **Ontario custom fields:** Additional fields like `access_level`, `opened_date`, `current_as_of`, `update_frequency`.
- **Datastore:** Use `datastore_search` / `datastore_search_sql` on tabular resources; some operations may require an API key.

---

## Quick Start

### Python
```python
pip install ckanapi

import ckanapi
  BASE_URL = "https://data.ontario.ca/"
  ckan = ckanapi.RemoteCKAN(BASE_URL)

  # Single dataset (includes resources list)
  pkg = ckan.action.package_show(id="your-package-id-or-slug")

  # Search datasets by org (Ontario fields included where present)
  resp = ckan.action.package_search(q="*", fq='organization:"your-org-slug"', rows=10)
  results = resp["results"]
```
### R
```r
install.packages("ckanr")
  library(ckanr)
  ckanr_setup(url = "https://data.ontario.ca/")

  # Single dataset
  pkg <- package_show("your-package-id-or-slug")

  # Search datasets by org
  res <- package_search(q="*", fq='organization:"your-org-slug"', rows=10)
  pkgs <- res$results
```

## Project Directory

**File overview (quick purpose):**

- `python/query_helper.py` — Basic CKAN connection utilities.
- `python/query_introduction.py` — Quick intro to CKAN + Ontario fields.
- `python/query_packages.py` — Package queries (`package_show`, `package_search`).
- `python/query_resources.py` — Resource queries (`resource_show`).

- `r/query_helper.r` — R equivalents of helper utilities.
- `r/query_introduction.r` — Intro examples in R.
- `r/query_packages.r` — Package queries in R.
- `r/query_resources.r` — Resource queries in R.

- `query_schema.yaml` — Compact schema for CKAN core + Ontario fields.
- `README.md` — Project overview and quick reference.

Official Ckan packages: [https://github.com/orgs/ckan/repositories](https://github.com/ckan)
