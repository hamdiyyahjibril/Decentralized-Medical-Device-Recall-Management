import { describe, it, expect, beforeEach } from "vitest"

// Mock implementation for testing Clarity contracts
const mockAlerts = new Map()
const mockDeviceAlerts = new Map()
const mockDevices = new Map()
let mockLastAlertId = 0

// Mock contract functions
const registerDevice = (deviceId) => {
  mockDevices.set(deviceId, { exists: true })
  return { ok: true }
}

const createAlert = (title, description, severity, affectedBatches, affectedTypes) => {
  const newId = mockLastAlertId + 1
  mockLastAlertId = newId
  
  mockAlerts.set(newId, {
    title,
    description,
    severity,
    affectedBatches,
    affectedTypes,
    createdAt: 100, // Mock block height
    createdBy: "ST1PQHQKV0PP9JV78HTDVVD6QJMJJEMWVAZJ3K7Z", // Mock tx-sender
  })
  
  return { ok: newId }
}

const associateAlertWithDevice = (alertId, deviceId) => {
  // Check if alert exists
  if (!mockAlerts.has(alertId)) {
    return { err: 404 }
  }
  
  // Check if device exists
  if (!mockDevices.has(deviceId)) {
    return { err: 404 }
  }
  
  // Add alert to device's list
  const currentAlerts = mockDeviceAlerts.get(deviceId) || { alertIds: [] }
  currentAlerts.alertIds.push(alertId)
  mockDeviceAlerts.set(deviceId, currentAlerts)
  
  return { ok: true }
}

const getAlert = (alertId) => {
  return mockAlerts.get(alertId) || null
}

const getDeviceAlerts = (deviceId) => {
  return mockDeviceAlerts.get(deviceId) || { alertIds: [] }
}

describe("Alert Distribution Contract", () => {
  beforeEach(() => {
    mockAlerts.clear()
    mockDeviceAlerts.clear()
    mockDevices.clear()
    mockLastAlertId = 0
    
    // Add some test devices
    registerDevice(1)
    registerDevice(2)
  })
  
  it("should create a new alert", () => {
    const result = createAlert(
        "Urgent Recall",
        "Potential battery defect",
        "critical",
        ["MT2023-001"],
        ["Cardiac Pacemaker"],
    )
    
    expect(result).toHaveProperty("ok")
    expect(result.ok).toBe(1)
    
    const alert = getAlert(1)
    expect(alert).toEqual({
      title: "Urgent Recall",
      description: "Potential battery defect",
      severity: "critical",
      affectedBatches: ["MT2023-001"],
      affectedTypes: ["Cardiac Pacemaker"],
      createdAt: 100,
      createdBy: "ST1PQHQKV0PP9JV78HTDVVD6QJMJJEMWVAZJ3K7Z",
    })
  })
  
  it("should associate an alert with a device", () => {
    createAlert("Urgent Recall", "Potential battery defect", "critical", ["MT2023-001"], ["Cardiac Pacemaker"])
    
    const result = associateAlertWithDevice(1, 1)
    
    expect(result).toHaveProperty("ok")
    expect(result.ok).toBe(true)
    
    const deviceAlerts = getDeviceAlerts(1)
    expect(deviceAlerts.alertIds).toContain(1)
  })
  
  it("should fail to associate non-existent alert", () => {
    const result = associateAlertWithDevice(999, 1)
    
    expect(result).toHaveProperty("err")
    expect(result.err).toBe(404)
  })
  
  it("should fail to associate alert with non-existent device", () => {
    createAlert("Urgent Recall", "Potential battery defect", "critical", ["MT2023-001"], ["Cardiac Pacemaker"])
    
    const result = associateAlertWithDevice(1, 999)
    
    expect(result).toHaveProperty("err")
    expect(result.err).toBe(404)
  })
})

