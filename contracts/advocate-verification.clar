;; Advocate Verification Contract
;; Validates quantum justice advocates and manages their credentials

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))

;; Data structures
(define-map advocates
  { advocate: principal }
  {
    verified: bool,
    verification-date: uint,
    specialization: (string-ascii 50),
    reputation-score: uint
  }
)

(define-map verification-requests
  { request-id: uint }
  {
    advocate: principal,
    submitted-at: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-request-id uint u1)

;; Public functions
(define-public (submit-verification-request (specialization (string-ascii 50)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        advocate: tx-sender,
        submitted-at: block-height,
        status: "pending"
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (verify-advocate (advocate principal) (specialization (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? advocates { advocate: advocate })) ERR_ALREADY_VERIFIED)
    (map-set advocates
      { advocate: advocate }
      {
        verified: true,
        verification-date: block-height,
        specialization: specialization,
        reputation-score: u100
      }
    )
    (ok true)
  )
)

(define-public (update-reputation (advocate principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? advocates { advocate: advocate })
      advocate-data (begin
        (map-set advocates
          { advocate: advocate }
          (merge advocate-data { reputation-score: new-score })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Read-only functions
(define-read-only (is-verified-advocate (advocate principal))
  (match (map-get? advocates { advocate: advocate })
    advocate-data (get verified advocate-data)
    false
  )
)

(define-read-only (get-advocate-info (advocate principal))
  (map-get? advocates { advocate: advocate })
)

(define-read-only (get-verification-request (request-id uint))
  (map-get? verification-requests { request-id: request-id })
)
