# Database Migrations

This folder contains SQL migrations for the QuickFlip database schema.

## How to Run Migrations

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of the migration file
4. Click "Run" to execute the migration

### Option 2: Supabase CLI
```bash
# If you have Supabase CLI installed
supabase db push
```

### Option 3: Direct PostgreSQL Connection
```bash
psql <your-database-connection-string> -f migrations/add_storage_location.sql
```

## Migration Files

- `add_storage_location.sql` - Adds storage_location column to track where items are physically stored

## Migration Order

Run migrations in chronological order based on the filename/date.
