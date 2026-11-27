# Home Services Marketplace --- UI/UX Product Plan

**Document purpose:** Product and UX blueprint for designing the
customer experience, service-provider experience, and admin operations
dashboard.

**Product type:** On-demand home-services marketplace\
**Initial service categories:** Maid/Cleaning, Cook, Electrical,
Plumbing, Painting\
**Initial payment model:** Customer pays the service provider in person
after the service. No online payment gateway in the initial release.

------------------------------------------------------------------------

## 1. Product vision

Build a home-services platform where customers can request trusted
professionals for services at their chosen address and time. Service
providers can receive, accept or reject work, while administrators can
oversee bookings and manually assign providers when needed.

The product has three user-facing surfaces:

1.  **Customer app** --- discover services, create bookings, follow
    provider search, manage bookings and review completed work.
2.  **Service-provider app** --- manage profile and service offerings,
    availability, location, booking offers and active jobs.
3.  **Admin web dashboard** --- manage customers, providers, service
    categories, bookings, provider assignment and operational
    exceptions.

The first release should focus on the complete booking lifecycle and
provider assignment. Avoid designing online payment flows, wallets,
commissions, subscriptions or complex promotions as part of the initial
scope.

## 2. User roles and permissions

### 2.1 Customer / Service receiver

Can: - Register, sign in and manage their profile. - Save multiple
service addresses. - Browse available service categories. - Select a
service, provide requirements and choose a date/time. - Create and
cancel eligible bookings. - Track booking status and provider
assignment. - Respond to the extended-search decision. - View provider
details after assignment. - View booking history. - Mark service
completion or raise an issue, according to the final business rules. -
Submit a rating and review after completion.

Cannot: - Select or change the assigned provider directly. - Change
booking status to confirmed, in progress or completed without the
permitted workflow. - View another customer's bookings or personal
information.

### 2.2 Service provider

Can: - Register and submit profile/verification information. - Manage
service categories they are qualified to provide. - Set service-specific
minimum prices or indicative rates, if enabled. - Set availability and
working hours. - Share/update current location while available. - Go
online or offline. - Receive booking offers for eligible services and
locations. - Accept or reject an offer before it expires. - View
assigned/upcoming jobs. - Update job progress through permitted
states. - Report an issue or request cancellation/reassignment. - View
completed job history and reviews.

Cannot: - Accept an expired offer. - Accept a booking that has already
been assigned to another provider. - Access customer information before
the offer/assignment stage permits it. - Change service price after
confirmation unless a separately approved quotation flow is introduced.

### 2.3 Admin / Operations

Can: - View operational dashboard and booking queue. - Search and filter
bookings by status, service, date, area and assignment mode. - View
customer, address and eligible-provider details according to
permissions. - Approve, suspend or deactivate providers. - Manage
service categories and provider-service eligibility. - Assign a provider
manually. - Send a booking offer to a selected provider. - Start or
switch a booking to broadcast assignment. - Monitor broadcast rounds and
provider responses. - Reassign a booking when an assignment fails. -
Cancel or expire bookings when permitted. - View assignment and status
history. - Manage customer support issues.

Admin actions should be recorded with the acting admin, timestamp and
reason where appropriate.

------------------------------------------------------------------------

## 3. Core product principles

1.  **One booking, one current provider.** A booking may be offered to
    many providers, but only one provider can hold the current
    assignment.
2.  **Offers are not assignments.** A provider receiving an offer has
    not yet been assigned.
3.  **Show clear progress.** Customers should understand whether the
    booking is awaiting review, searching, awaiting their decision,
    assigned or confirmed.
4.  **Never imply guaranteed availability.** Search radius and search
    duration are maximum discovery rules, not a guarantee that a
    provider will be found.
5.  **Prevent duplicate actions.** Disable or make actions idempotent
    while a request is processing.
6.  **Preserve history.** Provider offers, assignment attempts and admin
    decisions should remain auditable.
7.  **Be transparent about additional charges.** If extended search may
    incur extra travel charges, explain the possibility before the
    customer agrees. Do not silently add charges.
8.  **Design for failure states.** No provider found, provider
    rejection, offer expiry, customer timeout, provider cancellation and
    network failure are first-class UX states.

------------------------------------------------------------------------

## 4. Booking lifecycle

### 4.1 Proposed booking states

The exact state names and transition rules must be agreed with the
backend implementation. The UI should display friendly labels rather
than raw enum values.

  -----------------------------------------------------------------------
  Backend concept         Customer-facing label   Meaning
  ----------------------- ----------------------- -----------------------
  Pending admin review    Request received        Booking has been
                                                  created and is awaiting
                                                  operations review, if
                                                  this mode is enabled

  Searching provider      Finding a professional  Eligible providers are
                                                  being contacted

  Awaiting customer       No professional found   Customer must choose
  decision                nearby                  extended search or
                                                  cancellation

  Awaiting provider       Waiting for             An offer has been sent
  response                professional            to a provider

  Provider assigned       Professional found      A provider has
                                                  accepted; assignment is
                                                  being finalized

  Confirmed               Booking confirmed       Provider and booking
                                                  are confirmed

  In progress             Service in progress     Provider has started
                                                  the service

  Completed               Completed               Service has been marked
                                                  complete

  Cancelled               Cancelled               Booking has been
                                                  cancelled

  Expired                 Request expired         Customer did not
                                                  respond within the
                                                  decision window or the
                                                  request expired

  No provider available   No professional         Search ended without an
                          available               assignment (including
                                                  the customer's extended
                                                  search)
  -----------------------------------------------------------------------

Avoid exposing internal technical states such as `provider_assigned`
directly if a more understandable label is available.

### 4.2 Suggested lifecycle

1.  Customer chooses a service and submits a booking request.
2.  Booking is created and appears in the admin booking queue.
3.  Admin chooses one of:
    -   Manually offer the booking to one or more selected eligible
        providers. Each manual offer expires 10 minutes after it is
        sent. If every manual offer is rejected or expires, the booking
        returns to admin review so the admin can assign again or switch
        to broadcast.
    -   Start broadcast assignment.
4.  In broadcast mode the search runs in rounds:
    -   **Round 1:** search eligible, active providers within 10 km and
        send them offers. The round lasts up to 10 minutes.
    -   **Round 2:** if no provider accepts, expand to 20 km and send
        offers only to providers who have **not** already received an
        offer for this booking in an earlier round. The round lasts up
        to another 10 minutes.
    -   An offer expires at the same moment as the round it belongs to.
        When a round ends without an acceptance, its pending offers are
        expired and the round is closed.
    -   If every provider in a round rejects (or no provider is
        eligible), the round ends immediately instead of waiting for
        its deadline.
5.  If no provider is assigned after round 2, move the booking to
    "awaiting customer decision" and ask the customer to:
    -   Continue searching up to 50 km for a waiting time the customer
        chooses (minimum 10 minutes, maximum 2 hours), with a clear
        explanation that additional travel charges may apply; or
    -   Cancel the booking.
6.  Customer decision window is 30 minutes from when the decision is
    presented.
7.  If the customer does not respond within 30 minutes, expire the
    booking and notify them.
8.  If the customer chooses extended search, begin the 50 km search
    immediately. The extended search deadline is the moment of the
    decision plus the waiting time the customer chose. Offers go only
    to providers who have not already received an offer for this
    booking, and they expire at that same deadline. This extra search
    happens **once**: the customer is not asked again. If nobody
    accepts by the deadline (or nobody is eligible), the booking ends as
    "no provider available".
9.  When a provider accepts, atomically assign that provider and stop
    further discovery/offers: the search round is completed and the
    booking's other pending offers are closed.
10. Provider and customer receive confirmation.
11. Provider progresses the job through the permitted service states.
12. Booking is completed. Customer pays the provider in person.

**Important UX distinction:** The 10-minute and 20-minute periods are
search-round limits, and every offer in a round expires together with
that round. The UI should show providers the actual offer expiry (the
round deadline) as a countdown.

### 4.2.1 Timers and automatic transitions

Every deadline below is enforced by a scheduled background job. A job
re-checks the booking's current state when it runs and does nothing if
the booking has already moved on (accepted, rejected, cancelled or
decided), so a job never needs to be cancelled.

| Timer | Starts when | Length | If nobody has acted |
|---|---|---|---|
| Manual offer | Admin sends the offer | 10 minutes | Offer expires; if no pending offers remain, booking returns to admin review |
| Search round 1 (10 km) | Admin starts broadcast | 10 minutes | Offers expire, round closes, round 2 opens |
| Search round 2 (20 km) | Round 1 ends | 10 minutes | Offers expire, round closes, customer is asked to decide |
| Customer decision | Customer is asked | 30 minutes | Booking expires ("Request expired") |
| Extended search (50 km) | Customer chooses to keep searching | Waiting time chosen by the customer (10 minutes to 2 hours) | Offers expire, round closes, booking becomes "no provider available" |

If a round has no eligible provider, it is skipped immediately instead
of waiting for its timer. If even the first broadcast finds nobody, the
admin sees an error and the booking stays in admin review.

### 4.3 Customer decision screen

Suggested copy:

**We couldn't find a professional nearby**

"We couldn't find an available professional within 20 km right now."

Primary option: - **Keep searching** - Time selector: "How long should
we keep searching?" (minimum 10 minutes, maximum 2 hours). - Supporting
text: "We'll expand the search up to 50 km for the time you choose. A
professional may be farther away and additional travel charges may
apply. Any extra charge will be explained before you confirm the
service."

Secondary option: - **Cancel booking**

Show a visible 30-minute response deadline. Do not use vague copy such
as "wait for some time."

If the customer chooses to continue, show: - Search extended. - Maximum
search area: up to 50 km. - Search time: the time the customer chose
(up to 2 hours), with the exact end time shown. - Any confirmed extra
travel charge or the fact that it will be discussed before confirmation.
The customer is not asked to decide a second time: if nobody accepts
by that end time, show "No professional available".

If the customer does not respond: - Show that the request expired. -
Explain that no provider was assigned. - Offer a clear path to create a
new booking.

------------------------------------------------------------------------

## 5. Customer app --- screen inventory

### 5.1 Onboarding and account

-   Splash / launch.
-   Welcome and service-area introduction.
-   Phone number entry.
-   OTP verification.
-   Basic profile setup.
-   Permission explanations for location and notifications.
-   Sign in / sign out.

Location permission should be requested when it provides clear value.
Customers must also be able to enter or select an address manually.

### 5.2 Home

Primary elements: - Greeting and selected service address. - Search
services. - Service category cards: - Cleaning / Maid - Cook -
Electrical - Plumbing - Painting - Popular or frequently booked
services. - Active booking card, when one exists. - Recent bookings. -
Help/support entry point.

The home screen should prioritize booking a service over promotional
content.

### 5.3 Service discovery and details

Screens: - Service category listing. - Service detail. - Service
description and what is included. - Service-specific questions or
requirements. - Indicative pricing or "price confirmed after assessment"
where applicable. - Duration estimate, if known. - Service-area
availability information.

Service-specific forms should be configurable rather than creating
completely separate booking flows for every category.

Examples: - Cleaning: home size, number of rooms, cleaning type,
preferred duration. - Cook: meal type, number of people, one-time or
recurring requirement. - Electrical: issue type, appliance or wiring
details, photos if useful. - Plumbing: issue type, urgency, photos if
useful. - Painting: approximate area, number of rooms,
interior/exterior, inspection or quotation requirement.

Do not force a fixed price where the business has not defined one.

### 5.4 Address selection

-   Saved address list.
-   Add address.
-   Map pin selection.
-   Manual address entry.
-   Address label: Home, Work, Other.
-   Confirm service location.

Display the selected service address clearly before booking submission.

### 5.5 Booking creation

Suggested steps: 1. Select service. 2. Answer service-specific
questions. 3. Select service address. 4. Select date and time. 5. Review
booking details. 6. Submit booking.

Review screen should show: - Service requested. - Address. -
Date/time. - Requirements. - Indicative price or quotation note. -
Payment method note: "Pay the professional in person after the
service." - Cancellation/support information.

### 5.6 Booking tracking

A dedicated booking detail/tracking screen should show: - Booking
reference. - Service and scheduled time. - Current status with
plain-language explanation. - Timeline of important events. - Search
radius/current search stage when relevant. - Whether the request is
being handled manually or by broadcast, if useful to the customer. -
Cancel action when permitted. - Contact/support entry point.

During broadcast search, show progress without suggesting that the
system is searching every second if it is actually processing scheduled
rounds.

Example: - "Searching within 10 km" - "Expanding search to 20 km" -
"Waiting for your decision" - "Searching a wider area"

Do not show provider personal details before an offer is accepted and
assignment is finalized.

### 5.7 Provider found / booking confirmed

Show: - Provider name and profile photo. - Verified status, if
verified. - Rating and completed jobs, once those metrics exist. -
Service category. - Expected arrival time, only if reliably
calculated. - Contact options according to privacy policy. - Booking
date/time and address. - Cancellation/support action where allowed.

### 5.8 Active service

Show: - Provider details. - Booking summary. - Status: confirmed / in
progress. - Help or report issue. - Completion confirmation flow.

Payment note: - "Payment is made directly to the professional in
person." - Do not show online checkout, wallet, card entry or payment
gateway screens in this release.

### 5.9 Completion and history

-   Completion summary.
-   Rating and review.
-   Report a problem.
-   Past bookings list.
-   Booking detail and status history.
-   Rebook action.

------------------------------------------------------------------------

## 6. Service-provider app --- screen inventory

### 6.1 Onboarding and verification

-   Phone sign-in / OTP.
-   Personal details.
-   Profile photo.
-   Identity and verification document upload, if required.
-   Service categories offered.
-   Experience and skills.
-   Service-specific pricing information.
-   Address / service area.
-   Verification status screen.

### 6.2 Provider home

-   Online / offline toggle.
-   Current availability.
-   Today's jobs.
-   Pending offers count.
-   Earnings summary only if the business chooses to show it; no in-app
    payment collection is required initially.
-   Profile completion and verification status.

Clearly explain that going online means the provider may receive
eligible booking offers. Do not imply that going online guarantees work.

### 6.3 Availability and location

-   Working days.
-   Working hours.
-   Breaks / unavailable periods.
-   Upcoming commitments.
-   Current location permission/status.
-   Last location update.
-   Online/offline status.

A provider should not receive an offer if they are inactive, not
qualified for the requested service, outside the permitted search
radius, or unavailable for the requested time.

### 6.4 Booking offer screen

Every offer should show enough information for the provider to make a
decision: - Service category and task description. - Approximate
distance. - Requested date and time. - Estimated duration. - Indicative
price or quotation requirement. - Relevant customer notes/photos. -
Offer expiry countdown. - Accept and Reject actions.

Do not expose more customer personal information than necessary before
acceptance.

After the offer expires, disable both actions and show "Offer expired."

### 6.5 Assigned jobs

-   Upcoming jobs.
-   Job detail.
-   Customer/service address details after assignment.
-   Navigation action.
-   Contact customer, subject to policy.
-   Start service.
-   Mark completed.
-   Report issue / request cancellation.

Prevent invalid transitions in the UI, but always enforce them on the
backend too.

### 6.6 Provider history and profile

-   Completed jobs.
-   Rejected/expired offer history, where useful.
-   Ratings and reviews.
-   Service categories and pricing.
-   Availability settings.
-   Verification/profile status.

------------------------------------------------------------------------

## 7. Admin web dashboard --- screen inventory

The admin dashboard is an operational control center, not simply another
customer app.

### 7.1 Dashboard overview

KPI cards: - New bookings. - Awaiting admin review. - Searching for
providers. - Awaiting customer decision. - Awaiting provider response. -
Confirmed bookings. - In-progress bookings. - Unassigned / expired
bookings.

Charts and summaries can be added later. Prioritize actionable queues.

### 7.2 Booking management

Booking list with: - Booking ID. - Customer. - Service category. -
Service location / area. - Scheduled date/time. - Booking status. -
Assignment mode. - Current provider. - Created time.

Filters: - Status. - Service category. - Date range. - Area / postal
code. - Manual or broadcast. - Assigned / unassigned.

Booking detail should include: - Customer and service details. - Address
and map location. - Booking status timeline. - Search rounds. - Provider
offers and responses. - Current assignment. - Admin action history.

### 7.3 Manual provider assignment

Admin flow: 1. Open an unassigned booking. 2. View eligible providers.
3. Filter by service qualification, active status, availability and
distance. 4. Inspect provider profile and relevant information. 5.
Select provider. 6. Send offer. 7. See pending / accepted / rejected /
expired response. 8. If rejected or expired, select another provider or
switch to broadcast.

The UI must distinguish: - **Offer sent** --- provider has been
invited. - **Accepted** --- provider accepted the offer. - **Assigned**
--- backend successfully reserved the booking for that provider. -
**Confirmed** --- booking has reached its confirmed state.

### 7.4 Broadcast assignment

Admin flow: 1. Select broadcast mode. 2. View the initial 10 km search
area and eligible-provider count. 3. Start broadcast. 4. Monitor offers
and responses. 5. See the 10-minute round deadline. 6. If unsuccessful,
start/observe the 20 km round according to the configured automatic
policy (offers go only to providers not already offered this booking).
7. If still unsuccessful, see the customer-decision state (30-minute
window). 8. After customer consent, monitor the 50 km extended search,
which ends at the waiting time the customer chose. 9. Stop search
immediately after a valid assignment or cancellation.

Admin should be able to see: - Radius. - Search-round start and
deadline. - Number of eligible providers. - Number of offers sent. -
Accepted / rejected / expired / pending counts. - Providers excluded and
reason, where operationally appropriate.

### 7.5 Provider management

-   Provider list.
-   Verification queue.
-   Provider detail.
-   Service categories offered.
-   Active/inactive/suspended status.
-   Current location freshness.
-   Availability.
-   Upcoming assignments.
-   Offer response history.
-   Reviews and support history.

### 7.6 Service category management

-   Create/edit/deactivate service categories.
-   Service description and images.
-   Required booking questions.
-   Indicative price configuration, if applicable.
-   Default duration, if applicable.
-   Assignment/search policy configuration, if enabled.

### 7.7 Operational exceptions

Dedicated queues for: - No provider found. - Customer decision
pending. - Customer decision expired. - Provider rejected. - Provider
offer expired. - Provider cancelled after accepting. - Booking needs
reassignment. - Booking stuck in an unexpected state.

Admin actions that change assignment or booking status should require
confirmation and capture a reason where appropriate.

------------------------------------------------------------------------

## 8. Important UX states and edge cases

Design these states deliberately. Do not design only the happy path.

### Customer states

-   Booking submission loading.
-   Booking submitted.
-   Admin review pending.
-   Searching within 10 km.
-   Searching within 20 km.
-   No provider found; decision required.
-   Extended search accepted.
-   Extended search in progress.
-   Decision deadline approaching.
-   Decision expired after 30 minutes.
-   Provider found.
-   Booking confirmed.
-   Booking cancelled.
-   Booking expired.
-   Network disconnected / status refresh failed.
-   Provider cancelled; reassignment in progress.

### Provider states

-   Offline.
-   Online and available.
-   Offer received.
-   Offer nearly expired.
-   Offer accepted.
-   Offer rejected.
-   Offer expired.
-   Booking assigned.
-   Booking cancelled or reassigned.
-   Provider unavailable / suspended.
-   Location permission disabled or stale.

### Admin states

-   No eligible providers.
-   Providers found but none responded.
-   All offers rejected.
-   Offers pending.
-   Provider accepted but assignment conflict occurred.
-   Booking assigned.
-   Provider cancelled and reassignment required.
-   Customer decision pending.
-   Customer decision expired.
-   Background search/job failed and requires retry or intervention.

### Concurrency and consistency expectations

The UI should be designed around these backend guarantees: - Only one
provider can become the current assignee. - Multiple simultaneous accept
taps must not create multiple assignments. - Expired offers cannot be
accepted. - A cancelled/expired booking cannot continue broadcasting. -
Old background search rounds must not restart or modify a booking that
has already advanced. - Reassignment must preserve previous
offer/assignment history.

------------------------------------------------------------------------

## 9. Navigation and information architecture

### Customer app bottom navigation

Recommended: - Home - My Bookings - Help - Profile

The booking flow itself should be a focused sequence rather than a
permanent bottom-navigation section.

### Provider app bottom navigation

Recommended: - Home - Offers - Jobs - Profile

Availability should be prominently accessible from Home.

### Admin web navigation

Recommended sidebar: - Overview - Bookings - Assignment Operations -
Providers - Customers - Services - Support / Issues - Reports - Settings

Use role-based access for sensitive admin capabilities.

------------------------------------------------------------------------

## 10. Design system direction

The final visual style can be chosen by the design team. Recommended
product qualities:

-   Trustworthy and professional.
-   Clean, calm and easy to scan.
-   Clear hierarchy for booking status and primary actions.
-   Strong accessibility and readable typography.
-   Consistent spacing, components and interaction patterns.
-   Mobile-first customer/provider experiences.
-   Information-dense but organized admin dashboard.

### Suggested visual semantics

Use consistent status colors, but always pair color with text/icon so
status is not communicated by color alone.

  Meaning                          Suggested treatment
  -------------------------------- ---------------------------------
  Pending / waiting                Neutral or amber
  Searching                        Blue / informational
  Confirmed / completed            Green
  Rejected / cancelled / expired   Red or muted destructive
  Needs customer action            Prominent amber or blue callout

Component inventory: - Buttons: primary, secondary, destructive, text. -
Status badges. - Booking cards. - Provider cards. - Service category
cards. - Address selector. - Date/time picker. - Search progress
timeline. - Offer countdown. - Empty states. - Confirmation dialogs. -
Bottom sheets on mobile. - Tables, filters and detail panels on admin
web. - Toasts and inline error messages. - Loading skeletons.

Do not rely on countdown animations alone. Always show the actual
deadline or remaining time in readable text.

------------------------------------------------------------------------

## 11. Content and copy guidelines

Prefer simple, human language.

Examples:

  -----------------------------------------------------------------------
  Avoid                               Prefer
  ----------------------------------- -----------------------------------
  Provider discovery initiated        Finding a professional

  Assignment failed                   We couldn't assign a professional
                                      yet

  Radius expansion                    Searching a wider area

  Offer expired                       This request is no longer available

  Booking status: 3                   Booking confirmed

  No eligible provider records        No available professionals found
                                      nearby
  -----------------------------------------------------------------------

For additional charges, be explicit: - Explain why an extra charge may
apply. - Show the amount if known. - If not yet known, explain when and
how it will be confirmed. - Require customer agreement before applying a
charge.

------------------------------------------------------------------------

## 12. MVP scope and what to defer

### Include in the first UI/UX release

**Customer** - Authentication. - Service browsing. - Service-specific
booking form. - Address management. - Date/time selection. - Booking
creation. - Booking tracking. - Extended-search choice. -
Cancellation. - Provider details after assignment. - Completion and
booking history.

**Provider** - Authentication and onboarding. - Profile and service
categories. - Availability and online/offline. - Booking offers. -
Accept/reject. - Assigned jobs. - Start/complete service. - Job history.

**Admin** - Dashboard and booking queue. - Booking detail. - Manual
assignment. - Broadcast assignment. - Search-round monitoring. -
Provider management. - Customer-decision monitoring. - Reassignment and
cancellation controls. - Admin action history.

### Defer until later

-   Online payment gateway.
-   Wallet and provider payouts.
-   Coupons, loyalty and subscriptions.
-   Complex referral programs.
-   In-app chat.
-   Advanced dynamic pricing.
-   Automated route optimization.
-   Advanced analytics and forecasting.
-   Multi-city expansion tooling.
-   Complex recurring-service management, unless it is required for the
    initial Cook/Cleaning launch.

------------------------------------------------------------------------

## 13. UX deliverables to create

Before implementation, produce:

1.  User-flow diagrams for customer, provider and admin.
2.  Low-fidelity wireframes for all core screens.
3.  High-fidelity designs for the booking and assignment journeys.
4.  Clickable prototype for:
    -   Customer creates booking and tracks search.
    -   Customer chooses extended search or cancellation.
    -   Provider receives and accepts an offer.
    -   Admin manually assigns a provider.
    -   Admin starts and monitors broadcast assignment.
5.  Component library and design tokens.
6.  Empty, loading, error, expired and success states.
7.  Responsive admin dashboard designs.
8.  Handoff notes describing each action, validation rule and state
    transition.

------------------------------------------------------------------------

## 14. Open product decisions --- confirm before final UI

These decisions affect both UX and backend behavior:

1.  **Admin review:** Does every booking wait for admin review, or can
    the system begin broadcast automatically?
2.  **Manual offer expiry:** *Decided: 10 minutes.*
3.  **Broadcast offer expiry:** *Decided: an offer expires together with
    its search round (10 minutes for rounds 1 and 2; the customer's
    chosen waiting time for the extended search).*
4.  **Broadcast concurrency:** *Decided: all eligible providers in a
    round receive their offers at once. Later rounds only add providers
    who have not already been offered the booking.*
5.  **Provider acceptance:** Does acceptance immediately confirm the
    booking, or does admin/customer confirmation remain necessary?
6.  **Customer timeout:** *Decided: at 30 minutes without a decision the
    booking becomes `expired`. UI label: "Request expired."*
7.  **Extended-search charge:** Is the extra travel charge fixed,
    estimated, or agreed with the provider/customer before confirmation?
8.  **Provider cancellation:** Can a provider cancel after accepting?
    What reassignment flow follows?
9.  **Scheduled jobs:** Can providers accept future bookings while
    currently working, provided their schedules do not overlap?
10. **Service-specific pricing:** Which categories use fixed pricing,
    hourly pricing or inspection/quotation?

Do not invent final answers for these in the UI. Use clearly marked
assumptions in the prototype until product/operations confirms them.

------------------------------------------------------------------------

## 15. Recommended design order

Design in this order to validate the most important product flows early:

1.  **Admin booking operations** --- establishes how bookings enter the
    system and how assignment is controlled.
2.  **Customer booking creation and tracking** --- validates the
    customer journey and decision points.
3.  **Provider offer and job flow** --- validates the acceptance and
    service lifecycle.
4.  **Admin provider management** --- supports eligibility and manual
    assignment.
5.  **Edge cases and exception states** --- validates operational
    reliability.
6.  **Visual polish and component system** --- apply consistent styling
    after the flows are agreed.

**Primary success criterion:** A customer can request a service, the
system/admin can find and assign one eligible provider, both parties can
follow the booking lifecycle, and the booking can be completed or safely
cancelled --- with clear handling when no provider is available.
