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