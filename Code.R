## install all the required packages

if (!require(readxl)) {
  install.packages("readxl")
  library(readxl)
}
if (!require(stringr)) {
  install.packages("stringr")
  library(stringr)
}
if (!require(dplyr)) {
  install.packages("dplyr")
  library(dplyr)
}
if (!require(ggplot2)) {
  install.packages("ggplot2")
  library(ggplot2)
}
if (!require(gridExtra)) {
  install.packages("gridExtra")
  library(gridExtra)
}
if (!require(scales)) {
  install.packages("scales")
  library(scales)
}

## read and save the sheets to dataframes

filepath <- "C:/Users/V3rG1L/Desktop/515p/survey.xlsx"

survey_sheet_1 <- read_excel(filepath, sheet = "Sheet1")
survey_sheet_2 <- read_excel(filepath, sheet = "Sheet 2")

## Cleaning the datafiles

# possible errors in formatting, spelling, missing values, data type, outliers, etc

## formatting

# sheet 2 Timestamp imports as decimal for some reason, which is number of days + hours as decimal after epoch, so need to convert it
survey_sheet_2$Timestamp <- as.POSIXct(survey_sheet_2$Timestamp * 86400, origin = "1899-12-30", tz = "UTC")

# After that, we can proceed with merging the data frames before dealing with the remaining errors

# this one will be untouched
original_survey_data <- bind_rows(survey_sheet_1, survey_sheet_2)

original_survey_data <- original_survey_data %>%
  rename_all(tolower)

# For our case, we will replace bad data with some assumed data
survey_data_with_assumptions <- original_survey_data

## Missing values
# first of all, I will remove all rows where atleast half of the columns are set to NA
# Calculate the threshold for half of the columns
threshold <- ncol(survey_data_with_assumptions) / 2

# Keeping rows with fewer than half of the columns as NA
survey_data_with_assumptions <- survey_data_with_assumptions[rowSums(is.na(survey_data_with_assumptions)) < threshold, ]


## data type error

## timestamp
# timestamps can be outside of a valid range, or missing.
start_date <- as.POSIXct("2014-01-01", tz = "UTC")
end_date <- as.POSIXct("2016-12-31", tz = "UTC")
bad_or_missing_timestamps <- is.na(survey_data_with_assumptions$timestamp) | survey_data_with_assumptions$timestamp < start_date | survey_data_with_assumptions$timestamp > end_date
average_good_timestamp <- mean(survey_data_with_assumptions$timestamp[!bad_or_missing_timestamps])

# We defined a valid range, get a record of invalid timestamps, find the average of all the other 'good' timestamps, and replace the poor ones with them

survey_data_with_assumptions$timestamp[bad_or_missing_timestamps] <- average_good_timestamp


## age
# some age values are non-positive or non numeric, assume an allowed age range of [18-75], and replace all age values outside of this range with the mean of valid values

survey_data_with_assumptions$age <- as.numeric(as.character(survey_data_with_assumptions$age))
number_of_bad_age_values <- sum(survey_data_with_assumptions$age < 18 | survey_data_with_assumptions$age > 75 )
average_good_age <- mean(survey_data_with_assumptions$age[!is.na(survey_data_with_assumptions$age) & survey_data_with_assumptions$age >= 18 & survey_data_with_assumptions$age <= 75])

# There are 17 entries that fall outside of expected age values, which includes negative values, 0 values, what would be considered child employment, and immortals :)
# Hence, these will be replaced with the average of 'good' age values, which is 32.1. This is < 2% of total values and should have minimal impact on statistics
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(
    age = if_else(
      is.na(age) | age < 18 | age > 75,
      mean(age[age >= 18 & age <= 75], na.rm = TRUE), # Replace condition
      age # Keep original value
    )
  )

## gender

# This command lets us see all the unique values in the gender column. This will let us standardize and clean the data
unique(survey_data_with_assumptions$gender)

# We have 50 unique values, so we do our best to clean up the data. We will use regex matching. Note that Other encompasses all non m/f identities, as well as data that is filled in any weird formatting other than male/female or its misspellings

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(gender = case_when(
    str_detect(gender, regex("f", ignore_case = TRUE)) ~ "F",
    str_detect(gender, regex("m", ignore_case = TRUE)) ~ "M",
    # Keep unmatched entries as they are
    TRUE ~ "Other"  # Retain the original entry
  ))

# Verify that all entries are one of the 3 categories
# Note that we lump NA values into Other
unique(survey_data_with_assumptions$gender)

## Country

# Check the unique country values
unique(survey_data_with_assumptions$country)

# Some issues in the data are multiple values for USA, as well as people selecting US states for non-US countries. Here, I assume the country selection has a mistake, and change the country to USA

# First we standardize country name for USA
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(country = ifelse(country %in% c("United States", "US", "US"), "USA", country))

# Next we find entries with US state values but non US countries
non_usa_states <- survey_data_with_assumptions %>%
  filter(country != "USA", state != "NA") %>%
  select(country, state)

# Last, we change those entries' country to USA
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(country = ifelse(state != "NA" & country != "USA", "USA", country))

## self_employed
unique(survey_data_with_assumptions$self_employed)
# This data is completely clean

## family_history
unique(survey_data_with_assumptions$family_history)
# This data is completely clean

## treatment
unique(survey_data_with_assumptions$treatment)

# This one has some mix and match entries for yes/no as well as NA, so we employ previously used method of regex matching
# The data suggests that this method will work for us

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(treatment = case_when(
    str_detect(treatment, regex("n", ignore_case = TRUE)) ~ "No",
    str_detect(treatment, regex("y", ignore_case = TRUE)) ~ "Yes",
    # Keep unmatched entries as they are
    TRUE ~ "NA"
  ))

# verify that all the values are now cleaned up
unique(survey_data_with_assumptions$treatment)

## work_interfere
unique(survey_data_with_assumptions$work_interfere)

# This one has 4 values that look valid, and so we replace the other values with NA

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(work_interfere = ifelse(work_interfere %in% c("Sometimes", "Never", "Rarely", "Often"), work_interfere, "NA"))

# verify that all the values are now cleaned up
unique(survey_data_with_assumptions$work_interfere)

## no_employees
unique(survey_data_with_assumptions$no_employees)

# Looking at the raw data as well as the unique values above, I see that apart from valid categorical bracket entries, there seem to be some bad data such as decimal values or dates.
# While the field is imported as a numeric entry, it is safe to assume that these are incorrect values, and we can set them to NA

valid_company_size_categories <- c("100-500", "More than 1000", "26-100", "500-1000")

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(no_employees = ifelse(no_employees %in% valid_company_size_categories, no_employees, "NA"))

# verify that all the values are now cleaned up
unique(survey_data_with_assumptions$no_employees)

## remote_work
unique(survey_data_with_assumptions$remote_work)
uniqueCounts <- table(survey_data_with_assumptions$remote_work)
print(uniqueCounts)

# I see that almost all entries follow the no/yes format, so I will set the other entries to "NA"
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(remote_work = ifelse(remote_work %in% c("Yes", "No"), remote_work, "NA"))

## tech_company
unique(survey_data_with_assumptions$tech_company)
uniqueCounts <- table(survey_data_with_assumptions$tech_company)
print(uniqueCounts)

# same as remote_work, I will set the non Yes/No entries to "NA"

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(tech_company = ifelse(tech_company %in% c("Yes", "No"), tech_company, "NA"))

## benefits
unique(survey_data_with_assumptions$benefits)
uniqueCounts <- table(survey_data_with_assumptions$benefits)
print(uniqueCounts)

# Here, we have 3 unique type of values, Yes, No and variants of 'not sure'. So, I will change all non Yes/No values to "Unsure"
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(benefits = ifelse(benefits %in% c("Yes", "No"), benefits, "Unsure"))

## care_options
unique(survey_data_with_assumptions$care_options)
uniqueCounts <- table(survey_data_with_assumptions$care_options)
print(uniqueCounts)
# This data is completely clean

## wellness_program
unique(survey_data_with_assumptions$wellness_program)
uniqueCounts <- table(survey_data_with_assumptions$wellness_program)
print(uniqueCounts)
# This data is completely clean

## seek_help
unique(survey_data_with_assumptions$seek_help)
uniqueCounts <- table(survey_data_with_assumptions$seek_help)
print(uniqueCounts)

# again a trinary option variable, so we set all non Yes/No values "to Unsure"
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(seek_help = ifelse(seek_help %in% c("Yes", "No"), seek_help, "Unsure"))

## anonymity
unique(survey_data_with_assumptions$anonymity)
uniqueCounts <- table(survey_data_with_assumptions$anonymity)
print(uniqueCounts)

# again a trinary option variable, so we set all non Yes/No values "to Unsure"
survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(anonymity = ifelse(anonymity %in% c("Yes", "No"), anonymity, "Unsure"))

## leave
unique(survey_data_with_assumptions$leave)
uniqueCounts <- table(survey_data_with_assumptions$leave)
print(uniqueCounts)
# This data is completely clean assuming it was a 4 button radio choice with additional "Don't know" option.

## mental_health_consequence
unique(survey_data_with_assumptions$mental_health_consequence)
uniqueCounts <- table(survey_data_with_assumptions$mental_health_consequence)
print(uniqueCounts)
# This data is completely clean

## phys_health_consequence
unique(survey_data_with_assumptions$phys_health_consequence)
uniqueCounts <- table(survey_data_with_assumptions$phys_health_consequence)
print(uniqueCounts)

# This has some malformed values but still falls within trinary options, so we handle it accordingly. Set NA to "Unsure" as well

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(phys_health_consequence = case_when(
    grepl("maybe", tolower(phys_health_consequence)) ~ "Unsure",
    grepl("y", tolower(phys_health_consequence)) ~ "Yes",
    grepl("n", tolower(phys_health_consequence)) ~ "No",
    TRUE ~ "Unsure"
  ))

## coworkers
unique(survey_data_with_assumptions$coworkers)
uniqueCounts <- table(survey_data_with_assumptions$coworkers)
print(uniqueCounts)

# This has some malformed values but still falls within trinary options, so we handle it accordingly. Set NA to and bad values to "Unsure".

survey_data_with_assumptions <- survey_data_with_assumptions %>%
  mutate(coworkers = case_when(
    grepl("some", tolower(coworkers)) ~ "Some of them",
    grepl("y", tolower(coworkers)) ~ "Yes",
    grepl("n", tolower(coworkers)) ~ "No",
    TRUE ~ "Unsure"
  ))

## supervisor
unique(survey_data_with_assumptions$supervisor)
uniqueCounts <- table(survey_data_with_assumptions$supervisor)
print(uniqueCounts)
# This data is completely clean

## mental_health_interview
unique(survey_data_with_assumptions$mental_health_interview)
uniqueCounts <- table(survey_data_with_assumptions$mental_health_interview)
print(uniqueCounts)
# This data is completely clean

## phys_health_interview
unique(survey_data_with_assumptions$phys_health_interview)
uniqueCounts <- table(survey_data_with_assumptions$phys_health_interview)
print(uniqueCounts)
# This data is completely clean

## mental_vs_physical
unique(survey_data_with_assumptions$mental_vs_physical)
uniqueCounts <- table(survey_data_with_assumptions$mental_vs_physical)
print(uniqueCounts)
# This data is completely clean

## obs_consequence
unique(survey_data_with_assumptions$obs_consequence)
uniqueCounts <- table(survey_data_with_assumptions$obs_consequence)
print(uniqueCounts)
# This data is completely clean

## comments
# comments have a different type of value for data. We create a separate dataframe with rows that have actual comments, i.e. not NA and not empty

survey_data_with_assumptions_only_comments <- survey_data_with_assumptions[!is.na(survey_data_with_assumptions$comments) & survey_data_with_assumptions$comments != "NA", ]
# This is a separate dataframe that can then further be used to analyze actual comment content


## Plots
# Plot 1

p1 <- ggplot(survey_data_with_assumptions, aes(x = gender)) + geom_bar() + labs(title = "Gender Distribution on cleaned data")
p2 <- ggplot(original_survey_data, aes(x = gender)) + geom_bar() + labs(title = "Gender Distribution on original data")

# Arranging them in one grid
grid.arrange(p1, p2, ncol = 2)

# Plot 2

ggplot(survey_data_with_assumptions, aes(x = age)) + geom_histogram(binwidth = 5) + labs(title = "Age Distribution on cleaned data")

# Plot 3

survey_data_with_assumptions$self_employed <- factor(survey_data_with_assumptions$self_employed)
ggplot(survey_data_with_assumptions, aes(x = "", fill = self_employed)) + geom_bar(width = 1) + coord_polar(theta = "y") + labs(fill = "Self Employment", title = "Self Employment Status")

# Plot 4

survey_data_with_assumptions$Date <- as.Date(survey_data_with_assumptions$timestamp)
daily_counts <- as.data.frame(table(survey_data_with_assumptions$Date))

ggplot(daily_counts, aes(x = Var1, y = Freq)) +
  geom_line(group=1, color="blue") + # Line plot to show trends
  labs(title = "Entries Over Time",
       x = "Date",
       y = "Number of Entries") +
  theme_minimal()

# Plot 5

cumulative_entries <- survey_data_with_assumptions %>%
  group_by(Date) %>%
  summarise(Entries = n()) %>%
  mutate(Cumulative_Entries = cumsum(Entries))

# Plotting the cumulative sum over time
ggplot(cumulative_entries, aes(x = Date, y = Cumulative_Entries)) +
  geom_line(color = "blue") + 
  geom_point(color = "red") +
  labs(title = "Cumulative Sum of Entries Over Time",
       x = "Date",
       y = "Cumulative Entries") +
  theme_minimal()

# Plot 6

ggplot(survey_data_with_assumptions, aes(x = wellness_program, fill = seek_help)) +
  geom_bar(position = "dodge") +
  labs(title = "Seek Help vs Wellness Program Availability",
       x = "Wellness Program",
       y = "Count",
       fill = "Seek Help") +
  scale_fill_brewer(palette = "Set1") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Plot 7

survey_data_with_assumptions$leave <- factor(survey_data_with_assumptions$leave, levels = c("Don't know", "Very difficult", "Somewhat difficult", "Somewhat easy", "Very easy"))

# Modify the seek_help column to combine "No" and "Unsure"
survey_data_with_assumptions$seek_help <- as.character(survey_data_with_assumptions$seek_help)
survey_data_with_assumptions$seek_help[survey_data_with_assumptions$seek_help == "No" | survey_data_with_assumptions$seek_help == "Unsure" | is.na(survey_data_with_assumptions$seek_help)] <- "No/Unsure"
unique(survey_data_with_assumptions$seek_help)
uniqueCounts <- table(survey_data_with_assumptions$seek_help)
print(uniqueCounts)

# Ensure leave and seek_help are factors for proper ordering in the plot
survey_data_with_assumptions$seek_help <- factor(survey_data_with_assumptions$seek_help, levels = c("Yes", "No/Unsure"))

ggplot(survey_data_with_assumptions, aes(x = leave, fill = seek_help)) +
  geom_bar(position = "fill", aes(y = ..count.. / tapply(..count.., ..x.., sum)[..x..])) + # Calculate percentages
  scale_y_continuous(labels = scales::percent_format()) + # Convert y-axis to percentage
  geom_text(aes(label = scales::percent(..count.. / tapply(..count.., ..x.., sum)[..x..], accuracy = 1)),
            position = position_fill(vjust = 0.5), stat = "count", size = 3) + # Add percentage labels
  labs(title = "Percentage of Participants Who Sought Help by Ease of Taking Leave",
       x = "Ease of Taking Leave",
       y = "Percentage",
       fill = "Sought Help") +
  scale_fill_brewer(palette = "Set1") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


## File exporting
write.csv(survey_sheet_1, "C:/Users/V3rG1L/Desktop/515p/survey_sheet_1.csv", row.names = FALSE)
write.csv(survey_sheet_2, "C:/Users/V3rG1L/Desktop/515p/survey_sheet_2.csv", row.names = FALSE)
write.csv(original_survey_data, "C:/Users/V3rG1L/Desktop/515p/original_survey_data.csv", row.names = FALSE)
write.csv(survey_data_with_assumptions_only_comments, "C:/Users/V3rG1L/Desktop/515p/entries_with_comments.csv", row.names = FALSE)
write.csv(survey_data_with_assumptions, "C:/Users/V3rG1L/Desktop/515p/survey_data_with_assumptions.csv", row.names = FALSE)