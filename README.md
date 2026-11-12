# Fugglightspeed

A sleek single-page video feed built for GitHub Pages.

## Features
- Sign up / log in screen
- Search by title, creator, or category
- Category filters and sort options
- Create and publish videos
- Trim preview before publishing
- View posts in a clean feed
- Add comments on posts
- Delete your own posts
- Browser-only local demo storage

## Notes
This version is built as a static HTML app and stores data in the browser using local storage and IndexedDB. It does not sync across devices or real users. It is intended as a front-end prototype and static page demo for GitHub Pages.

## Deploy
1. Push this repo to GitHub.
2. Enable GitHub Pages in the repository settings.
3. Use the included GitHub Actions workflow in `.github/workflows/pages.yml`.
4. Open the Pages URL from the repo settings.

## Local usage
Open `index.html` directly in a browser, or serve it with any static host.
