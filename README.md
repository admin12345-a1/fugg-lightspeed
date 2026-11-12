# Fugglightspeed

A static HTML video-sharing front end with Supabase for shared accounts, video uploads, public posts, comments, and creator subscriptions. Each person has their own account; public videos are visible to everyone across devices.

## Setup

1. Create a Supabase project.
2. In **SQL Editor**, run the complete [`supabase-setup.sql`](supabase-setup.sql) script. It creates the tables, signup profile trigger, public video bucket, and row-level security policies.
3. In `index.html`, replace `YOUR_SUPABASE_PROJECT_URL` and `YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY` with the project URL and browser-safe publishable/anon key from Supabase API settings. Never put a `service_role` or secret key in this file.
4. Commit the changes to `main`. The included GitHub Pages Actions workflow deploys the site. Wait for the workflow to finish, then visit the Pages URL in the repository settings.
5. Create an account and test uploading a small video. Open the public Pages URL in another browser/device to confirm the post is shared.

The Supabase publishable/anon key is intended for browser use; access is controlled by the SQL policies. Keep account passwords out of source code. Videos in the public bucket are public to watch. This is a starter app, so add moderation, reporting, rate limits, privacy policy, and storage/bandwidth budgeting before inviting a large public audience.

## Features

- Individual Supabase Auth accounts
- Shared public feed and video storage
- Search by title, creator, or category
- Category filters and Everyone / Following feed modes
- Upload and delete your own videos
- Trim-range playback preview (does not export an edited video)
- Shared comments and creator subscriptions
- Responsive, single-page HTML UI

## Local preview

Use a local static server or GitHub Pages. Direct `file://` access may be restricted by browser or Supabase auth redirect settings. Add the preview URL to Supabase **Authentication → URL Configuration** if needed.
