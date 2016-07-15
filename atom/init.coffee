# Your init script
#
# Atom will evaluate this file each time a new window is opened. It is run
# after packages are loaded/activated and after the previous editor state
# has been restored.
#
# An example hack to log to the console when each text editor is saved.
#
# atom.workspace.observeTextEditors (editor) ->
#   editor.onDidSave ->
#     console.log "Saved! #{editor.getPath()}"

atom.commands.add 'atom-text-editor', 'editor:cut-to-end-of-line', ->
  return null

for b in atom.keymaps.keyBindings
  b.command = 'unset!' if /^ctrl-k /.test(b.keystrokes)

atom.commands.add 'atom-text-editor:not([mini])', 'custom:snippet-open-or-next', ->
  editor = atom.views.getView atom.workspace.getActiveTextEditor()
  atom.commands.dispatch(editor, 'snippets:next-tab-stop')
  atom.commands.dispatch(editor, 'snippets:expand')
