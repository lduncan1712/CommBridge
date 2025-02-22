library(RPostgres)
library(jsonlite)
library(dbscan)
library(dplyr)
library(tidyr)
library(purrr)

creds <- fromJSON("CommBridge\\credentials\\db_creds.json")

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = creds$dbname,
  host = creds$host,
  port = creds$port,
  user = creds$user,
  password = creds$password
)

data <- dbGetQuery(con, "SELECT 
                            id,
                            content,
                            sparticipant,
                            sroom,
                            m3_response,
                            m4_weight,
                            m5_turn,
                            m1_past,
                            EXTRACT(EPOCH FROM start) as time,
                            day
                         from 
                            communication
                         where 
                          NOT start is NULL
                          and NOT sroom is NULL
                         order by
                            sroom, start
                         ")



generate_clusters <- function(rows){
  
  #Grouping By Sequential Interaction
  grouped <- aggregate(time ~ day + m5_turn,
                       data = rows,
                       FUN = mean)
  
  #Clustering using HDBSCAN
  clustering <- hdbscan(as.matrix(grouped[,"time"]), minPts = 2)
  
  #Ungrouping Sequential
  grouped$cluster <- clustering$cluster
  merged_data <- merge(data_in_room, grouped[, c("date", "m5_turn", "cluster")], 
                       by = c("date", "m5_temp"), all.x = TRUE)
  
  
  
  
  
  
  
  
  compute_entropy <- function(participants,weights) {
    
    weights <- tapply(weights,participants,sum,na.rm=TRUE)
    
    probabilities <- weights / sum(weights)
    
    entropy <- -sum(probabilities *log2(probabilities), na.rm = TRUE)
    
    return(entropy)
    
    
  }
  
  
  
  
  
  
  compute_weighted_varience <- function(times,weights){
    
    if (length(times) > 1){
      
      weighted_mean <- sum(times*weights,na.rm=TRUE)/sum(weights,na.rm=TRUE)
      
      weighted_var <- sum(weights * (times - weighted_mean)^2, na.rm = TRUE) / sum(weights, na.rm = TRUE)
      
      return(as.integer(weighted_var))
      
    } else{
      return(0L)
    }
    
  }
  
  
  
  
  rooms <- unique(data$temp_super_room)
  
  for (room in rooms){
    
    data_in_room <- data[data$temp_super_room == room,]
    
    clustered <- generate_clusters(data_in_room)
    
    data$m5_cluster[data$temp_super_room == room] <- clustered$cluster
  }
  
  
  
  
  agg_data <- data |>
    group_by(sroom, day) |>
    summarise(
      m1_weight = sum(m4_weight), #Total Communication
      m2_entropy = compute_entropy(sparticipant, m4_weight),  #How Split By Paritcipant It Is
      m3_entropy = compute_entropy(sparticipant[-1], m3_response[-1]),  #Split In Response Times By Participant
      m4_varience = var(m1_past[-1],na.rm=TRUE),    #How dense communication is,
      m5_turn = sum(m4_weight)/n_distinct(m5_turn)  #Turn Size
    ) 
  
  
  
  dbWriteTable(con, "communication_aggregate", agg_data, append = TRUE, row.names = FALSE)
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  return(merged_data)
}