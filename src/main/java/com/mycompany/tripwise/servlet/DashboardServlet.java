package com.mycompany.tripwise.servlet;

import com.mycompany.tripwise.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

@WebServlet("/api/dashboard")
public class DashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        try (Connection con = DBConnection.getConnection()) {

            int totalTrips = getCount(con,
                    "SELECT COUNT(*) FROM TRIPS");

            int upcomingTrips = getCount(con,
                    "SELECT COUNT(*) FROM TRIPS WHERE START_DATE >= ?",
                    Date.valueOf(LocalDate.now()));

            BigDecimal totalBudget = getAmount(con,
                    "SELECT NVL(SUM(TOTAL_BUDGET), 0) FROM TRIPS");

            BigDecimal totalSpent = getAmount(con,
                    "SELECT NVL(SUM(ACTUAL_AMOUNT), 0) FROM TRIP_EXPENSES");

            StringBuilder tripsJson = new StringBuilder();
            tripsJson.append("[");

            String sql = """
                    SELECT TRIP_ID, TRIP_NAME, DESTINATION,
                           START_DATE, TOTAL_BUDGET
                    FROM TRIPS
                    WHERE START_DATE >= ?
                    ORDER BY START_DATE ASC
                    FETCH FIRST 4 ROWS ONLY
                    """;

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setDate(1, Date.valueOf(LocalDate.now()));

                try (ResultSet rs = ps.executeQuery()) {
                    boolean first = true;

                    while (rs.next()) {
                        if (!first) {
                            tripsJson.append(",");
                        }

                        tripsJson.append("{")
                                .append("\"tripId\":")
                                .append(rs.getLong("TRIP_ID"))
                                .append(",\"tripName\":")
                                .append(jsonString(rs.getString("TRIP_NAME")))
                                .append(",\"destination\":")
                                .append(jsonString(rs.getString("DESTINATION")))
                                .append(",\"startDate\":")
                                .append(jsonString(
                                        rs.getDate("START_DATE") == null
                                                ? null
                                                : rs.getDate("START_DATE").toString()))
                                .append(",\"budget\":")
                                .append(rs.getBigDecimal("TOTAL_BUDGET") == null
                                        ? "0"
                                        : rs.getBigDecimal("TOTAL_BUDGET").toPlainString())
                                .append("}");

                        first = false;
                    }
                }
            }

            tripsJson.append("]");

            String json = "{"
                    + "\"totalTrips\":" + totalTrips + ","
                    + "\"upcomingTrips\":" + upcomingTrips + ","
                    + "\"totalBudget\":" + totalBudget.toPlainString() + ","
                    + "\"totalSpent\":" + totalSpent.toPlainString() + ","
                    + "\"upcomingTripList\":" + tripsJson
                    + "}";

            response.getWriter().write(json);

        } catch (SQLException e) {
            getServletContext().log("Failed to load TripWise dashboard", e);

            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write(
                    "{\"error\":\"Unable to load dashboard data. Check the database connection and server logs.\"}"
            );
        }
    }

    private int getCount(Connection con, String sql, Date... dates)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < dates.length; i++) {
                ps.setDate(i + 1, dates[i]);
            }

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private BigDecimal getAmount(Connection con, String sql)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                BigDecimal amount = rs.getBigDecimal(1);
                return amount == null ? BigDecimal.ZERO : amount;
            }
        }

        return BigDecimal.ZERO;
    }

    private String jsonString(String value) {
        if (value == null) {
            return "null";
        }

        StringBuilder result = new StringBuilder("\"");

        for (char c : value.toCharArray()) {
            switch (c) {
                case '"' -> result.append("\\\"");
                case '\\' -> result.append("\\\\");
                case '\b' -> result.append("\\b");
                case '\f' -> result.append("\\f");
                case '\n' -> result.append("\\n");
                case '\r' -> result.append("\\r");
                case '\t' -> result.append("\\t");
                default -> {
                    if (c < 0x20) {
                        result.append(String.format("\\u%04x", (int) c));
                    } else {
                        result.append(c);
                    }
                }
            }
        }

        return result.append('"').toString();
    }
}
