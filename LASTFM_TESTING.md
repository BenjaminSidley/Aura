# Testing Last.fm Features on Localhost

## Step 1: Get Last.fm API Credentials

1. Go to https://www.last.fm/api/account/create
2. Sign in or create a Last.fm account
3. Fill out the application form:
   - **Application name**: Aura (or your choice)
   - **Application description**: Music review application
   - **Callback URL**: `http://localhost:3000/auth/lastfm/callback` (for localhost)
4. After creating the application, you'll receive:
   - **API Key** (32 characters)
   - **Shared Secret** (32 characters) - keep this secure!

## Step 2: Configure Environment Variables

Create or edit `.local.env` in the project root:

```bash
# Last.fm API Configuration
LASTFM_API_KEY=your_api_key_here
LASTFM_SHARED_SECRET=your_shared_secret_here
LASTFM_CALLBACK_URL=http://localhost:3000/auth/lastfm/callback
```

**Note**: The callback URL is optional - if not set, it will be auto-generated from the route.

## Step 3: Run the Database Migration

```bash
bin/rails db:migrate
```

This will add the Last.fm fields to your users table.

## Step 4: Start the Rails Server

```bash
bin/rails server
# or
bin/dev
```

The app should be available at `http://localhost:3000`

## Step 5: Test the Features

### A. Test Authentication Flow

1. **Sign in** to your application (or create an account)
2. Click **"Connect Last.fm"** in the navigation bar
3. You'll be redirected to Last.fm's authorization page
4. **Authorize** the application
5. You'll be redirected back to your app with a success message
6. You should see **"♫ Last.fm Connected"** in the navigation

### B. Test Recent Tracks

1. Make sure you're connected to Last.fm
2. Navigate to: `http://localhost:3000/lastfm/recent`
   - Or click "Review recently played" if available on the albums page
3. You should see a list of your recently scrobbled tracks
4. Each track should show:
   - Track name
   - Artist name
   - Album name
   - Played timestamp
   - Album artwork (if available)
   - "Review" button
   - "Open in Last.fm" link

### C. Test Search

1. Navigate to: `http://localhost:3000/lastfm/search`
   - Or use the search form on the albums page (if connected)
2. Enter a song or artist name (e.g., "Radiohead" or "Creep")
3. Click "Search"
4. You should see search results with:
   - Track name
   - Artist name
   - Album name
   - Album artwork (if available)
   - "Review" button
   - "Open in Last.fm" link

### D. Test Disconnect

1. Click **"Disconnect Last.fm"** in the navigation
2. You should see a success message
3. The Last.fm connection status should disappear
4. Last.fm features should no longer be accessible

## Troubleshooting

### Issue: "Last.fm API not configured"
- **Solution**: Make sure `.local.env` exists and contains `LASTFM_API_KEY` and `LASTFM_SHARED_SECRET`
- Restart your Rails server after adding environment variables

### Issue: "Last.fm auth failed: no token received"
- **Solution**: Check that your callback URL in Last.fm API settings matches `http://localhost:3000/auth/lastfm/callback`
- Make sure you're using `http://` not `https://` for localhost

### Issue: "Last.fm auth failed: could not get session"
- **Solution**: 
  - Verify your API key and shared secret are correct
  - Check Rails logs for detailed error messages
  - Make sure the token hasn't expired (tokens are valid for 60 minutes)

### Issue: "Could not load recent tracks from Last.fm"
- **Solution**:
  - Make sure you're connected to Last.fm
  - Check that you have scrobbled some tracks on Last.fm
  - Check Rails logs for API errors

### Issue: No search results
- **Solution**:
  - Try a different search query
  - Check Rails logs for API errors
  - Verify your API key is correct

## Checking Rails Logs

To see detailed error messages, check your Rails logs:

```bash
tail -f log/development.log
```

Look for lines starting with `[LastfmClient` or `[LastfmAuth` for Last.fm-specific errors.

## Testing with Rails Console

You can also test the client directly in the Rails console:

```bash
bin/rails console
```

```ruby
# Get a user
user = User.first

# Check if connected
user.lastfm_connected?

# Test the client
client = LastfmClient.new(user)
tracks = client.recent_tracks(limit: 5)
puts tracks.inspect

# Test search (doesn't require authentication)
client = LastfmClient.new
results = client.search_tracks("Radiohead", limit: 5)
puts results.inspect
```

## Notes

- **Search is public**: You don't need to be connected to Last.fm to search tracks
- **Recent tracks require connection**: You must be connected to see your recent tracks
- **Session keys don't expire**: Once connected, you stay connected unless you disconnect
- **API Rate Limits**: Last.fm has rate limits - if you hit them, wait a bit and try again

