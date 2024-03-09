# Testing using an API for pulling in Edinburgh bike count numbers
library(tidyverse)
library(httr2)
library(jsonlite)
library(arrow) # for saving as a parquet file


# I first generate a key, and scrambled my API secret using it. I then saved
# the key into my environment variable, so I can unscramble it my directly referring to it.
# see httr2 vignette on this. Very helpful!
# https://httr2.r-lib.org/articles/wrapping-apis.html#secret-management
# 
# key <- httr2::secret_make_key()



api_secret <- httr2::secret_decrypt("pEqCEJrx5Gt7Mp6KqVJDBM-Eut7t_wb16TFM-ohFQPOjm68gvBfk_X8n6iPj_8-1Vgtk_JQ7PpbErrXY6As-lL_7V3rAL1XTYHOhhw", "EDINBURGHBIKECOUNTS_KEY")

# Define the paths -----------

cycline_scotland_url <- "https://api.usmart.io/org/d1b773fa-d2bd-4830-b399-ecfd18e832f3/5421f510-69b1-4deb-a319-135289598388/latest/urql"

edinburgh_cc_url <- "https://api.usmart.io/org/d1b773fa-d2bd-4830-b399-ecfd18e832f3/7aa487cd-3cd5-405b-850e-1e2ac317816c/latest/urql"

# Requesting data ---------

# Carry out a test request; the limit(-1) catches all the data.
cycling_scotland_resp <- request(
 paste0(cycline_scotland_url,"?limit(-1,0)")
  ) 

edinburgh_cc_resp <- request(
 paste0(edinburgh_cc_url,"?limit(-1,0)")
  ) 

cycling_scotland_resp |> req_dry_run()

edicc <- edinburgh_cc_resp |> 
  req_headers(
    `cache-control`= "no-cache",
    `api-key-id` = "diarmuid.lloyd@gmail.com",
    `api-key-secret`= api_secret
  ) |>  
  req_perform() |> # this is where we actually call the uSmart API
  resp_body_json() |> # extract the body information
  bind_rows()

cycling_scotland <- cycling_scotland_resp |> 
  req_headers(
  `cache-control`= "no-cache",
  `api-key-id` = "diarmuid.lloyd@gmail.com",
  `api-key-secret`= api_secret
) |>  
  req_perform() |> # this is where we actually call the uSmart API
  resp_body_json() |> # extract the body information
  bind_rows()

# Write data --------
arrow::write_parquet(edicc,"data/edinburgh_cc_bike_counter.parquet")
arrow::write_parquet(cycling_scotland,"data/cycling_scotland_counter.parquet")


# Requesting all the data all the time isn't very practical, given the length of time it takes. 
# So, let's request only the data covering the past week.
 past_seven_days <- Sys.Date() - 366
 
 
# I can't get the req_url_query command to work, or understand how it relates
# to the uSmart API. But I can build it manually using paste0...
data_seven_days <- request(
  paste0(cycline_scotland_url,
         "?limit(-1)",
         "gt(startTime,",past_seven_days,")")
) |> 
  req_headers(
  `cache-control`= "no-cache",
  `api-key-id` = "diarmuid.lloyd@gmail.com",
  `api-key-secret`= api_secret
) |>  
  req_perform() |> # this is where we actually call the uSmart API
  resp_body_json() |> # extract the body information
  bind_rows()


data_seven_days |> 
  group_by(area, location, startTime) |> 
  filter(area == "Edinburgh", count>0) |> 
  mutate(startTime = as_datetime(startTime)) |> 
  ggplot(aes(x = startTime, y = count, colour = location)) +
  geom_point(alpha = 0.1) +
  geom_smooth() +
  scale_color_viridis_d() +
  theme_minimal()



