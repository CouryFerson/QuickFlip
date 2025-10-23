-- Migration: Add storage_location column to scanned_items table
-- Date: 2025-10-23
-- Description: Adds an optional storage_location field to track where items are physically stored

-- Add storage_location column
ALTER TABLE scanned_items
ADD COLUMN IF NOT EXISTS storage_location VARCHAR(100);

-- Add comment to column for documentation
COMMENT ON COLUMN scanned_items.storage_location IS 'Optional field to track where the item is physically stored (e.g., "Garage shelf", "Closet bin 3")';

-- Create index for faster filtering by storage location (optional, but helpful for queries)
CREATE INDEX IF NOT EXISTS idx_scanned_items_storage_location
ON scanned_items(storage_location)
WHERE storage_location IS NOT NULL;
