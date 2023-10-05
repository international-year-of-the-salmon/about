# Identify packages used in R Markdown files
get_packages <- function(file_path) {
  lines <- readLines(file_path)
  packages <- unique(grep("library\\(", lines, value = TRUE))
  packages <- gsub("library\\(([^)]+)\\)", "\\1", packages)
  return(packages)
}

# List all Rmd files in your project directory
rmd_files <- list.files(pattern = "*.Rmd")

# Extract package names from all Rmd files
all_packages <- unique(unlist(lapply(rmd_files, get_packages)))

# Create DESCRIPTION file
description_content <- paste0(
  "Package: MyProject\n",
  "Type: Project\n",
  "License: What license it uses\n",
  "Imports:\n",
  paste(all_packages, collapse = ",\n"),
  "\n"
)

# Write the DESCRIPTION file
writeLines(description_content, "DESCRIPTION")
