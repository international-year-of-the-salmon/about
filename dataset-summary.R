library(rdatacite)
library(dplyr)
library(networkD3)
library(readr)
library(purrr)
library(tibble)
library(rcrossref)
library(plotly)


# View the results
print(results)

# Using Datacite to retrieve all IYS dataset DOIs
iys_dois <- dc_dois(query = "titles.title:International Year of the Salmon", limit = 1000)
n_citations <- sum(iys_dois[["meta"]][["citations"]][["count"]])

doi_data <- iys_dois[["data"]]
filtered_data <- doi_data %>%
  select(id)

# Use list of IYS DOIs to retrieve citations
iys_dois <- dc_dois(ids = filtered_data$id, limit = 1000)

# Citation network
# Create a tibble with the title, citation count, and DOI for each record, then filter by citation count greater than 0
all_iys_citations <- tibble(
  title = lapply(iys_dois$data$attributes$titles, "[[", "title"),
  citations = iys_dois[["data"]][["attributes"]][["citationCount"]],
  doi = iys_dois[["data"]][["attributes"]][["doi"]]
)

# strip title after comma
all_iys_citations$title <- gsub(",.*", "", all_iys_citations$title)

# strip leading c(" from titile and trailing " from title
all_iys_citations$title <- gsub("^c\\(\"|\"$", "", all_iys_citations$title)

iys_citations <- all_iys_citations |>
  filter(citations > 0) |>
  # select top ten
  slice_max(citations, n = 10) |>
  mutate(doi = paste0("https://doi.org/", doi))

write_csv(iys_citations, "docs/assets/data/iys_citations.csv")



# # Reduce the title to the substring
# iys_citations$title <- substr(iys_citations$title, 4, 80)

# # Initialize a list to store citation details of each DOI
# cites_iys_list <- list()

# # TODO test if this pagination works
# # Fetch citation details of each DOI and store it in the list
# for (i in iys_citations$doi) {
#   cursor <- NULL
#   while (TRUE) {
#     x <- dc_events(
#       obj_id = paste0("https://doi.org/", i), cursor = cursor,
#       limit = 1000
#     )
#     if (length(x$data) == 0) break
#     cites_iys_list[[i]] <- c(cites_iys_list[[i]], x)
#     cursor <- x$meta$cursor
#   }
# }

# # Initialize lists to store objId and subjId
# obj_ids <- list()
# subj_ids <- list()

# # Loop over the list to retrieve objId and subjId
# for (i in 1:length(cites_iys_list)) {
#   data <- cites_iys_list[[i]]$data$attributes
#   obj_ids[[i]] <- data$objId
#   subj_ids[[i]] <- data$subjId
# }


# # Flatten the lists and remove the prefix 'https://doi.org/'
# obj_ids <- substring(unlist(obj_ids), 17)
# subj_ids <- substring(unlist(subj_ids), 17)


# # breakdown obj_ids and subj_ids into smaller chunks
# obj_ids <- split(obj_ids, ceiling(seq_along(obj_ids) / 100))
# subj_ids <- split(subj_ids, ceiling(seq_along(subj_ids) / 100))


# # Initialize lists to store titles
# obj_titles <- list()
# subj_titles <- list()

# # Iterate through each list in obj_ids
# for (i in seq_along(obj_ids)) {
#   # Get titles for each list in obj_ids
#   obj_titles[[i]] <- rdatacite::dc_dois(ids = obj_ids[[i]], limit = 1000)
#   # sleep for 1 second
#   Sys.sleep(1)
# }

# # sleep for 60 seconds
# Sys.sleep(1000)

# # TODO if this takes too long, try using the graphQL API
# # Iterate through each list in subj_ids
# for (i in seq_along(subj_ids)) {
#   # Get titles for each list in subj_ids
#   subj_titles[[i]] <- rdatacite::dc_dois(ids = subj_ids[[i]], limit = 10000)
#   # sleep for 1 second
#   Sys.sleep(1)
# }


# # Create a tibble of position, obj_doi, and its corresponding title

# # Initialize lists to store obj_dois and titles
# obj_dois <- list()
# title_vector <- list()

# # Iterate over each list in obj_titles
# for (i in seq_along(obj_titles)) {
#   # Extract doi and titles from each list and store them in obj_dois and title_vector
#   obj_dois[[i]] <- obj_titles[[i]]$data$attributes$doi
#   title_list <- obj_titles[[i]]$data$attributes$titles
#   title_vector[[i]] <- unlist(map(title_list, function(x) x[["title"]][1]))
# }

# # Flatten the lists
# obj_dois <- unlist(obj_dois)
# title_vector <- unlist(title_vector)

# # Create a sequence
# seq <- as.character(1:length(obj_dois))

# # Create a tibble
# objects <- tibble(position = seq, obj_dois, title_vector)

# # Initialize lists to store subj_dois and titles
# subj_dois <- list()
# subjtitle_vector <- list()

# # Iterate over each list in subj_titles
# for (i in seq_along(subj_titles)) {
#   # Extract doi and titles from each list and store them in subj_dois and subjtitle_vector
#   subj_dois[[i]] <- subj_titles[[i]]$data$attributes$doi
#   subjtitle_list <- subj_titles[[i]]$data$attributes$titles
#   subjtitle_vector[[i]] <- unlist(map(subjtitle_list, function(x) x[["title"]][1]))
# }

# # Flatten the lists
# subj_dois <- unlist(subj_dois)
# subjtitle_vector <- unlist(subjtitle_vector)

# # create tibble
# subjects <- tibble(subj_dois, subjtitle_vector) %>%
#   filter(subjtitle_vector != "Zooplankton Bongo Net Data from the 2019 and 2020 Gulf of Alaska International Year of the Salmon Expeditions") %>%
#   filter(subjtitle_vector != "Occurrence Download")

# # Create a sequence
# seq2 <- as.character(1:length(subjects$subj_dois))

# # Create a tibble
# subjects <- tibble(seq2, subjects)

# # save .csv file
# write_csv(subjects, "docs/assets/data/cites_iys_data.csv")

# # Initialize an empty list to store related identifiers
# related_ids <- list()

# # Iterate over each list in subj_titles
# for (i in seq_along(subj_titles)) {
#   # Extract related identifiers from each list and store them in related_ids
#   related_ids[[i]] <- subj_titles[[i]]$data$attributes$relatedIdentifiers
# }

# # Bind rows of related_ids and filter by obj_dois, join with subjects, and filter by relationType
# subj_related_ids <- bind_rows(related_ids, .id = "position") |>
#   semi_join(objects, by = c("relatedIdentifier" = "obj_dois")) |>
#   left_join(subjects, by = c("position" = "seq2")) |>
#   filter(relationType != "IsPreviousVersionOf")

# # Join objects and subj_related_ids by 'obj_dois' = 'relatedIdentifier'
# relationships <- full_join(objects, subj_related_ids, by = c("obj_dois" = "relatedIdentifier"))
# write_csv(relationships, "./docs/assets/data/relationships.csv")

# # Prepare data for network plot

# objects$type.label <- "IYS Dataset"
# subjects$type.label <- "Referencing Dataset"
# ids <- c(objects$obj_dois, subjects$subj_dois)
# names <- c(objects$title_vector, subjects$subjtitle_vector)
# type.label <- c(objects$type.label, subjects$type.label)

# # Create edges for network plot
# edges <- tibble(from = relationships$obj_dois, to = relationships$subj_dois)
# links.d3 <- data.frame(
#   from = as.numeric(factor(edges$from)) - 1,
#   to = as.numeric(factor(edges$to)) - 1
# )
# size <- links.d3 |>
#   group_by(from) |>
#   summarize(weight = n())

# nodes <- tibble(ids, names, type.label) |>
#   mutate(names = case_when(
#     names == "Occurrence Download" ~ paste0(names, " ", ids),
#     TRUE ~ names
#   ), )

# length <- nrow(nodes)

# missing_length <- as.integer(length) - nrow(size)
# missing_size <- rep.int(0, missing_length)
# size <- c(size$weight, missing_size)

# nodes$size <- size

# # Ensure there are no duplicate names
# nodes <- nodes[!duplicated(nodes$names), ]

# # Create nodes.d3
# nodes.d3 <- cbind(idn = factor(nodes$names, levels = nodes$names), nodes)

# # JavaScript function to open a new tab with URL based on the clicked node's ids
# js_click_action <- "function(d) { window.open('https://doi.org/' + d.ids, '_blank'); }"

# # Create and render the network plot
# plot <- forceNetwork(
#   Links = links.d3, Nodes = nodes.d3, Source = "from", Target = "to",
#   NodeID = "idn", Group = "type.label", linkWidth = 1,
#   linkColour = "#afafaf", fontSize = 12, zoom = F, legend = T,
#   Nodesize = "size", opacity = 0.8, charge = -1000,
#   width = 1200, height = 800, bounded = TRUE, clickAction = js_click_action
# )

# plot
# saveNetwork(plot, file = "./docs/assets/relationships.html", selfcontained = TRUE)
