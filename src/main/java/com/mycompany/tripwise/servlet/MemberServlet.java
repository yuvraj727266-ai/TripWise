
package com.mycompany.tripwise.servlet;

import com.mycompany.tripwise.DBConnection;
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

@WebServlet("/members")
public class MemberServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws jakarta.servlet.ServletException, IOException {

        List<TripOption> trips = new ArrayList<>();
        List<Member> members = new ArrayList<>();

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
                SELECT M.MEMBER_ID, M.TRIP_ID, M.MEMBER_NAME, T.TRIP_NAME
                FROM TRIP_MEMBERS M
                JOIN TRIPS T ON T.TRIP_ID = M.TRIP_ID
                ORDER BY T.TRIP_NAME, M.MEMBER_NAME
                """;

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Member m = new Member();
                    m.id = rs.getLong("MEMBER_ID");
                    m.tripId = rs.getLong("TRIP_ID");
                    m.name = rs.getString("MEMBER_NAME");
                    m.tripName = rs.getString("TRIP_NAME");
                    members.add(m);
                }
            }

            // Calculate shared expenses actually paid by each member.
            String totalsSql = """
                SELECT M.MEMBER_ID, M.MEMBER_NAME, M.TRIP_ID,
                       NVL(SUM(E.ACTUAL_AMOUNT), 0) AS PAID
                FROM TRIP_MEMBERS M
                LEFT JOIN TRIP_EXPENSES E
                    ON E.PAID_BY_MEMBER_ID = M.MEMBER_ID
                   AND E.TRIP_ID = M.TRIP_ID
                GROUP BY M.MEMBER_ID, M.MEMBER_NAME, M.TRIP_ID
                """;

            List<MemberTotal> totals = new ArrayList<>();

            try (PreparedStatement ps = con.prepareStatement(totalsSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MemberTotal total = new MemberTotal();
                    total.memberId = rs.getLong("MEMBER_ID");
                    total.memberName = rs.getString("MEMBER_NAME");
                    total.tripId = rs.getLong("TRIP_ID");
                    total.paid = rs.getBigDecimal("PAID");
                    totals.add(total);
                }
            }

            request.setAttribute("memberTotals", totals);

        } catch (SQLException e) {
            getServletContext().log("Failed to load travel group", e);
            request.setAttribute("error",
                    "Could not load travel group. Check Oracle connection and table structure.");
        }

        request.setAttribute("trips", trips);
        request.setAttribute("members", members);

        request.getRequestDispatcher("/members.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("create".equals(action)) {
                createMember(request);
                redirect(request, response, "created");
            } else if ("delete".equals(action)) {
                deleteMember(request);
                redirect(request, response, "deleted");
            } else {
                response.sendError(400, "Unknown action.");
            }
        } catch (IllegalArgumentException e) {
            response.sendError(400, "Invalid input. Check the trip and member name.");
        } catch (SQLException e) {
            getServletContext().log("Travel group operation failed", e);
            response.sendError(500,
                    "Could not update travel group. Check the Tomcat log.");
        }
    }

    private void createMember(HttpServletRequest request) throws SQLException {
        long tripId = Long.parseLong(required(request, "tripId"));
        String name = required(request, "memberName");

        if (name.length() > 100) {
            throw new IllegalArgumentException("Member name is too long.");
        }

        String sql = """
            INSERT INTO TRIP_MEMBERS (TRIP_ID, MEMBER_NAME)
            VALUES (?, ?)
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, tripId);
            ps.setString(2, name);
            ps.executeUpdate();
        }
    }

    private void deleteMember(HttpServletRequest request) throws SQLException {
        long memberId = Long.parseLong(required(request, "memberId"));

        // Prevent deleting a member who is already assigned to expenses.
        try (Connection con = DBConnection.getConnection();
             PreparedStatement check = con.prepareStatement(
                     "SELECT COUNT(*) FROM TRIP_EXPENSES WHERE PAID_BY_MEMBER_ID=?")) {

            check.setLong(1, memberId);

            try (ResultSet rs = check.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    throw new SQLException(
                            "This member is assigned to expenses. Reassign those expenses first.");
                }
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM TRIP_MEMBERS WHERE MEMBER_ID=?")) {
                ps.setLong(1, memberId);

                if (ps.executeUpdate() == 0) {
                    throw new SQLException("Member not found.");
                }
            }
        }
    }

    private String required(HttpServletRequest request, String key) {
        String value = request.getParameter(key);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing field: " + key);
        }
        return value.trim();
    }

    private void redirect(HttpServletRequest request, HttpServletResponse response,
                          String status) throws IOException {
        response.sendRedirect(request.getContextPath() + "/members?success=" + status);
    }

    public static class TripOption {
        public long id;
        public String name;

        public TripOption(long id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    public static class Member {
        public long id, tripId;
        public String name, tripName;
    }

    public static class MemberTotal {
        public long memberId, tripId;
        public String memberName;
        public BigDecimal paid;
    }
}
