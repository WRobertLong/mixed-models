# Code related to my answer for this question on Cross Validated:
# https://stats.stackexchange.com/questions/294929/how-to-estimate-random-effects-for-new-subjects-for-predictions-example-in-gnu
#
# The objective of this post is to forecast future reaction times for new participants using the built-in predict function and a 
# non-parametric bootstrap, within a mixed effects modelling framework. Utilising the same sleepstudy dataset as used in the OP, 
# which is from a study looking at reaction times measured across 9 days for 18 subjects who were sleep-deprived. We first fit a
#  model to 15 subjects (the "training" data). Subsequently, we utilise this fitted model to predict the responses on days 6-9 for
#  the 3 additional subjects, based on their initial observations (days 0 to 5. This procedure entails merging the training and new 
# data, conducting bootstrap resampling to capture variability, and generating forecasts for future days. The objective is to 
# evaluate the level of uncertainty and generate reliable predictions for the reaction times of the new participants.


library(lme4)
library(boot)

# Fit the mixed-effects model to the observed data (only 15 subjects)
data("sleepstudy")
sleepstudy.reduced <- subset(sleepstudy, Subject %in% levels(sleepstudy$Subject)[1:15])
FITTED.reduced <- lmer(Reaction ~ Days + (Days|Subject), sleepstudy.reduced)
summary(FITTED.reduced)

# New observations for three new subjects
sleepstudy.newdata <- subset(sleepstudy, (Subject %in% levels(sleepstudy$Subject)[16:18]) & (Days <= 5))

# Future time points for new subjects
sleepstudy.toPredict <- subset(sleepstudy, (Subject %in% levels(sleepstudy$Subject)[16:18]) & (Days > 5 & Days <= 9))

# Function to refit the model and make predictions
predict_fun <- function(data, newdata) {
  # Fit the model
  fit <- lmer(Reaction ~ Days + (Days|Subject), data = data)
  # Make predictions
  preds <- predict(fit, newdata = newdata, re.form = NULL, allow.new.levels = TRUE)
  return(preds)
}

# Adjust the function to handle newdata
adjusted_predict_fun <- function(data, indices) {
  d <- data[indices, ]
  return(predict_fun(d, sleepstudy.toPredict))
}

# Combine original data with new data for resampling
combined_data <- rbind(sleepstudy.reduced, sleepstudy.newdata)

# Bootstrap resampling
set.seed(123)
boot_results <- boot(combined_data, statistic = adjusted_predict_fun, R = 100)

# Extract bootstrap predictions
bootstrap_predictions <- boot_results$t

# Display a summary of the bootstrap predictions
summary(bootstrap_predictions)

library(ggplot2)
library(reshape2)

# Convert the bootstrap predictions to a data frame
colnames(bootstrap_df) <- paste0("Day", 6:9) 
bootstrap_df <- bootstrap_df[, colnames(bootstrap_df)[!is.na(colnames(bootstrap_df))]]

# Melt the data frame for ggplot2
bootstrap_melted <- melt(bootstrap_df, variable.name = "Day", value.name = "Prediction")

# Plot the distribution of predictions for each day
ggplot(bootstrap_melted, aes(x = Day, y = Prediction)) +
  geom_boxplot() +
  labs(title = "Bootstrap Prediction Distributions for Future Time Points",
       x = "Future Time Points",
       y = "Predicted Reaction Time") +
  theme_minimal()



ggplot(bootstrap_melted, aes(x = Day, y = Prediction)) +
  geom_boxplot() +
  labs(title = "Bootstrap Prediction Distributions for Future Time Points",
       x = "Future Time Points",
       y = "Predicted Reaction Time") +
       geom_density(aes(x = Day, y = stat(scaled)), inherit.aes = FALSE)


library(PupillometryR)

ggplot(bootstrap_melted, aes(x = Day, y = Prediction)) +
  geom_point(
             position = position_jitter(w = .15),
             size = 0.5,
             alpha = 0.05) +
  geom_boxplot(width = .25,
               outlier.shape = NA,
               alpha = 0.5) +
  PupillometryR::geom_flat_violin(position = position_nudge(x = .2),
                   alpha = 0.7,
                   adjust = 0.5)




  coord_flip() +
  scale_x_discrete(expand = c(0,0)) +
  scale_y_continuous(breaks = breaks_width(5000), labels = axis_unit_scaler) +
  scale_fill_manual(values = JACE_COLOR) +
  scale_color_manual(values = JACE_COLOR) +
  guides(fill = guide_legend(title = "Type of verification of the applicant's income",
                             direction = "horizontal",
                             reverse = T),
         color = guide_legend(title = "Type of verification of the applicant's income",
                              direction = "horizontal",
                              reverse = T)) +
  labs(x = "",
       title = "Raincloud Plot of loan amount by 3 different verified income status") +
  theme_jace +
  only_x +
  theme(legend.position = "bottom")


