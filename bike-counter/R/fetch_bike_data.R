# Function fetches data for a given date range
# 
#

fetch_bike_data <- function(input_date){
  
  api_secret <- httr2::secret_decrypt("pEqCEJrx5Gt7Mp6KqVJDBM-Eut7t_wb16TFM-ohFQPOjm68gvBfk_X8n6iPj_8-1Vgtk_JQ7PpbErrXY6As-lL_7V3rAL1XTYHOhhw", "EDINBURGHBIKECOUNTS_KEY")
  
  cycline_scotland_url <- "https://api.usmart.io/org/d1b773fa-d2bd-4830-b399-ecfd18e832f3/5421f510-69b1-4deb-a319-135289598388/latest/urql"
  
  cycling_scotland_resp <- httr2::request(paste0(
    cycline_scotland_url,
    "?limit(-1,0)",
    "gt(startTime,",
    input_date,
    ")"
  ))
   
  
  fetch_bike_data <- cycling_scotland_resp |> 
    httr2::req_headers(
      `cache-control`= "no-cache",
      `api-key-id` = "diarmuid.lloyd@gmail.com",
      `api-key-secret`= api_secret
    ) |>  
    httr2::req_perform() |> # this is where we actually call the uSmart API
    httr2:: resp_body_json() |> # extract the body information
    dplyr::bind_rows()
  
}
