/**
 * CodeQL / SECURITY_WORKFLOWS 検証用サンプル。
 * 意図的な XSS の可能性を含みます。本番では使用しないこと。
 */

/**
 * ユーザー入力をそのまま innerHTML に渡す（脆弱なパターン）。
 */
function renderUserInput(element, userInput) {
  element.innerHTML = userInput;
}

/**
 * ユーザー入力をそのまま document.write に渡す（脆弱なパターン）。
 * CodeQL の js/xss 等が検出する想定。
 */
function writeUserInput(userInput) {
  document.write(userInput);
}
