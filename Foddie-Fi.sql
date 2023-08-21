 -- How many customers has Foodie-Fi ever had?
  select distinct customer_id from subscriptions;
  -- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
  select * from subscriptions;
  select month(start_date),count(distinct customer_id) from subscriptions
  where plan_id=0
  group by month(start_date);
  
