# PRD: Server-Driven Sales Infrastructure

## Overview
Implement a comprehensive sales infrastructure that allows admins to create, manage, and deploy targeted sales campaigns to users through the backend. Sales will be configured via the Gardener admin app and displayed to users in the iOS app through auto-presenting modals, Today Insights banners, and Settings promotions.

---

## Goals
- Enable dynamic, server-driven sales campaigns without requiring app updates
- Target specific user segments (free, subscribed, expired, all users)
- Provide flexible pricing display with RevenueCat integration
- Track sale performance through TelemetryDeck
- Maintain sync between admin changes and client display

---

## Phase 1: Backend (Vapor API)

### Database Model: SaleRecord

**Location:** `Backend/Bloom-Backend/Sources/App/Database/Models/SaleRecord.swift`

**Fields:**
- `id` (String, UUID) - Unique identifier
- `title` (String, required) - Sale title displayed to users
- `bodyText` (String, required) - Sale description/body copy
- `imageURL` (String, optional) - S3 URL for sale hero image
- `saleProductId` (String, required) - RevenueCat product ID being sold
- `compareProductId` (String, optional) - RevenueCat product ID to compare against for discount display
- `targetAudience` (Enum, required) - User segment to target:
  - `allUsers` - Show to all users
  - `freeUsers` - Show only to users who never subscribed
  - `subscribedUsers` - Show only to currently subscribed users
  - `expiredUsers` - Show only to users whose subscription expired
- `startDate` (Date, required) - Sale start timestamp
- `endDate` (Date, required) - Sale end timestamp
- `displayFrequencyDays` (Int, required) - How often to auto-show modal (1-30 days)
- `isActive` (Bool, required) - Manual on/off switch (allows draft mode, quick disable, pause/resume)
- `telemetryEventName` (String, required) - TelemetryDeck event name to log when sale appears
- `createdAt` (Timestamp) - Auto-populated creation time
- `updatedAt` (Timestamp) - Auto-populated last update time

**Migration:**
- Create `SaleRecord+Migrations.swift` with table and enum creation
- Register in `AllMigrations.swift`

### API Endpoints

#### Public Endpoints (SalesController)

**`GET /v1/sales/active`**
- **Auth:** Required (UserToken)
- **Returns:** `SalesResponse` containing array of `SaleDetails`
- **Filtering:**
  - `isActive = true`
  - Within date range (`startDate ≤ now ≤ endDate`)
- **Logic:** Returns all active sales; client filters by user's subscription status using RevenueCat data
- **Architecture Decision:** Client-side filtering simplifies backend and allows real-time RevenueCat status

#### Admin Endpoints (AdminSalesController)

**`GET /v1/admin/sales`**
- **Auth:** Required (AdminUserToken)
- **Returns:** All sales (including inactive)

**`POST /v1/admin/sales/create`**
- **Auth:** Required (AdminUserToken)
- **Body:** Sale creation data
- **Validation:** Requires `saleProductId` and `telemetryEventName`

**`PATCH /v1/admin/sales/:id`**
- **Auth:** Required (AdminUserToken)
- **Body:** Updated sale data
- **Purpose:** Update any field including toggling `isActive`

**`DELETE /v1/admin/sales/:id`**
- **Auth:** Required (AdminUserToken)

**`POST /v1/admin/sales/:id/upload-image`**
- **Auth:** Required (AdminUserToken)
- **Body:** Image file
- **Returns:** S3 URL for uploaded image

### Image Storage

**Implementation:**
- Add `StoragePath.saleImages` enum case
- Upload to S3 using existing `ImageStorage` service
- Generate signed URLs with appropriate expiration (24-48 hours)
- Follow existing pattern from `FoodController` image uploads

---

## Phase 2: Gardener (macOS Admin App)

### Sales Management UI

**Location:** `Apps/Gardener/Gardener/UserInterface/SalesManagement/`

#### SalesListView
- **Purpose:** Master list of all sales
- **Display:**
  - Table/List with columns: Title, Date Range, Target Audience, Status (Active/Inactive)
  - Visual indicators for active vs inactive sales
  - Sortable by date, status
- **Actions:**
  - Click row to edit
  - "Create New Sale" button
  - Delete option (with confirmation)

#### SaleDetailView
- **Layout:** Split view with image preview (left) and form (right)
- **Pattern:** Follow `FoodItemDetailView` design

**Left Pane:**
- Image preview (hero image for sale)
- Upload button for image selection
- Preview of how image will appear to users

**Right Pane Form Sections:**

1. **Basic Info**
   - Title (TextField, required)
   - Body Text (TextEditor, required, multiline)

2. **Products**
   - Sale Product ID (TextField, required) - The product being sold
   - Compare Product ID (TextField, optional) - Product to show original price/discount from

3. **Targeting**
   - Target Audience (Picker, required) - All Users / Free Users / Subscribed Users / Expired Users

4. **Schedule**
   - Start Date (DatePicker, required)
   - End Date (DatePicker, required)
   - Display Frequency Days (Stepper, required, 1-30) - How often to show modal

5. **Analytics**
   - Telemetry Event Name (TextField, required) - TelemetryDeck event to log

6. **Status**
   - Active (Toggle) - Enable/disable sale without deleting

**Bottom Shelf:**
- Save button (disabled if required fields empty)
- Delete button (if editing existing sale, with confirmation)

#### SaleDetailViewModel
- **Responsibilities:**
  - Form validation (required fields)
  - Network calls for CRUD operations
  - Image upload handling
  - State management

### Navigation
- Add "Sales" item to Gardener sidebar
- Route to SalesListView on click

### Networking
- Add admin sale endpoints to `NetworkStack.swift`
- Follow existing admin API patterns

---

## Phase 3: iOS App

### Shared Models (BloomModel)

**Location:** `Shared/BloomModel/Sources/BloomModel/`

#### SaleDetails
- **Purpose:** Shared network model between client and server
- **Note:** NOT called "DTO" (reserved for SwiftData models)
- **Conformance:** `SendableNetworkModel`
- **Fields:** Mirror all `SaleRecord` fields

#### SalesResponse
- **Purpose:** API response wrapper
- **Fields:**
  - `sales: [SaleDetails]`

#### TargetAudience Enum
- `allUsers`, `freeUsers`, `subscribedUsers`, `expiredUsers`
- Shared between client and server

### Sales Manager

**Location:** `Apps/Bloom/Bloom/Managers/SalesManager.swift`

#### Smart Polling Strategy

**Logic:**
1. Check if any cached sale's date window contains current date/time
2. **If YES (in sale window):** Fetch from API on every app foreground
3. **If NO (outside sale windows):** Only fetch if 3+ days since last fetch

**Why:** Allows quick disabling of problematic sales during active campaigns while being efficient when no sales are running

#### Core Methods

**`fetchActiveSales() async`**
- Make API call to `/v1/sales/active` (returns all active sales)
- Filter sales client-side by determining user's subscription status
- Update cached sales in UserDefaults
- Update last fetch timestamp

**`determineUserAudience() -> TargetAudience`**
- Check `EntitlementController.customerInfo` (RevenueCat)
- Logic:
  - If has active entitlement → `.subscribedUsers`
  - If has entitlement history but `isActive == false` → `.expiredUsers` (includes expired trials)
  - If no entitlement history → `.freeUsers`
- Return user's current audience segment

**`shouldShowSaleModal() -> SaleDetails?`**
- Check if any active sale should auto-present
- Criteria:
  - Sale is within date range
  - Sale's `targetAudience` is `.allUsers` OR matches user's determined audience
  - displayFrequencyDays has elapsed since last shown to this user
  - Sale not dismissed
- Return sale to present, or nil

**`shouldShowBannerInToday() -> SaleDetails?`**
- Check if should show banner in Today Insights
- Criteria:
  - Sale is within date range
  - Sale's `targetAudience` is `.allUsers` OR matches user's determined audience
  - Sale not dismissed by user
- Return sale to show, or nil

**`activeSaleForSettings() -> SaleDetails?`**
- Return active sale for Settings view (always visible, not dismissible)
- Filter by matching `targetAudience`

**`dismissSale(id: String)`**
- Mark sale as dismissed for Today Insights banner
- Still shows in Settings
- Doesn't prevent auto-modal per displayFrequencyDays

#### State Tracking

**Cached Data:**
- `cachedSales: [SaleDetails]` - Stored in UserDefaults as JSON
- `lastFetchDate: Date` - Last API fetch timestamp
- `lastShownTimestamps: [String: Date]` - Per-sale tracking of when modal last shown
- `dismissedSales: Set<String>` - Sale IDs dismissed from Today Insights

### Networking

**Location:** `Apps/Bloom/CoreNetwork/URLRequests/URLRequest+Endpoints.swift`

**Add:**
```swift
extension URLRequest {
  enum Sales {
    static func getActiveSales() async throws -> URLRequest
  }
}
```

**Response Type:** `SalesResponse`

### UI Components

**Location:** `Apps/Bloom/Bloom/UserInterface/Sales/`

#### SaleModalView
- **Pattern:** Full-screen modal using `CardView` as container
- **Layout:**
  - Hero image at top (from `imageURL`)
  - Title (large, bold)
  - Body text (description)
  - Product pricing section (see RevenueCat integration below)
  - Purchase button
  - Dismiss button (X)
- **Behavior:**
  - On appear: Log TelemetryDeck event with `sale.telemetryEventName`
  - On purchase: Use RevenueCat to purchase `saleProductId`
  - On dismiss: Close modal
- **RevenueCat Integration:**
  - Fetch package for `saleProductId`
  - If `compareProductId` exists:
    - Fetch compare package
    - Show original price with strikethrough (compare product price)
    - Show sale price (sale product price)
    - Calculate and display discount: `(comparePrice - salePrice) / comparePrice * 100%`
  - If no `compareProductId`:
    - Show sale product price normally
  - Display intro offers/free trials from sale product
  - Follow existing paywall patterns from `BloomPlusPaywall`

#### SaleBannerCard
- **Pattern:** Compact card for Today Insights feed
- **Layout:**
  - Image (aspect ratio preserving)
  - Title
  - Brief description
  - CTA button
  - Dismiss button (X icon, top-right)
- **Modifiers:**
  - Use `.cardContainer()` for proper styling
- **Behavior:**
  - On appear: Log TelemetryDeck event with `sale.telemetryEventName`
  - On tap: Present `SaleModalView` with sale details
  - On dismiss tap: Call `SalesManager.dismissSale(id:)`, remove from view

#### SaleSettingsRow
- **Pattern:** Settings row/cell
- **Display:** Shows active sale info (title, brief description)
- **Behavior:** Tap to present `SaleModalView`
- **Note:** Not dismissible in Settings (always visible during sale)

### Integration Points

#### RootView
**Location:** `Apps/Bloom/Bloom/UserInterface/RootView.swift`

**On Launch / Foreground:**
1. Call `SalesManager.fetchActiveSales()` (smart polling)
2. Check `shouldShowSaleModal()`
3. If sale returned, present `SaleModalView`
4. Respect `displayFrequencyDays` (don't show too frequently)

#### TodayView
**Location:** `Apps/Bloom/Bloom/UserInterface/Today/TodayView.swift`

**Integration:**
- Check `SalesManager.shouldShowBannerInToday()`
- If sale returned, insert `SaleBannerCard` into Today feed
- Position: After hero image, before habits section
- Use `.cardContainer()` and proper vertical spacing

#### SettingsView
**Location:** `Apps/Bloom/Bloom/UserInterface/Settings/SettingsView.swift`

**Integration:**
- Add "Special Offers" section
- Check `SalesManager.activeSaleForSettings()`
- If sale returned, show `SaleSettingsRow`
- Always visible during sale (not dismissible here)

### RevenueCat Integration

**Requirements:**
- Fetch offerings: `Purchases.shared.offerings()`
- Match `saleProductId` to get sale Package (required)
- If `compareProductId` exists, match to get compare Package (optional)
- Calculate discount: `(comparePrice - salePrice) / comparePrice * 100`
- Display intro offers from sale product (free trial, discounted periods)
- Purchase flow: Use `saleProductId` package, follow existing paywall patterns

**Error Handling:**
- If `saleProductId` not found in offerings: Show error state, don't show sale
- If `compareProductId` not found: Just show sale price without comparison

### Local Storage (UserDefaults)

**Keys in `UserDefaults.group`:**
- `SalesManager.cachedSales` - JSON encoded `[SaleDetails]`
- `SalesManager.lastFetchDate` - Date
- `SalesManager.lastShownTimestamps` - JSON encoded `[String: Date]`
- `SalesManager.dismissedSales` - JSON encoded `Set<String>`

---

## Testing Requirements

### Backend Testing
- CRUD operations via Postman/Insomnia
- `isActive` filtering (only return active sales)
- Date range filtering (only return sales within window)
- Image upload and S3 URL generation
- Validation: `saleProductId` and `telemetryEventName` required
- Note: Audience filtering tested on client, not backend

### Gardener Testing
- Create sales with various configurations
- Validation: Can't save without required fields
- Toggle `isActive` and verify
- Upload images and preview
- Test with and without `compareProductId`
- Error handling for network failures

### iOS Testing
- Smart polling logic:
  - Verify frequent checks during sale window
  - Verify 3-day checks outside sale windows
- Audience detection (free/subscribed/expired user classification)
- Modal auto-presentation with `displayFrequencyDays` respect
- Banner dismissal in Today Insights
- Settings always showing active sale
- RevenueCat product matching:
  - With `compareProductId`: verify discount calculation, strikethrough pricing
  - Without `compareProductId`: verify normal price display
- Purchase flow with `saleProductId`
- TelemetryDeck event logging on sale appearance

### End-to-End Testing
- Create sale in Gardener with both products → Verify correct display on iOS
- Create sale without `compareProductId` → Verify normal pricing on iOS
- Toggle `isActive` off in Gardener → Verify sale disappears on iOS after next fetch
- Test with different target audiences → Verify correct users see appropriate sales
- Test date boundaries (before start, during, after end)
- Test `displayFrequencyDays` (shouldn't show modal more frequently than configured)

---

## Key Design Decisions

### Naming Conventions
- **`SaleDetails`** for shared network model (NOT `SaleDTO` - reserved for SwiftData)
- **`SaleRecord`** for backend database model

### isActive Field
- **Purpose:** Manual on/off switch in Gardener
- **Use Cases:**
  - Create sales in "draft" mode (`isActive = false`)
  - Quickly disable problematic sales without deleting
  - Pause and resume sales as needed
  - Keep historical records of past campaigns

### Smart Polling Strategy
- **During sale window:** Check on every foreground (stay in sync with admin changes)
- **Outside sale window:** Check every 3 days (efficient, less API load)
- **Benefit:** Balance between real-time updates during active sales and efficiency

### Target Audiences
- **allUsers:** Everyone
- **freeUsers:** Users who never subscribed
- **subscribedUsers:** Currently have active subscription
- **expiredUsers:** Previously subscribed, now expired (includes expired free trials - re-engagement opportunity)

### Client-Side Audience Filtering
- **Architecture Decision:** Backend returns all active sales; iOS client filters by user's subscription status
- **Rationale:**
  - Client has real-time RevenueCat CustomerInfo data
  - Simpler backend (no need to sync subscription status from client to server)
  - No additional database fields or migrations needed
  - Client can instantly react to subscription changes without waiting for backend sync
- **Implementation:** SalesManager uses EntitlementController to determine user's audience, then filters sales locally

### displayFrequencyDays
- **Purpose:** Control how often auto-modal appears per user
- **Range:** 1-30 days
- **Example:** Value of 7 means modal won't auto-show more than once per week per user

### telemetryEventName
- **Purpose:** Custom TelemetryDeck event for tracking per-sale performance
- **Required:** Ensures every sale is tracked
- **When Logged:** When sale card appears (modal or banner)

### Product IDs
- **saleProductId** (required): The RevenueCat product being sold
- **compareProductId** (optional): Product to compare against for showing discount
- **Benefit:** Flexibility to show "50% OFF" with comparison or just sale price without

---

## Architecture Patterns to Follow

### Backend
- Model pattern: `FoodItemRecord.swift`
- Migration pattern: `FoodItemRecord+Migrations.swift`
- Controller pattern: `FoodController.swift`, `AdminFoodController.swift`
- Image storage: Existing S3 `ImageStorage` service

### Gardener
- Admin UI pattern: `FoodItemDetailView.swift` (split pane, form, shelf)
- ViewModel pattern: Observable with validation
- Networking: `NetworkStack.swift` admin endpoints

### iOS
- Paywall pattern: `BloomPlusPaywall.swift` (RevenueCat integration, purchase flow)
- Manager pattern: Singleton with UserDefaults caching
- Card UI: Use `.cardContainer()` modifier
- Scroll views: Use `BloomScrollView`
- ViewModels: `@Observable` with `@MainActor`
- Sheet presentation: `presentedSheet: AnyView?` pattern

---

## Success Metrics

### Implementation Success
- Backend endpoints functional and return correct filtered sales
- Gardener allows CRUD operations for sales
- iOS displays sales correctly with proper targeting
- Smart polling reduces API load while maintaining sync

### Business Success (to be tracked via TelemetryDeck)
- Sale impressions (modal, banner)
- Sale dismissals (banner)
- Conversion rate per sale (purchases initiated from sale)
- Target audience performance (which segments convert best)

---

## Future Enhancements (Out of Scope)

### Silent Push Notifications
- Send APNs silent push when admin changes sale
- Set refresh flag on client
- Immediate sync without waiting for foreground polling
- **Deferred:** Current smart polling is sufficient, can add later if needed

### Multi-Device Support
- Track which devices have seen sales
- Sync dismissals across devices
- **Current:** Per-device tracking is acceptable

### A/B Testing
- Multiple variants of same sale
- Random assignment
- Performance comparison
- **Current:** Manual testing sufficient

### Schedule Preview
- Preview in Gardener how sale will appear to users
- Live preview of RevenueCat pricing
- **Current:** Create test sale and view on device
