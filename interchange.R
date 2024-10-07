library(ggplot2)
library(igraph)

# Data description: https://www.eia.gov/electricity/gridmonitor/about
interchange_data <- read.csv("EIA930_INTERCHANGE_2023_Jan_Jun.csv")

print(summary(interchange_data))
#print(summary(interchange_data$Hour_Number))
#print(summary(interchange_data$Interchange_MW))

# *******************************************************************

# Idea: The interchange_MW data has 1st and 3rd quartiles at around -200 and 200.
#   So plot a histogram of the data just in the range.
middle_data <- interchange_data$Interchange_MW[abs(interchange_data$Interchange_MW) < 200]
middle_hist <- hist(middle_data, breaks = seq(from= -200.5, to=200.5, by=1))
plot(middle_hist)

# Results: The most common datapoint looks to be zero (by a factor of ~5)!
#   Then frequecies decay exponentially(?) and symmetrically away from 0.
#   But there are funny humps near +/- 10, lazy data?
#   Why would data near +/- 10 be more common?
#   The data description above mentions that BA are sometimes bad with data,
#   So lazy data is more likely?

# *******************************************************************

# Idea: Let's sum the Interchange_MW over each hour,
#   Then plot the sums as a function of time.
interchange_mw_sum_by_hour <- aggregate(Interchange_MW ~ Data_Date + Hour_Number, data = interchange_data, sum)

# Massage date-time
interchange_mw_sum_by_hour$DateTime <- as.POSIXct(
                                        paste(interchange_mw_sum_by_hour$Data_Date, 
                                              interchange_mw_sum_by_hour$Hour - 1), 
                                        format="%m/%d/%Y %H")

ggplot(interchange_mw_sum_by_hour, aes(x = DateTime, y = Interchange_MW)) +
  geom_line() +
  labs(title = "Time Series Plot of Aggregated Values",
       x = "DateTime",
       y = "Sum of Values") +
  theme_minimal()  # Applies a minimalistic theme

ggsave("interchange_MW_time_series.png", width = 40, height = 6)

# Resutls: The sums as a function of time look similar to brownian motion
#   That is, pretty random. I would expect some structure in the total
#   amount of energy flowing in the grid. But perhaps the randomness
#   is expected? The balancing authorities don't *want* to transfer
#   energy if they can avoid it. So any interchange is due to the
#   a random fluxuation in demand not predicted by the BA's model?
#   OR: The interchange data is not duplicated. So, if BA A sends
#   100 MW to BA B, it could be reported as (-100) from A -> B
#   or as (100) B -> A. The same energy is flowing, but the 
#   sums would look different. Might need to model on graph to see
#   real behavior.

# *******************************************************************
# Idea: Study the graph structure of the interchange data, 

# *******************************************************************


# *******************************************************************
# Question: Are there two entries for each physical tie?
#   For each at A -> B (100) entry, is there a corresponding B -> A (-100)?

# AECI -> MISO or MISO -> AECI
AECI_MISO_int_data <- interchange_data[
                        (interchange_data$Balancing_Authority == "AECI" &
                        interchange_data$Directly_Interconnected_Balancing_Authority == "MISO")
                        | 
                        (interchange_data$Balancing_Authority == "MISO" &
                        interchange_data$Directly_Interconnected_Balancing_Authority == "AECI")
                        , ]

# Answer: Yes, there are two entries for each tie datestamp, but they generally disagree
#   That is, A->B (100) and then B->(-70).
#   So this interchange data is very loose.
#   These BA's report an *average* value of the meter read over the entire hour!
#   How to handle these disagreements?
# *******************************************************************

# *******************************************************************
# Prediction: The data of discrepancies between reported values,
#   (just the *sum* of the two reported values, they *should* be equal but oppposite
#   so they *should* sum to 0, but they almost never do!),
#   I was going to say will be approximately normal, so long as your "near zero"
#   histogram bucket is ``wide enough''.
# *******************************************************************

# Idea: The Interchange_MW counts decay exponentially away from zero
#   So create a log-scale histogram
#hist(interchange_data$Interchange_MW, breaks = 300)
#
#count <- hist(interchange_data$Interchange_MW, breaks = 250)
#log_counts <- log1p(count$counts)
#plot(count$mids, log_counts)

# Results: The counts indeed decay exponentially, with a ``shelf''
#   on the right side, near 10000?

# *******************************************************************


# *******************************************************************
# Idea: load the data and analyze with igraph package

#graph <- graph_from_data_frame(d = interchange_data, directed = TRUE,
#                               vertices = NULL, edge.list = c("Balancing_Authority",
#                               "Directly_Interconnected_Balancing_Authority", "Interchange_MW"))
# Unique BAs
#unique(interchange_data$Balancing.Authority)
# [1] "AECI" "AVA"  "AVRN" "AZPS" "BANC" "BPAT" "CHPD" "CISO" "CPLE" "CPLW"
#[11] "DEAA" "DOPD" "DUK"  "EPE"  "ERCO" "FMPP" "FPC"  "FPL"  "GCPD" "GRID"
#[21] "GVL"  "GWA"  "HGMA" "HST"  "IID"  "IPCO" "ISNE" "JEA"  "LDWP" "LGEE"
#[31] "MISO" "NEVP" "NWMT" "NYIS" "PACE" "PACW" "PGE"  "PJM"  "PNM"  "PSCO"
#[41] "PSEI" "SC"   "SCEG" "SCL"  "SEC"  "SEPA" "SOCO" "SPA"  "SRP"  "SWPP"
#[51] "TAL"  "TEC"  "TEPC" "TIDC" "TPWR" "TVA"  "WACM" "WALC" "WAUW" "WWA"
#[61] "YAD"

