
package com.mycompany.tripwise.servlet;

import com.mycompany.tripwise.DBConnection;
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

@WebServlet("/itinerary")
public class ItineraryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException, jakarta.servlet.ServletException {

        List<TripOption> trips = new ArrayList<>();
        List<Activity> activities = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT TRIP_ID, TRIP_NAME FROM TRIPS ORDER BY TRIP_NAME");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    trips.add(new TripOption(
                            rs.getLong("TRIP_ID"),
                            rs.getString("TRIP_NAME")));
                }
            }

            String sql = """
                SELECT I.ACTIVITY_ID, I.TRIP_ID, T.TRIP_NAME,
                       I.DAY_NUMBER, I.ACTIVITY_NAME, I.ACTIVITY_DATE,
                       I.ESTIMATED_COST, I.ACTIVITY_STATUS
                FROM ITINERARY I
                JOIN TRIPS T ON T.TRIP_ID = I.TRIP_ID
                ORDER BY I.TRIP_ID, I.DAY_NUMBER, I.ACTIVITY_DATE
                """;

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Activity a = new Activity();
                    a.id = rs.getLong("ACTIVITY_ID");
                    a.tripId = rs.getLong("TRIP_ID");
                    a.tripName = rs.getString("TRIP_NAME");
                    a.day = rs.getInt("DAY_NUMBER");
                    a.name = rs.getString("ACTIVITY_NAME");

                    Date date = rs.getDate("ACTIVITY_DATE");
                    a.date = date == null ? "" : date.toString();

                    a.cost = rs.getBigDecimal("ESTIMATED_COST");
                    a.status = rs.getString("ACTIVITY_STATUS");
                    activities.add(a);
                }
            }

        } catch (SQLException e) {
            getServletContext().log("Failed to load itinerary", e);
            request.setAttribute("error",
                    "Could not load itinerary. Check your Oracle connection and table structure.");
        }

        request.setAttribute("trips", trips);
        request.setAttribute("activities", activities);
        request.getRequestDispatcher("/itinerary.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("create".equals(action)) {
                createActivity(request);
                redirect(request, response, "created");
            } else if ("update".equals(action)) {
                updateActivity(request);
                redirect(request, response, "updated");
            } else if ("status".equals(action)) {
                updateStatus(request);
                redirect(request, response, "updated");
            } else if ("delete".equals(action)) {
                deleteActivity(request);
                redirect(request, response, "deleted");
            } else {
                response.sendError(400, "Unknown action.");
            }
        } catch (IllegalArgumentException e) {
            response.sendError(400, "Invalid input. Check the dates, day number and cost.");
        } catch (SQLException e) {
            getServletContext().log("Itinerary operation failed", e);
            response.sendError(500, "Itinerary operation failed. Check the Tomcat log.");
        }
    }

    private void createActivity(HttpServletRequest request) throws SQLException {
        long tripId = Long.parseLong(required(request, "tripId"));
        int day = Integer.parseInt(required(request, "day"));
        String name = required(request, "activityName");
        Date date = Date.valueOf(required(request, "activityDate"));
        BigDecimal cost = new BigDecimal(required(request, "cost"));
        String status = required(request, "status");

        validate(day, cost, status);

        String sql = """
            INSERT INTO ITINERARY
                (TRIP_ID, DAY_NUMBER, ACTIVITY_NAME, ACTIVITY_DATE,
                 ESTIMATED_COST, ACTIVITY_STATUS)
            VALUES (?, ?, ?, ?, ?, ?)
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, tripId);
            ps.setInt(2, day);
            ps.setString(3, name);
            ps.setDate(4, date);
            ps.setBigDecimal(5, cost);
            ps.setString(6, status);
            ps.executeUpdate();
        }
    }

    private void updateActivity(HttpServletRequest request) throws SQLException {
        long id = Long.parseLong(required(request, "activityId"));
        long tripId = Long.parseLong(required(request, "tripId"));
        int day = Integer.parseInt(required(request, "day"));
        String name = required(request, "activityName");
        Date date = Date.valueOf(required(request, "activityDate"));
        BigDecimal cost = new BigDecimal(required(request, "cost"));
        String status = required(request, "status");

        validate(day, cost, status);

        String sql = """
            UPDATE ITINERARY
            SET TRIP_ID=?, DAY_NUMBER=?, ACTIVITY_NAME=?,
                ACTIVITY_DATE=?, ESTIMATED_COST=?, ACTIVITY_STATUS=?
            WHERE ACTIVITY_ID=?
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, tripId);
            ps.setInt(2, day);
            ps.setString(3, name);
            ps.setDate(4, date);
            ps.setBigDecimal(5, cost);
            ps.setString(6, status);
            ps.setLong(7, id);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Activity not found.");
            }
        }
    }

    private void updateStatus(HttpServletRequest request) throws SQLException {
        long id = Long.parseLong(required(request, "activityId"));
        String status = required(request, "status");

        if (!isValidStatus(status)) {
            throw new IllegalArgumentException("Invalid activity status.");
        }

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE ITINERARY SET ACTIVITY_STATUS=? WHERE ACTIVITY_ID=?")) {
            ps.setString(1, status);
            ps.setLong(2, id);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Activity not found.");
            }
        }
    }

    private void deleteActivity(HttpServletRequest request) throws SQLException {
        long id = Long.parseLong(required(request, "activityId"));

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM ITINERARY WHERE ACTIVITY_ID=?")) {
            ps.setLong(1, id);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Activity not found.");
            }
        }
    }

    private void validate(int day, BigDecimal cost, String status) {
        if (day < 1 || cost.signum() < 0 || !isValidStatus(status)) {
            throw new IllegalArgumentException("Invalid activity values.");
        }
    }

    private boolean isValidStatus(String status) {
        return "PLANNED".equals(status)
                || "COMPLETED".equals(status)
                || "CANCELLED".equals(status);
    }

    private String required(HttpServletRequest request, String key) {
        String value = request.getParameter(key);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing " + key);
        }
        return value.trim();
    }

    private void redirect(HttpServletRequest request, HttpServletResponse response,
                          String status) throws IOException {
        response.sendRedirect(request.getContextPath() + "/itinerary?success=" + status);
    }

    public static class TripOption {
        public long id;
        public String name;

        public TripOption(long id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    public static class Activity {
        public long id, tripId;
        public int day;
        public String tripName, name, date, status;
        public BigDecimal cost;
    }
}
