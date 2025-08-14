;; Carbon Credits Smart Contract

(define-data-var admin principal tx-sender)

(define-map balances
  { owner: principal }
  uint
)

(define-map total-issued
  { user: principal }
  uint
)

(define-data-var total-supply uint u0)
(define-data-var total-retired uint u0)

;; Verifiers who can mint carbon credits
(define-map approved-verifiers
  principal  ;; Fixed: removed parentheses
  bool
)

;; Carbon credit metadata
(define-map credit-metadata
  uint ;; credit-id
  {
    issuer: principal,
    project-name: (string-ascii 100),
    vintage-year: uint,
    methodology: (string-ascii 50),
    amount: uint,
    retired: bool
  }
)

(define-data-var next-credit-id uint u0)

;; Events for tracking
(define-map transfer-events
  uint ;; event-id
  {
    from: principal,
    to: principal,
    amount: uint,
    block-height: uint
  }
)

(define-data-var next-event-id uint u0)

;; ========== ADMIN FUNCTIONS ==========

;; ADMIN adds a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u401))
    (map-set approved-verifiers verifier true)
    (ok true)
  )
)

;; ADMIN removes a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u401))
    (map-delete approved-verifiers verifier)
    (ok true)
  )
)

;; ADMIN can change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u401))
    (var-set admin new-admin)
    (ok true)
  )
)

;; ========== VERIFIER FUNCTIONS ==========

;; MINT carbon credits (only verifiers)
(define-public (mint (to principal) (amount uint) (project-name (string-ascii 100)) (vintage-year uint) (methodology (string-ascii 50)))
  (let ((credit-id (var-get next-credit-id)))
    (begin
      (asserts! (default-to false (map-get? approved-verifiers tx-sender)) (err u402))
      (asserts! (> amount u0) (err u405))
      
      ;; Update balances
      (map-set balances { owner: to } (+ (default-to u0 (map-get? balances { owner: to })) amount))
      (map-set total-issued { user: to } (+ (default-to u0 (map-get? total-issued { user: to })) amount))
      
      ;; Update supply
      (var-set total-supply (+ (var-get total-supply) amount))
      
      ;; Store credit metadata
      (map-set credit-metadata credit-id {
        issuer: tx-sender,
        project-name: project-name,
        vintage-year: vintage-year,
        methodology: methodology,
        amount: amount,
        retired: false
      })
      
      ;; Increment credit ID
      (var-set next-credit-id (+ credit-id u1))
      
      (ok credit-id)
    )
  )
)

;; ========== USER FUNCTIONS ==========

;; TRANSFER carbon credits
(define-public (transfer (to principal) (amount uint))
  (let (
    (sender-balance (default-to u0 (map-get? balances { owner: tx-sender })))
    (event-id (var-get next-event-id))
  )
    (begin
      (asserts! (>= sender-balance amount) (err u403))
      (asserts! (> amount u0) (err u405))
      (asserts! (not (is-eq tx-sender to)) (err u406))
      
      ;; Update balances
      (map-set balances { owner: tx-sender } (- sender-balance amount))
      (map-set balances { owner: to } (+ (default-to u0 (map-get? balances { owner: to })) amount))
      
      ;; Log transfer event
      (map-set transfer-events event-id {
        from: tx-sender,
        to: to,
        amount: amount,
        block-height: stacks-block-height
      })
      (var-set next-event-id (+ event-id u1))
      
      (ok true)
    )
  )
)

;; RETIRE (burn) carbon credits to offset emissions
(define-public (retire (amount uint))
  (let ((balance (default-to u0 (map-get? balances { owner: tx-sender }))))
    (begin
      (asserts! (>= balance amount) (err u404))
      (asserts! (> amount u0) (err u405))
      
      ;; Update balance and totals
      (map-set balances { owner: tx-sender } (- balance amount))
      (var-set total-retired (+ (var-get total-retired) amount))
      (var-set total-supply (- (var-get total-supply) amount))
      
      (ok true)
    )
  )
)

;; Batch transfer function
(define-public (batch-transfer (recipients (list 10 { to: principal, amount: uint })))
  (let ((sender-balance (default-to u0 (map-get? balances { owner: tx-sender }))))
    (begin
      (asserts! (>= sender-balance (fold + (map get-amount recipients) u0)) (err u403))
      (map process-transfer recipients)
      (ok true)
    )
  )
)

;; Helper function for batch transfer
(define-private (process-transfer (recipient { to: principal, amount: uint }))
  (let (
    (to (get to recipient))
    (amount (get amount recipient))
  )
    (begin
      (map-set balances { owner: tx-sender } 
        (- (default-to u0 (map-get? balances { owner: tx-sender })) amount))
      (map-set balances { owner: to } 
        (+ (default-to u0 (map-get? balances { owner: to })) amount))
      true
    )
  )
)

(define-private (get-amount (recipient { to: principal, amount: uint }))
  (get amount recipient)
)

;; ========== READ-ONLY FUNCTIONS ==========

;; Check balance
(define-read-only (get-balance (who principal))
  (ok (default-to u0 (map-get? balances { owner: who })))
)

;; Get total issued by user
(define-read-only (get-total-issued (user principal))
  (ok (default-to u0 (map-get? total-issued { user: user })))
)

;; Get total supply and retired
(define-read-only (get-stats)
  (ok {
    supply: (var-get total-supply),
    retired: (var-get total-retired),
    net-credits: (- (var-get total-supply) (var-get total-retired))
  })
)

;; Check if verifier is approved
(define-read-only (is-approved-verifier (verifier principal))
  (ok (default-to false (map-get? approved-verifiers verifier)))
)

;; Get credit metadata
(define-read-only (get-credit-info (credit-id uint))
  (ok (map-get? credit-metadata credit-id))
)

;; Get admin
(define-read-only (get-admin)
  (ok (var-get admin))
)

;; Get transfer event
(define-read-only (get-transfer-event (event-id uint))
  (ok (map-get? transfer-events event-id))
)

;; Get contract info
(define-read-only (get-contract-info)
  (ok {
    name: "Carbon Credits Token",
    version: "1.0.0",
    admin: (var-get admin),
    total-supply: (var-get total-supply),
    total-retired: (var-get total-retired),
    next-credit-id: (var-get next-credit-id)
  })
)
