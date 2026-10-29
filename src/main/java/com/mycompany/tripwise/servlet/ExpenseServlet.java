
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
import java.util.ArrayList;
import java.util.List;

@WebServlet("/expenses")
public class ExpenseServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Expense> expenses = new ArrayList<>();
        List<TripOption> trips = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT TRIP_ID, TRIP_NAME FROM TRIPS ORDER BY TRIP_NAME");
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    trips.add(new TripOption(
                            rs.getLong("TRIP_ID"),
                            rs.getString("TRIP_NAME")
                    ));
                }
            }

            String sql = """
                SELECT E.EXPENSE_ID, E.TRIP_ID, T.TRIP_NAME,
                       E.CATEGORY, E.DESCRIPTION, E.ESTIMATED_AMOUNT,
                       E.ACTUAL_AMOUNT, E.EXPENSE_DATE
                FROM TRIP_EXPENSES E
                JOIN TRIPS T ON T.TRIP_ID = E.TRIP_ID
                ORDER BY E.EXPENSE_DATE DESC NULLS LAST, E.EXPENSE_ID DESC
                """;

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Expense e = new Expense();
                    e.id = rs.getLong("EXPENSE_ID");
                    e.tripId = rs.getLong("TRIP_ID");
                    e.tripName = rs.getString("TRIP_NAME");
                    e.category = rs.getString("CATEGORY");
                    e.description = rs.getString("DESCRIPTION");
                    e.estimated = rs.getBigDecimal("ESTIMATED_AMOUNT");
                    e.actual = rs.getBigDecimal("ACTUAL_AMOUNT");

                    Date date = rs.getDate("EXPENSE_DATE");
                    e.date = date == null ? "" : date.toString();

                    expenses.add(e);
                }
            }

            request.setAttribute("expenses", expenses);
            request.setAttribute("trips", trips);

        } catch (SQLException e) {
            getServletContext().log("Failed to load expenses", e);
            request.setAttribute("error",
                    "Could not load expenses. Check the Oracle connection and table structure.");
            request.setAttribute("expenses", expenses);
            request.setAttribute("trips", trips);
        }

        request.getRequestDispatcher("/expenses.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("create".equals(action)) {
                saveExpense(request, false);
                redirect(request, response, "created");
            } else if ("update".equals(action)) {
                saveExpense(request, true);
                redirect(request, response, "updated");
            } else if ("delete".equals(action)) {
                deleteExpense(request);
                redirect(request, response, "deleted");
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action.");
            }
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid input. Check the dates and amounts.");
        } catch (SQLException e) {
            getServletContext().log("Expense operation failed", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Expense operation failed. Check the Tomcat log.");
        }
    }

    private void saveExpense(HttpServletRequest request, boolean update)
            throws SQLException {

        long tripId = Long.parseLong(required(request, "tripId"));
        String category = required(request, "category");
        String description = required(request, "description");
        BigDecimal estimated = new BigDecimal(required(request, "estimated"));
        String actualInput = request.getParameter("actual");
        BigDecimal actual = (actualInput == null || actualInput.isBlank())
                ? BigDecimal.ZERO : new BigDecimal(actualInput.trim());
        Date date = Date.valueOf(required(request, "expenseDate"));

        if (estimated.signum() < 0 || actual.signum() < 0) {
            throw new IllegalArgumentException("Amounts cannot be negative.");
        }

        try (Connection con = DBConnection.getConnection()) {
            if (update) {
                long id = Long.parseLong(required(request, "expenseId"));

                String sql = """
                    UPDATE TRIP_EXPENSES
                    SET TRIP_ID=?, CATEGORY=?, DESCRIPTION=?,
                        ESTIMATED_AMOUNT=?, ACTUAL_AMOUNT=?, EXPENSE_DATE=?
                    WHERE EXPENSE_ID=?
                    """;

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setLong(1, tripId);
                    ps.setString(2, category);
                    ps.setString(3, description);
                    ps.setBigDecimal(4, estimated);
                    ps.setBigDecimal(5, actual);
                    ps.setDate(6, date);
                    ps.setLong(7, id);

                    if (ps.executeUpdate() == 0) {
                        throw new SQLException("Expense not found.");
                    }
                }
            } else {
                String sql = """
                    INSERT INTO TRIP_EXPENSES
                    (TRIP_ID, CATEGORY, DESCRIPTION, ESTIMATED_AMOUNT,
                     ACTUAL_AMOUNT, EXPENSE_DATE)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """;

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setLong(1, tripId);
                    ps.setString(2, category);
                    ps.setString(3, description);
                    ps.setBigDecimal(4, estimated);
                    ps.setBigDecimal(5, actual);
                    ps.setDate(6, date);
                    ps.executeUpdate();
                }
            }
        }
    }

    private void deleteExpense(HttpServletRequest request) throws SQLException {
        long id = Long.parseLong(required(request, "expenseId"));

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM TRIP_EXPENSES WHERE EXPENSE_ID=?")) {

            ps.setLong(1, id);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Expense not found.");
            }
        }
    }

    private String required(HttpServletRequest request, String name) {
        String value = request.getParameter(name);

        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing field: " + name);
        }

        return value.trim();
    }

    private void redirect(HttpServletRequest request, HttpServletResponse response,
                          String status) throws IOException {
        response.sendRedirect(request.getContextPath() + "/expenses?success=" + status);
    }

    public static class Expense {
        public long id, tripId;
        public String tripName, category, description, date;
        public BigDecimal estimated, actual;
    }

    public static class TripOption {
        public long id;
        public String name;

        public TripOption(long id, String name) {
            this.id = id;
            this.name = name;
        }
    }
}
