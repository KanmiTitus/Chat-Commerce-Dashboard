# Chat-commerce business performance analysis and dashboard
## Table of Contents
- [Overview](#overview)
  - [Goals](#goals)
- [Problem Statement](#problem-statement)
  - [SQL Problem Statement](#sql-problem-statement)
  - [Power BI Problem Statement](#power-bi-problem-statement)
- [Data Structure](#data-structure)
- [Data Cleaning](#data-cleaning)
- [Answering business questions with SQL queries](#answering-business-questions-with-sql-queries)
- [Power BI dashboard design](#power-bi-dashboard-design)
  - [Thought process and design thinking](#thought-process-and-design-thinking)
  - [Power BI Data Source and Modelling](#power-bi-data-source-and-modelling)
  - [Dashboard Page Layout](#dashboard-page-layout)
- [Insights Deep Dive](#insights-deep-dive)

## Overview 
Clickatell empowers businesses to connect with their customers via SMS, WhatsApp, and other channels, enabling seamless communication, engagement, and
transactions. As a BI & Data Visualization Specialist, in the BI & Data Analytics team, I was tasked to perform an end-end analysis, provided with a flat file to be loaded into My SQL Server database, submit a .SQL data dump of the dataset, write SQL query that answers business questions to provide insights into client engagement, our clients end users demographic, end user activity ranking, transaction analysis and interaction success rate. Lastly, develop dashboards that drive actionable insights for our clients.

## Goals

- Provide insights into top-performing clients in terms of interactions, client engagement, end-user demographics, activity ranking, transaction analysis, and interaction success rates. 
  Reports and actionable recommendations were delivered to guide stakeholders in resource allocation for marketing and commercial spending, optimizing acquisition costs, and improving 
  client satisfaction and retention.
  
- Build a comprehensive BI solution designed to deliver real-time insights into inbound and outbound interactions between clients and their end users. It integrates 
  data on transactions conducted through these interactions and visualizes the distribution of clients and end users across regions and industries.

- The dashboard was multi-purpose built for in-house cross-functional department stakeholders and developed as a comprehensive BI solution to enhance service rendered to help clients 
  track interaction success and failure rates (successful, pending, and failed transactions) while gaining deeper insights into their end users, to make informed decisions.

## Problem Statement
###  SQL Problem Statement
- List our top 5 clients with the highest number of interactions (messages) in the last 2 years. Include their client ID, client name, message direction, and the total 
  number of interactions.
- What are the average user engagement scores for each region and gender, considering only users aged 25-40?
- What's the total successful transaction amount for each client in the past year? 
- Determine the success rate of interactions (percentage of "Delivered" messages) for each communication channel.
- Who are the top 3 end users per region? by their total number of transactions in each region?
 
### Power BI Problem statement 
- Develop an Insightful Dashboard
  - Use the dataset to build an interactive Power BI dashboard that highlights trends, patterns, and actionable insights.
    
### Data Structure:
- **_Client table_**: Each record represents client information such as client ID, client name, industry and region they operate, and date they were onboarded on our platform.
- **_Transactions table_**: Each record represents information on all financial transactions through our platform, with columns like transaction ID, end user ID, transaction status, type, and date.
- **_Interactions table_**: This dataset provides insights into logs of messages exchanged between clients and end users between January 2020 and November 2024.
- **_End Users table_**: Information about consumers who interact with businesses through channels like SMS or WhatsApp

### Data Cleaning: 
*We have a dataset of 50 distinct Clients across 5 industries, with 990 distinct end users, these users completed 5000 distinct transactions within 3 years between 22/11/2020 and 23/11/2024, indicating that some end users have initiated multiple transactions from 10,000 interactions.*

NOTE: Our dataset is well-organized and clean, with accurate data types throughout the four tables. As I utilized dbo while importing data from the flat file through the import wizard while exploring, I noticed we have a few transactions and interactions with transaction_date and interaction_date in the year 2020, and we don't have any client data that was onboarded in 2020.
I decided to delete data points from the Transactions and Interactions table that were from 2020, so we can have accurate analysis, as we've money calculations involved in our analysis as well as give our clients accurate timely insights.

*Before deleting rows from Transactions and Interactions I created a backup of my table to avoid any data loss.*
   ```SQL
   SELECT * INTO Backup_Interactions_Table
   FROM Interactions;

   SELECT * INTO Backup_Transactions_Table
   FROM Transactions; 
   ```
 *Previewing the data to be DELETED, 273 and 150 data points were deleted from the Interactions and Transactions table respectively.*
 
   ```SQL
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
   ```
   ### Answering business questions with SQL queries
   - *Client engagement insights:* 
     - List our top 5 clients with the highest number of interactions (messages) in the last 2 years. Include their client ID, client name, message direction, and the 
        total number of interactions.
   
   ```SQL 
   SELECT TOP 5
       C.client_id AS Client_Id,
       client_name AS Client_Name,
	   message_direction AS Message_Directions,
	   COUNT(message_id) AS Total_Interactions

 FROM Interactions I
 JOIN [Clients ] C ON I.client_id = C.client_id
 WHERE I.timestamp >= DATEADD(YEAR, -2, GETDATE())
 GROUP BY C.client_id, client_name, message_direction
 ORDER BY Total_Interactions DESC;
```
- *User demographic and engagement insights:* 
   - What are the average user engagement scores for each region and gender, considering only users aged 25-40?
   
```SQL
 SELECT 
       region AS Region,
       gender AS Gender,
	   ROUND(AVG(user_engagement_score),2) AS Avg_User_Engagement_Score
 FROM [End Users] E
 JOIN [Clients ] C ON E.client_id = C.client_id
 WHERE age >= 25 and age<= 40
 GROUP BY region, gender
 ORDER BY Avg_User_Engagement_Score DESC;
```

- *Transaction Insights:*
   - What's the total transaction successful transaction amount for each client in the past year? 
  
```SQL
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
```

- *Interaction Success Rate insights:*
   - Determine the success rate of interactions (percentage of "Delivered" messages) for each communication channel.

```SQL
 SELECT 
       channel AS Communication_Channels,
       COUNT(
	   CASE WHEN status = 'Delivered' THEN 1 END) * 100 /COUNT(message_id) AS SuccessRate_Percentage
  FROM Interactions
 GROUP BY channel
 ORDER BY SuccessRate_Percentage DESC;
```

- *End User Activity Ranking insights:*
   - Who are the top 3 end users per region? by their total number of transactions in each region?

```SQL
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
```

### Power BI dashboard design:

- #### _Thought process and design thinking:_
  - With the variety of data I have from interaction, transaction, clients, and end-user information, I recognized the need for different pages to visualize
    important KPIs and provide further insights through appropriate charts, I decided to create a four-page dashboard going to be used internally, and 3 of those pages — 
    interaction, transaction, and end-user pages are also accessible to our clients through page-level security.
   
    We have clients in banking, telecoms, retail, healthcare, and e-commerce. I understand that different days of the week and times of the day will mean different things 
    to our clients in these industries. To accommodate these, I categorized transactions and interactions into times of day like "Morning" and "Afternoon." Additionally, I 
    wrote advanced DAX queries to track KPIs over the last seven thirty and ninety days.

    A hierarchical row-level security model ensures tailored access: managers can view country-level data, while regional managers have oversight across their assigned 
    regions and can access client-specific pages.
    I implemented an app-like design for seamless navigation, allowing users to easily switch between pages and focus on specific insights. This includes features such as 
    bookmarking, page navigation, menu buttons, filters, and tooltips, as well as new card visuals for tracking and comparing KPIs.
    Furthermore, I leveraged Power BI's AI features, which include self-updating Smart Narratives to summarize key insights and forecasting models to predict trends, aiding 
    in proactive decision-making and strategic planning.
    
- #### _Power BI Data Source and Modelling:_
    The SQL database was connected to Power BI as my data source, and data from the SQL data dump database was imported into Power Query. I also imported the internal company managers' data file into Power BI, also updated our clients' access database in the Microsoft 365 account to make hierarchical row-level security easy.
  
- *Data Model*

  <img width="585" alt="Data_Model" src="https://github.com/user-attachments/assets/255a094c-c767-4075-8e55-06882f8b7208" />

- *Hierarchical row-level security build-up*

  <img width="739" alt="Hierachical row low security build up" src="https://github.com/user-attachments/assets/6e98869a-eecf-4a08-aff5-cd91792ed6b7" />

  - *Login User Dax query measure*
  ```SQL
  Login User =                                                              
           LOOKUPVALUE(RegionalManagerdb[ID],     
           RegionalManagerdb[Email],
           USERPRINCIPALNAME()
        )
  ```
- *Hierarchical row-level security dax measure*
```SQL
PATHCONTAINS(
    RegionalManagerdb[Access Path],
    LOOKUPVALUE(RegionalManagerdb[ID],
    RegionalManagerdb[Email], 
    USERPRINCIPALNAME())
)
 ```

- #### _Dashboard Page Layout:_
- Overview Page
  
   ![__Overview Page](https://github.com/user-attachments/assets/5e828a1f-b5fb-4abe-ad94-a3b8d5ae1ba9)

- Interaction Page
  
   ![__Interaction Page](https://github.com/user-attachments/assets/9fbb9a0b-31e9-47bf-a285-25c21c056255)

- Transaction Page
  
  ![__Transaction Page](https://github.com/user-attachments/assets/d85f1f04-da6a-4bc8-abfa-490306ede3de)
  

- End User's Page
  
  ![__EndUsers Page](https://github.com/user-attachments/assets/8ae0a8ed-c06a-4320-a793-2bc7871b6548)

You can interact with the dashboard [here](https://app.powerbi.com/view?r=eyJrIjoiMTI0NTNkZTQtZTRjNi00MWJlLTk4ZDctOTk3NGY5ZjY0MmVkIiwidCI6ImIxNjIzYzU5LWJjYmQtNGU1YS1iNTY3LTBkZjI0NGI5ODU0MyJ9)

### Insights Deep-Dive:
- Three of the top five Clients were Outbound message directions
- The data shows that females in Europe have the highest user engagement scores, while males in South America and females in North America exhibit the lowest average user 
   engagement scores.
- Wade, Bentley, and Patton are the top-performing clients, achieving the highest total value of successful transactions at $4,372.95. In contrast, Alvarado LLC is the 
  least-performing client, with a total of $564.46 in transactions over the past year. 
- SMS emerges as the top-performing communication channel, achieving a 34% interaction success rate, while Apple Messages ranks as the least effective channel, with a 32% 
  success rate. This high-level overview provides a general understanding, but further analysis of customer behavior data is necessary to investigate the reasons behind the 
  below-average success rates we are observing. 
- The Asia region had the lowest performance, with its top three individual end-user transactions each totaling under $3,000. In contrast, two of Europe and Africa's top 
  three transactions exceeded $3,000, and Africa had the end user with the highest transaction total.
