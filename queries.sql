
		# AUTOMATED DATA CLEANING - US INCOME DATA


# View the existing data, determine cleaning steps.
SELECT * 
FROM us_household_income;


	# 1. CREATE A STORED PROCEDURE

# All of the data cleaning steps will be housed within a stored procedure
# called 'copy_and_clean_data()'. The stored procedure will run based on
# an event so that it will regularly and automatically clean data.


# Create a stored procedure for data-cleaning automation.
# When the stored procedure is called, it will create a new table called
# `us_household_income_cleaned`, populate it with existing data, and then
# it will perform the data-cleaning steps.
DELIMITER $$
DROP PROCEDURE IF EXISTS copy_and_clean_data;
CREATE PROCEDURE copy_and_clean_data()
BEGIN

	# Step 1: Create a copy of the columns from the 'us_household_income'
	# 		  table with an added 'TimeStamp' column. 
    DROP TABLE IF EXISTS us_household_income_cleaned;
	CREATE TABLE `us_household_income_cleaned` (
	`row_id` int DEFAULT NULL,
	`id` int DEFAULT NULL,
	`State_Code` int DEFAULT NULL,
	`State_Name` text,
	`State_ab` text,
	`County` text,
	`City` text,
	`Place` text,
	`Type` text,
	`Primary` text,
	`Zip_Code` int DEFAULT NULL,
	`Area_Code` int DEFAULT NULL,
	`ALand` int DEFAULT NULL,
	`AWater` int DEFAULT NULL,
	`Lat` double DEFAULT NULL,
	`Lon` double DEFAULT NULL,
	`TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


	# Step 2: Copy the existing data into the new table.
    INSERT INTO us_household_income_cleaned
	SELECT *, CURRENT_TIMESTAMP()
	FROM us_household_income;
    
    
    # Step 3: Perform the various data-cleaning queries.
    # Remove Duplicates
	DELETE FROM us_household_income_cleaned 
	WHERE row_id IN (
		SELECT row_id
		FROM (
			SELECT row_id, id,
			ROW_NUMBER() OVER (
							PARTITION BY id
							ORDER BY id
							) AS row_num
			FROM us_household_income_cleaned
			) duplicates
		WHERE row_num > 1
	);

	# Fix various typos and standardize column data with capital letters.
	UPDATE us_household_income_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income_cleaned
	SET County = UPPER(County);

	UPDATE us_household_income_cleaned
	SET City = UPPER(City);

	UPDATE us_household_income_cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';
            
END $$
DELIMITER ;


# Call the stored procedure to populate the new table with the existing 
# data and perform the cleaning tasks.
CALL copy_and_clean_data();


# Check the table for accuracy and to ensure stored procedure functionality.
SELECT * 
FROM us_household_income_cleaned;




	# 2. CREATE EVENT
    
# Create an event that will execute the stored procedure above. The event will
# occur daily but can be set to any desired interval of time. 
DROP EVENT IF EXISTS run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 1 DAY
    DO CALL copy_and_clean_data();

# Check the table for accuracy and to ensure event functionality.
SELECT * 
FROM us_household_income_cleaned;

SELECT DISTINCT TimeStamp
FROM us_household_income_cleaned;


