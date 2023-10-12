# Identify packages used in R Markdown files
get_packages <- function(file_path) {
  lines <- readLines(file_path)
  packages <- unique(grep("library\\(", lines, value = TRUE))
  packages <- gsub("library\\(([^)]+)\\)", "\\1", packages)
  packages <- gsub("\"|\\s+", "", packages) # Remove quotes and extra spaces
  return(packages)
}

# Get installed version of a package
get_package_version <- function(package) {
  version <- as.character(packageVersion(package))
  return(paste0("(", ">= ", version, ")"))
}

# List all Rmd files in your project directory
rmd_files <- list.files(pattern = "*.Rmd")

# Extract package names from all Rmd files
all_packages <- unique(unlist(lapply(rmd_files, get_packages)))

# Generate the formatted package strings
formatted_packages <- sapply(all_packages, function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    version_info <- get_package_version(pkg)
    return(paste0("    ", pkg, " ", version_info, ","))
  } else {
    return(NULL) # Skip if the package is not installed
  }
}, USE.NAMES = FALSE)

# Concatenate all the package strings into a single string
formatted_package_string <- paste(formatted_packages, collapse = "\n")

# Remove the trailing comma from the last package
formatted_package_string <- sub(",$", "", formatted_package_string)

description_content <- paste0(
  "Package: about\n",
  "Version: 0.0.1\n",
  "Title: About\n",
  "Description: Website for IYS\n",
  "Encoding: UTF-8\n",
  "License: CC BY 4.0\n",
  "Imports:\n",
  paste(formatted_package_string)
)

# Remove the old DESCRIPTION file if it exists
if (file.exists("DESCRIPTION")) {
  file.remove("DESCRIPTION")
}

# Write the DESCRIPTION file
writeLines(description_content, "DESCRIPTION")
