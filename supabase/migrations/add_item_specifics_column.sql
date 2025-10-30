-- Migration: Add item_specifics column for category-specific attributes
-- Created: 2025-10-30
-- Description: Adds JSONB column to store AI-extracted item attributes for better eBay listings

-- Add item_specifics column to scanned_items table
ALTER TABLE scanned_items
ADD COLUMN IF NOT EXISTS item_specifics JSONB;

-- Add index for faster queries on item_specifics
-- GIN index is efficient for JSONB column queries
CREATE INDEX IF NOT EXISTS idx_scanned_items_item_specifics
ON scanned_items USING gin (item_specifics);

-- Add comment to document the column
COMMENT ON COLUMN scanned_items.item_specifics IS
'Category-specific attributes extracted by AI (e.g., {"Brand": "Nike", "US Shoe Size": "10.5", "Color": "Black"})';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'scanned_items' AND column_name = 'item_specifics';
