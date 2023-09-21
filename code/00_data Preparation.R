### Loading Packages
require(stringr)
require(dplyr)
require(tidyr)
require(reshape2)

### Loading SLAM database
SLAM_rawDB = read.csv(
    "data/diversity_data/SLAM_V68-2023_07_20.csv",
    sep = ";",
    dec = ","
)

Date_database = read.csv(
    "data/diversity_data/SLAM_Dates.csv",
    sep = ","
)
Date_database$Placement = as.Date(Date_database$Placement)
Date_database$Sampling.Date = as.Date(Date_database$Sampling.Date)

### Select data Terceira
SLAM_TER = SLAM_rawDB[str_detect(SLAM_rawDB$Event_ID, "TER"),]

## Remove lepidoptera (MF19 and 116)
SLAM_TER = SLAM_TER %>% filter(order != "Lepidoptera")

## Remove Aphid MF1230

## Remove NPI
SLAM_TER = SLAM_TER %>% filter(MF != "NPI")

## Merge synonym
SLAM_TER$Total_Abundance_90 = str_replace_all(
    SLAM_TER$Total_Abundance_90,
    ",",
    "."
)
SLAM_TER$Total_Abundance_90 = as.numeric(SLAM_TER$Total_Abundance_90)

SLAM_TER$Total_Abundance_Adult_90 = str_replace_all(
    SLAM_TER$Total_Abundance_Adult_90,
    ",",
    "."
)
SLAM_TER$Total_Abundance_Adult_90 = as.numeric(SLAM_TER$Total_Abundance_Adult_90)


SLAM_TER = SLAM_TER %>%
    group_by(Event_ID, MF) %>%
    summarise(
        A = sum(A),
        AM = sum(AM),
        AF = sum(AF),
        J = sum(J),
        Total_Abundance = sum(Total_Abundance),
        Total_Abundance_Adult = sum(Total_Abundance_Adult),
        Total_Abundance_90 = sum(Total_Abundance_90),
        Total_Abundance_Adult_90 = sum(Total_Abundance_Adult_90),
        scientificName
    )

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

# Remove Serreta
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "-200M", negate = T),]
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "-400M", negate = T),]
SLAM_TER_sites = SLAM_TER_sites[str_detect(SLAM_TER_sites$site_codes, "-0M", negate = T),]

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

Date_TER = separate(
    data = Date_database,
    col = "Event_ID",
    into = c("site_codes","drop"),
    sep = "_",
    extra = "drop",
    remove = F
) %>% filter(str_detect(site_codes, "TER"))

Date_TER = Date_TER[Date_TER$site_codes %in% unique(SLAM_TER$site_codes),]


## Add date information
# Check Event_ID
Event_SLAM_DB = SLAM_TER$Event_ID %>% unique()
Event_Date_DB = Date_TER$Event_ID %>% unique()

PB_Event = Event_Date_DB[!(Event_Date_DB %in% Event_SLAM_DB)]
PB_Event = Date_database[Date_database$Event_ID %in% PB_Event,]

SLAM_TER = merge(
    SLAM_TER,
    select(
        Date_TER,
        Event_ID,
        Placement,
        Sampling.Date,
        Notes,
        Season,
        Year
    ),
    by = "Event_ID"
) %>% arrange(Event_ID, MF)

# filter Samples between 70 and 110 days
SLAM_TER$nb_days = as.numeric(SLAM_TER$Sampling.Date - SLAM_TER$Placement)
SLAM_TER = SLAM_TER[SLAM_TER$nb_days %in% c(70:110),]

## Checking Sample availability
Note_SLAM_TER = unique(SLAM_TER$Notes)
SLAM_TER = SLAM_TER %>% filter(is.na(Notes))

## Checking number of samples available per seasons and years
data_available = SLAM_TER %>% select(site_codes, Year, Season) %>% unique()
data_available$site_codes = as.factor(data_available$site_codes)
data_available$sampling_period = as.factor(
    paste(
        data_available$Season,
        data_available$Year,
        sep = "_"
    )
)
table(data_available$sampling_period)

## Compute Mat com
Mat_com = SLAM_TER %>%
    select(
        site_codes,
        MF,
        Total_Abundance_90,
        Total_Abundance_Adult_90,
        Season,
        Year
    ) %>% 
    group_by(
        MF,
        site_codes,
        Season,
        Year
    ) %>% 
    summarise(
        Total_Abundance_90 = sum(Total_Abundance_90),
        Total_Abundance_Adult_90 = sum(Total_Abundance_Adult_90)
    ) %>%
    ungroup()


## Add time step information
time_step = data.frame(
    Season = rep(c("spring","summer", "autumn", "winter"), 12)
) %>% arrange(Season)
time_step$Year = rep(c(2012:2023), 4)

## Réordonnancement de time_step$Season
time_step$Season <- factor(time_step$Season,
  levels = c("winter","spring","summer", "autumn")
)
time_step = time_step %>% arrange(Year,Season)
time_step$step = as.numeric(row.names(time_step))

Mat_com = merge(
    Mat_com,
    time_step,
    by = c("Year", "Season")
)
# Time step available
time_step_available = sort(unique(Mat_com$step))

# Continuous time series between Summer 2013 (Time step 7) and Winter 2023 (time step 45)
Season_available = time_step[time_step$step %in% time_step_available,]
Mat_com = Mat_com %>% filter(step %in% c(7:45))
Season_available = Season_available %>% filter(step %in% c(7:45))
Season_available$sampling_period = paste(
    Season_available$Season,
    Season_available$Year,
    sep = "_"
)
Mat_com$sampling_period = as.factor(paste(Mat_com$Season, Mat_com$Year, sep = "_"))

### Post balancing data
iteration_table = data.frame(
    sampling_period = NA,
    MF = NA,
    Total_Abundance_90 = NA,
    Total_Abundance_Adult_90 = NA
) %>% na.omit()

for (iteration_nb in 1:10000) {
   print(iteration_nb)

    temp_table = data.frame(
        sampling_period = NA,
        MF = NA,
        Total_Abundance_90 = NA,
        Total_Abundance_Adult_90 = NA
    ) %>% na.omit()

    for(step_selected in Season_available$step){
        # print(step_selected)


        season_selected = paste(
            Season_available$Season[Season_available$step == step_selected],
            Season_available$Year[Season_available$step == step_selected],
            sep = "_"
        )
        # print(season_selected)

        possible_site = data_available$site_codes[data_available$sampling_period == season_selected]
        site_selected = sample(possible_site, 3)
        data_selected = Mat_com %>% filter(sampling_period == season_selected & site_codes %in% site_selected)
        data_selected = data_selected %>% 
            group_by(
                sampling_period,
                MF
            ) %>%
            summarise(
                # Divide by 3 => data site wise
                # Multiply by 10 => data for 10 sites
                Total_Abundance_90 = 10 * sum(Total_Abundance_90) / 3, 
                Total_Abundance_Adult_90 = 10 * sum(Total_Abundance_Adult_90) / 3
            )

        temp_table = rbind(temp_table, data_selected)
    }
    iteration_table = rbind(iteration_table, temp_table)
}

iteration_table = iteration_table %>%
    group_by(
        sampling_period,
        MF
    ) %>%
    summarise(
        Total_Abundance_90 = mean(Total_Abundance_90),
        Total_Abundance_Adult_90 = mean(Total_Abundance_Adult_90),
        Total_Abundance_Juvenile_90 = mean(Total_Abundance_90) - mean(Total_Abundance_Adult_90)
    )


Mat_com_Total = dcast(
    iteration_table,
    sampling_period ~ MF,
    fun.aggregate = sum,
    fill = 0,
    value.var = "Total_Abundance_90"
) %>% arrange(sampling_period)

Mat_com_Adult = dcast(
    iteration_table,
    sampling_period ~ MF,
    fun.aggregate = sum,
    fill = 0,
    value.var = "Total_Abundance_Adult_90"
) %>% arrange(sampling_period)

Mat_com_Juv = dcast(
    iteration_table,
    sampling_period ~ MF,
    fun.aggregate = sum,
    fill = 0,
    value.var = "Total_Abundance_Juvenile_90"
) %>% arrange(sampling_period)

Mat_com_Total = merge(
    Mat_com_Total,
    select(
        Season_available,
        sampling_period,
        step
    ),
    by = "sampling_period"
) %>% arrange(step)

Mat_com_Adult = merge(
    Mat_com_Adult,
    select(
        Season_available,
        sampling_period,
        step
    ),
    by = "sampling_period"
) %>% arrange(step)

Mat_com_Juv = merge(
    Mat_com_Juv,
    select(
        Season_available,
        sampling_period,
        step
    ),
    by = "sampling_period"
) %>% arrange(step)


## Select MF with sufficient number of individuals (at least 100 adults over 10 years)
summary_abundance = colSums(
    select(
        Mat_com_Adult,
        -c(step, sampling_period)
    )
)
summary_abundance = as.data.frame(summary_abundance)
summary(summary_abundance)
summary_abundance$MF = row.names(summary_abundance)

summary_abundance = summary_abundance[summary_abundance$summary_abundance > 100,]

MF_selected = summary_abundance$MF

Mat_com_Adult_dominant = select(
    Mat_com_Adult,
    "step", "sampling_period", MF_selected
)
Mat_com_dominant = select(
    Mat_com_Total,
    "step", "sampling_period", MF_selected
)
Mat_com_Juv_dominant = select(
    Mat_com_Juv,
    "step", "sampling_period", MF_selected
)

## Saving datasets
write.table(
    Mat_com_Adult_dominant,
    "data/diversity_data/Matrix_Adults_dominant.csv",
    sep = ";",
    row.names = F
)
write.table(
    Mat_com_dominant,
    "data/diversity_data/Matrix_Total_dominant.csv",
    sep = ";",
    row.names = F
)
write.table(
    Mat_com_Juv_dominant,
    "data/diversity_data/Matrix_Juv_dominant.csv",
    sep = ";",
    row.names = F
)