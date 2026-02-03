/**
 * CodeQL / SECURITY_WORKFLOWS 検証用サンプル。
 * 意図的な SQL インジェクション脆弱性を含みます。本番では使用しないこと。
 */
package example;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Example {

    /**
     * ユーザー入力を文字列連結でクエリに含め、executeQuery に渡す（脆弱なパターン）。
     * CodeQL の java/sql-injection または java/concatenated-sql-query が検出する想定。
     */
    public ResultSet runUnsafeQuery(Connection conn, String userInput) throws SQLException {
        String query = "SELECT * FROM users WHERE name = '" + userInput + "'";
        Statement stmt = conn.createStatement();
        return stmt.executeQuery(query);
    }
}
