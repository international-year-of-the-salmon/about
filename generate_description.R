# Identify packages used in R Markdown files
install.packages('usethis')
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

manual_entry <- "    usethis (>= 2.1.6),"
# Prepend the manual entry to the existing formatted package string
formatted_package_string <- paste(manual_entry, formatted_package_string, sep = "\n")

# Remove the trailing comma from the last package
formatted_package_string <- sub(",$", "", formatted_package_string)

# Remove the old DESCRIPTION file if it exists
if (file.exists("DESCRIPTION")) {
  file.remove("DESCRIPTION")
}

# Use the formatted package string in the `usethis::use_description` function
usethis::use_description(fields = list(Title = "About page", Imports = formatted_package_string))
