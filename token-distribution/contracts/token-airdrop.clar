;; Airdrop Distribution Contract

;; Define constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERROR-NOT-CONTRACT-OWNER (err u100))
(define-constant ERROR-AIRDROP-ALREADY-CLAIMED (err u101))
(define-constant ERROR-RECIPIENT-NOT-ELIGIBLE (err u102))
(define-constant ERROR-INSUFFICIENT-TOKEN-BALANCE (err u103))
(define-constant ERROR-AIRDROP-NOT-ACTIVE (err u104))
(define-constant ERROR-INVALID-AMOUNT (err u105))
(define-constant ERROR-RECLAIM-PERIOD-NOT-ENDED (err u106))
(define-constant ERROR-INVALID-RECIPIENT (err u107))
(define-constant ERROR-INVALID-PERIOD (err u108))

;; Define data variables
(define-data-var is-airdrop-active bool true)
(define-data-var total-tokens-distributed uint u0)
(define-data-var airdrop-amount-per-recipient uint u100)
(define-data-var airdrop-start-block uint block-height)
(define-data-var reclaim-period-length uint u10000) ;; Number of blocks after which unclaimed tokens can be reclaimed

;; Define data maps
(define-map eligible-airdrop-recipients principal bool)
(define-map claimed-airdrop-amounts principal uint)

;; Define fungible token
(define-fungible-token airdrop-distribution-token)

;; Define events
(define-data-var next-event-id uint u0)
(define-map contract-events uint {event-type: (string-ascii 20), data: (string-ascii 256)})

;; Event logging function
(define-private (log-event (event-type (string-ascii 20)) (data (string-ascii 256)))
  (let ((event-id (var-get next-event-id)))
    (map-set contract-events event-id {event-type: event-type, data: data})
    (var-set next-event-id (+ event-id u1))
    event-id))

;; Admin functions

(define-public (add-eligible-recipient (recipient-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERROR-NOT-CONTRACT-OWNER)
    (asserts! (is-none (map-get? eligible-airdrop-recipients recipient-address)) ERROR-INVALID-RECIPIENT)
    (log-event "recipient-add" "new recipient")
    (ok (map-set eligible-airdrop-recipients recipient-address true))))

(define-public (remove-eligible-recipient (recipient-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERROR-NOT-CONTRACT-OWNER)
    (asserts! (is-some (map-get? eligible-airdrop-recipients recipient-address)) ERROR-RECIPIENT-NOT-ELIGIBLE)
    (log-event "recipient-remove" "removed recipient")
    (ok (map-delete eligible-airdrop-recipients recipient-address))))

(define-public (bulk-add-eligible-recipients (recipient-addresses (list 200 principal)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERROR-NOT-CONTRACT-OWNER)
    (log-event "bulk-recipients-add" "recipients added")
    (ok (map add-eligible-recipient recipient-addresses))))

(define-public (update-airdrop-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERROR-NOT-CONTRACT-OWNER)
    (asserts! (> new-amount u0) ERROR-INVALID-AMOUNT)
    (var-set airdrop-amount-per-recipient new-amount)
    (log-event "amount-updated" "amount changed")
    (ok new-amount)))

(define-public (update-reclaim-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERROR-NOT-CONTRACT-OWNER)
    (asserts! (> new-period u0) ERROR-INVALID-PERIOD)
    (var-set reclaim-period-length new-period)
    (log-event "period-updated" "reclaim period changed")
    (ok new-period)))

;; Airdrop distribution function

(define-public (claim-airdrop-tokens)
  (let (
    (recipient-address tx-sender)
    (claim-amount (var-get airdrop-amount-per-recipient))
  )
    (asserts! (var-get is-airdrop-active) ERROR-AIRDROP-NOT-ACTIVE)
    (asserts! (is-some (map-get? eligible-airdrop-recipients recipient-address)) ERROR-RECIPIENT-NOT-ELIGIBLE)
    (asserts! (is-none (map-get? claimed-airdrop-amounts recipient-address)) ERROR-AIRDROP-ALREADY-CLAIMED)
    (asserts! (<= claim-amount (ft-get-balance airdrop-distribution-token CONTRACT-OWNER)) ERROR-INSUFFICIENT-TOKEN-BALANCE)
    (try! (ft-transfer? airdrop-distribution-token claim-amount CONTRACT-OWNER recipient-address))
    (map-set claimed-airdrop-amounts recipient-address claim-amount)
    (var-set total-tokens-distributed (+ (var-get total-tokens-distributed) claim-amount))
    (log-event "tokens-claimed" "tokens claimed")
    (ok claim-amount)))

;; Token reclaim function

(define-public (reclaim-unclaimed-tokens)
  (let (
    (current-block block-height)
    (reclaim-allowed-after (+ (var-get airdrop-start-block) (var-get reclaim-period-length)))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERROR-NOT-CONTRACT-OWNER)
    (asserts! (>= current-block reclaim-allowed-after) ERROR-RECLAIM-PERIOD-NOT-ENDED)
    (let (
      (total-minted (ft-get-supply airdrop-distribution-token))
      (total-claimed (var-get total-tokens-distributed))
      (unclaimed-amount (- total-minted total-claimed))
    )
      (try! (ft-burn? airdrop-distribution-token unclaimed-amount CONTRACT-OWNER))
      (log-event "tokens-reclaimed" "unclaimed tokens burned")
      (ok unclaimed-amount))))

;; Read-only functions

(define-read-only (get-airdrop-active-status)
  (var-get is-airdrop-active))

(define-read-only (is-recipient-eligible (recipient-address principal))
  (default-to false (map-get? eligible-airdrop-recipients recipient-address)))

(define-read-only (has-recipient-claimed-airdrop (recipient-address principal))
  (is-some (map-get? claimed-airdrop-amounts recipient-address)))

(define-read-only (get-recipient-claimed-amount (recipient-address principal))
  (default-to u0 (map-get? claimed-airdrop-amounts recipient-address)))

(define-read-only (get-total-tokens-distributed)
  (var-get total-tokens-distributed))

(define-read-only (get-airdrop-amount-per-recipient)
  (var-get airdrop-amount-per-recipient))

(define-read-only (get-reclaim-period)
  (var-get reclaim-period-length))

(define-read-only (get-airdrop-start-block)
  (var-get airdrop-start-block))

(define-read-only (get-event (event-id uint))
  (map-get? contract-events event-id))

;; Contract initialization

(begin
  (ft-mint? airdrop-distribution-token u1000000000 CONTRACT-OWNER))