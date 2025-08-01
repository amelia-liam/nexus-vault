;; NexusVault - Advanced sBTC Yield Protocol (Fixed Version)
;;
;; A secure, efficient yield farming protocol for sBTC on Stacks blockchain.
;; Features time-locked deposits, dynamic rewards, and comprehensive position management.
;;
;; Key Improvements:
;; - Enhanced security with input validation and overflow protection
;; - Clearer error handling and descriptive error messages
;; - Optimized calculations with proper precision handling
;; - Better code organization and documentation
;; - Emergency functions for protocol safety
;; - More flexible reward mechanisms

;; TRAIT DEFINITIONS

(define-trait sbtc-token-trait (
  (transfer
    (uint principal principal)
    (response bool uint)
  )
  (get-balance
    (principal)
    (response uint uint)
  )
))

;; CONSTANTS AND CONFIGURATION

;; Contract governance
(define-constant CONTRACT_OWNER tx-sender)

;; Error codes with clear descriptions
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_STAKED (err u101))
(define-constant ERR_NO_POSITION_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_BELOW_MINIMUM_STAKE (err u104))
(define-constant ERR_POSITION_STILL_LOCKED (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_INVALID_CONTRACT (err u107))
(define-constant ERR_INVALID_LOCK_PERIOD (err u108))
(define-constant ERR_NO_REWARDS_AVAILABLE (err u109))
(define-constant ERR_TRANSFER_FAILED (err u110))
(define-constant ERR_PROTOCOL_PAUSED (err u111))
(define-constant ERR_CALCULATION_OVERFLOW (err u112))

;; Protocol parameters
(define-constant MIN_STAKE_AMOUNT u100000) ;; 0.001 sBTC (100,000 satoshis)
(define-constant BLOCKS_PER_YEAR u52560) ;; Approximate blocks per year on Stacks
(define-constant MIN_LOCK_PERIOD u2628) ;; ~1 month in blocks
(define-constant MAX_LOCK_PERIOD u262800) ;; ~5 years in blocks
(define-constant PRECISION_FACTOR u10000) ;; For percentage calculations (basis points)
(define-constant MAX_APR u10000) ;; 100% maximum APR
(define-constant DEFAULT_BASE_APR u500) ;; 5% default APR

;; STATE VARIABLES

(define-data-var total-value-locked uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var protocol-start-block uint u0)
(define-data-var sbtc-token-contract principal 'SP3DX3H4FEYZJZ586MFBS25ZW3HZDMEW92260R2PR.sbtc)
(define-data-var base-rewards-rate uint DEFAULT_BASE_APR)
(define-data-var protocol-paused bool false)
(define-data-var emergency-mode bool false)

;; DATA MAPS

;; Individual staking positions
(define-map user-positions
  principal
  {
    staked-amount: uint,
    start-block: uint,
    lock-period-blocks: uint,
    total-rewards-claimed: uint,
    last-claim-block: uint,
    lock-bonus-multiplier: uint,
  }
)

;; User lifetime statistics
(define-map user-statistics
  principal
  {
    lifetime-staked: uint,
    lifetime-rewards: uint,
    total-positions: uint,
    first-stake-block: uint,
  }
)

;; Protocol snapshots for analytics
(define-map daily-snapshots
  uint ;; block height
  {
    tvl: uint,
    active-positions: uint,
    rewards-distributed: uint,
  }
)

;; VALIDATION FUNCTIONS

(define-private (is-contract-owner (caller principal))
  (is-eq caller CONTRACT_OWNER)
)

(define-private (is-valid-sbtc-contract (contract principal))
  (is-eq contract (var-get sbtc-token-contract))
)

(define-private (is-protocol-active)
  (and
    (not (var-get protocol-paused))
    (not (var-get emergency-mode))
  )
)

(define-private (validate-amount (amount uint))
  (and
    (> amount u0)
    (>= amount MIN_STAKE_AMOUNT)
  )
)

(define-private (validate-lock-period (lock-blocks uint))
  (and
    (>= lock-blocks MIN_LOCK_PERIOD)
    (<= lock-blocks MAX_LOCK_PERIOD)
  )
)

;; CALCULATION FUNCTIONS

;; Helper function to get minimum of two values
(define-private (min-uint
    (a uint)
    (b uint)
  )
  (if (< a b)
    a
    b
  )
)

;; Calculate lock bonus multiplier based on lock period
(define-private (calculate-lock-bonus (lock-period uint))
  (let (
      (years-locked (/ lock-period BLOCKS_PER_YEAR))
      (bonus-rate (min-uint (* years-locked u100) u500)) ;; Max 5% bonus per year, capped at 25%
    )
    (+ PRECISION_FACTOR bonus-rate)
    ;; Return multiplier in basis points
  )
)

;; Calculate rewards with overflow protection
(define-private (calculate-position-rewards (position {
  staked-amount: uint,
  start-block: uint,
  lock-period-blocks: uint,
  total-rewards-claimed: uint,
  last-claim-block: uint,
  lock-bonus-multiplier: uint,
}))
  (let (
      (current-block stacks-block-height)
      (last-claim (get last-claim-block position))
      (blocks-eligible (if (> current-block last-claim)
        (- current-block last-claim)
        u0
      ))
      (stake-amount (get staked-amount position))
      (base-rate (var-get base-rewards-rate))
      (lock-multiplier (get lock-bonus-multiplier position))
    )
    (if (is-eq blocks-eligible u0)
      u0
      (let (
          ;; Calculate base rewards: (amount * rate * blocks) / (PRECISION_FACTOR * blocks_per_year)
          (base-numerator (* (* stake-amount base-rate) blocks-eligible))
          (base-denominator (* PRECISION_FACTOR BLOCKS_PER_YEAR))
          (base-rewards (/ base-numerator base-denominator))
          ;; Apply lock bonus: base_rewards * lock_multiplier / PRECISION_FACTOR
          (bonus-rewards (/ (* base-rewards lock-multiplier) PRECISION_FACTOR))
        )
        ;; Return total rewards with overflow check
        (if (< bonus-rewards (* stake-amount u2)) ;; Sanity check: rewards shouldn't exceed 2x stake
          bonus-rewards
          u0
        )
      )
    )
  )
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-user-position (user principal))
  (map-get? user-positions user)
)

(define-read-only (get-user-statistics (user principal))
  (map-get? user-statistics user)
)

(define-read-only (get-protocol-info)
  {
    tvl: (var-get total-value-locked),
    total-rewards: (var-get total-rewards-distributed),
    base-apr: (var-get base-rewards-rate),
    is-paused: (var-get protocol-paused),
    emergency-mode: (var-get emergency-mode),
    sbtc-contract: (var-get sbtc-token-contract),
  }
)

(define-read-only (get-available-rewards (user principal))
  (match (get-user-position user)
    position (ok (calculate-position-rewards position))
    ERR_NO_POSITION_FOUND
  )
)

(define-read-only (is-position-unlocked (user principal))
  (match (get-user-position user)
    position (let ((unlock-block (+ (get start-block position) (get lock-period-blocks position))))
      (>= stacks-block-height unlock-block)
    )
    false
  )
)

;; CORE STAKING FUNCTIONS

(define-public (create-position
    (sbtc-contract <sbtc-token-trait>)
    (amount uint)
    (lock-period-blocks uint)
  )
  (let (
      (user tx-sender)
      (current-block stacks-block-height)
      (lock-bonus (calculate-lock-bonus lock-period-blocks))
    )
    ;; Validations
    (asserts! (is-protocol-active) ERR_PROTOCOL_PAUSED)
    (asserts! (is-valid-sbtc-contract (contract-of sbtc-contract))
      ERR_INVALID_CONTRACT
    )
    (asserts! (validate-amount amount) ERR_BELOW_MINIMUM_STAKE)
    (asserts! (validate-lock-period lock-period-blocks) ERR_INVALID_LOCK_PERIOD)
    (asserts! (is-none (get-user-position user)) ERR_ALREADY_STAKED)
    ;; Transfer sBTC to contract
    (match (contract-call? sbtc-contract transfer amount user (as-contract tx-sender))
      success (begin
        ;; Create position
        (map-set user-positions user {
          staked-amount: amount,
          start-block: current-block,
          lock-period-blocks: lock-period-blocks,
          total-rewards-claimed: u0,
          last-claim-block: current-block,
          lock-bonus-multiplier: lock-bonus,
        })
        ;; Update user statistics
        (let ((existing-stats (default-to {
            lifetime-staked: u0,
            lifetime-rewards: u0,
            total-positions: u0,
            first-stake-block: current-block,
          }
            (get-user-statistics user)
          )))
          (map-set user-statistics user {
            lifetime-staked: (+ (get lifetime-staked existing-stats) amount),
            lifetime-rewards: (get lifetime-rewards existing-stats),
            total-positions: (+ (get total-positions existing-stats) u1),
            first-stake-block: (if (is-eq (get total-positions existing-stats) u0)
              current-block
              (get first-stake-block existing-stats)
            ),
          })
        )
        ;; Update protocol state
        (var-set total-value-locked (+ (var-get total-value-locked) amount))
        (ok amount)
      )
      error
      ERR_TRANSFER_FAILED
    )
  )
)

(define-public (claim-rewards (sbtc-contract <sbtc-token-trait>))
  (let (
      (user tx-sender)
      (position (unwrap! (get-user-position user) ERR_NO_POSITION_FOUND))
      (available-rewards (calculate-position-rewards position))
    )
    ;; Validations
    (asserts! (is-protocol-active) ERR_PROTOCOL_PAUSED)
    (asserts! (is-valid-sbtc-contract (contract-of sbtc-contract))
      ERR_INVALID_CONTRACT
    )
    (asserts! (> available-rewards u0) ERR_NO_REWARDS_AVAILABLE)
    ;; Transfer rewards to user
    (match (as-contract (contract-call? sbtc-contract transfer available-rewards
      (as-contract tx-sender) user
    ))
      success (begin
        ;; Update position
        (map-set user-positions user {
          staked-amount: (get staked-amount position),
          start-block: (get start-block position),
          lock-period-blocks: (get lock-period-blocks position),
          total-rewards-claimed: (+ (get total-rewards-claimed position) available-rewards),
          last-claim-block: stacks-block-height,
          lock-bonus-multiplier: (get lock-bonus-multiplier position),
        })
        ;; Update user statistics
        (let ((stats (unwrap! (get-user-statistics user) ERR_NO_POSITION_FOUND)))
          (map-set user-statistics user {
            lifetime-staked: (get lifetime-staked stats),
            lifetime-rewards: (+ (get lifetime-rewards stats) available-rewards),
            total-positions: (get total-positions stats),
            first-stake-block: (get first-stake-block stats),
          })
        )
        ;; Update protocol state
        (var-set total-rewards-distributed
          (+ (var-get total-rewards-distributed) available-rewards)
        )
        (ok available-rewards)
      )
      error
      ERR_TRANSFER_FAILED
    )
  )
)

(define-public (close-position (sbtc-contract <sbtc-token-trait>))
  (let (
      (user tx-sender)
      (position (unwrap! (get-user-position user) ERR_NO_POSITION_FOUND))
      (stake-amount (get staked-amount position))
      (available-rewards (calculate-position-rewards position))
    )
    ;; Validations
    (asserts! (is-valid-sbtc-contract (contract-of sbtc-contract))
      ERR_INVALID_CONTRACT
    )
    (asserts! (is-position-unlocked user) ERR_POSITION_STILL_LOCKED)
    ;; Claim any remaining rewards first if available
    (begin
      (if (> available-rewards u0)
        (begin
          (try! (claim-rewards sbtc-contract))
          true
        )
        true
      )
      ;; Return staked amount to user
      (match (as-contract (contract-call? sbtc-contract transfer stake-amount (as-contract tx-sender)
        user
      ))
        success (begin
          ;; Remove position
          (map-delete user-positions user)
          ;; Update protocol TVL
          (var-set total-value-locked
            (- (var-get total-value-locked) stake-amount)
          )
          (ok stake-amount)
        )
        error
        ERR_TRANSFER_FAILED
      )
    )
  )
)

;; ADMINISTRATIVE FUNCTIONS

(define-public (update-base-rewards-rate (new-rate uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (asserts! (<= new-rate MAX_APR) ERR_INVALID_AMOUNT)
    (var-set base-rewards-rate new-rate)
    (ok new-rate)
  )
)

(define-public (update-sbtc-contract (new-contract principal))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    ;; Additional validation to ensure the contract is valid
    (asserts! (not (is-eq new-contract (as-contract tx-sender)))
      ERR_INVALID_CONTRACT
    )
    (asserts! (is-standard new-contract) ERR_INVALID_CONTRACT)
    (var-set sbtc-token-contract new-contract)
    (ok new-contract)
  )
)

(define-public (pause-protocol (pause bool))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (var-set protocol-paused pause)
    (ok pause)
  )
)

(define-public (emergency-withdraw
    (sbtc-contract <sbtc-token-trait>)
    (recipient principal)
    (amount uint)
  )
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (asserts! (var-get emergency-mode) ERR_UNAUTHORIZED)
    ;; Additional validations for emergency withdrawal
    (asserts! (is-valid-sbtc-contract (contract-of sbtc-contract))
      ERR_INVALID_CONTRACT
    )
    (asserts! (is-standard recipient) ERR_INVALID_CONTRACT)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (as-contract (contract-call? sbtc-contract transfer amount (as-contract tx-sender)
      recipient
    ))
  )
)

(define-public (activate-emergency-mode)
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (var-set emergency-mode true)
    (var-set protocol-paused true)
    (ok true)
  )
)

;; INITIALIZATION

;; Initialize protocol start block
(var-set protocol-start-block stacks-block-height)
