# analyze-single-item-v2 Edge Function

## Overview

This is the v2 edge function for analyzing scanned items with **enhanced category-specific attribute extraction**. It replaces the hardcoded eBay item specifics with AI-powered extraction that adapts to each item's category.

## What's New in V2

### Enhanced Attribute Extraction

The v2 function extracts **category-specific attributes** that are actually relevant to the item:

**Before (v1):**
- ❌ Scanned Nike shoes → Listed on eBay with "Connectivity: Wireless"
- ❌ All items got hardcoded cellphone accessory attributes

**After (v2):**
- ✅ Nike shoes → "Brand: Nike, US Shoe Size: 10.5, Color: Black/White"
- ✅ AirPods → "Brand: Apple, Connectivity: Bluetooth, Type: In-Ear Headphones"
- ✅ T-Shirts → "Brand: Vintage, Size: Large, Material: 100% Cotton"

### Category-Specific Attributes

The AI now extracts attributes based on the item category:

| Category | Extracted Attributes |
|----------|---------------------|
| **Footwear** | Brand, US Shoe Size, Width, Color, Style, Material |
| **Electronics** | Brand, Model, Storage Capacity, Color, Connectivity, Operating System |
| **Clothing** | Brand, Size, Size Type, Color, Material, Style, Fit |
| **Books** | Title, Author, Format, ISBN, Publisher, Publication Year, Language |
| **Audio Equipment** | Brand, Model, Type, Connectivity, Color, Features |
| **Sports Equipment** | Brand, Sport, Size, Material, Color |
| **Home Goods** | Brand, Material, Dimensions, Color, Style, Room Type |

## Deployment Steps

### 1. Deploy the Edge Function

```bash
# Navigate to your project root
cd /path/to/QuickFlip

# Deploy the v2 function to Supabase
supabase functions deploy analyze-single-item-v2

# Verify deployment
supabase functions list
```

### 2. Test the V2 Function

Update `SingleItemRequester.swift` to test with v2:

```swift
// Change line 26 from:
var functionName: String { "analyze-single-item" }

// To:
var functionName: String { "analyze-single-item-v2" }
```

### 3. Test with Different Item Categories

Scan and test these item types:
- ✅ Shoes/Sneakers (verify Size, Brand, Color extracted)
- ✅ Electronics (verify Model, Connectivity, Storage extracted)
- ✅ Clothing (verify Size, Material, Style extracted)
- ✅ Books (verify Title, Author, ISBN extracted)

### 4. Verify eBay Listings

Check that eBay listings now show:
- Category-appropriate attributes
- No more "Connectivity: Wireless" on shoes
- Real sizes, colors, brands extracted from images

### 5. Migrate Production

Once testing is successful, the v1 function can be deprecated:

```bash
# Optional: Remove old function after migration
supabase functions delete analyze-single-item
```

## Database Migration

The Swift models have been updated to support `itemSpecifics`. You'll need to add the column to your Supabase database:

```sql
-- Add item_specifics column to scanned_items table
ALTER TABLE scanned_items
ADD COLUMN IF NOT EXISTS item_specifics JSONB;

-- Add index for faster queries (optional)
CREATE INDEX IF NOT EXISTS idx_scanned_items_item_specifics
ON scanned_items USING gin (item_specifics);
```

## Response Format

The v2 function returns the same format as v1, plus the new `ATTRIBUTES` field:

```
ITEM: Nike Air Max 270 Men's Running Shoes
CATEGORY: Clothing, Shoes & Accessories > Men's Shoes > Athletic Shoes
CONDITION: Good
DESCRIPTION: Nike Air Max 270 in black and white colorway. Visible creasing on toe box...
VALUE: $45 - $75
ATTRIBUTES: {"Brand": "Nike", "US Shoe Size": "10.5", "Color": "Black/White", "Style": "Running, Athletic"}
```

## Backward Compatibility

The Swift code includes fallback logic for items scanned with v1:

- Items without `itemSpecifics` → Falls back to basic brand extraction
- Items with empty `itemSpecifics` → Only includes brand in eBay listing
- Items with v2 `itemSpecifics` → Uses full AI-extracted attributes

This ensures existing users aren't affected during the migration.

## Testing Checklist

- [ ] Deploy v2 edge function to Supabase
- [ ] Add `item_specifics` column to database
- [ ] Update `SingleItemRequester.swift` to use v2 function
- [ ] Scan shoes and verify Size/Brand/Color extracted
- [ ] Scan electronics and verify Model/Connectivity extracted
- [ ] Scan clothing and verify Size/Material extracted
- [ ] Create test eBay listing and verify correct attributes
- [ ] Verify legacy items (v1) still work with fallback
- [ ] Run app with v2 for 24-48 hours before production migration

## Troubleshooting

### Issue: ATTRIBUTES field not parsing

**Check:** Ensure `SingleItemRequester.swift` line 68-75 includes the ATTRIBUTES parsing logic:

```swift
else if cleanLine.hasPrefix("ATTRIBUTES:") {
    let attributesJSON = String(cleanLine.dropFirst(11)).trimmingCharacters(in: .whitespacesAndNewlines)
    if let data = attributesJSON.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
        itemSpecifics = json
    }
}
```

### Issue: eBay listing still shows hardcoded attributes

**Check:** Verify `eBayTradingService.swift` line 107-152 uses the dynamic `getItemSpecifics()` function that reads from `listing.itemSpecifics`.

### Issue: Database error saving itemSpecifics

**Check:** Run the database migration SQL to add the `item_specifics` JSONB column.

## Support

For issues or questions about the v2 deployment, check:
1. Supabase function logs: `supabase functions logs analyze-single-item-v2`
2. Xcode console for parsing errors
3. eBay API response for XML formatting issues
