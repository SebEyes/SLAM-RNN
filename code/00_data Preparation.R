### Loading Packages
require(stringr)
require(dplyr)
require(tidyr)
require(reshape2)
require(FactoMineR)
require(Factoshiny)

### Loading SLAM database
SLAM_rawDB = read.csv(
    "data/SLAM_V66-2023_05_23.csv",
    sep = ";"
)

Date_database = read.csv(
    "data/SLAM_Dates.csv",
    sep = ";"
)
Date_database$Placement = as.Date(Date_database$Placement)
Date_database$Sampling.Date = as.Date(Date_database$Sampling.Date)

### Select data
SLAM_TER = SLAM_rawDB[str_detect(SLAM_rawDB$Event_ID, "TER"),]

# List sites available
SLAM_TER_sites = SLAM_TER %>%
    select(Event_ID) %>% 
    unique()

SLAM_TER_sites = separate(
    data = SLAM_TER_sites,
    col = "Event_ID",
    into = c("site_codes","drop"),
    sep = "_",
    extra = "drop"
) %>% unique()

# Remove T-18
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "18-CENTRE", negate = T),]
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "18-D", negate = T),]
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "18-E", negate = T),]
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "18-T", negate = T),]

# Remove T164B and T33B
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "33-B", negate = T),]
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "164B", negate = T),]

#Clean site list
SLAM_TER_sites = select(
    SLAM_TER_sites,
    site_codes
) %>% unique()

# Select data
SLAM_TER = separate(
    data = SLAM_TER,
    col = "Event_ID",
    into = "site_codes",
    extra = "drop",
    remove = F,
    sep = "_"
)

SLAM_TER = SLAM_TER[SLAM_TER$site_codes %in% SLAM_TER_sites$site_codes,]

## Add date range
SLAM_TER = merge(
    SLAM_TER,
    select(
        Date_database,
        Event_ID,
        Placement,
        Sampling.Date
    ),
    by = "Event_ID"
)

# filter Samples between 70 and 110 days
SLAM_TER$nb_days = as.numeric(SLAM_TER$Sampling.Date - SLAM_TER$Placement)
SLAM_TER = SLAM_TER[SLAM_TER$nb_days %in% c(70:110),]

## Remove lepidoptera (MF19 and 116)
SLAM_TER = SLAM_TER %>% filter(order != "Lepidoptera")


## Compute Mat com
Mat_com = SLAM_TER %>%
    select(
        Event_ID,
        MF,
        Total_Abundance
    ) %>% 
    group_by(
        MF,
        Event_ID
    ) %>% 
    summarise(
        Total_Abundance = sum(Total_Abundance)
    ) %>%
    ungroup()


## Add time step information
time_step = data.frame(
    Season = rep(c("summer", "autumn", "winter", "spring"), 12)
) %>% arrange(Season)
time_step$Year = rep(c(2012:2023), 4)

## Réordonnancement de time_step$Season
time_step$Season <- factor(time_step$Season,
  levels = c("summer", "autumn", "winter", "spring")
)
time_step = time_step %>% arrange(Year, Season)
time_step$step = row.names(time_step)

date_TERNF = Date_database[str_detect(Date_database$Event_ID, "TER-NF"),]

date_TERNF = merge(
    date_TERNF,
    time_step,
    by = c("Season", "Year")
) %>% select(
    Event_ID, step
)

Mat_com = merge(
    Mat_com,
    select(
        date_TERNF,
        Event_ID,
        step
    ),
    by = "Event_ID"
)

Mat_com = select(Mat_com, -Event_ID)


Mat_com = dcast(
    Mat_com,
    step ~ MF,
    fun.aggregate = sum,
    fill = 0,
    value.var = "Total_Abundance"
) %>% arrange(step)

Mat_com$step = as.numeric(Mat_com$step)
Mat_com = Mat_com %>% arrange(step)


## Select MF with sufficient number of individuals
summary_abundance = colSums(
    select(
        Mat_com,
        -step
    )
)
summary_abundance = as.data.frame(summary_abundance)
summary(summary_abundance)
summary_abundance$MF = row.names(summary_abundance)
summary_abundance = summary_abundance %>% filter(MF != "NPI")
summary_abundance = summary_abundance[summary_abundance$summary_abundance > 100,]

Mat_com_dominant = select(
    Mat_com,
    c(summary_abundance$MF, "step")
)
row.names(Mat_com_dominant) = Mat_com_dominant$step
Mat_com_dominant = select(
    Mat_com_dominant,
    -step
)

## Save training dataset
Mat_com_dominant$time_step = row.names(Mat_com_dominant)
Mat_com_dominant$time_step = as.numeric(Mat_com_dominant$time_step)
Mat_com_dominant = Mat_com_dominant %>% filter(time_step >= 9) %>% filter(time_step < 47)

write.table(
    Mat_com_dominant,
    "data/Matrix_dominant.csv",
    sep = ";",
    row.names = F
)

## PCA
# res.PCA<-PCA(Mat_com_dominant,graph=FALSE)
# res.PCA$ind$coord

# ## Save training dataset
# data_NN = as.data.frame(res.PCA$ind$coord)
# data_NN$time_step = row.names(data_NN)

# write.table(
#     data_NN,
#     "data/data_NN.csv",
#     sep = ";",
#     row.names = F
# )
