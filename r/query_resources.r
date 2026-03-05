# ontario_pkg_with_resources_to_json.R# ontario file
#
# Notes:
#   - Uses public metadata only (no API key required)
#   - Replace ORG_ID as needed
#   - Edit OUTPUT_JSON to change the destination filename/path
#
# What gets saved:
#   [
#     {
#       "package": { id, title, organization_id, organization_title,
#                    access_level, license_id, opened_date, metadata_modified },
#       "resources": [ { id, name, format, mimetype, language, url, size,
#                        last_modified, state, created, description }, ... ]
#     }
#   ]

# install.packages("ckanr")     # if needed
# install.packages("jsonlite")  # if needed
suppressWarnings(suppressMessages({
  library(ckanr)
  library(jsonlite)
}))

BASE_URL   <- "https://data.ontario.ca/"
ORG_ID     <- "solicitor-general"             # ← replace as needed
OUTPUT_JSON <- "ontario_pkg_with_resources.json"

# Configure CKAN (public; read-only metadata)
ckanr_setup(url = BASE_URL)

# ----------------------------
# Helpers
# ----------------------------
`%||%` <- function(x, y) if (is.null(x)) y else x

normalize_resource <- function(res) {
  # Safely extract core resource metadata (keep it portable).
  if (is.null(res) || !is.list(res)) return(list())
  list(
    id            = res$id %||% NULL,
    name          = (res$name %||% res$title) %||% NULL,
    format        = res$format %||% NULL,
    mimetype      = res$mimetype %||% NULL,
    language      = res$language %||% NULL,
    url           = res$url %||% NULL,
    size          = res$size %||% NULL,
    last_modified = res$last_modified %||% NULL,
    state         = res$state %||% NULL,
    created       = res$created %||% NULL,
    description   = res$description %||% NULL
  )
}

summarize_package <- function(pkg) {
  # Summarize dataset + all resource metadata.
  if (is.null(pkg) || !is.list(pkg)) return(list())
  org <- pkg$organization %||% list()
  resources <- (pkg$resources %||% list())
  list(
    package = list(
      id                 = pkg$id %||% NULL,
      title              = pkg$title %||% NULL,
      organization_id    = org$id %||% NULL,
      organization_title = org$title %||% NULL,
      access_level       = pkg$access_level %||% NULL,
      license_id         = pkg$license_id %||% NULL,
      opened_date        = pkg$opened_date %||% NULL,
      metadata_modified  = pkg$metadata_modified %||% NULL
    ),
    resources = lapply(resources, normalize_resource)
  )
}

# ----------------------------
# Primary search (latest open dataset for org)
# ----------------------------
message("Running primary search (latest open dataset)...")
resp <- package_search(
  q    = "*",
  fq   = paste0('organization:"', ORG_ID, '" +access_level:"open"'),
  rows = 1,
  sort = "metadata_modified desc"
)

results <- resp$results %||% list()
message("count: ", resp$count %||% 0L)
message("len(results): ", length(results))

# ----------------------------
# Fallback search (if primary returns nothing)
# ----------------------------
if (length(results) == 0) {
  message("No results. Retrying with minimal params...")
  resp <- package_search(
    fq   = paste0('organization:"', ORG_ID, '" +access_level:"open"'),
    rows = 50
  )
  results <- resp$results %||% list()
  message("count: ", resp$count %||% 0L)
  message("len(results): ", length(results))
}

# ----------------------------
# Build output structure
# ----------------------------
output <- lapply(results, summarize_package)

# Print to console (human-readable)
cat(prettify(toJSON(output, auto_unbox = TRUE)), sep = "\n")

# Save to local JSON file
writeLines(prettify(toJSON(output, auto_unbox = TRUE)), con = OUTPUT_JSON, useBytes = TRUE)
message(sprintf("Saved JSON → %s", normalizePath(OUTPUT_JSON, winslash = "/", mustWork = FALSE)))
#
# Purpose:
#   - Search Ontario CKAN for the latest open dataset in an organization
#   - Summarize the package + all of its resources (core + useful fields)
