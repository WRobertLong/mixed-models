# Reproduces a singular fit in lme4 via simulation (zero random-intercept variance)
# and saves the data that caused it.
# 
# Based on (and slightly refined from) the code in my Cross Validated answer:
# https://stats.stackexchange.com/questions/156725/statsmodels-what-can-cause-linalg-error
#
# If you are reading this in conjunction with the answer I posted, you may find a few 
# differences if I have not got round to updating the code on CV yet. However most
# differences should be minor and related to error handling, formatting etc. If not,
# free to open a GitHub issue.


# setwd("")  # removed for privacy

library(lme4)

# Simulate a dataset and fit a random-intercept LMM.
# Returns a list with:
#   - data  : data.frame used for fitting
#   - model : fitted merMod object, or NULL if model fitting failed
simulate_and_fit <- function(seed, n = 100, groups = 10, beta = 1.5, eps_sd = 1) {

  set.seed(seed)

  group <- factor(rep(seq_len(groups), each = n / groups))
  x <- rnorm(n)

  # Zero variance random intercepts -> tends to produce singular fits
  intercepts <- rep(0, groups)

  y <- beta * x + intercepts[group] + rnorm(n, sd = eps_sd)

  dat <- data.frame(y = y, x = x, group = group)

  fit <- try(lmer(y ~ x + (1 | group), data = dat, REML = FALSE), silent = TRUE)
  model <- if (inherits(fit, "try-error")) NULL else fit

  list(data = dat, model = model)
}

# Loop until a singular fit is found; save the *actual* dataset that produced it
seed <- 1

repeat {
  res <- simulate_and_fit(seed)

  if (!is.null(res$model) && isSingular(res$model)) {
    cat("Singular fit encountered with seed:", seed, "\n")
    write.csv(res$data, file = sprintf("singular_data_seed_%d.csv", seed), row.names = FALSE)
    break
  }

  seed <- seed + 1
}
