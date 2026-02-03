/**
 * CodeQL / SECURITY_WORKFLOWS 検証用サンプル。
 * 意図的な SQL インジェクション脆弱性を含みます。本番では使用しないこと。
 */
package example;

public class Example {

    /**
     * ユーザー入力を文字列連結でクエリに含める（脆弱なパターン）。
     * CodeQL が SQL インジェクションとして検出する想定。
     */
    public String buildQuery(String input) {
        String query = "SELECT * FROM users WHERE name = '" + input + "'";
        return query;
    }
}
