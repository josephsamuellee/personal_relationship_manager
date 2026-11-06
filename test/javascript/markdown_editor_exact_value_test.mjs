import assert from "node:assert/strict"
import test from "node:test"

// Mirrors markdown_editor_controller.js: restore exact initial Markdown if
// OverType rewrites the value during init (trailing newlines, wiki links, tags).
function restoreExactIfNeeded(editor, initialValue) {
  if (editor.getValue() !== initialValue) {
    editor.setValue(initialValue)
  }
  return editor.getValue()
}

test("restores exact trailing newlines when editor rewrites on init", () => {
  const initial = "Dinner with [[Ada Lovelace]].\n\n#church\n"
  let value = initial.trimEnd()
  const editor = {
    getValue: () => value,
    setValue: (next) => {
      value = next
    }
  }

  assert.equal(restoreExactIfNeeded(editor, initial), initial)
})

test("leaves matching values untouched", () => {
  const initial = "Hello [[Person]]\n"
  let value = initial
  let setCount = 0
  const editor = {
    getValue: () => value,
    setValue: (next) => {
      setCount += 1
      value = next
    }
  }

  assert.equal(restoreExactIfNeeded(editor, initial), initial)
  assert.equal(setCount, 0)
})
