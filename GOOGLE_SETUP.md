# Google Calendar Integration Setup για Mr. PlannTer

## Προαπαιτούμενα
- Android Studio με Android SDK Platform 36
- Φυσική συσκευή Android ή Emulator με Google Play Services
- Google λογαριασμός

## Βήμα 1: Δημιουργία Google Cloud Project
1. Μεταβείτε στο [Google Cloud Console](https://console.cloud.google.com/)
2. Δημιουργήστε νέο project ή επιλέξτε υπάρχον
3. Σημειώστε το όνομα του project

## Βήμα 2: Ενεργοποίηση Google Calendar API
1. Στο αριστερό μενού: **APIs & Services** → **Library**
2. Αναζητήστε "Google Calendar API"
3. Κλικ και πατήστε **Enable**

## Βήμα 3: Δημιουργία Android OAuth Client
1. Πηγαίνετε στο **APIs & Services** → **Credentials**
2. Κλικ **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
3. Αν ζητηθεί, ρυθμίστε το OAuth consent screen:
   - User Type: **External**
   - App name: **Mr PlannTer**
   - User support email: Το email σας
   - Developer contact: Το email σας
   - **Save and Continue** μέχρι το τέλος
4. Επιστρέψτε στο **Create OAuth Client ID**:
   - Application type: **Android**
   - Name: **Mr PlannTer Android**
   - Package name: `com.example.app_mr_plannter`
   - SHA-1 certificate fingerprint: (Βλέπε παρακάτω πώς το βρίσκετε)

### Πώς να βρείτε το SHA-1 fingerprint
Για **debug keystore** (development):
```powershell
keytool -list -v -keystore "C:\Users\<USERNAME>\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
Αντιγράψτε το SHA1 που εμφανίζεται (π.χ. `8C:F8:64:5A:6B:01:6D:B8:4A:81:2F:21:CF:1B:5F:B6:31:2E:1A:02`)

5. Κλικ **Create**
6. **Κατεβάστε** το `google-services.json` που δημιουργήθηκε

## Βήμα 4: Εγκατάσταση google-services.json
1. Τοποθετήστε το αρχείο που κατεβάσατε στο:
   ```
   android/app/google-services.json
   ```
2. Αντικαταστήστε το υπάρχον αρχείο αν ήδη υπάρχει

## Βήμα 5: Build & Test
1. Καθαρισμός και rebuild:
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```
2. Εγκατάσταση σε συσκευή/emulator:
   ```powershell
   flutter run
   ```
3. Στην εφαρμογή:
   - Πλοηγηθείτε στην προβολή Calendar
   - Πατήστε "Google Calendar Sync"
   - Επιλέξτε Export, Import ή Two-way Sync
   - Εισέλθετε με τον Google λογαριασμό σας
   - Εγκρίνετε τα δικαιώματα


## Σημειώσεις Ασφαλείας

- ✅ Το `google-services.json` πρέπει να είναι στο `.gitignore` (ήδη ρυθμισμένο)
- ✅ Κάθε developer χρειάζεται το δικό του `google-services.json` με το δικό του SHA-1
- ⚠️ Για production: δημιουργήστε release keystore και αντίστοιχο OAuth client με release SHA-1

## Troubleshooting

**Σφάλμα: "Google failed to authenticate back in the app"**
- Βεβαιωθείτε ότι το package name στο `google-services.json` ταιριάζει με το `android/app/build.gradle.kts` (`com.example.app_mr_plannter`)
- Ελέγξτε ότι το SHA-1 fingerprint είναι σωστό
- Επιβεβαιώστε ότι έχετε δημιουργήσει **Android** OAuth client (όχι Desktop ή Web)

**Σφάλμα: "API not enabled"**
- Στο Google Cloud Console, βεβαιωθείτε ότι το Google Calendar API είναι enabled

**Η αυθεντικοποίηση δεν ολοκληρώνεται**
- Ελέγξτε ότι η συσκευή/emulator έχει Google Play Services
- Δοκιμάστε logout και ξανά login στον Google λογαριασμό της συσκευής
- Βεβαιωθείτε ότι έχετε internet σύνδεση

**Σφάλμα εγκατάστασης APK: "INSTALL_FAILED_USER_RESTRICTED"**
- Στη συσκευή: Settings → Security → Install unknown apps → επιτρέψτε την πηγή
- Ή στη συσκευή: Settings → Developer options → βεβαιωθείτε ότι "USB debugging" είναι ON

## Επιπλέον Πληροφορίες

### OAuth Consent Screen Setup
Αν το project σας είναι σε "Testing" mode:
- Προσθέστε τους Google λογαριασμούς που θα χρησιμοποιήσουν την εφαρμογή στη λίστα "Test users"
- Στο OAuth consent screen → Test users → + ADD USERS

### Release Build SHA-1
Για production APK χρειάζεστε release keystore:
1. Δημιουργήστε release keystore (αν δεν έχετε):
   ```powershell
   keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Πάρτε το SHA-1:
   ```powershell
   keytool -list -v -keystore release.keystore -alias release
   ```
3. Δημιουργήστε νέο Android OAuth client με το release SHA-1
4. Κατεβάστε το αντίστοιχο `google-services.json` και χρησιμοποιήστε το για production builds