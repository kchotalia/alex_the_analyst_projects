SELECT *
FROM dbo.Nashville_Housing_Data

------------------------------------------------------
--- Standardise Date Format ---
------------------------------------------------------
-- -- Already done using Azure import wizard
SELECT SaleDate
FROM dbo.Nashville_Housing_Data

------------------------------------------------------   
--- Populate Property Address Data ---
------------------------------------------------------
--- NULL values in this column
--- When ParcelID is the same, address will be the same
--- if the address is NULL can use ParcelID duplicate to our advantage

SELECT * -- PropertyAddress
FROM dbo.Nashville_Housing_Data
ORDER BY ParcelID

-- Self JOIN tables where parcelID is the same but rows are different, show the NULL values
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.Nashville_Housing_Data a
JOIN dbo.Nashville_Housing_Data b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

-- Using SELECT ISNULL to test query before updating the table
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.Nashville_Housing_Data a
JOIN dbo.Nashville_Housing_Data b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

-- After running this below, the above when run should be empty
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.Nashville_Housing_Data a
JOIN dbo.Nashville_Housing_Data b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

------------------------------------------------------
--- Breaking Down Addresses (Address, City, State) ---
------------------------------------------------------

SELECT PropertyAddress
FROM dbo.Nashville_Housing_Data
-- ORDER BY ParcelID

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, -- -1 gets rid of the comma in the output
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address -- +1 makes sure we don't include the comma 
FROM dbo.Nashville_Housing_Data

-- Create new column for address
ALTER TABLE dbo.Nashville_Housing_Data
ADD PropertySplitAddress NVARCHAR(255);

UPDATE dbo.Nashville_Housing_Data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 

-- Create new column for city
ALTER TABLE dbo.Nashville_Housing_Data
ADD PropertySplitCity NVARCHAR(255);

UPDATE dbo.Nashville_Housing_Data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
FROM dbo.Nashville_Housing_Data

------------------------------------------------------
-- Owner Address -- using parsename, much easier than substring
------------------------------------------------------
SELECT OwnerAddress
FROM dbo.Nashville_Housing_Data

SELECT 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM dbo.Nashville_Housing_Data

ALTER TABLE dbo.Nashville_Housing_Data
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE dbo.Nashville_Housing_Data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALTER TABLE dbo.Nashville_Housing_Data
ADD OwnerSplitCity NVARCHAR(255);

UPDATE dbo.Nashville_Housing_Data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

ALTER TABLE dbo.Nashville_Housing_Data
ADD OwnerSplitState NVARCHAR(255);

UPDATE dbo.Nashville_Housing_Data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

SELECT *
FROM dbo.Nashville_Housing_Data

------------------------------------------------------
--- Change Y and N to Yes and No in SoldAsVacant ---
------------------------------------------------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM dbo.Nashville_Housing_Data
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'YES'
    WHEN SoldAsVacant = 'N' THEN 'NO'
    ELSE SoldAsVacant
    END
FROM dbo.Nashville_Housing_Data

UPDATE dbo.Nashville_Housing_Data
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'YES'
    WHEN SoldAsVacant = 'N' THEN 'NO'
    ELSE SoldAsVacant
    END

------------------------------------------------------
--- Remove Duplicates ---
------------------------------------------------------
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY ParcelID,
                     PropertyAddress,
                     SalePrice,
                     LegalReference
                     ORDER BY 
                        UniqueID
    ) rownum
FROM dbo.Nashville_Housing_Data
)
SELECT * -- DELETE -- Use this then rerun with select to see result
FROM RowNumCTE
WHERE rownum > 1
ORDER BY PropertyAddress

------------------------------------------------------
--- Delete Unused Columns ---
------------------------------------------------------

--- Removing OwnerAddress etc ---

SELECT *
FROM dbo.Nashville_Housing_Data

ALTER TABLE dbo.Nashville_Housing_Data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress