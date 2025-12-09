# Debug Token Flow - Session Not Found Issue

## What to Check in Console Logs

### 1. During Login
Look for these log messages in order:

```
🔵 saveAuthResponse called
🔵 Token from response: Bearer eyJhbGciOiJIUzI1...
🔵 Refresh token from response: EXISTS
Token saved successfully
✅ Auth response saved successfully
🔍 Verification - Token saved: YES
🔍 Saved token preview: Bearer eyJhbGciOiJIUzI1...
```

**If you DON'T see these:**
- Token is not being received from API
- Check API response in authservice.dart logs

### 2. When Opening Capture Screen
Look for:

```
🟡 AssetService: Fetching plants
🔵 AssetService: Calling AuthMiddleware.get()
🔵 AuthMiddleware: Getting auth headers...
🔍 getAuthToken called - Token: EXISTS (Bearer eyJhbGciOiJIUzI1...)
✅ Auth headers prepared with Bearer token
🟡 Making API request to: http://20.86.117.62:8105/api/v1/Config/plants
🔵 Headers: ✅ Has Auth Token
```

**If you see "🔴 NO AUTH TOKEN":**
- Token was not saved during login
- OR SharedPreferences was cleared
- OR using wrong key

### 3. If Token is NULL
You'll see:

```
🔴 WARNING: No token available for auth headers
🔍 Checking SharedPreferences directly...
🔍 All keys in SharedPreferences: [list of keys]
🔍 Direct token check: NULL
```

**This means:**
- Token was never saved
- OR saved with different key
- OR SharedPreferences was cleared

## Quick Fix Steps

### Step 1: Clear App Data
```bash
flutter clean
flutter pub get
```

### Step 2: Uninstall and Reinstall
- Uninstall app from phone
- Run: `flutter run`

### Step 3: Login and Check Logs
1. Login with credentials
2. Watch console for "🔵 saveAuthResponse called"
3. Check if "Token saved successfully" appears
4. Check if "🔍 Verification - Token saved: YES" appears

### Step 4: Navigate to Capture
1. Go to capture screen
2. Watch for "🔵 AuthMiddleware: Getting auth headers..."
3. Check if "✅ Has Auth Token" appears

## Common Issues

### Issue 1: Token Not Saved During Login
**Symptom:** No "Token saved successfully" log
**Cause:** response.token is null
**Fix:** Check API response format in authservice.dart

### Issue 2: Token Saved But Not Retrieved
**Symptom:** "Token saved successfully" but later "No token found"
**Cause:** SharedPreferences key mismatch
**Fix:** Check _authTokenKey matches StorageKeys.authToken

### Issue 3: Token Retrieved But Not Added to Headers
**Symptom:** Token exists but "NO AUTH TOKEN" in headers
**Cause:** getAuthHeaders() not adding Bearer prefix
**Fix:** Already fixed in authstorage.dart

## What the Logs Should Show

### ✅ CORRECT Flow:
```
Login → saveAuthResponse → Token saved → Navigate → getAuthToken → Token EXISTS → Headers prepared → API call SUCCESS
```

### ❌ BROKEN Flow (Token not saved):
```
Login → saveAuthResponse → Token NULL → Navigate → getAuthToken → Token NULL → NO AUTH TOKEN → API call FAILS
```

### ❌ BROKEN Flow (Token not retrieved):
```
Login → saveAuthResponse → Token saved → Navigate → getAuthToken → Token NULL → NO AUTH TOKEN → API call FAILS
```

## Next Steps

1. Run the app with `flutter run`
2. Copy ALL console logs from login to capture screen
3. Search for the emoji markers (🔵, ✅, 🔴, 🟡)
4. Share the logs to identify where the flow breaks
