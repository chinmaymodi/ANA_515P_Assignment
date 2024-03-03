# README

ANA_515P_Assignment: Project 3, Mental Health in Tech.

Upload Repository for the Data Preparation Assignment of ANA 515P, 2024GSP_ANA_515P_01 Exp Practicum Fundamentals

Dealing with Data Errors:

1. Formatting and Spelling Errors: Most errors are of this type; looking at the data shows how multiple types of entries can be standardized to 1 subtype, e.g. M/m/male/man can all be reduced to M.
2. Missing values: Some rows in the original data had a whole bunch of NA entries and some random columns in some rows. These have been removed where applicable and replaced with assumptions elsewhere.
3. Data Type: There weren't many columns with this type of error. Only the timestamp columns were imported weirdly, and a single conversion fixed this issue.
4. Outliers: The timestamp and age columns had highly improbable outliers. I have handled this by replacing them with assumed values, being the averages of the 'good' values of those columns.

Data File Combination:

The original excel file contained two sheets, which were imported as 2 data frames([Sheet 1](Exported%20Data%20Frames/Original%20Sheets%20read%20into%20Data%20Frames/survey_sheet_1.csv) and [Sheet 2](Exported%20Data%20Frames/Original%20Sheets%20read%20into%20Data%20Frames/survey_sheet_2.csv)) in the code, and then merged into a [single data frame](Exported%20Data%20Frames/Original%20Sheets%20read%20into%20Data%20Frames/original_survey_data.csv).

I have also included the [modified data frame](Exported%20Data%20Frames/Modified%20Data%20Frames/survey_data_with_assumptions.csv), as well as an edited version of the modified data frame that contains only the [comment data](Exported%20Data%20Frames/Modified%20Data%20Frames/entries_with_comments.csv) This is not used in the project, but it's just another step to be taken in real-world projects if comment analysis is something to be done.

These are uploaded in [this commit](../../commit/8847b19e5e280195c92566d5335f6e0f504e9463).

Visuals:

I have included 7 plots generated on multiple variables in [this commit](../../commit/feaaa1e157d83e824bf786c4d0a398357eb76391), based on 1, 2 and 3 variables from the data. They are [here](images).

![](images/Plot%201%20-%20Gender%20Distribution%20Data%20to%20show%20impact%20of%20cleaning.png) This image indicates the impact cleaning data can have on data analytics. The other images are all on the cleaned data and are intended to draw different results.

Plots [6](images/Plot%206%20-%20Impact%20of%20Wellness%20Program%20Availability%20on%20Proportion%20of%20Help%20Seekers.png) and [7](images/Plot%207%20-%20Ease%20of%20taking%20leave%20versus%20Help%20Seeking%20Behavior.png) are the most difficult ones and point us towards us the biggest conclusions to be drawn from this data: the presence of wellness programs, as well as making leave-taking easier, have a positive impact on the trend of employees seeking help.

Comments:

I have commented at each step of the code to show what I am doing, and why I am doing it.

Repository Status:

This is a public repository containing all the relevant files for the project.
I have also included my [R code](Code.R) as well as the [original excel file](survey.xlsx).
