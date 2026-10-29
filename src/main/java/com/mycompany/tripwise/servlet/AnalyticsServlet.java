
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
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/analytics")
public class AnalyticsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        BigDecimal totalBudget = BigDecimal.ZERO;
        BigDecimal estimatedExpenses = BigDecimal.ZERO;
        BigDecimal actualExpenses = BigDecimal.ZERO;

        List<CategoryStat> categoryStats = new ArrayList<>();
        List<TripStat> tripStats = new ArrayList<>();

        String totalsSql =
                "SELECT NVL((SELECT SUM(TOTAL_BUDGET) FROM TRIPS), 0) AS TOTAL_BUDGET, " +
                "NVL((SELECT SUM(ESTIMATED_AMOUNT) FROM TRIP_EXPENSES), 0) AS ESTIMATED_TOTAL, " +
                "NVL((SELECT SUM(ACTUAL_AMOUNT) FROM TRIP_EXPENSES), 0) AS ACTUAL_TOTAL " +
                "FROM DUAL";

        String categorySql =
                "SELECT CATEGORY, " +
                "NVL(SUM(ESTIMATED_AMOUNT), 0) AS ESTIMATED_TOTAL, " +
                "NVL(SUM(ACTUAL_AMOUNT), 0) AS ACTUAL_TOTAL " +
                "FROM TRIP_EXPENSES " +
                "GROUP BY CATEGORY " +
                "ORDER BY NVL(SUM(ACTUAL_AMOUNT), 0) DESC";

        String tripSql =
                "SELECT T.TRIP_ID, T.TRIP_NAME, T.DESTINATION, " +
                "T.TOTAL_BUDGET, " +
                "NVL(SUM(E.ESTIMATED_AMOUNT), 0) AS ESTIMATED_TOTAL, " +
                "NVL(SUM(E.ACTUAL_AMOUNT), 0) AS ACTUAL_TOTAL " +
                "FROM TRIPS T " +
                "LEFT JOIN TRIP_EXPENSES E ON T.TRIP_ID = E.TRIP_ID " +
                "GROUP BY T.TRIP_ID, T.TRIP_NAME, T.DESTINATION, T.TOTAL_BUDGET " +
                "ORDER BY T.TRIP_ID DESC";

        try (Connection con = DBConnection.getConnection()) {

            if (con == null) {
                throw new SQLException("Database connection returned null.");
            }

            try (PreparedStatement ps = con.prepareStatement(totalsSql);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    totalBudget = rs.getBigDecimal("TOTAL_BUDGET");
                    estimatedExpenses = rs.getBigDecimal("ESTIMATED_TOTAL");
                    actualExpenses = rs.getBigDecimal("ACTUAL_TOTAL");

                    if (totalBudget == null) totalBudget = BigDecimal.ZERO;
                    if (estimatedExpenses == null) estimatedExpenses = BigDecimal.ZERO;
                    if (actualExpenses == null) actualExpenses = BigDecimal.ZERO;
                }
            }

            try (PreparedStatement ps = con.prepareStatement(categorySql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    BigDecimal estimated = rs.getBigDecimal("ESTIMATED_TOTAL");
                    BigDecimal actual = rs.getBigDecimal("ACTUAL_TOTAL");

                    categoryStats.add(new CategoryStat(
                            rs.getString("CATEGORY"),
                            estimated == null ? BigDecimal.ZERO : estimated,
                            actual == null ? BigDecimal.ZERO : actual
                    ));
                }
            }

            try (PreparedStatement ps = con.prepareStatement(tripSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    BigDecimal budget = rs.getBigDecimal("TOTAL_BUDGET");
                    BigDecimal estimated = rs.getBigDecimal("ESTIMATED_TOTAL");
                    BigDecimal actual = rs.getBigDecimal("ACTUAL_TOTAL");

                    tripStats.add(new TripStat(
                            rs.getLong("TRIP_ID"),
                            rs.getString("TRIP_NAME"),
                            rs.getString("DESTINATION"),
                            budget == null ? BigDecimal.ZERO : budget,
                            estimated == null ? BigDecimal.ZERO : estimated,
                            actual == null ? BigDecimal.ZERO : actual
                    ));
                }
            }

        } catch (SQLException e) {
            throw new ServletException("Unable to load TripWise analytics.", e);
        }

        request.setAttribute("totalBudget", totalBudget);
        request.setAttribute("estimatedExpenses", estimatedExpenses);
        request.setAttribute("actualExpenses", actualExpenses);
        request.setAttribute("categoryStats", categoryStats);
        request.setAttribute("tripStats", tripStats);

        request.getRequestDispatcher("/analytics.jsp")
               .forward(request, response);
    }

    public static class CategoryStat {
        private final String category;
        private final BigDecimal estimated;
        private final BigDecimal actual;

        public CategoryStat(String category, BigDecimal estimated,
                            BigDecimal actual) {
            this.category = category;
            this.estimated = estimated;
            this.actual = actual;
        }

        public String getCategory() { return category; }
        public BigDecimal getEstimated() { return estimated; }
        public BigDecimal getActual() { return actual; }
    }

    public static class TripStat {
        private final long tripId;
        private final String tripName;
        private final String destination;
        private final BigDecimal budget;
        private final BigDecimal estimated;
        private final BigDecimal actual;

        public TripStat(long tripId, String tripName, String destination,
                        BigDecimal budget, BigDecimal estimated,
                        BigDecimal actual) {
            this.tripId = tripId;
            this.tripName = tripName;
            this.destination = destination;
            this.budget = budget;
            this.estimated = estimated;
            this.actual = actual;
        }

        public long getTripId() { return tripId; }
        public String getTripName() { return tripName; }
        public String getDestination() { return destination; }
        public BigDecimal getBudget() { return budget; }
        public BigDecimal getEstimated() { return estimated; }
        public BigDecimal getActual() { return actual; }

        public BigDecimal getRemaining() {
            return budget.subtract(actual);
        }

        public double getUsedPercent() {
            if (budget.compareTo(BigDecimal.ZERO) <= 0) {
                return actual.compareTo(BigDecimal.ZERO) > 0 ? 100.0 : 0.0;
            }

            return actual.multiply(BigDecimal.valueOf(100))
                         .divide(budget, 2, java.math.RoundingMode.HALF_UP)
                         .doubleValue();
        }

        public String getBudgetStatus() {
            if (actual.compareTo(budget) > 0) {
                return "Over budget";
            }
            if (budget.compareTo(BigDecimal.ZERO) > 0
                    && getUsedPercent() >= 80.0) {
                return "Near budget";
            }
            return "Within budget";
        }
    }
}
