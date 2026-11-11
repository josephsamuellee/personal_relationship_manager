// Pure helpers for inserting text into a textarea-backed Markdown field.
// Used by markdown_editor_controller and covered by Node tests.

export function wikiPersonReference(name) {
  return `[[${name}]]`
}

export function resolveInsertRange(value, selection) {
  if (
    selection &&
    Number.isInteger(selection.start) &&
    Number.isInteger(selection.end) &&
    selection.start >= 0 &&
    selection.end >= selection.start &&
    selection.start <= value.length &&
    selection.end <= value.length
  ) {
    return { start: selection.start, end: selection.end }
  }

  return { start: value.length, end: value.length }
}

export function insertAtRange(value, text, selection) {
  const { start, end } = resolveInsertRange(value, selection)
  return {
    value: value.slice(0, start) + text + value.slice(end),
    caret: start + text.length
  }
}
