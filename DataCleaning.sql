-- Create SaleDate to date format as SaleDateConverted
ALTER TABLE nashville.NashvilleHousing
ADD SaleDateConverted date;

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing
SET SaleDateConverted = CONVERT(SaleDate,date);
SET SQL_SAFE_UPDATES = 1;

-- Populate Property Address data
-- Check if same parcel id already exists with an address. If so, if property address is null then fill it
SELECT a.ParcelID , a.PropertyAddress , b.ParcelID, b.PropertyAddress , IFNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashville.NashvilleHousing a
JOIN nashville.NashvilleHousing b 
ON a.ParcelID = b.ParcelID
AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update property address
SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing a
	JOIN nashville.NashvilleHousing b 
	ON (a.ParcelID = b.ParcelID
	AND a.UniqueID != b.UniqueID)
    SET a.PropertyAddress = IFNULL(a.PropertyAddress,b.PropertyAddress) 
    WHERE a.PropertyAddress IS NULL;
SET SQL_SAFE_UPDATES = 1;

-- Split property address into address and city 
SELECT PropertyAddress FROM nashville.NashvilleHousing;
SELECT SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress,LOCATE(',',PropertyAddress)+1,LENGTH(PropertyAddress)) AS City
FROM nashville.NashvilleHousing;

-- New column for property address 
ALTER TABLE nashville.NashvilleHousing
ADD PropertySplitAddress varchar(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress)-1);
SET SQL_SAFE_UPDATES = 1;

-- New column for property city
ALTER TABLE nashville.NashvilleHousing
ADD PropertySplitCity varchar(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,LOCATE(',',PropertyAddress)+1,LENGTH(PropertyAddress));
SET SQL_SAFE_UPDATES = 1;

-- Split Owner Address into address , city , state 
SELECT SUBSTRING_INDEX(OwnerAddress,',',1) AS Address, 
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1) AS City,
SUBSTRING_INDEX(OwnerAddress,',',-1) AS State
FROM nashville.NashvilleHousing;

-- New column for Owner Address
ALTER TABLE nashville.NashvilleHousing
ADD OwnerSplitAddress varchar(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,',',1);
SET SQL_SAFE_UPDATES = 1;

-- New column for Owner City
ALTER TABLE nashville.NashvilleHousing
ADD OwnerSplitCity varchar(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1);
SET SQL_SAFE_UPDATES = 1;

-- New column for Owner State
ALTER TABLE nashville.NashvilleHousing
ADD OwnerSplitState varchar(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',',-1);
SET SQL_SAFE_UPDATES = 1;

-- Replace the 'N' with 'No' and 'Y' with 'Yes' to maintain uniformity in SoldAsVacant 
SELECT SoldAsVacant,COUNT(*) 
FROM nashville.NashvilleHousing 
GROUP BY SoldAsVacant 
ORDER BY 2 DESC;

SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
        ELSE SoldAsVacant
        END
FROM nashville.NashvilleHousing;

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville.NashvilleHousing 
SET SoldAsVacant = 	CASE WHEN SoldAsVacant = 'N' THEN 'No'
						WHEN SoldAsVacant = 'Y' THEN 'Yes' 
						ELSE SoldAsVacant
						END;
SET SQL_SAFE_UPDATES = 1;

-- Remove Duplicates 

-- Find rows with same ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference = Duplicates
SET SQL_SAFE_UPDATES = 0;

WITH RowNumCTE AS (
SELECT * , 
 ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY 
                 UniqueID) row_num
FROM nashville.NashvilleHousing
)

-- Delete those rows that occur more than once ( row_num>2) are duplicates 
DELETE FROM nashville.NashvilleHousing USING nashville.NashvilleHousing 
JOIN RowNumCTE ON nashville.NashvilleHousing.UniqueID = RowNumCTE.UniqueID
WHERE RowNumCTE.row_num > 1;
SET SQL_SAFE_UPDATES =1;



