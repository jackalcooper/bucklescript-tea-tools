// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
var vscode = require('vscode');

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
function activate(context) {

    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "bucklescript-tea-tools" is now active!');

    // The command has been defined in the package.json file
    // Now provide the implementation of the command with  registerCommand
    // The commandId parameter must match the command field in package.json
    var disposable = vscode.commands.registerCommand('bucklescript-tea-tools.html-to-view', function () {
        var editor = vscode.window.activeTextEditor;
        // Check if there is a valid editor activiated
        if (editor) {
            var selectedText = editor.document.getText(editor.selection);
            var tabSize = editor.options.tabSize;
            var withSpaces = editor.options.insertSpaces;
            // See if selected text is empty
            if (selectedText.length === 0) {
                vscode.window.showWarningMessage('Please feed me with some selected HTML 😁');
                return;
            } else {
                editor.edit(function (editBuilder) {
                    editBuilder.replace(editor.selection, "converted");
                }).then(function () {});
            }
        } else {
            vscode.window.showWarningMessage('Please open/activiate at least one tab/window in VS Code 😁');
        }
    });

    context.subscriptions.push(disposable);
}
exports.activate = activate;

// this method is called when your extension is deactivated
function deactivate() {}
exports.deactivate = deactivate;