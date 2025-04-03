;; Patient Tracking Contract
;; Securely links devices to recipient patients

;; Define data maps
(define-map patient-devices
  { patient-id: principal }
  { device-ids: (list 20 uint) }
)

(define-map device-patients
  { device-id: uint }
  { patient-id: principal }
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

;; Associate a device with a patient
(define-public (associate-device (device-id uint) (patient-id principal))
  (let
    (
      (current-devices (default-to { device-ids: (list) } (map-get? patient-devices { patient-id: patient-id })))
      (device-exists (default-to { exists: false } (map-get? devices { device-id: device-id })))
    )
    ;; Check if device exists
    (if (get exists device-exists)
      ;; Check if device is already associated with a patient
      (if (is-none (map-get? device-patients { device-id: device-id }))
        (begin
          ;; Associate device with patient
          (map-set device-patients
            { device-id: device-id }
            { patient-id: patient-id }
          )

          ;; Add device to patient's list
          (map-set patient-devices
            { patient-id: patient-id }
            { device-ids: (unwrap-panic (as-max-len? (append (get device-ids current-devices) device-id) u20)) }
          )

          (ok true)
        )
        (err u403) ;; Device already associated
      )
      (err u404) ;; Device not found
    )
  )
)

;; Disassociate a device from a patient
(define-public (disassociate-device (device-id uint))
  (let
    (
      (device-patient (map-get? device-patients { device-id: device-id }))
    )
    (if (is-some device-patient)
      (let
        (
          (patient-id (get patient-id (unwrap-panic device-patient)))
          (current-devices (default-to { device-ids: (list) } (map-get? patient-devices { patient-id: patient-id })))
          (updated-devices (filter (lambda (id) (not (is-eq id device-id))) (get device-ids current-devices)))
        )
        ;; Remove device from patient's list
        (map-set patient-devices
          { patient-id: patient-id }
          { device-ids: updated-devices }
        )

        ;; Remove device-patient association
        (map-delete device-patients { device-id: device-id })

        (ok true)
      )
      (err u404) ;; Device not associated
    )
  )
)

;; Read-only functions

;; Get all devices for a patient
(define-read-only (get-patient-devices (patient-id principal))
  (default-to { device-ids: (list) } (map-get? patient-devices { patient-id: patient-id }))
)

;; Get patient for a device
(define-read-only (get-device-patient (device-id uint))
  (map-get? device-patients { device-id: device-id })
)

