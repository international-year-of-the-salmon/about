# Fetch all citations 
library(rdatacite)
library(dplyr)
library(networkD3)
library(readr)
# Using Datacite not just GBIF

iys_dois <- dc_dois(client_id = 'hakai.dfukgl', limit = 1000)

doi_data <- iys_dois[["data"]]
filtered_data <- doi_data %>% 
  filter(attributes$publisher == "North Pacific Anadromous Fish Commission") |> 
  select(id)

# Use list of IYS DOIs to retrieve citations
iys_dois <- dc_dois(ids = filtered_data$id, limit = 1000)

n_citations <- sum(iys_dois[["meta"]][["citations"]][["count"]])

# Citation network

# Get the data from 'International Year of the Salmon' titles
iys_dois <- dc_dois(query = "titles.title:International Year of the Salmon", limit = 1000)

# Create a tibble with the title, citation count, and DOI for each record, then filter by citation count greater than 0
iys_citations <- tibble(
  title = lapply(iys_dois$data$attributes$titles, "[[", "title"),
  citations = iys_dois[["data"]][["attributes"]][["citationCount"]],
  doi = iys_dois[["data"]][["attributes"]][["doi"]]
) |> filter(citations > 0)

write_csv(iys_citations, "docs/assets/data/iys_citations.csv")

# Reduce the title to the substring from the 4th to the 80th character
iys_citations$title <- substr(iys_citations$title, 4, 80)

# Initialize a list to store citation details of each DOI
cites_iys_list <- list()

# Fetch citation details of each DOI and store it in the list
for (i in iys_citations$doi) {
  x <- dc_events(obj_id = paste0("https://doi.org/", i))
  cites_iys_list[[i]] <- x
}

# Initialize lists to store objId and subjId
obj_ids <- list()
subj_ids <- list()

# Loop over the list to retrieve objId and subjId
for(i in 1:length(cites_iys_list)) {
  data <- cites_iys_list[[i]]$data$attributes
  obj_ids[[i]] <- data$objId
  subj_ids[[i]] <- data$subjId
}

# Flatten the lists and remove the prefix 'https://doi.org/'
obj_ids <- substring(unlist(obj_ids), 17)
subj_ids <- substring(unlist(subj_ids), 17)

# Get titles for objId and subjId
obj_titles <- rdatacite::dc_dois(ids = obj_ids, limit = 1000)
subj_titles <- rdatacite::dc_dois(ids = subj_ids, limit = 1000)

# Create a tibble of position, obj_doi, and its corresponding title
obj_dois <- obj_titles[["data"]][["attributes"]][["doi"]]
title_list <- obj_titles[["data"]][["attributes"]][["titles"]]
title_vector <- unlist(map(title_list, function(x) x[['title']][1]))
seq <- as.character(1:length(obj_dois))
objects <- tibble(position = seq, obj_dois, title_vector)

# Create a tibble of position, subj_doi, and its corresponding title
subj_dois <- subj_titles[["data"]][["attributes"]][["doi"]]
subjtitle_list <- subj_titles[["data"]][["attributes"]][["titles"]]
subjtitle_vector <- unlist(map(subjtitle_list, function(x) x[['title']][1]))
seq2 <- as.character(1:length(subj_dois))
subjects <- tibble(seq2, subj_dois, subjtitle_vector) |> 
  filter(subjtitle_vector != "Zooplankton Bongo Net Data from the 2019 and 2020 Gulf of Alaska International Year of the Salmon Expeditions")

# Get related identifiers and filter by obj_dois, join with subjects, and filter by relationType
subj_related_ids <- bind_rows(subj_titles[["data"]][["attributes"]][["relatedIdentifiers"]], .id = "position") |> 
  semi_join(objects, by = c('relatedIdentifier' = 'obj_dois')) |> 
  left_join(subjects, by = c('position' = 'seq2')) |> 
  filter(relationType != "IsPreviousVersionOf")

# Join objects and subj_related_ids by 'obj_dois' = 'relatedIdentifier'
relationships <- full_join(objects, subj_related_ids, by = c('obj_dois' = 'relatedIdentifier'))
write_csv(relationships, "./docs/assets/data/relationships.csv")

# Prepare data for network plot

objects$type.label <- "IYS Dataset"
subjects$type.label <- "Referencing Dataset"
ids <- c(objects$obj_dois,subjects$subj_dois)
names <- c(objects$title_vector, subjects$subjtitle_vector)
type.label <- c(objects$type.label, subjects$type.label)

# Create edges for network plot
edges <-tibble(from = relationships$obj_dois, to = relationships$subj_dois)
links.d3 <- data.frame(from=as.numeric(factor(edges$from))-1, 
                       to=as.numeric(factor(edges$to))-1 ) 
size <- links.d3 |> 
   group_by(from) |> 
  summarize(weight = n())

nodes <- tibble(ids, names, type.label) |> 
  mutate(names = case_when(
    names == "Occurrence Download" ~ paste0(names, " ", ids),
    TRUE ~ names
    ),
  )

length <- nrow(nodes)

missing_length <- as.integer(length) - nrow(size)
missing_size <- rep.int(0, missing_length)
size <- c(size$weight, missing_size)

nodes$size <- size

nodes.d3 <- cbind(idn=factor(nodes$names, levels=nodes$names), nodes) 

# Create and render the network plot
plot <- forceNetwork(Links = links.d3, Nodes = nodes.d3, Source="from", Target="to",
               NodeID = "idn", Group = "type.label",linkWidth = 1,
               linkColour = "#afafaf", fontSize=12, zoom=T, legend=T, 
               Nodesize="size", opacity = 0.8, charge=-300,
               width = 600, height = 400)

saveNetwork(plot, file = "./docs/assets/relationships.html", selfcontained = TRUE)
