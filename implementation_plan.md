# High-End Workout App Implementation Plan

This document outlines the architecture, data model, and execution steps to build a high-end, Leomoves-style workout application using Flutter, Supabase (`mwp2` project), and Bunny.net Stream.

## User Review Required

> [!IMPORTANT]
> **API Keys & Secrets:** To implement Bunny.net streaming and Supabase properly, I will need access to your Supabase Project URL & Anon Key, as well as your Bunny.net Stream Library ID and API Key. Please let me know how you'd like to provide these (e.g., in a `.env` file).

> [!IMPORTANT]
> **Project Initialization:** The target workspace directory (`c:\Users\srida\mwp2\mwp2`) is currently empty. I will initialize a fresh Flutter project here. Please confirm if this is correct, or if we should be migrating code from your previous `mwp` directory.

## Open Questions

> [!WARNING]
> 1. **Bunny.net Uploads:** Should the app include an Admin Panel within the Flutter app to upload videos directly to Bunny.net, or will you manage video uploads via the Bunny.net dashboard and only use the app for streaming?
> 2. **Authentication:** Do you want to use Supabase Auth for email/password and social logins from the start?
> 3. **State Management:** I propose using `Riverpod` for state management as it is robust for complex apps. Are you comfortable with this choice?

## Proposed Architecture

### Tech Stack
*   **Frontend:** Flutter (compatible with iOS and Android).
*   **State Management:** Riverpod.
*   **Backend & DB:** Supabase (`mwp2` project).
*   **Video Streaming:** Bunny.net Stream (using a Flutter video player package like `video_player` with HLS support).
*   **Routing:** GoRouter.

### Supabase Data Model (To be applied)

We will create a structured hierarchy similar to professional apps like Leomoves:

1.  **`programs`**: The high-level plans (e.g., "Beginner Calisthenics", "Mobility Flow").
    *   `id` (uuid, pk), `title`, `description`, `difficulty_level`, `cover_image_url`, `created_at`
2.  **`workouts`**: Individual sessions within a program.
    *   `id` (uuid, pk), `program_id` (fk), `title`, `description`, `order_index`
3.  **`exercises`**: The global library of movements.
    *   `id` (uuid, pk), `title`, `description`, `bunny_video_id` (used to construct the stream URL), `instructions`
4.  **`workout_blocks`**: Groupings within a workout (e.g., Warm-up, Circuit A, Finisher).
    *   `id` (uuid, pk), `workout_id` (fk), `title`, `block_type`, `order_index`, `rounds`
5.  **`workout_exercises`**: The specific mapping of an exercise to a block with prescriptive variables.
    *   `id` (uuid, pk), `block_id` (fk), `exercise_id` (fk), `reps`, `sets`, `duration_seconds`, `rest_seconds`, `order_index`

### Application Features

1.  **Onboarding & Auth:** Clean, premium UI for login/signup.
2.  **Dashboard:** Displaying current program progress, recommended workouts.
3.  **Program Explorer:** Browsing available programs and standalone workouts.
4.  **Workout Player (The Core Experience):**
    *   A full-screen, follow-along or self-paced sequence player.
    *   Integration with Bunny.net HLS streams for seamless, buffer-free video playback.
    *   Timers, audio cues, and transitions between exercises.
    *   Ability to swap exercises for harder/easier regressions.
5.  **Exercise Library:** A searchable dictionary of all movements with instructional videos.

## Execution Steps

### Phase 1: Setup & Infrastructure
1.  Initialize Flutter project in `c:\Users\srida\mwp2\mwp2`.
2.  Add core dependencies (`supabase_flutter`, `flutter_riverpod`, `go_router`, `video_player`, `chewie` or `appinio_video_player` for custom controls).
3.  Execute Supabase SQL migrations to create the data model above.
4.  Setup `.env` configuration for Supabase and Bunny.net keys.

### Phase 2: Core Services & Data Access
1.  Implement `SupabaseService` for DB operations.
2.  Implement `BunnyStreamService` to handle generating secure stream URLs based on `bunny_video_id`.
3.  Create Riverpod providers for state management (Programs, Workouts, active playback state).

### Phase 3: UI & Theming (Premium Aesthetics)
1.  Implement a dark-themed, glassmorphism-inspired design system (`AppTheme`).
2.  Build reusable UI components (Cards, Buttons, Video Thumbnails).
3.  Develop the Dashboard, Program Listing, and Workout Details screens.

### Phase 4: Workout Player Integration
1.  Build the `SequencePlayer` screen.
2.  Integrate the Flutter video player to stream HLS from Bunny.net.
3.  Implement workout logic (timers, auto-advance to next exercise, play/pause).

## Verification Plan

### Automated/Manual Tests
*   **Database:** Run test queries on `@mcp:supabase:mwp2` to ensure tables and RLS policies are correct.
*   **Flutter Run:** Build and run the app locally on an Android emulator or Windows desktop target to verify UI and navigation.
*   **Video Streaming:** Hardcode a test Bunny.net video ID to ensure the HLS stream plays correctly within the app.
