;; Alert Distribution Contract
;; Manages notification of affected individuals

;; Define data variables
(define-data-var last-alert-id uint u0)

;; Define data maps
(define-map alerts
  { alert-id: uint }
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    severity: (string-utf8 20),
    affected-batches: (list 10 (string-utf8 50)),
    affected-types: (list 10 (string-utf8 100)),
    created-at: uint,
    created-by: principal
  }
)

(define-map device-alerts
  { device-id: uint }
  { alert-ids: (list 20 uint) }
)

;; Define data map for devices (simplified version of device-registration)
(define-map devices
  { device-id: uint }
  { exists: bool }
)

;; Define public functions

;; Register device in this contract (simplified)
(define-public (register-device (device-id uint))
  (begin
    (map-set devices { device-id: device-id } { exists: true })
    (ok true)
  )
)

;; Create a new alert
(define-public (create-alert
                (title (string-utf8 100))
                (description (string-utf8 500))
                (severity (string-utf8 20))
                (affected-batches (list 10 (string-utf8 50)))
                (affected-types (list 10 (string-utf8 100))))
  (let
    (
      (new-id (+ (var-get last-alert-id) u1))
      (tx-sender tx-sender)
    )
    (var-set last-alert-id new-id)
    (map-set alerts
      { alert-id: new-id }
      {
        title: title,
        description: description,
        severity: severity,
        affected-batches: affected-batches,
        affected-types: affected-types,
        created-at: block-height,
        created-by: tx-sender
      }
    )
    (ok new-id)
  )
)

;; Associate an alert with a device
(define-public (associate-alert-with-device (alert-id uint) (device-id uint))
  (let
    (
      (current-alerts (default-to { alert-ids: (list) } (map-get? device-alerts { device-id: device-id })))
      (alert-exists (is-some (map-get? alerts { alert-id: alert-id })))
      (device-exists (default-to { exists: false } (map-get? devices { device-id: device-id })))
    )
    ;; Check if alert and device exist
    (if (and alert-exists (get exists device-exists))
      (begin
        ;; Add alert to device's list
        (map-set device-alerts
          { device-id: device-id }
          { alert-ids: (unwrap-panic (as-max-len? (append (get alert-ids current-alerts) alert-id) u20)) }
        )

        (ok true)
      )
      (err u404) ;; Alert or device not found
    )
  )
)

;; Read-only functions

;; Get alert details
(define-read-only (get-alert (alert-id uint))
  (map-get? alerts { alert-id: alert-id })
)

;; Get all alerts for a device
(define-read-only (get-device-alerts (device-id uint))
  (default-to { alert-ids: (list) } (map-get? device-alerts { device-id: device-id }))
)

;; Get total number of alerts
(define-read-only (get-alert-count)
  (var-get last-alert-id)
)

