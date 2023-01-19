
/*

DATA CLEANING IN SQL

Skills used: Alter and Update Table functions, String to Date function, IFNULL and Self-Joins, Sub-String and Sub-String Index functions, CASE statements, Subqueries


*/



-- 1. 
-- Rename columns for better schema
-- Replace blank strings with NULL
ALTER TABLE nash_housing
RENAME COLUMN UniqueId TO unique_id;

ALTER TABLE nash_housing
RENAME COLUMN ParcelId TO parcel_id;

ALTER TABLE nash_housing
RENAME COLUMN LandUse TO land_use;

ALTER TABLE nash_housing
RENAME COLUMN PropertyAddress TO property_address;

UPDATE nash_housing
SET property_address = NULL WHERE property_address = '';

ALTER TABLE nash_housing
RENAME COLUMN SaleDate TO sale_date;

UPDATE nash_housing
SET sale_date = NULL WHERE sale_date = '';

ALTER TABLE nash_housing
RENAME COLUMN SalePrice TO sale_price;

UPDATE nash_housing
SET sale_price = NULL WHERE sale_price = '';

ALTER TABLE nash_housing
RENAME COLUMN LegalReference TO legal_reference;

UPDATE nash_housing
SET legal_reference = NULL WHERE legal_reference = '';

ALTER TABLE nash_housing
RENAME COLUMN SoldAsVacant TO sold_as_vacant;

UPDATE nash_housing
SET sold_as_vacant = NULL WHERE sold_as_vacant = '';

ALTER TABLE nash_housing
RENAME COLUMN OwnerName TO owner_name;

UPDATE nash_housing
SET owner_name = NULL WHERE owner_name = '';

ALTER TABLE nash_housing
RENAME COLUMN OwnerAddress TO owner_address;

UPDATE nash_housing
SET owner_address = NULL WHERE owner_address = '';

ALTER TABLE nash_housing
RENAME COLUMN Acreage TO acreage;

UPDATE nash_housing
SET acreage = NULL WHERE acreage = '';

ALTER TABLE nash_housing
RENAME COLUMN TaxDistrict TO tax_district;

UPDATE nash_housing
SET tax_district = NULL WHERE tax_district = '';

ALTER TABLE nash_housing
RENAME COLUMN LandValue TO land_value;

UPDATE nash_housing
SET land_value = NULL WHERE land_value = '';

ALTER TABLE nash_housing
RENAME COLUMN BuildingValue TO building_value;

UPDATE nash_housing
SET building_value = NULL WHERE building_value = '';

ALTER TABLE nash_housing
RENAME COLUMN TotalValue TO total_value;

UPDATE nash_housing
SET total_value = NULL WHERE total_value = '';

ALTER TABLE nash_housing
RENAME COLUMN YearBuilt TO year_built;

UPDATE nash_housing
SET year_built = NULL WHERE year_built = '';

ALTER TABLE nash_housing
RENAME COLUMN Bedrooms TO bedrooms;

UPDATE nash_housing
SET bedrooms = NULL WHERE bedrooms = '';

ALTER TABLE nash_housing
RENAME COLUMN FullBath TO full_bath;

UPDATE nash_housing
SET full_bath = NULL WHERE full_bath = '';

ALTER TABLE nash_housing
RENAME COLUMN HalfBath TO half_bath;

UPDATE nash_housing
SET half_bath = NULL WHERE half_bath = '';



-- 2.
-- Standardize Date format
SELECT
	str_to_date(sale_date, '%m/%d/%Y')
FROM nash_housing;

UPDATE nash_housing
SET sale_date = str_to_date(sale_date, '%m/%d%Y');

ALTER TABLE nash_housing
MODIFY COLUMN sale_date date;



-- 3.
-- Populate Missing Property Address Data
SELECT *
FROM nash_housing
ORDER BY parcel_id;


SELECT
	a.parcel_id,
    a.property_address,
    b.parcel_id,
    b.property_address,
    IFNULL(a.property_address, b.property_address)
FROM nash_housing AS a
	INNER JOIN nash_housing AS b
		ON a.parcel_id = b.parcel_id
        AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL;


UPDATE nash_housing AS a
JOIN (SELECT 
	a.parcel_id,
    a.property_address,
    b.parcel_id AS b_parcel_id,
    b.property_address AS b_property_address,
    IFNULL(a.property_address, b.property_address)
FROM nash_housing AS a
	INNER JOIN nash_housing AS b
		ON a.parcel_id = b.parcel_id
        AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL) AS b
SET a.property_address = IFNULL(a.property_address, b.b_property_address)
WHERE a.property_address IS NULL;



-- 4.
-- Splitting Address columns (property address and owner address) into different columns for Address, City, State

-- Property Address column
SELECT 
	substr(property_address, 1, LOCATE(',', property_address) -1) AS address,
	substr(property_address, LOCATE(',', property_address) + 1, LENGTH(property_address)) AS city
FROM nash_housing;

ALTER TABLE nash_housing
ADD COLUMN property_street_address NVARCHAR(255) AFTER property_address;

UPDATE nash_housing
SET property_street_address = substr(property_address, 1, LOCATE(',', property_address) -1);

ALTER TABLE nash_housing
ADD COLUMN property_city NVARCHAR(255) AFTER property_street_address;

UPDATE nash_housing
SET property_city = substr(property_address, LOCATE(',', property_address) + 1, LENGTH(property_address));


-- Owner Address Column
SELECT
	substring_index(owner_address, ',', 1) AS owner_street_address,
    substring_index(substring_index(owner_address, ',', 2), ',', -1) AS owner_city,
    substring_index(substring_index(owner_address, ',', 3), ',', - 1) AS owner_state
FROM nash_housing;

ALTER TABLE nash_housing
ADD COLUMN owner_street_address NVARCHAR(255) AFTER owner_address;

UPDATE nash_housing
SET owner_street_address = substring_index(owner_address, ',', 1);

ALTER TABLE nash_housing
ADD COLUMN owner_city NVARCHAR(255) AFTER owner_street_address;

UPDATE nash_housing
SET owner_city = substring_index(substring_index(owner_address, ',', 2), ',', -1);

ALTER TABLE nash_housing
ADD COLUMN owner_state NVARCHAR(255) AFTER owner_city;

UPDATE nash_housing
SET owner_state = substring_index(substring_index(owner_address, ',', 3), ',', - 1);



-- 5.
-- Change Y/N to 'Yes'/'No' in sold_as_vacant column using Case Statement
SELECT DISTINCT(sold_as_vacant),
	COUNT(sold_as_vacant)
FROM nash_housing
GROUP BY 1
ORDER BY 2;

SELECT
	sold_as_vacant,
CASE 
	WHEN sold_as_vacant = 'N' THEN 'No'
    WHEN sold_as_vacant = 'Y' THEN 'Yes'
    ELSE sold_as_vacant
END
FROM nash_housing;

UPDATE nash_housing
SET sold_as_vacant = 
	CASE 
		WHEN sold_as_vacant = 'N' THEN 'No'
        WHEN sold_as_vacant = 'Y' THEN 'Yes'
		ELSE sold_as_vacant
	END;



-- 6. 
-- Remove Duplicates
-- Use subquery to delete duplicate rows that have same information but different value in primary key
SELECT *
FROM (SELECT *,
	  ROW_NUMBER() OVER(
		PARTITION BY parcel_id,
					property_address,
                    sale_price,
                    sale_date,
                    legal_reference
                    ORDER BY unique_id
                    ) AS row_num
FROM nash_housing) AS sub_row
WHERE row_num >1;

DELETE FROM nash_housing
WHERE 
	unique_id IN (
	SELECT 
		unique_id
    FROM (
		SELECT *,
	    ROW_NUMBER() OVER(
		PARTITION BY parcel_id,
					property_address,
                    sale_price,
                    sale_date,
                    legal_reference
                    ORDER BY unique_id
                    ) AS row_num
	FROM nash_housing) AS sub_row 
	WHERE row_num >1);
  
  
  
-- 7. 
-- Remove unused columns: property_address, owner_address 
ALTER TABLE nash_housing
DROP COLUMN property_address;
ALTER TABLE nash_housing
DROP COLUMN owner_address;

