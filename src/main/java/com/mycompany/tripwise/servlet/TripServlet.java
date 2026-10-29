
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
import java.util.ArrayList;
import java.util.List;

@WebServlet("/trips")
public class TripServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        List<TripRecord> trips = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            String sql = """
                SELECT TRIP_ID, TRIP_NAME, ORIGIN_CITY, DESTINATION,
                       START_DATE, END_DATE, TRAVELLER_COUNT,
                       TOTAL_BUDGET, TRIP_TYPE
                FROM TRIPS
                ORDER BY CREATED_AT DESC
                """;

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    TripRecord t = new TripRecord();
                    t.id = rs.getLong("TRIP_ID");
                    t.name = rs.getString("TRIP_NAME");
                    t.origin = rs.getString("ORIGIN_CITY");
                    t.destination = rs.getString("DESTINATION");

                    Date start = rs.getDate("START_DATE");
                    Date end = rs.getDate("END_DATE");

                    t.startDate = start == null ? "" : start.toString();
                    t.endDate = end == null ? "" : end.toString();
                    t.travellers = rs.getInt("TRAVELLER_COUNT");
                    t.budget = rs.getBigDecimal("TOTAL_BUDGET");
                    t.type = rs.getString("TRIP_TYPE");

                    trips.add(t);
                }
            }

            request.setAttribute("trips", trips);

        } catch (SQLException e) {
            getServletContext().log("Failed to load trips", e);
            request.setAttribute(
                    "error",
                    "Could not load trips. Verify the Oracle connection and database schema."
            );
            request.setAttribute("trips", trips);
        }

        request.getRequestDispatcher("/trips.jsp")
                .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("create".equals(action)) {
                createTrip(request);
                redirect(response, request, "created");
            } else if ("update".equals(action)) {
                updateTrip(request);
                redirect(response, request, "updated");
            } else if ("delete".equals(action)) {
                deleteTrip(request);
                redirect(response, request, "deleted");
            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Invalid trip action."
                );
            }
        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid input. Check dates, numbers and required fields."
            );
        } catch (SQLException e) {
            getServletContext().log("Trip operation failed", e);
            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Trip operation failed. Check the Tomcat server log."
            );
        }
    }

    private void createTrip(HttpServletRequest request)
            throws SQLException {

        String name = required(request, "tripName");
        String origin = required(request, "origin");
        String destination = required(request, "destination");
        LocalDate start = LocalDate.parse(required(request, "startDate"));
        LocalDate end = LocalDate.parse(required(request, "endDate"));
        int travellers = Integer.parseInt(required(request, "travellers"));
        BigDecimal budget = new BigDecimal(required(request, "budget"));
        String type = required(request, "tripType");

        validateTrip(start, end, travellers, budget);

        String sql = """
            INSERT INTO TRIPS
                (TRIP_NAME, ORIGIN_CITY, DESTINATION, START_DATE, END_DATE,
                 TRAVELLER_COUNT, TOTAL_BUDGET, TRIP_TYPE)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, name);
            ps.setString(2, origin);
            ps.setString(3, destination);
            ps.setDate(4, Date.valueOf(start));
            ps.setDate(5, Date.valueOf(end));
            ps.setInt(6, travellers);
            ps.setBigDecimal(7, budget);
            ps.setString(8, type);

            ps.executeUpdate();
        }
    }

    private void updateTrip(HttpServletRequest request)
            throws SQLException {

        long id = Long.parseLong(required(request, "tripId"));
        String name = required(request, "tripName");
        String origin = required(request, "origin");
        String destination = required(request, "destination");
        LocalDate start = LocalDate.parse(required(request, "startDate"));
        LocalDate end = LocalDate.parse(required(request, "endDate"));
        int travellers = Integer.parseInt(required(request, "travellers"));
        BigDecimal budget = new BigDecimal(required(request, "budget"));
        String type = required(request, "tripType");

        validateTrip(start, end, travellers, budget);

        String sql = """
            UPDATE TRIPS
            SET TRIP_NAME = ?, ORIGIN_CITY = ?, DESTINATION = ?,
                START_DATE = ?, END_DATE = ?, TRAVELLER_COUNT = ?,
                TOTAL_BUDGET = ?, TRIP_TYPE = ?
            WHERE TRIP_ID = ?
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, name);
            ps.setString(2, origin);
            ps.setString(3, destination);
            ps.setDate(4, Date.valueOf(start));
            ps.setDate(5, Date.valueOf(end));
            ps.setInt(6, travellers);
            ps.setBigDecimal(7, budget);
            ps.setString(8, type);
            ps.setLong(9, id);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Trip not found.");
            }
        }
    }

    private void deleteTrip(HttpServletRequest request)
            throws SQLException {

        long id = Long.parseLong(required(request, "tripId"));

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps =
                     con.prepareStatement("DELETE FROM TRIPS WHERE TRIP_ID = ?")) {

            ps.setLong(1, id);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Trip not found.");
            }
        }
    }

    private void validateTrip(LocalDate start, LocalDate end,
                              int travellers, BigDecimal budget) {

        if (end.isBefore(start)) {
            throw new IllegalArgumentException(
                    "End date must not be before start date."
            );
        }

        if (travellers < 1 || travellers > 100) {
            throw new IllegalArgumentException(
                    "Traveller count must be between 1 and 100."
            );
        }

        if (budget.signum() < 0) {
            throw new IllegalArgumentException(
                    "Budget cannot be negative."
            );
        }
    }

    private String required(HttpServletRequest request, String name) {
        String value = request.getParameter(name);

        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    "Missing required field: " + name
            );
        }

        return value.trim();
    }

    private void redirect(HttpServletResponse response,
                          HttpServletRequest request,
                          String status) throws IOException {

        response.sendRedirect(
                request.getContextPath() + "/trips?success=" + status
        );
    }

    public static class TripRecord {
        public long id;
        public String name;
        public String origin;
        public String destination;
        public String startDate;
        public String endDate;
        public String type;
        public int travellers;
        public BigDecimal budget;
    }
}
