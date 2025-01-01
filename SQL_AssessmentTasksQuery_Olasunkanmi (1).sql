/* Technical Assessment for Junior BI Analyst Role

   SQL Assessment Tasks / Queries to provide insights for all business questions  */

/* Data Exploration to better understand the table, clean and transform if need be;

KEY FINDINGS; Our dataset is well-organized and clean, with accurate data types throughout the four tables, as i 
utilized dbo while importing data from the flat file through the import wizard. 

~~ We have a dataset of 50 distinct Clients across 5 industries, with 990 distinct end users, these users completed 5000 distinct
   transactions within 3 years between 22/11/2020 and 23/11/2024, indicating that some end users have initiated multiple transactions
   from 10,000 interactions.

~~ NOTE: From data exploration, I noticed we have a few transactions and interactions that have transaction_date and interaction_date
   in the year 2020 and we don't have any client data that was onboarded in 2020.

~~ I decided to delete datapoints from the Transactions and Interactions table that were from 2020, so we can have accurate
   analysis, as we've money calculations involved in our analysis as well as give our clients accurate timely insights.    */

/* First, before deleting rows from Transactions and Interactions i created backup of my table to avoid any data loss  */

   SELECT * INTO Backup_Interactions_Table
     FROM Interactions;


   SELECT * INTO Backup_Transactions_Table
     FROM Transactions;

 /* Previewing the data to be DELETED, 273 and 150 datapoint were deleted from Interactions and Transactions table respectively  */

   SELECT COUNT(*) 
   FROM Interactions 
   WHERE YEAR(timestamp) = 2020; 

   SELECT COUNT(*)
   FROM Transactions 
   WHERE YEAR(transaction_date) = 2020

   DELETE FROM Interactions
   WHERE YEAR(timestamp) = 2020;

   DELETE FROM Transactions
   WHERE YEAR(transaction_date) = 2020;


/* 2. Client Engagement Analysis

 Logic: Join Clients and Interactions tables using INNER JOIN to match each interaction with corresponding client details. 
 Used COUNT() to aggregate total interactions for each clients, utilized WHERE clause with DATEADD() and GETDATE() to ensures
 only interactions from the last 2years are considered. The results were grouped by message direction for detail, then sorted 
 in descending order, and used TOP 5 in the select statement to return the top five clients.
 
 Insights: Three of the top five Clients were Outbound message directions */

 SELECT 
       TOP 5
       C.client_id AS Client_Id,
       client_name AS Client_Name,
	   message_direction AS Message_Directions,
	   COUNT(message_id) AS Total_Interactions

 FROM Interactions I
 JOIN [Clients ] C ON I.client_id = C.client_id

 WHERE I.timestamp >= DATEADD(YEAR, -2, GETDATE())

 GROUP BY C.client_id, client_name, message_direction

 ORDER BY Total_Interactions DESC;



/* 3. User Demographics and Engagement;

      Logic: To the region, join End_Users and Clients tables ON client_id. Aggregated the average user engagement 
	  score using the ROUND(AVG()) function for clarity. Additionally, utilized the WHERE() clause in conjunction with
	  the >= and <= operators to restrict the results to users whosea ages fall within include age 25 and 40.

      Insight: The data shows that females in Europe have the highest user engagement scores, while males in South America and
	  females in North America exhibit the lowest average user engagement scores.  */

 SELECT 
       region AS Region,
       gender AS Gender,
	   ROUND(AVG(user_engagement_score),2) AS Avg_User_Engagement_Score

 FROM [End Users] E
 JOIN [Clients ] C ON E.client_id = C.client_id

 WHERE age >= 25 and age<= 40

 GROUP BY region,gender

 ORDER BY Avg_User_Engagement_Score DESC;


/* Transaction Anlaysis;

    Logic: Transactions table does not have a direct relationship with the Clients table. I joined End_Users with Clients table
     based on the end_user_id and then connected the End_Users table to the Transaction table to retrieve the client_id and
	client name.  To filter only successful transactions from the past year, I wrote two conditions, in the WHERE() clause
	combined DATEADD() and GETDATE() to filter only transactions that occured with the last 12 months, and implemented 
	ROUND and SUM in the SELECT statement to accurately calculate and output the Total_TransactionAmount per client.

    Insights: Wade, Bentley and Patton is the top-performing clients, achieving the highest total value of successful transactions
	at $4,372.95. In contrast, Alvarado LLC is the least-performing client, with a total of $564.46 in transactions over the past 
	year.  */

 SELECT 
       E.client_id AS Client_ID,
       client_name AS Client_Name,
	   ROUND(SUM(transaction_amount),2) AS Total_TransactionAmount

  FROM Transactions T
  JOIN [End Users] E ON T.end_user_id = E.end_user_id
  JOIN [Clients ] C ON C.client_id = E.client_id

 WHERE transaction_status = 'Successful'
      AND
	  T.transaction_date >= DATEADD(YEAR, -1, GETDATE())

 GROUP BY E.client_id, C.client_name

 ORDER BY Total_TransactionAmount DESC;


/* Interaction Success Rate

   Logic: The output is derived from a single table and utilizes the CASE statement with COUNT function to count instances of
   'Delivered' messages, to calculate the success rate percentage. Group the results by communication channels to ensures the
   success rate is caluclated for each channel, ORDER BY results by success rate percentage in descending order to identify
   the most effective channel.

    Insights: SMS emerges as the top-performing communication channel, achieving a 34% interaction success rate, while Apple 
	Messages ranks as the least effective channel, with a 32% success rate. This high-level overview provides a general understanding,
	but further analysis of customer behavior data is necessary to investigate the reasons behind the below-average success rates we
	are observing. */

 SELECT 
       channel AS Communication_Channels,
       COUNT(
	   CASE WHEN status = 'Delivered' THEN 1 END) * 100 /COUNT(message_id) AS SuccessRate_Percentage
	     
  FROM Interactions

 GROUP BY channel
  
 ORDER BY SuccessRate_Percentage DESC; 


/* End User Activity Ranking
 
   Logic: To achieve the desired result, Computed the total transaction amount and ROUND for clarity, I employed the 
   RANK() OVER(PARTITION BY -- ORDER BY -- DESC) function, to assign ranking to users within the same region based on their total
   transaction amount in descending order.  In the SELECT statement, I performed several joins and organized everything within the CTE.
   Then, I wrote another query to display the desired output, using the WHERE clause to filter out all but the top three users in each 
   region.

   Insight: The Asia region had the lowest performance, with its top three individual end-user transactions each totaling under
   $3,000. In contrast, two of Europe and Africa's top three transactions exceeded $3,000, and Africa had the end user with the 
   highest transaction total.    */

WITH EndUser_TransactionRaking AS (
  SELECT 
       T.end_user_id AS User_Id,
       region AS Region,
	   ROUND(SUM(transaction_amount),2) AS Total_TransactionAmount,
	   RANK() OVER(PARTITION BY region ORDER BY SUM(transaction_amount) DESC ) AS Users_Ranking

  FROM Transactions T 
  JOIN [End Users] E ON T.end_user_id = E.end_user_id
  JOIN [Clients ] C ON  C.client_id = E.client_id

  GROUP BY T.end_user_id, region
           ) 

  SELECT 
        User_Id,
		Region,
		Total_TransactionAmount,
		Users_Ranking

  FROM EndUser_TransactionRaking

  WHERE Users_Ranking <= 3

  ORDER BY Region, Users_Ranking; 