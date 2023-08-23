-- How many customers has Foodie-Fi ever had?
  select distinct customer_id from subscriptions;
  
  -- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
 select month(start_date),count(distinct customer_id) from subscriptions
  where plan_id=0
  group by month(start_date);
  
  -- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
  select subscriptions.plan_id,count(subscriptions.plan_id) as events_count,plan_name from subscriptions inner join plans on subscriptions.plan_id=plans.plan_id
  where year(start_date)>2020
  group by subscriptions.plan_id;
  
   -- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
  select plan_name,round(count(distinct customer_id) * 100 /(select count(distinct customer_id) from subscriptions),2) as churned_percentage,subscriptions.plan_id
  ,count(distinct customer_id) as churned_customers,(select count(distinct customer_id) from subscriptions) as total_count from subscriptions
  inner join plans on subscriptions.plan_id=plans.plan_id
  where subscriptions.plan_id=4;
  
  -- How many customers have churned straight after their initial free trial - what percentage 
  WITH next_plan_cte AS
  (SELECT *,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   FROM subscriptions),
     churners AS
  (SELECT *
   FROM next_plan_cte
   WHERE next_plan=4
     AND plan_id=0)
SELECT count(customer_id) AS 'churn after trial count',
round(100 *count(customer_id)/
(SELECT count(DISTINCT customer_id) AS 'distinct customers'
FROM subscriptions), 2) AS 'churn percentage'
 FROM churners;
 
--  What is the number and percentage of customer plans after their initial free trial?

WITH total_plan_cte AS
  (SELECT customer_id,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan,plan_id
   FROM subscriptions )
   select  next_plan,count(next_plan) as next_plan_count,round(count(next_plan)*100/(select count(distinct customer_id) from subscriptions),2) as total_count 
   from total_plan_cte
   where plan_id=0
group by next_plan;
   
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31
WITH latest_plan_cte AS
  (SELECT *,row_number() over(PARTITION BY customer_id
                            ORDER BY start_date DESC) AS latest_plan
   FROM subscriptions
   JOIN plans USING (plan_id)
   WHERE start_date <='2020-12-31')
select count(distinct customer_id) as latest_customers_count, round(count(distinct customer_id)/(select count(customer_id) from latest_plan_cte),2) as latest_customers 
,plan_id from latest_plan_cte
where latest_plan=1
group by plan_id;

-- How many customers have upgraded to an annual plan in 2020?
WITH upgraded_plan_cte AS
  (SELECT customer_id,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan,plan_id
   from subscriptions
   where year(start_date)=2020)
select count(customer_id) as total_upgraded_annualplan from upgraded_plan_cte
where next_plan=3;


   
   -- -- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with average as (select customer_id,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan,plan_id,start_date
   from subscriptions where year(start_date)=2020)
   select count(customer_id) as customers_downgraded from average
   where plan_id=2 and next_plan =1;

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with average as (select customer_id,
          lead(start_date, 1) over(PARTITION BY customer_id
                                ORDER BY start_date)  AS next_date,plan_id,start_date,
		   lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   from subscriptions )
select * from average
where  plan_id=0;

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trial_plan_customer_cte AS
  (SELECT *
   FROM subscriptions
   JOIN plans USING (plan_id)
   WHERE plan_id=0),
     annual_plan_customer_cte AS
  (SELECT *
   FROM subscriptions
   JOIN plans USING (plan_id)
   WHERE plan_id=3)


SELECT avg(datediff(annual_plan_customer_cte.start_date, trial_plan_customer_cte.start_date)) AS avg_conversion_days
FROM trial_plan_customer_cte
INNER JOIN annual_plan_customer_cte USING (customer_id);
