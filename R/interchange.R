here::i_am("R/interchange.R")
pdf(NULL) # So Rscript won't produce duplicate plots

library(ggplot2)
library(readr)
library(here)

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the filename argument was provided
if (length(args) == 0) {
    stop("No year provided. Please provide a year as a command-line argument.")
}

# Use the first argument as the filename
year <- args[1]
file <- paste0("EIA930_INTERCHANGE_", year, "_Jan_Jun.csv.clean")
filename <- here("data", file)

# Read the CSV file
# Data description: https://www.eia.gov/electricity/gridmonitor/about
interchange_data <- read.csv(filename)

# Print summary of the data
# print(summary(interchange_data))

# *******************************************************************

# Idea: Plot a histogram of the data in the range -200 to 200 MW
middle_data <- interchange_data$Interchange_MW[
                abs(interchange_data$Interchange_MW) < 200]
middle_hist <- hist(middle_data, breaks = seq(from = -200.5, to = 200.5, by = 1))

# Save the histogram plot
png(here("fig","middle_histogram.png"))
plot(middle_hist, main = "Histogram of Interchange MW (-200 to 200)",
     xlab = "Interchange MW", ylab = "Frequency", col = "skyblue")
dev.off()

# *******************************************************************

# Idea: Sum the Interchange_MW over all BAs each hour,
#   then plot the sums as a function of time.
interchange_mw_sum_by_hour <- aggregate(Interchange_MW ~ UTC_Time_at_End_of_Hour,
                                        data = interchange_data, sum)

# Massage date-time
interchange_mw_sum_by_hour$DateTime <- as.POSIXct(
  interchange_mw_sum_by_hour$UTC_Time_at_End_of_Hour,
  format = "%m/%d/%Y %H:%M:%S %p"
)

# Plot time series of summed interchange values
p <- ggplot(interchange_mw_sum_by_hour, aes(x = DateTime, y = Interchange_MW)) +
  geom_line(color = "dodgerblue") +
  labs(title = "Hourly Sum of Interchange MW Over Time",
       x = "Hour",
       y = "Hourly Sum of Interchange MW") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = "white"),
        plot.background = element_rect(fill = "white", color = "white"))


ggsave(here("fig","interchange_MW_time_series.png"), plot = p, width = 12, height = 6, bg = "white")

# *******************************************************************

# Idea: Analyze the interchange data between AECI and MISO
AECI_MISO_int_data <- interchange_data[
  (interchange_data$Balancing_Authority == "AECI" &
   interchange_data$Directly_Interconnected_Balancing_Authority == "MISO") |
  (interchange_data$Balancing_Authority == "MISO" &
   interchange_data$Directly_Interconnected_Balancing_Authority == "AECI"),
]

# *******************************************************************

# Idea: The Interchange_MW counts decay exponentially away from zero.
# Create a log-scale histogram to visualize this trend.

# Create the histogram
count <- hist(interchange_data$Interchange_MW, breaks = 250)

# Apply log scaling to the counts
log_counts <- log1p(count$counts)

# Save the log-scale plot
png(here("fig","log_scaled_histogram.png"))
plot(count$mids, log_counts, type = "h",
     main = "Log-Scaled Histogram of Interchange MW",
     xlab = "Interchange MW", ylab = "Log(1 + Frequency)",
     col = "lightcoral")
dev.off()

# *******************************************************************
