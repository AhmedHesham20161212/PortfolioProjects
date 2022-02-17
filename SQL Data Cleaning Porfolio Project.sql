/* 
 
Cleaning Data in SQL Queries

*/


-- Looking at the first 20 row of the dataset

SELECT TOP 20 *
FROM ['NashvilleHousing'] 


-- Standardize Date Format

/* Here we will convert the 'SaleDate' column from  date time format to date format 
to get rid of the time part as it does not serve us */

ALTER TABLE ['NashvilleHousing'] 
ALTER COLUMN SaleDate date

SELECT SaleDate
FROM ['NashvilleHousing']


/* We will start cleaning the data by populating the 'PropertyAddress' column 
to get rid of the NULL values */

-- First we will look at the NULL values of the 'PropertyAddress' column

SELECT 
	UniqueID, 
	ParcelID,
	PropertyAddress
FROM ['NashvilleHousing']
WHERE PropertyAddress IS NULL


-- Then we will make a self join to populate the property address by the similar ParcelID

SELECT 
	n_1.ParcelID,
	n_1.PropertyAddress, 
	n_2.ParcelID,
	n_2.PropertyAddress,
	COALESCE(n_1.PropertyAddress, n_2.PropertyAddress) AS Property_Address
FROM ['NashvilleHousing'] n_1
JOIN ['NashvilleHousing'] n_2
ON n_1.ParcelID = n_2.ParcelID 
AND n_1.UniqueID != n_2.UniqueID
WHERE n_1.PropertyAddress IS NULL


-- Now we will update the table with the new column

UPDATE n_1
SET PropertyAddress = COALESCE(n_1.PropertyAddress, n_2.PropertyAddress)
FROM ['NashvilleHousing'] n_1
JOIN ['NashvilleHousing'] n_2
ON n_1.ParcelID = n_2.ParcelID 
AND n_1.UniqueID != n_2.UniqueID
WHERE n_1.PropertyAddress IS NULL



/* Seperating address to two columns, the first column will contain the address and
the second column will contain the city */

-- First we will have a look at the PropertyAddress column

SELECT 
	PropertyAddress
FROM ['NashvilleHousing']

-- Here we will split the column into ( Address, City )

SELECT 
	PropertyAddress,
-- Calculating the length of characters in the address	
	LEN(PropertyAddress) AS Address_Length,
-- Getting the index of the seperator ',' 
-- In other words we will get length of characters until we reach the seperator 
	CHARINDEX(',', PropertyAddress) AS Sep_Index,
-- Determining the length of characters after the seperator in the address 
	LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) AS Rest_Length,
-- Getting the first part of the address before the seperator and aliasing it as address
	LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1) AS Address,
-- Getting the second part of the address after the seperator and aliasing it as city
	RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) - 1) AS City
FROM ['NashvilleHousing'];


-- Now we will update the table with the new columns
-- First we extract the city in the new column (PropertyCity)

ALTER TABLE ['NashvilleHousing']
ADD PropertyCity varchar(255);

UPDATE ['NashvilleHousing']
SET PropertyCity = RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) - 1)

/* We will modify the original column (PropertyAddress) which contain the address
and the city to contain the address only */

UPDATE ['NashvilleHousing']
SET PropertyAddress = LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1)

-- Here we will check part of the data to see the results of our previous queries

SELECT TOP(25) PERCENT *
FROM ['NashvilleHousing']


/* Next we will deal with the (OwnerAddress) column such as the (PropertyAddress) column
but with different method*/

-- First we will have a look at the column

SELECT OwnerAddress
FROM ['NashvilleHousing']


/* We will split the (OwnerAddress) column to three columns
the first column will contain the address, the second column will contain the city
and the third one will contain the state */

-- We can use SUBSTRING and RIGHT fuctions to get each column as following 

SELECT 
	OwnerAddress,
	SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress) - 1) AS Address,
	SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress) + 2, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - CHARINDEX(',', OwnerAddress) - 2) AS City,
	RIGHT(OwnerAddress, LEN(OwnerAddress) - CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - 1) AS State
FROM ['NashvilleHousing']

/* There is another method for splitting the columns by using PARSENAME function */

/* Here we will use REPLACE function nested in the function PARSENAME to replace the ',' seperator with
the '.' seperator to be suitable for PARSENAME */

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS city,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS state
FROM ['NashvilleHousing']

/* We will use PARSENAME as it is much more easy than SUBSTRING, LEFT or RIGHT */

-- Now we will update the table with the new columns
-- First we will put the state in the new column (OwnerState)

ALTER TABLE ['NashvilleHousing']
ADD OwnerState varchar(255)

UPDATE ['NashvilleHousing']
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 

-- Adding the new column (OwnerCity) and fill it with the city

ALTER TABLE ['NashvilleHousing']
ADD OwnerCity varchar(255)

UPDATE ['NashvilleHousing']
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) 

/* Modifing the original column (OwnerAddress) which contain the address,
the city and the state to contain the address only */

UPDATE ['NashvilleHousing']
SET OwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) 

-- Here we will check part of the data to see the results of our previous queries

SELECT TOP(25) PERCENT *
FROM ['NashvilleHousing']

-- We will look at the four columns (OwnerCity), (PropertyCity), (OwnerAddress), (PropertyAddress)

SELECT 
	OwnerCity,
	PropertyCity,
	OwnerAddress,
	PropertyAddress
FROM ['NashvilleHousing']


/* We will fill the NULL values in the (OwnerCity),
(OwnerAddress) columns by the values in the (PropertyCity), (PropertyAddress) columns 
*/
SELECT 
	ISNULL(OwnerCity, PropertyCity) AS OwnerCity,
	ISNULL(OwnerAddress, PropertyAddress) AS OwnerAddress
FROM ['NashvilleHousing']

-- Updating the columns with these new values

UPDATE ['NashvilleHousing']
SET OwnerCity = ISNULL(OwnerCity, PropertyCity)

UPDATE ['NashvilleHousing']
SET OwnerAddress = 	ISNULL(OwnerAddress, PropertyAddress) 


/* We will look at the (OwnerCity), (OwnerAddress) columns and we will filter the columns
to show null values to assure that there are not null values in the columns */

SELECT 
	OwnerCity
FROM ['NashvilleHousing']
WHERE OwnerCity IS NULL

SELECT 
	OwnerAddress
FROM ['NashvilleHousing']
WHERE OwnerAddress IS NULL

-- We will look at the distinct values in the (SoldAsVacant) column

SELECT DISTINCT 
	SoldAsVacant
FROM ['NashvilleHousing']


-- There are four values (Y, N, Yes, No) and we will convert the values (Y, N) to the values (Yes, No)
-- We will use CASE statement

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END AS SoldAsVacant
FROM ['NashvilleHousing']

-- Here we will update the column with the new results

UPDATE ['NashvilleHousing']
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

-- Assuring that there is two values (Yes, No)
		
SELECT DISTINCT 
	SoldAsVacant
FROM ['NashvilleHousing']
		
-- Removing duplicates from the dataset

/* First we will use ROW_NUMBER function to get distinct record for each uniqe row
and more than one record for the duplicate rows */

SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num
FROM ['NashvilleHousing']


-- We will use CTE to filter the table and show the duplicate rows

WITH DupRowTable AS 
(SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num
FROM ['NashvilleHousing'] )

SELECT *
FROM DupRowTable
WHERE row_num > 1


-- Then we can delete the duplicate rows by using DELETE instead of SELECT

/* WITH DupRowTable AS 
(SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num
FROM ['NashvilleHousing'] )

DELETE 
FROM DupRowTable
WHERE row_num > 1 */ 


-- We will use TRIM function to remove the extra spaces in the columns

SELECT 
	TRIM(OwnerAddress) AS OwnerAddress,
	TRIM(OwnerCity) AS OwnerCity,
	TRIM(OwnerName) AS OwnerName,
	TRIM(OwnerState) AS OwnerState,
	TRIM(PropertyCity) AS PropertyCity,
	TRIM(PropertyAddress) AS PropertyAddress,
	TRIM(LandUse) AS LandUse
FROM ['NashvilleHousing']
		

-- Updating the columns with the new values

UPDATE ['NashvilleHousing']
SET OwnerAddress = TRIM(OwnerAddress),  
	OwnerCity = TRIM(OwnerCity),
	OwnerName = TRIM(OwnerName), 
	OwnerState = TRIM(OwnerState), 
	PropertyCity = TRIM(PropertyCity),
	PropertyAddress = TRIM(PropertyAddress),
	LandUse = TRIM(LandUse)


-- Deleting Unused Columns

ALTER TABLE ['NashvilleHousing']
DROP COLUMN OwnerAddress, TaxDistrict, OwnerCity

/* Replacing the column OwnerState by the column PropertyState  */

ALTER TABLE ['NashvilleHousing']
ADD PropertyState varchar(255)

UPDATE ['NashvilleHousing']
SET PropertyState = OwnerState

ALTER TABLE ['NashvilleHousing']
DROP COLUMN OwnerState

SELECT *
FROM ['NashvilleHousing']


