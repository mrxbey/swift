import Foundation

/// Application configuration with fail-fast validation for production security.
///
/// This enum ensures NO hardcoded credentials exist in the codebase.
/// All sensitive configuration must be provided via environment variables.
///
/// # Security Model
///
/// - **NO fallback values** - fails fast if configuration missing
/// - **Clear error messages** - developers know exactly what to configure
/// - **Environment-based** - different configs for dev/staging/prod
/// - **Zero secrets in code** - all credentials externalized
///
/// # Usage
///
/// ```swift
/// // Configuration is lazy-loaded and validated on first access
/// let url = Config.supabaseURL        // Fails fast if not set
/// let key = Config.supabaseAnonKey    // Fails fast if not set
///
/// // Or validate explicitly on app startup
/// try Config.validate()
/// ```
///
/// # Setup Instructions
///
/// **Xcode Configuration:**
/// 1. Product > Scheme > Edit Scheme
/// 2. Run > Arguments > Environment Variables
/// 3. Add the following variables:
///    - `SUPABASE_URL`: Your Supabase project URL
///    - `SUPABASE_ANON_KEY`: Your Supabase anonymous/public API key
///
/// **Finding Your Credentials:**
/// 1. Open Supabase Dashboard: https://app.supabase.com
/// 2. Select your project
/// 3. Settings > API
/// 4. Copy "Project URL" → SUPABASE_URL
/// 5. Copy "anon public" key → SUPABASE_ANON_KEY
///
/// **Example Values:**
/// ```
/// SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
/// SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
/// ```
///
/// # Testing
///
/// **Command Line:**
/// ```bash
/// export SUPABASE_URL="https://xxxxx.supabase.co"
/// export SUPABASE_ANON_KEY="eyJ..."
/// swift test
/// ```
///
/// **Xcode Schemes:**
/// - Development: Points to development Supabase project
/// - Staging: Points to staging Supabase project
/// - Production: Points to production Supabase project
///
public enum Config {
    // MARK: - Configuration Properties

    /// Supabase project URL
    ///
    /// Must be provided via `SUPABASE_URL` environment variable.
    /// No fallback value provided to prevent accidental credential exposure.
    ///
    /// **Format:** `https://xxxxxxxxxxxxx.supabase.co`
    ///
    /// **Find in:** Supabase Dashboard > Settings > API > Project URL
    public static let supabaseURL: String = {
        guard let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty else {
            fatalError("""
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                ⚠️  CONFIGURATION ERROR: SUPABASE_URL Not Set
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                The SUPABASE_URL environment variable is required but not configured.

                📝 To fix this in Xcode:

                   1. Product menu → Scheme → Edit Scheme...
                   2. Select "Run" in the left sidebar
                   3. Select "Arguments" tab
                   4. Under "Environment Variables" click "+"
                   5. Add:
                      Name:  SUPABASE_URL
                      Value: https://xxxxxxxxxxxxx.supabase.co

                🔍 Finding your Supabase URL:

                   1. Open https://app.supabase.com
                   2. Select your project
                   3. Go to Settings → API
                   4. Copy "Project URL"

                📌 Example:
                   SUPABASE_URL=https://wiecalnwrmnnojkvnkym.supabase.co

                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                """)
        }

        // Validate URL format
        guard url.hasPrefix("https://"), url.contains(".supabase.co") else {
            fatalError("""
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                ⚠️  CONFIGURATION ERROR: Invalid SUPABASE_URL Format
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                Current value: \(url)

                ✅ Valid format:   https://xxxxx.supabase.co
                ❌ Invalid format: \(url)

                Make sure your SUPABASE_URL:
                  • Starts with https://
                  • Contains .supabase.co
                  • Matches your Supabase project URL exactly

                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                """)
        }

        return url
    }()

    /// Supabase anonymous/public API key
    ///
    /// Must be provided via `SUPABASE_ANON_KEY` environment variable.
    /// No fallback value provided to prevent accidental credential exposure.
    ///
    /// **Format:** JWT token starting with `eyJ...`
    ///
    /// **Find in:** Supabase Dashboard > Settings > API > anon public key
    ///
    /// **Security Note:**
    /// This is the "public" key safe to use in client applications.
    /// It works with Row Level Security (RLS) policies to restrict data access.
    public static let supabaseAnonKey: String = {
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty else {
            fatalError("""
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                ⚠️  CONFIGURATION ERROR: SUPABASE_ANON_KEY Not Set
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                The SUPABASE_ANON_KEY environment variable is required but not configured.

                📝 To fix this in Xcode:

                   1. Product menu → Scheme → Edit Scheme...
                   2. Select "Run" in the left sidebar
                   3. Select "Arguments" tab
                   4. Under "Environment Variables" click "+"
                   5. Add:
                      Name:  SUPABASE_ANON_KEY
                      Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

                🔍 Finding your Supabase anon key:

                   1. Open https://app.supabase.com
                   2. Select your project
                   3. Go to Settings → API
                   4. Copy "anon public" key (NOT service_role!)

                ⚠️  Important: Use the "anon public" key, NOT "service_role"
                   The service_role key should NEVER be in client code.

                📌 The key should start with: eyJ...

                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                """)
        }

        // Validate JWT format (basic check)
        guard key.hasPrefix("eyJ") else {
            fatalError("""
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                ⚠️  CONFIGURATION ERROR: Invalid SUPABASE_ANON_KEY Format
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                The anon key should be a JWT token starting with "eyJ"

                Current value starts with: \(key.prefix(10))...

                Make sure you copied the entire "anon public" key from:
                Supabase Dashboard → Settings → API

                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                """)
        }

        return key
    }()

    // MARK: - Validation

    /// Validates all configuration on startup
    ///
    /// This triggers lazy evaluation of all configuration properties,
    /// ensuring the app fails fast on startup if configuration is missing.
    ///
    /// **Usage:**
    /// ```swift
    /// // In SupabaseService.init()
    /// do {
    ///     try Config.validate()
    /// } catch {
    ///     fatalError("Configuration error: \(error)")
    /// }
    /// ```
    ///
    /// - Throws: Never throws - uses fatalError for missing config
    public static func validate() throws {
        // Trigger lazy evaluation
        _ = supabaseURL
        _ = supabaseAnonKey

        print("✅ Configuration validated successfully")
        print("   • Supabase URL: \(supabaseURL)")
        print("   • Anon Key: \(supabaseAnonKey.prefix(20))...")
    }

    // MARK: - Development Helpers

    /// Returns true if running in Xcode test environment
    public static var isTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Returns true if running in Xcode preview
    public static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    // MARK: - Debug Information

    /// Prints current configuration status (safe - no secrets)
    public static func printStatus() {
        print("""
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            📊 Configuration Status
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            SUPABASE_URL:      \(supabaseURL)
            SUPABASE_ANON_KEY: \(supabaseAnonKey.prefix(20))...[REDACTED]

            Environment:
              • Testing:  \(isTesting ? "YES" : "NO")
              • Preview:  \(isPreview ? "YES" : "NO")

            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            """)
    }
}

// MARK: - Security Audit

/*
 ┌─────────────────────────────────────────────────────────────────────┐
 │                         SECURITY AUDIT                               │
 └─────────────────────────────────────────────────────────────────────┘

 ✅ NO hardcoded credentials in this file
 ✅ NO fallback values that could leak secrets
 ✅ Fail-fast behavior prevents running with missing config
 ✅ Clear error messages guide developers to fix issues
 ✅ JWT format validation prevents common mistakes
 ✅ URL format validation prevents configuration errors
 ✅ Debug helpers redact sensitive values
 ✅ Environment-based configuration supports dev/staging/prod

 ⚠️ NEVER commit actual credentials to this file
 ⚠️ NEVER add fallback values for production
 ⚠️ ALWAYS use environment variables for secrets

 Last Security Review: 2025-11-20
 Status: ✅ SECURE - No credentials in code
 */
