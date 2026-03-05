# Minimal CKAN Helper (ckanapi, Public Only)

# Basic connection (public datasets; no auth needed)
from ckanapi import RemoteCKAN
ckan = RemoteCKAN("https://data.ontario.ca/")

# ID Placeholders
package_id  = "your-package-id"
resource_id = "your-resource-id"
org_id      = "solicitor-general"

# OPS-specific metadata fields (package): 
"""
current_as_of, opened_date, update_frequency
geographic_coverage, access_level, access_instructions
license_id, owner_org, maintainer, maintainer_email, author
author_email, maintainer_branch, exemption, exemption_rationale  
"""
# OPS-specific metadata fields (resource): 
"""
data_range_start, data_range_end, date_publicly_available, 
data_last_updated, created, type, format, language, size  
"""
# =========================
# Ontario Open Data CKAN Action API Snippets 
# =========================

# --- Package (dataset) core ---
print(ckan.action.package_show(id=package_id)["title"])
print([r["id"] for r in ckan.action.package_show(id=package_id)["resources"]])
print([t["name"] for t in ckan.action.package_show(id=package_id)["tags"]])

# --- Package: OPS metadata quick grabs ---
print(ckan.action.package_show(id=package_id).get("current_as_of"))          # Metadata: Last Validated Date  
print(ckan.action.package_show(id=package_id).get("opened_date"))            # Date Opened          
print(ckan.action.package_show(id=package_id).get("update_frequency"))       # Update Frequency     
print(ckan.action.package_show(id=package_id).get("geographic_coverage"))    # Geographic Coverage  
print(ckan.action.package_show(id=package_id).get("access_level"))           # Access Level         
print(ckan.action.package_show(id=package_id).get("access_instructions"))    # Access Instructions  
print(ckan.action.package_show(id=package_id).get("license_id"))             # Licence ID           
print(ckan.action.package_show(id=package_id).get("owner_org"))              # Ministry (org id)    
print(ckan.action.package_show(id=package_id).get("maintainer"))             # Maintainer           
print(ckan.action.package_show(id=package_id).get("maintainer_email"))       # Maintainer Email     
print(ckan.action.package_show(id=package_id).get("author"))                 # Author               
print(ckan.action.package_show(id=package_id).get("author_email"))           # Author Email         
print(ckan.action.package_show(id=package_id).get("maintainer_branch"))      # Maintainer Branch    
print(ckan.action.package_show(id=package_id).get("exemption"))              # Exemption            
print(ckan.action.package_show(id=package_id).get("exemption_rationale"))    # Exemption Rationale  

# --- Resource core ---
print(ckan.action.resource_show(id=resource_id)["name"])
print(ckan.action.resource_show(id=resource_id)["format"])
print(ckan.action.resource_show(id=resource_id)["url"])

# --- Resource: OPS metadata quick grabs ---
print(ckan.action.resource_show(id=resource_id).get("data_range_start"))     # Data Range Start     
print(ckan.action.resource_show(id=resource_id).get("data_range_end"))       # Data Range End       
print(ckan.action.resource_show(id=resource_id).get("date_publicly_available")) # Data made public   
print(ckan.action.resource_show(id=resource_id).get("data_last_updated"))    # Data last updated    
print(ckan.action.resource_show(id=resource_id).get("created"))              # Added to Catalogue   
print(ckan.action.resource_show(id=resource_id).get("type"))                 # Type (data/aux)      
print(ckan.action.resource_show(id=resource_id).get("language"))             # Language             
print(ckan.action.resource_show(id=resource_id).get("size"))                 # File size            

# --- Organization filter (solicitor-general) ---
print([p["name"] for p in ckan.action.package_search(fq=f"organization:{org_id}", rows=20)["results"]])

# EXAMPLES

# 1) Dataset summary dict with OPS fields (single call, reuse locals)
_pkg = ckan.action.package_show(id=package_id)
dataset_summary = {
    "title": _pkg.get("title"),
    "org": _pkg.get("organization", {}).get("title"),
    "opened_date": _pkg.get("opened_date"),
    "current_as_of": _pkg.get("current_as_of"),
    "update_frequency": _pkg.get("update_frequency"),
    "geographic_coverage": _pkg.get("geographic_coverage"),
    "access_level": _pkg.get("access_level"),
    "license_id": _pkg.get("license_id"),
}
print(dataset_summary)  # fields per About page 

# 2) For each dataset in org: show title + first CSV resource URL (if present)
_org_pkgs = ckan.action.package_search(fq=f"organization:{org_id}", rows=100)["results"]
first_csv = [
    (p["title"], next((r["url"] for r in p.get("resources", []) if r.get("format", "").upper() == "CSV"), None))
    for p in _org_pkgs
]
print(first_csv[:10])

# 3) Resource + parent dataset key facts (manual join via package_id)
_res = ckan.action.resource_show(id=resource_id)
_pkg2 = ckan.action.package_show(id=_res["package_id"])
joined = {
    "resource_name": _res.get("name"),
    "resource_format": _res.get("format"),
    "resource_url": _res.get("url"),
    "data_last_updated": _res.get("data_last_updated"),
    "dataset_title": _pkg2.get("title"),
    "org_title": _pkg2.get("organization", {}).get("title"),
}
print(joined)  # resource/package fields per About page 

# 4) fetch list of organizations (ministries) with try/finally
import ckanapi
ckan_tmp = ckanapi.RemoteCKAN("https://data.ontario.ca/")
try:
    result_orgs = ckan_tmp.action.organization_list()
    print(result_orgs[:10])  # preview first 10
finally:
    ckan_tmp.close()

# 5) fetch list of ministry datasets with try/finally
import ckanapi
ckan_tmp = ckanapi.RemoteCKAN("https://data.ontario.ca/")
try:
    result_pkgs = ckan_tmp.action.package_list(fq="organization:solicitor-general", rows=100)
    for pkg in result_pkgs["results"]:
        print(pkg["name"], "→", pkg.get("title"))
finally:
    ckan_tmp.close()

