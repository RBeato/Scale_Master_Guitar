-- ============================================
-- Scale Master Guitar - Fingerings Library Schema
-- Run this in your Supabase SQL Editor
--
-- NOTE: Using 'smg_' prefix for all tables/functions
-- so they can coexist with Guitar Progression Generator
-- tables in the same Supabase project.
-- ============================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- SAVED FINGERINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS smg_saved_fingerings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  dot_positions JSONB NOT NULL,        -- 2D array of booleans [6 strings][25 frets]
  dot_colors JSONB NOT NULL,           -- 2D array of hex color strings
  sharp_flat_preference TEXT,          -- 'sharps' | 'flats' | null
  show_note_names BOOLEAN DEFAULT false,
  fretboard_color TEXT,                -- hex color string for background
  is_public BOOLEAN DEFAULT false,
  likes_count INTEGER DEFAULT 0,
  loads_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_smg_saved_fingerings_user_id ON smg_saved_fingerings(user_id);
CREATE INDEX IF NOT EXISTS idx_smg_saved_fingerings_is_public ON smg_saved_fingerings(is_public);
CREATE INDEX IF NOT EXISTS idx_smg_saved_fingerings_created_at ON smg_saved_fingerings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_smg_saved_fingerings_likes_count ON smg_saved_fingerings(likes_count DESC);

-- ============================================
-- FINGERING LIKES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS smg_fingering_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  fingering_id UUID NOT NULL REFERENCES smg_saved_fingerings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fingering_id)
);

-- Index for faster like lookups
CREATE INDEX IF NOT EXISTS idx_smg_fingering_likes_user_id ON smg_fingering_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_smg_fingering_likes_fingering_id ON smg_fingering_likes(fingering_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on smg_saved_fingerings
ALTER TABLE smg_saved_fingerings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own fingerings
CREATE POLICY "Users can read own fingerings"
  ON smg_saved_fingerings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can read public fingerings
CREATE POLICY "Anyone can read public fingerings"
  ON smg_saved_fingerings
  FOR SELECT
  USING (is_public = true);

-- Policy: Users can insert their own fingerings
CREATE POLICY "Users can insert own fingerings"
  ON smg_saved_fingerings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own fingerings
CREATE POLICY "Users can update own fingerings"
  ON smg_saved_fingerings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own fingerings
CREATE POLICY "Users can delete own fingerings"
  ON smg_saved_fingerings
  FOR DELETE
  USING (auth.uid() = user_id);

-- Enable RLS on smg_fingering_likes
ALTER TABLE smg_fingering_likes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read all likes (for counting)
CREATE POLICY "Anyone can read likes"
  ON smg_fingering_likes
  FOR SELECT
  USING (true);

-- Policy: Users can insert their own likes
CREATE POLICY "Users can insert own likes"
  ON smg_fingering_likes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own likes
CREATE POLICY "Users can delete own likes"
  ON smg_fingering_likes
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- FUNCTIONS FOR INCREMENTING/DECREMENTING COUNTS
-- ============================================

-- Function to increment likes count
CREATE OR REPLACE FUNCTION smg_increment_fingering_likes(fingering_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE smg_saved_fingerings
  SET likes_count = likes_count + 1
  WHERE id = fingering_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement likes count
CREATE OR REPLACE FUNCTION smg_decrement_fingering_likes(fingering_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE smg_saved_fingerings
  SET likes_count = GREATEST(likes_count - 1, 0)
  WHERE id = fingering_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment loads count
CREATE OR REPLACE FUNCTION smg_increment_fingering_loads(fingering_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE smg_saved_fingerings
  SET loads_count = loads_count + 1
  WHERE id = fingering_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- POPULAR FINGERINGS VIEW
-- ============================================
CREATE OR REPLACE VIEW smg_popular_fingerings AS
SELECT
  *,
  (likes_count * 2 + loads_count) AS popularity_score
FROM smg_saved_fingerings
WHERE is_public = true
ORDER BY popularity_score DESC;

-- ============================================
-- ENABLE ANONYMOUS AUTH
-- ============================================
-- Go to Authentication > Settings in Supabase Dashboard
-- Enable "Allow anonymous sign-ins"

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON smg_saved_fingerings TO anon, authenticated;
GRANT ALL ON smg_fingering_likes TO anon, authenticated;
GRANT SELECT ON smg_popular_fingerings TO anon, authenticated;
GRANT EXECUTE ON FUNCTION smg_increment_fingering_likes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION smg_decrement_fingering_likes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION smg_increment_fingering_loads TO anon, authenticated;
