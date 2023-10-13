## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(reshape2)
require(forcats)

### Import database
adult_DB = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
)

MF_data = read.csv(
    "data/diversity_data/MF_completeInfo.csv",
    sep = ";",
    stringsAsFactors = T
)


### Retrieve MF information

MF_selected = names(adult_DB)[str_detect(names(adult_DB), "MF")]
MF_selected = str_remove(MF_selected, "MF")

MF_info = data.frame(
    MF = MF_selected
)

MF_info = merge(
    MF_info,
    MF_data,
    by = "MF"
)

### Supplementary material S2
# write.table(
#     MF_info %>% select(-abpcode, -scientificName_GBIF),
#     "data/diversity_data/SuppS2_MF_Info.csv",
#     sep = ";",
#     row.names = F
# )

MF_order = MF_info  %>% select(class, order) %>% unique() %>% group_by(class) %>% summarise(
        NB_order = n()
    )
MF_family = MF_info %>% select(class, family) %>% unique()%>% group_by(class) %>% summarise(
        NB_family = n()
    )
MF_genus = MF_info  %>% select(class, genus) %>% unique() %>% group_by(class) %>% summarise(
        NB_genus = n()
    )
MF_sp = MF_info  %>% select(class, MF, taxonRank) %>% filter(taxonRank == "species") %>% unique() %>% group_by(class) %>% summarise(
    NB_sp = n()
)
MF_ssp = MF_info  %>% select(class, MF, taxonRank) %>% filter(taxonRank == "subspecies") %>% unique() %>% group_by(class) %>% summarise(
    NB_ssp = n()
)
MF_spEN = MF_info  %>% select(class, MF, taxonRank, establishmentMeans) %>% filter(establishmentMeans == "E") %>% unique() %>% group_by(class) %>% summarise(
    NB_sp_E = n()
)
MF_spN = MF_info  %>% select(class, MF, taxonRank, establishmentMeans) %>% filter(establishmentMeans == "N") %>% unique() %>% group_by(class) %>% summarise(
    NB_s_N = n()
)
MF_spI = MF_info  %>% select(class, MF, taxonRank, establishmentMeans) %>% filter(establishmentMeans == "I") %>% unique() %>% group_by(class) %>% summarise(
    NB_sp_I = n()
)


MF_summary = merge(
    MF_order,
    MF_family
)
MF_summary = merge(
    MF_summary,
    MF_genus,
    all.x = T
)
MF_summary = merge(
    MF_summary,
    MF_sp,
    all.x = T
)
MF_summary = merge(
    MF_summary,
    MF_ssp,
    all.x = T
)
MF_summary = merge(
    MF_summary,
    MF_spEN,
    all.x = T
)
MF_summary = merge(
    MF_summary,
    MF_spN,
    all.x = T
)
MF_summary = merge(
    MF_summary,
    MF_spI,
    all.x = T
)
MF_summary[is.na(MF_summary)] = 0

write.table(
    MF_summary,
    "data/diversity_data/table1_SummaryMF.csv",
    sep = ";",
    row.names = F
)
