(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_COMMUNITY_NOT_FOUND (err u103))
(define-constant ERR_MINING_OPERATION_NOT_FOUND (err u104))
(define-constant ERR_INVALID_PERCENTAGE (err u105))
(define-constant ERR_ALREADY_EXISTS (err u106))

(define-data-var contract-balance uint u0)
(define-data-var total-mining-operations uint u0)
(define-data-var total-communities uint u0)
(define-data-var contract-paused bool false)

(define-map communities
  {community-id: uint}
  {
    name: (string-ascii 50),
    wallet: principal,
    royalty-percentage: uint,
    total-received: uint,
    is-active: bool
  }
)

(define-map mining-operations
  {operation-id: uint}
  {
    operator: principal,
    location: (string-ascii 100),
    production-value: uint,
    community-id: uint,
    timestamp: uint,
    royalty-paid: uint
  }
)

(define-map community-payouts
  {community-id: uint, payout-id: uint}
  {
    amount: uint,
    timestamp: uint,
    operation-id: uint
  }
)

(define-map community-payout-counts
  {community-id: uint}
  {count: uint}
)

(define-public (register-community (name (string-ascii 50)) (wallet principal) (royalty-percentage uint))
  (let ((community-id (+ (var-get total-communities) u1)))
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (>= royalty-percentage u1) (<= royalty-percentage u100)) ERR_INVALID_PERCENTAGE)
    (asserts! (is-none (map-get? communities {community-id: community-id})) ERR_ALREADY_EXISTS)
    
    (map-set communities
      {community-id: community-id}
      {
        name: name,
        wallet: wallet,
        royalty-percentage: royalty-percentage,
        total-received: u0,
        is-active: true
      }
    )
    (var-set total-communities community-id)
    (ok community-id)
  )
)

(define-public (log-mining-production (location (string-ascii 100)) (production-value uint) (community-id uint))
  (let (
    (operation-id (+ (var-get total-mining-operations) u1))
    (community-data (unwrap! (map-get? communities {community-id: community-id}) ERR_COMMUNITY_NOT_FOUND))
    (royalty-amount (/ (* production-value (get royalty-percentage community-data)) u100))
  )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (> production-value u0) ERR_INVALID_AMOUNT)
    (asserts! (get is-active community-data) ERR_COMMUNITY_NOT_FOUND)
    
    (map-set mining-operations
      {operation-id: operation-id}
      {
        operator: tx-sender,
        location: location,
        production-value: production-value,
        community-id: community-id,
        timestamp: stacks-block-height,
        royalty-paid: royalty-amount
      }
    )
    
    (var-set total-mining-operations operation-id)
    (var-set contract-balance (+ (var-get contract-balance) royalty-amount))
    
    (try! (distribute-royalty community-id royalty-amount operation-id))
    (ok operation-id)
  )
)

(define-private (distribute-royalty (community-id uint) (amount uint) (operation-id uint))
  (let (
    (community-data (unwrap! (map-get? communities {community-id: community-id}) ERR_COMMUNITY_NOT_FOUND))
    (current-count (default-to {count: u0} (map-get? community-payout-counts {community-id: community-id})))
    (payout-id (+ (get count current-count) u1))
  )
    (asserts! (>= (var-get contract-balance) amount) ERR_INSUFFICIENT_FUNDS)
    
    (try! (stx-transfer? amount (as-contract tx-sender) (get wallet community-data)))
    
    (map-set community-payouts
      {community-id: community-id, payout-id: payout-id}
      {
        amount: amount,
        timestamp: stacks-block-height,
        operation-id: operation-id
      }
    )
    
    (map-set community-payout-counts
      {community-id: community-id}
      {count: payout-id}
    )
    
    (map-set communities
      {community-id: community-id}
      (merge community-data {total-received: (+ (get total-received community-data) amount)})
    )
    
    (var-set contract-balance (- (var-get contract-balance) amount))
    (ok amount)
  )
)

(define-public (fund-contract)
  (let ((amount (stx-get-balance tx-sender)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok amount)
  )
)

(define-public (deactivate-community (community-id uint))
  (let ((community-data (unwrap! (map-get? communities {community-id: community-id}) ERR_COMMUNITY_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set communities
      {community-id: community-id}
      (merge community-data {is-active: false})
    )
    (ok true)
  )
)

(define-public (update-royalty-percentage (community-id uint) (new-percentage uint))
  (let ((community-data (unwrap! (map-get? communities {community-id: community-id}) ERR_COMMUNITY_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (>= new-percentage u1) (<= new-percentage u100)) ERR_INVALID_PERCENTAGE)
    (map-set communities
      {community-id: community-id}
      (merge community-data {royalty-percentage: new-percentage})
    )
    (ok new-percentage)
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-read-only (get-community (community-id uint))
  (map-get? communities {community-id: community-id})
)

(define-read-only (get-mining-operation (operation-id uint))
  (map-get? mining-operations {operation-id: operation-id})
)

(define-read-only (get-community-payout (community-id uint) (payout-id uint))
  (map-get? community-payouts {community-id: community-id, payout-id: payout-id})
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

(define-read-only (get-total-communities)
  (var-get total-communities)
)

(define-read-only (get-total-mining-operations)
  (var-get total-mining-operations)
)

(define-read-only (get-community-payout-count (community-id uint))
  (get count (default-to {count: u0} (map-get? community-payout-counts {community-id: community-id})))
)

(define-read-only (calculate-royalty (production-value uint) (royalty-percentage uint))
  (/ (* production-value royalty-percentage) u100)
)

(define-read-only (get-community-total-received (community-id uint))
  (match (map-get? communities {community-id: community-id})
    community-data (some (get total-received community-data))
    none
  )
)

(define-read-only (get-operation-royalty (operation-id uint))
  (match (map-get? mining-operations {operation-id: operation-id})
    operation-data (some (get royalty-paid operation-data))
    none
  )
)

(define-read-only (is-community-active (community-id uint))
  (match (map-get? communities {community-id: community-id})
    community-data (get is-active community-data)
    false
  )
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)
