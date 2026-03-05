# intro_ckan_ontario_metadata.R
#
# Streamlined intro dataset UUID or slug# Streamlined intro for learning how to query metadata from Ontario’s CKAN (https://data.ontario.ca).
  example_resource_id <- "your-resource-id"   # resource UUID
  example_org_slug    <- "your-org-slug"      # ministry/org slug

  # 1) CKAN core package
  # pkg <- get_core_package(example_package_id)
  # print(brief_package(pkg))

  # 2) CKAN core resource
  # res <- get_core_resource(example_resource_id)
  # print(brief_resource(res))

  # 3) Ontario package search (top 3 newest open datasets for org)
  # pkgs <- search_ontario_packages(example_org_slug, rows = 3, open_only = TRUE)
  # lapply(pkgs, function(p) print(brief_package(p)))

  # 4) Ontario resource (Ontario fields appear if set)
  # ores <- get_ontario_resource(example_resource_id)
  # print(brief_resource(ores))

# Focus: clear concepts, minimal code, ready to run once you drop real IDs.
#
# What you’ll learn (in order):
#   1) CKAN core PACKAGE metadata (dataset-level, via package_show)
#   2) CKAN core RESOURCE metadata (file/endpoint-level, via resource_show)
#   3) Ontario custom PACKAGE metadata (extra fields, via package_search)
#   4) Ontario custom RESOURCE metadata (extra fields, via resource_show)
#
# How to use:
#   • Replace the example IDs at the bottom and run the file.
#   • Functions return raw lists; use the brief_* helpers to see the essentials.

# install.packages("ckanr") # uncomment if needed
suppressWarnings(suppressMessages(library(ckanr)))

# ================================================================
# CKAN client (Ontario public instance)
# ================================================================
BASE_URL <- "https://data.ontario.ca/"
ckanr_setup(url = BASE_URL)  # public; no API key needed for read-only metadata

# ================================================================
# 1) CKAN core: PACKAGE metadata (dataset)
# ================================================================
# Fetch a dataset by id (UUID) or slug.
# Typical fields: id, name, title, notes, metadata_created/modified,
# license_id, owner_org, organization{...}, tags[], groups[], resources[], extras
get_core_package <- function(package_id_or_name) {
  package_show(id = package_id_or_name)
}

# ================================================================
# 2) CKAN core: RESOURCE metadata (file/endpoint)
# ================================================================
# Fetch a resource by id (UUID).
# Typical fields: id, package_id, name, description, format, mimetype, url,
# size, created, last_modified, language, state, extras
get_core_resource <- function(resource_id) {
  resource_show(id = resource_id)
}

# ================================================================
# 3) Ontario custom: PACKAGE metadata via search
# ================================================================
# Search Ontario packages for an organization (ministry).
# Ontario extra fields often present: access_level, opened_date, current_as_of,
# update_frequency, geographic_coverage, access_instructions, maintainer_branch,
# exemption, exemption_rationale
search_ontario_packages <- function(org_slug, rows = 10, open_only = TRUE) {
  fq <- paste0('organization:"', org_slug, '"', if (open_only) ' +access_level:"open"' else "")
  res <- package_search(q = "*", fq = fq, sort = "metadata_modified desc", rows = rows)
  res$results %||% list()
}

# ================================================================
# 4) Ontario custom: RESOURCE metadata
#    (same call as core; Ontario fields appear inline if present)
# ================================================================
# Fetch a resource; Ontario extra fields (if present): data_range_start,
# data_range_end, date_publicly_available, data_last_updated, created, type
get_ontario_resource <- function(resource_id) {
  get_core_resource(resource_id)
}

# ================================================================
# Compact, readable summaries for quick learning
# ================================================================
`%||%` <- function(x, y) if (is.null(x)) y else x

brief_package <- function(pkg) {
  org <- pkg$organization %||% list()
  list(
    # Core
    id = pkg$id,
    name = pkg$name,
    title = pkg$title,
    organization = org$title %||% NULL,
    license_id = pkg$license_id,
    metadata_modified = pkg$metadata_modified,
    resource_count = length(pkg$resources %||% list()),
    # Ontario custom (may be absent)
    access_level = pkg$access_level %||% NULL,
    opened_date = pkg$opened_date %||% NULL,
    current_as_of = pkg$current_as_of %||% NULL,
    update_frequency = pkg$update_frequency %||% NULL
  )
}

brief_resource <- function(res) {
  list(
    # Core
    id = res$id,
    package_id = res$package_id,
    name = res$name,
    format = res$format,
    url = res$url,
    size = res$size %||% NULL,
    created = res$created %||% NULL,
    last_modified = res$last_modified %||% NULL,
    language = res$language %||% NULL,
    # Ontario custom (may be absent)
    data_last_updated = res$data_last_updated %||% NULL,
    data_range_start = res$data_range_start %||% NULL,
    data_range_end = res$data_range_end %||% NULL,
    date_publicly_available = res$date_publicly_available %||% NULL,
    type = res$type %||% NULL
  )
}

# ================================================================
# Walkthrough — replace IDs and run
# ================================================================
if (identical(Sys.getenv("RUN_CKAN_INTRO"), "1")) {
  # Replace with real values before running:
