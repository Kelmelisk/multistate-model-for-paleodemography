# Load required libraries
install.packages("remotes")
remotes::install_github("MichaelHoltonPrice/demohaz")

install.packages("demohaz")
library(devtools)
library(demohaz)

setwd("C:/Users/Saige.Kelmelis/OneDrive - The University of South Dakota/github/kelmelis_price_danish_multistate")

# Read the CSV file
data <- read.csv("Danish_data_multistate.csv")

# Extract the 'Final Age' column for our analysis
x <- data$Final.Age

# Extract the LEH column and convert it to a numeric vector
ill <- as.numeric(data$LEH)

# Remove observations where ill is NA
valid_data <- !is.na(ill)
x <- x[valid_data]
ill <- ill[valid_data]

# Siler parameter vector from Gage and Dyke 1986, Table 2, Level 15.
a <- c(.175, 1.40, .368 * .01, .075 * .001, .917 * .1)

# Convert the traditional parameterization, a, to the more robust
# parameterization used by demohaz, b.
b <- trad_to_demohaz_siler_param(a)

# The full parameter vector is th = c(k1, k2, b), where k1 is the
# constant transition hazard from the well to ill state, k2 is the factor by
# which the mortality hazard out of the ill state is larger than that out of the
# well state, and b is the Siler parameters.
# We'll use the same initial values as in the simulation script
th0 <- c(2e-2, 1.2, b)

# Set up the fitting parameters
rp <- 20
num_cyc <- 200

# Set up the temperature vector and proposal scale matrix as in the original script
temp_vect = 10^(rev(seq(-1,1,by=.25)))
num_param <- length(th0)
just_scale <- t(replicate(num_param,
                          rev(seq(0.0001,1,len=length(temp_vect)))))
just_param <- replicate(length(temp_vect),.1)
prop_scale_mat <- just_scale * just_param

# Print data summary before fitting
print("Data summary before fitting:")
print(paste("Number of observations:", length(x)))
print(paste("Number with LEH:", sum(ill)))
print(paste("Age range:", min(x), "to", max(x), "years"))

# Fit the model to the real data
fit <- temper_and_tune_usher3(verbose=TRUE,
                              report_period=rp,
                              num_cyc=num_cyc,
                              prop_scale_mat=prop_scale_mat,
                              x=x,
                              ill=ill)

# Extract the fitted parameters
th_fit <- fit$th_temper

# Plot the fitted hazard functions
xcalc <- seq(0, max(x), by=0.01)
haz_well <- hsiler(xcalc, th_fit[3:7])
haz_ill <- th_fit[2] * haz_well

png("fitted_hazards.png")
plot(xcalc, haz_well, type="l", col="blue", lwd=3,
     xlab='Age [Years]', ylab='Fitted Mortality Hazard',
     ylim=range(c(haz_well, haz_ill)))
lines(xcalc, haz_ill, col="red", lwd=3)
legend("topleft", legend=c("Well", "Ill"), col=c("blue", "red"), lwd=3)
dev.off()

# Create histogram with fitted density overlay
png("age_distribution_fitted.png", width = 800, height = 600)

# Calculate the breaks for the histogram
breaks <- seq(min(x), max(x), length.out = 31)

# Create the histogram
hist(x, breaks = breaks, probability = TRUE, 
     main = "Age Distribution with Fitted Density",
     xlab = "Age (years)", ylab = "Density",
     col = "lightblue", border = "white")

# Calculate the density using usher3_rho1 and usher3_rho2 functions
xcalc <- seq(min(x), max(x), length.out = 1000)
rho1 <- usher3_rho1(xcalc, th_fit[1], th_fit[3:7])
rho2 <- usher3_rho2(xcalc, th_fit[1], th_fit[2], th_fit[3:7])
dens_fitted <- rho1 + rho2

# Add the fitted density curve
lines(xcalc, dens_fitted, col = "red", lwd = 2)

# Add a legend
legend("topright", legend = c("Observed", "Fitted Density"), 
       fill = c("lightblue", NA), border = c("lightblue", NA),
       col = c(NA, "red"), lwd = c(NA, 2))

dev.off()

# Print the fitted parameters
print("Fitted parameters:")
print(th_fit)

# Calculate some summary statistics
print("Summary of the data:")
print(paste("Total number of individuals:", length(x)))
print(paste("Number with LEH:", sum(ill)))
print(paste("Proportion with LEH:", sum(ill) / length(ill)))
print(paste("Age range:", min(x), "to", max(x), "years"))

# Print summary statistics of the age distribution
print("Age Distribution Summary:")
print(summary(x))
print(paste("Standard Deviation:", sd(x)))
