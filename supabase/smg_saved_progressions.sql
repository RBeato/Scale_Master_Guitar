-- SMG Saved Progressions Table
-- For Scale Master Guitar app
-- Uses 'smg_' prefix to avoid conflicts with other apps in shared Supabase project

-- Create the progressions table
CREATE TABLE IF NOT EXISTS smg_saved_progressions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    tags TEXT,
    chords JSONB NOT NULL,
    total_beats INTEGER NOT NULL DEFAULT 0,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    likes_count INTEGER NOT NULL DEFAULT 0,
    loads_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_smg_progressions_user_id ON smg_saved_progressions(user_id);
CREATE INDEX IF NOT EXISTS idx_smg_progressions_is_public ON smg_saved_progressions(is_public);
CREATE INDEX IF NOT EXISTS idx_smg_progressions_created_at ON smg_saved_progressions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE smg_saved_progressions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own progressions
CREATE POLICY "Users can view own progressions"
    ON smg_saved_progressions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can view public progressions
CREATE POLICY "Anyone can view public progressions"
    ON smg_saved_progressions
    FOR SELECT
    USING (is_public = true);

-- Policy: Users can insert their own progressions
CREATE POLICY "Users can insert own progressions"
    ON smg_saved_progressions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own progressions
CREATE POLICY "Users can update own progressions"
    ON smg_saved_progressions
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can delete their own progressions
CREATE POLICY "Users can delete own progressions"
    ON smg_saved_progressions
    FOR DELETE
    USING (auth.uid() = user_id);

-- Likes table for progressions
CREATE TABLE IF NOT EXISTS smg_progression_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    progression_id UUID NOT NULL REFERENCES smg_saved_progressions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, progression_id)
);

-- Index for likes
CREATE INDEX IF NOT EXISTS idx_smg_progression_likes_user ON smg_progression_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_smg_progression_likes_progression ON smg_progression_likes(progression_id);

-- Enable RLS on likes
ALTER TABLE smg_progression_likes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all likes (for counting)
CREATE POLICY "Anyone can view progression likes"
    ON smg_progression_likes
    FOR SELECT
    USING (true);

-- Policy: Users can insert their own likes
CREATE POLICY "Users can like progressions"
    ON smg_progression_likes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own likes
CREATE POLICY "Users can unlike progressions"
    ON smg_progression_likes
    FOR DELETE
    USING (auth.uid() = user_id);

-- RPC function to increment likes count
CREATE OR REPLACE FUNCTION smg_increment_progression_likes(progression_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE smg_saved_progressions
    SET likes_count = likes_count + 1
    WHERE id = progression_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to decrement likes count
CREATE OR REPLACE FUNCTION smg_decrement_progression_likes(progression_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE smg_saved_progressions
    SET likes_count = GREATEST(likes_count - 1, 0)
    WHERE id = progression_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to increment loads count
CREATE OR REPLACE FUNCTION smg_increment_progression_loads(progression_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE smg_saved_progressions
    SET loads_count = loads_count + 1
    WHERE id = progression_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION smg_increment_progression_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION smg_decrement_progression_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION smg_increment_progression_loads(UUID) TO authenticated;
