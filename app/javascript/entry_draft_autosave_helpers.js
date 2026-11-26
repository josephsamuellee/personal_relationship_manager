export function buildSnapshot({ title = "", rawDate = "", bodyMarkdown = "" } = {}) {
  return {
    title: String(title ?? ""),
    rawDate: String(rawDate ?? ""),
    bodyMarkdown: String(bodyMarkdown ?? "")
  }
}

export function snapshotsEqual(a, b) {
  if (!a || !b) return false
  return a.title === b.title && a.rawDate === b.rawDate && a.bodyMarkdown === b.bodyMarkdown
}

export function nextBackoffMs(attempt) {
  const steps = [2000, 5000, 15000, 30000]
  const index = Math.max(0, Math.min(attempt, steps.length - 1))
  return steps[index]
}

export function statusLabel(state) {
  switch (state) {
    case "unsaved":
      return "Unsaved changes"
    case "saving":
      return "Saving draft…"
    case "saved":
      return "Draft saved"
    case "retrying":
      return "Not saved — retrying"
    case "conflict":
      return "Conflict detected"
    default:
      return ""
  }
}

/** Pure helper for conflict reload: server fields win in the editor; local body kept for copy. */
export function conflictReloadState(serverPayload, localSnapshot) {
  return {
    title: serverPayload?.title ?? localSnapshot?.title ?? "",
    rawDate: serverPayload?.raw_date ?? localSnapshot?.rawDate ?? "",
    bodyMarkdown: serverPayload?.body_markdown ?? localSnapshot?.bodyMarkdown ?? "",
    localCopy: localSnapshot?.bodyMarkdown ?? "",
    lockVersion: serverPayload?.lock_version
  }
}

export function shouldHaltAutosaveAfterStatus(status) {
  return status === 409 || status === 404 || status === 410
}
