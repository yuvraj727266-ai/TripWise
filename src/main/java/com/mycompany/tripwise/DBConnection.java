
package com.mycompany.tripwise;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL =
            "jdbc:oracle:thin:@//localhost:1521/XEPDB1";

    private static final String USER = "SYSTEM";
    private static final String PASSWORD = "tanu";

    private DBConnection() {
    }

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("oracle.jdbc.OracleDriver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "Oracle JDBC driver is missing from the application runtime. "
                    + "Check the ojdbc11 Maven dependency and WEB-INF/lib.",
                    e
            );
        }

        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    public static void main(String[] args) {
        try (Connection con = getConnection()) {
            System.out.println("Oracle Database connected successfully!");
            System.out.println("Connected user: "
                    + con.getMetaData().getUserName());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
