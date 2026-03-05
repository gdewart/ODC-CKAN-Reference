# ============================================================
# Minimal CKAN Helper in R (ckanr, Public Only)
# Target portal: https://data.ontario.ca/
# Notes:
#   - Uses public endpoints only (no API key required)
#   - Mirrors Python ckANAPI examples with idiomatic R
#   - OPS-specific metadata fields included where applicable
# ============================================================

# ---- Setup --------------------------------------------------
# Install if needed:
# install.packages("ckanr")

suppressWarnings(suppressMessages({
  library(ckanr)
}))

# Configure CKAN base URL (public)
ckanr_setup(url = "https://data.ontario.ca/")

# ---- ID Placeholders ---------------------------------------
package_id  <- "your-package-id"
resource_id <- "your-resource-id"
org_id      <- "solicitor-general"

# ---- Helper: safe getter -----------------------------------
safe_get <- function(x, field, default = NULL) {
  if (is.null(x)) return(default)
  if (!is.list(x) && !is.environment(x)) return(default)
  if (!is.null(x[[field]])) return(x[[field]])
  default
}

# ============================================================
# OPS-specific metadata fields (for reference)
# Package-level:
#   current_as_of, opened_date, update_frequency, geographic_coverage,
#   access_level, access_instructions, license_id, owner_org, maintainer,
#   maintainer_email, author, author_email, maintainer_branch, exemption,
#   exemption_rationale
#
# Resource-level:
#   data_range_start, data_range_end, date_publicly_available,
#   data_last_updated, created, type, format, language, size
# ============================================================


# =========================
# Ontario CKAN Action API Snippets
# =========================

# --- Package (dataset) core ---
pkg <- try(package_show(id = package_id), silent = TRUE)
if (!inherits(pkg, "try-error")) {
  # Title
  print(pkg$title)

  # Resource IDs
  res_ids <- if (!is.null(pkg$resources)) vapply(pkg$resources, `[[`, "", "id") else character(0)
  print(res_ids)

  # Tag names
  tag_names <- if (!is.null(pkg$tags)) vapply(pkg$tags, `[[`, "", "name") else character(0)
  print(tag_names)
} else {
  message("package_show failed. Check 'package_id'.")
}

# --- Package: OPS metadata quick grabs ---
if (!inherits(pkg, "try-error")) {
  print(safe_get(pkg, "current_as_of"))         # Last Validated Date
  print(safe_get(pkg, "opened_date"))           # Date Opened
  print(safe_get(pkg, "update_frequency"))      # Update Frequency
  print(safe_get(pkg, "geographic_coverage"))   # Geographic Coverage
  print(safe_get(pkg, "access_level"))          # Access Level
  print(safe_get(pkg, "access_instructions"))   # Access Instructions
  print(safe_get(pkg, "license_id"))            # Licence ID
  print(safe_get(pkg, "owner_org"))             # Ministry (org id)
  print(safe_get(pkg, "maintainer"))            # Maintainer
  print(safe_get(pkg, "maintainer_email"))      # Maintainer Email
  print(safe_get(pkg, "author"))                # Author
  print(safe_get(pkg, "author_email"))          # Author Email
  print(safe_get(pkg, "maintainer_branch"))     # Maintainer Branch
  print(safe_get(pkg, "exemption"))             # Exemption
  print(safe_get(pkg, "exemption_rationale"))   # Exemption Rationale
}

# --- Resource core ---
res <- try(resource_show(id = resource_id), silent = TRUE)
if (!inherits(res, "try-error")) {
  print(res$name)
  print(res$format)
  print(res$url)
} else {
  message("resource_show failed. Check 'resource_id'.")
}

# --- Resource: OPS metadata quick grabs ---
if (!inherits(res, "try-error")) {
  print(safe_get(res, "data_range_start"))       # Data Range Start
  print(safe_get(res, "data_range_end"))         # Data Range End
  print(safe_get(res, "date_publicly_available"))# Date made public
  print(safe_get(res, "data_last_updated"))      # Data last updated
  print(safe_get(res, "created"))                # Added to Catalogue
  print(safe_get(res, "type"))                   # Type (data/aux)
  print(safe_get(res, "language"))               # Language
  print(safe_get(res, "size"))                   # File size
}

# --- Organization filter (solicitor-general) ---
# NOTE: Use package_search for filtering (fq). Returns $results list.
org_search <- try(package_search(fq = paste0("organization:", org_id), rows = 20), silent = TRUE)
if (!inherits(org_search, "try-error")) {
  org_pkg_names <- vapply(org_search$results, `[[`, "", "name")
  print(org_pkg_names)
} else {
  message("package_search failed. Check 'org_id'.")
}


# =========================
# EXAMPLES
# =========================

# 1) Dataset summary list with OPS fields (single call, reuse locals)
pkg <- try(package_show(id = package_id), silent = TRUE)
if (!inherits(pkg, "try-error")) {
  dataset_summary <- list(
    title = safe_get(pkg, "title"),
    org   = safe_get(safe_get(pkg, "organization"), "title"),
    opened_date = safe_get(pkg, "opened_date"),
    current_as_of = safe_get(pkg, "current_as_of"),
    update_frequency = safe_get(pkg, "update_frequency"),
    geographic_coverage = safe_get(pkg, "geographic_coverage"),
    access_level = safe_get(pkg, "access_level"),
    license_id = safe_get(pkg, "license_id")
  )
  print(dataset_summary)  # fields per About page
} else {
  message("package_show failed. Cannot build dataset_summary.")
}

# 2) For each dataset in org: show title + first CSV resource URL (if present)
org_pkgs <- try(package_search(fq = paste0("organization:", org_id), rows = 100), silent = TRUE)
if (!inherits(org_pkgs, "try-error")) {
  results <- org_pkgs$results %||% list()
  first_csv <- lapply(results, function(p) {
    first_csv_url <- NULL
    if (!is.null(p$resources)) {
      csv_res <- Filter(function(r) toupper(safe_get(r, "format", "")) == "CSV", p$resources)
      if (length(csv_res) > 0) first_csv_url <- safe_get(csv_res[[1]], "url")
    }
    list(title = safe_get(p, "title"), csv_url = first_csv_url)
  })
  # Preview first 10
  print(utils::head(first_csv, 10))
} else {
  message("package_search failed. Cannot enumerate first CSV URLs.")
}

# 3) Resource + parent dataset key facts (manual join via package_id)
res <- try(resource_show(id = resource_id), silent = TRUE)
if (!inherits(res, "try-error")) {
  pkg2 <- try(package_show(id = safe_get(res, "package_id")), silent = TRUE)
  if (!inherits(pkg2, "try-error")) {
    joined <- list(
      resource_name = safe_get(res, "name"),
      resource_format = safe_get(res, "format"),
      resource_url = safe_get(res, "url"),
      data_last_updated = safe_get(res, "data_last_updated"),
      dataset_title = safe_get(pkg2, "title"),
      org_title = safe_get(safe_get(pkg2, "organization"), "title")
    )
    print(joined)  # resource/package fields per About page
  } else {
    message("package_show (from resource package_id) failed.")
  }
} else {
  message("resource_show failed. Cannot join resource→package.")
}

# 4) Fetch list of organizations (ministries)
orgs <- try(organization_list(), silent = TRUE)
if (!inherits(orgs, "try-error")) {
  print(utils::head(orgs, 10))
} else {
  message("organization_list failed.")
}

# 5) Fetch list of ministry datasets
# NOTE: In CKAN, filtering is done via package_search, not package_list.
# This example mirrors Python intent using package_search.
ministry_pkgs <- try(package_search(fq = "organization:solicitor-general", rows = 100), silent = TRUE)
if (!inherits(ministry_pkgs, "try-error")) {
  for (p in ministry_pkgs$results) {
    cat(safe_get(p, "name", ""), "→", safe_get(p, "title", ""), "\n")
  }
} else {
  message("package_search for ministry datasets failed.")
}

# ---- Small infix helper (used above) ------------------------
`%||%` <- function(x, y) if (is.null(x)) y else x