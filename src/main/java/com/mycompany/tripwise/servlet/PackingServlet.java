
package com.mycompany.tripwise.servlet;

import com.mycompany.tripwise.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/packing")
public class PackingServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<TripOption> trips = new ArrayList<>();
        List<PackingItem> items = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            String tripSql = "SELECT TRIP_ID, TRIP_NAME FROM TRIPS ORDER BY TRIP_NAME";

            try (PreparedStatement ps = con.prepareStatement(tripSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    trips.add(new TripOption(
                            rs.getLong("TRIP_ID"),
                            rs.getString("TRIP_NAME")));
                }
            }

            String itemSql = """
                SELECT P.ITEM_ID, P.TRIP_ID, T.TRIP_NAME,
                       P.ITEM_NAME, P.IS_PACKED
                FROM PACKING_ITEMS P
                JOIN TRIPS T ON T.TRIP_ID = P.TRIP_ID
                ORDER BY T.TRIP_NAME, P.ITEM_NAME
                """;

            try (PreparedStatement ps = con.prepareStatement(itemSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PackingItem item = new PackingItem();
                    item.id = rs.getLong("ITEM_ID");
                    item.tripId = rs.getLong("TRIP_ID");
                    item.tripName = rs.getString("TRIP_NAME");
                    item.name = rs.getString("ITEM_NAME");
                    item.packed = "Y".equalsIgnoreCase(rs.getString("IS_PACKED"));
                    items.add(item);
                }
            }

        } catch (SQLException e) {
            getServletContext().log("Failed to load packing checklist", e);
            request.setAttribute("error",
                    "Could not load packing checklist. Check Oracle connection and table structure.");
        }

        request.setAttribute("trips", trips);
        request.setAttribute("items", items);
        request.getRequestDispatcher("/packing.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            switch (action == null ? "" : action) {
                case "create" -> {
                    createItem(request);
                    redirect(request, response, "created");
                }
                case "toggle" -> {
                    toggleItem(request);
                    redirect(request, response, "updated");
                }
                case "delete" -> {
                    deleteItem(request);
                    redirect(request, response, "deleted");
                }
                default -> response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST, "Unknown action.");
            }
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid input. Enter a valid trip and item name.");
        } catch (SQLException e) {
            getServletContext().log("Packing checklist operation failed", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Packing operation failed. Check the Tomcat server log.");
        }
    }

    private void createItem(HttpServletRequest request) throws SQLException {
        long tripId = Long.parseLong(required(request, "tripId"));
        String name = required(request, "itemName");

        if (name.length() > 100) {
            throw new IllegalArgumentException("Item name is too long.");
        }

        String sql = """
            INSERT INTO PACKING_ITEMS (TRIP_ID, ITEM_NAME, IS_PACKED)
            VALUES (?, ?, 'N')
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, tripId);
            ps.setString(2, name);
            ps.executeUpdate();
        }
    }

    private void toggleItem(HttpServletRequest request) throws SQLException {
        long itemId = Long.parseLong(required(request, "itemId"));
        String packedValue = required(request, "packed");

        if (!"Y".equals(packedValue) && !"N".equals(packedValue)) {
            throw new IllegalArgumentException("Invalid packing status.");
        }

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE PACKING_ITEMS SET IS_PACKED=? WHERE ITEM_ID=?")) {
            ps.setString(1, packedValue);
            ps.setLong(2, itemId);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Packing item not found.");
            }
        }
    }

    private void deleteItem(HttpServletRequest request) throws SQLException {
        long itemId = Long.parseLong(required(request, "itemId"));

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM PACKING_ITEMS WHERE ITEM_ID=?")) {
            ps.setLong(1, itemId);

            if (ps.executeUpdate() == 0) {
                throw new SQLException("Packing item not found.");
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
        response.sendRedirect(request.getContextPath() + "/packing?success=" + status);
    }

    public static class TripOption {
        public long id;
        public String name;

        public TripOption(long id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    public static class PackingItem {
        public long id, tripId;
        public String tripName, name;
        public boolean packed;
    }
}
