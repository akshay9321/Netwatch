# NetWatch — Cloud Build via GitHub Actions

Nothing installs on your Mac for this. GitHub's servers compile the app on a
real macOS machine (with Xcode already there — not your disk), and you just
download the finished `.app` when it's done.

---

## Step 1 — Create a GitHub account (skip if you have one)

Go to [github.com/signup](https://github.com/signup) — free, just email +
password.

## Step 2 — Create a new repository

1. Click the **+** in the top-right → **New repository**.
2. Name it e.g. `netwatch-app`.
3. Set it to **Public** (public repos get unlimited free macOS build
   minutes; private repos only get a small monthly quota and macOS builds
   burn it 10x faster than normal, so public is the easier default for
   this).
4. Don't check "Add a README" — leave it empty. Click **Create repository**.

## Step 3 — Upload the files (no git needed)

You're on the empty repo page now.

1. Click **uploading an existing file** (link in the middle of the page),
   or **Add file → Upload files**.
2. From your computer, open the `NetWatch-Repo` folder I gave you and drag
   the **entire contents** of that folder (not the folder itself — its
   contents: `Package.swift`, `Sources/`, `Resources/`, `Scripts/`,
   `.github/`, `.gitignore`) onto the upload area.
   - Most browsers (Chrome/Edge) let you drag whole folders and keep the
     structure. If yours doesn't, you may need to upload folder-by-folder —
     GitHub will recreate the paths as long as you drop each folder in one
     at a time at the repo root.
3. Scroll down, add a commit message like "Initial upload", and click
   **Commit changes** (commit directly to `main`).

## Step 4 — Watch the build run

1. Click the **Actions** tab at the top of your repo.
2. You should see a workflow run start automatically (triggered by your
   push) — click into it.
3. It takes roughly **2–5 minutes**. Green checkmark = success.

If it fails (red ✕), click into the failed step to see the error and paste
it back to me — I'll fix the source and you re-upload just the changed
file(s).

## Step 5 — Download the built app

1. Still inside that workflow run page, scroll to the bottom to
   **Artifacts**.
2. Click **NetWatch-macOS** to download a zip.
3. Unzip it on your Mac — you'll have `NetWatch.app`.

## Step 6 — First launch (unsigned app, one-time step)

The app isn't code-signed (that needs a paid Apple Developer account), so
macOS Gatekeeper will block it the first time:

- **Right-click (or Control-click) `NetWatch.app` → Open** → a dialog
  appears saying Apple couldn't verify it → click **Open** again. This only
  needs to happen once; after that it opens normally.
- If instead you get a message saying the app **"is damaged and can't be
  opened"** (common for unsigned apps downloaded as a zip), open
  **Terminal** (already on your Mac, no install needed) and run:
  ```
  xattr -cr /path/to/NetWatch.app
  ```
  (drag the app into the Terminal window after typing `xattr -cr ` to
  auto-fill the path, then press Enter). Then try opening it again.

On first real launch, macOS will also prompt for **Local Network** access —
click **Allow**, otherwise device scanning won't work.

---

## Making changes later

Any time I update the source, you'll re-upload the changed files the same
way (GitHub → your repo → drag the new file onto the existing path → commit)
and the Actions workflow re-runs automatically, giving you a fresh
`.app` artifact each time. No local rebuilding, ever.

## What this build includes

Same real functionality as discussed: live device scanning (ARP/ping sweep),
Ping/Traceroute/DNS Lookup/Wake-on-LAN/Port Scan tools, Cloudflare-based
speed test, heuristic security checks, People/presence, Timeline, Settings —
all running natively on your Mac once launched, no server involved.
