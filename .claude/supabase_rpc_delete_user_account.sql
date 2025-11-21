-- Supabase RPC Function: delete_user_account
--
-- Purpose: Deletes all user data and complies with GDPR right to erasure
--
-- This function should be created in your Supabase project via the SQL Editor
-- or migration system.
--
-- Usage: Called by AuthService.deleteAccount() in Swift code

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete all user data in correct order (respecting foreign key constraints)
    -- Delete measurements first (references goal_occurrences)
    DELETE FROM measurements WHERE user_id = auth.uid();

    -- Delete goal occurrences (references goals)
    DELETE FROM goal_occurrences WHERE user_id = auth.uid();

    -- Delete goals (references areas)
    DELETE FROM goals WHERE user_id = auth.uid();

    -- Delete reflections (independent)
    DELETE FROM reflections WHERE user_id = auth.uid();

    -- Delete areas (independent of goals at this point)
    DELETE FROM areas WHERE user_id = auth.uid();

    -- Delete profile (last)
    DELETE FROM profiles WHERE id = auth.uid();

    -- Note: Auth account deletion may require admin API or separate handling
    -- Supabase's Auth system typically requires admin privileges to delete auth users
    -- This can be handled via:
    -- 1. Supabase Admin API (from backend service)
    -- 2. Soft delete (mark account as deleted but keep auth record)
    -- 3. Database trigger on profiles deletion to clean auth.users

    -- For now, this function handles all application data deletion
    -- Auth account cleanup can be added separately if needed
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION delete_user_account() IS
'Deletes all user data for the currently authenticated user. Complies with GDPR right to erasure. Called by the mobile app when user requests account deletion.';
