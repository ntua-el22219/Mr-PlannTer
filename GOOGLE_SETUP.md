# Google Calendar Integration Setup

## How to Get Google OAuth Credentials

### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project name

### Step 2: Enable Google Calendar API
1. In the left menu, go to **APIs & Services** → **Library**
2. Search for "Google Calendar API"
3. Click on it and press **Enable**

### Step 3: Create OAuth Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
3. If prompted, configure the OAuth consent screen:
   - User Type: **External** (for testing)
   - App name: **Mr PlannTer**
   - User support email: Your email
   - Developer contact: Your email
   - Click **Save and Continue** through all steps
4. Back to **Create OAuth Client ID**:
   - Application type: **Desktop app**
   - Name: **Mr PlannTer Desktop**
   - Click **Create**
5. **Copy** the Client ID and Client Secret shown

### Step 4: Configure Your App
1. In project root, copy `.env.example` to `.env`:
   ```bash
   copy .env.example .env
   ```
2. Edit `.env` file and paste your credentials:
   ```
   GOOGLE_CLIENT_ID=your_actual_client_id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=your_actual_client_secret
   ```
3. Run `flutter pub get` to install dependencies

### Step 5: Test
1. Run your app: `flutter run -d windows`
2. Go to Calendar view
3. Click "Synchronize with Google Calendar"
4. A browser window will open for authentication
5. Grant permissions to your app

## Security Notes

- ✅ `.env` file is gitignored - never commit credentials
- ✅ Share `.env.example` as template (no secrets)
- ✅ Each developer needs their own `.env` with credentials
- ⚠️ For production: use a backend server to handle OAuth

## Troubleshooting

**Error: "No .env file found"**
- Create `.env` file from `.env.example` template

**Error: "401 invalid_client"**
- Check your Client ID and Secret are correct in `.env`
- Ensure no extra spaces or quotes

**Error: "redirect_uri_mismatch"**
- In Google Cloud Console, add redirect URI: `http://localhost`
- Or use the exact URI shown in the error message

**Browser doesn't open**
- Check url_launcher package is installed
- Try manually copying the auth URL from console
