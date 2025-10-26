
-- Nashville Housing Data Cleaning Script

-- 1. Select all data from NashvilleHousing table
SELECT *
FROM CleaningProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- 2. Standardize Date Format

-- Convert SaleDate to a standard Date format
SELECT saleDateConverted, CONVERT(Date, SaleDate)
FROM CleaningProject.dbo.NashvilleHousing;

-- Update SaleDate to standardized Date format
UPDATE CleaningProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

-- If the above update doesn't work, add a new column and update it
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE CleaningProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

--------------------------------------------------------------------------------------------------------------------------

-- 3. Populate Property Address Data

-- Select all records ordered by ParcelID
SELECT *
FROM CleaningProject.dbo.NashvilleHousing
ORDER BY ParcelID;

-- Join to fill in missing PropertyAddress data
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM CleaningProject.dbo.NashvilleHousing a
JOIN CleaningProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null;

-- Update PropertyAddress with data from joined table
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM CleaningProject.dbo.NashvilleHousing a
JOIN CleaningProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null;

--------------------------------------------------------------------------------------------------------------------------

-- 4. Break out Address into Individual Columns (Address, City, State)

-- Select PropertyAddress to examine its structure
SELECT PropertyAddress
FROM CleaningProject.dbo.NashvilleHousing;

-- Extract Address part from PropertyAddress
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM CleaningProject.dbo.NashvilleHousing;

-- Add new columns for split address components
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

-- Update new columns with split address data
UPDATE CleaningProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Select all data to review changes
SELECT *
FROM CleaningProject.dbo.NashvilleHousing;

-- Select OwnerAddress to examine its structure
SELECT OwnerAddress
FROM CleaningProject.dbo.NashvilleHousing;

-- Extract components from OwnerAddress
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM CleaningProject.dbo.NashvilleHousing;

-- Add new columns for split owner address components
ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

-- Update new columns with split owner address data
UPDATE CleaningProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE CleaningProject.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE CleaningProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Select all data to review changes
SELECT *
FROM CleaningProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- 5. Change 'Y' and 'N' to 'Yes' and 'No' in "Sold as Vacant" field

-- Check distinct values in SoldAsVacant field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM CleaningProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Select SoldAsVacant with new values for Y and N
SELECT SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM CleaningProject.dbo.NashvilleHousing;

-- Update SoldAsVacant field with new values
UPDATE CleaningProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Remove Duplicates

-- Create a CTE to identify duplicate rows
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM CleaningProject.dbo.NashvilleHousing
)

-- Select duplicate rows
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Select all data to review changes
SELECT *
FROM CleaningProject.dbo.NashvilleHousing;

---------------------------------------------------------------------------------------------------------

-- 7. Delete Unused Columns

-- Select all data to review existing columns
SELECT *
FROM CleaningProject.dbo.NashvilleHousing;

-- Drop unused columns
ALTER TABLE CleaningProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
