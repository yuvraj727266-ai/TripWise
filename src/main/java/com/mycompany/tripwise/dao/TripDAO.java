
package com.mycompany.tripwise.dao;

import com.mycompany.tripwise.DBConnection;
import com.mycompany.tripwise.Trip;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TripDAO {

    private Trip mapTrip(ResultSet rs) throws SQLException {
        Trip t = new Trip();
        t.setTripId(rs.getInt("TRIP_ID"));
        t.setTripName(rs.getString("TRIP_NAME"));
        t.setOriginCity(rs.getString("ORIGIN_CITY"));
        t.setDestination(rs.getString("DESTINATION"));

        Date start = rs.getDate("START_DATE");
        Date end = rs.getDate("END_DATE");
        if (start != null) t.setStartDate(start.toLocalDate());
        if (end != null) t.setEndDate(end.toLocalDate());

        t.setTravellerCount(rs.getInt("TRAVELLER_COUNT"));
        t.setTotalBudget(rs.getBigDecimal("TOTAL_BUDGET"));
        t.setTripType(rs.getString("TRIP_TYPE"));
        return t;
    }

    public List<Trip> findAll() throws SQLException {
        String sql = "SELECT * FROM TRIPS ORDER BY TRIP_ID DESC";
        List<Trip> trips = new ArrayList<>();

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) trips.add(mapTrip(rs));
        }
        return trips;
    }

    public Trip findById(int id) throws SQLException {
        String sql = "SELECT * FROM TRIPS WHERE TRIP_ID = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapTrip(rs);
            }
        }
        return null;
    }

    public void create(Trip t) throws SQLException {
        String sql = """
            INSERT INTO TRIPS
            (TRIP_NAME, ORIGIN_CITY, DESTINATION, START_DATE, END_DATE,
             TRAVELLER_COUNT, TOTAL_BUDGET, TRIP_TYPE)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, t.getTripName());
            ps.setString(2, t.getOriginCity());
            ps.setString(3, t.getDestination());
            ps.setDate(4, Date.valueOf(t.getStartDate()));
            ps.setDate(5, Date.valueOf(t.getEndDate()));
            ps.setInt(6, t.getTravellerCount());
            ps.setBigDecimal(7, t.getTotalBudget());
            ps.setString(8, t.getTripType());
            ps.executeUpdate();
        }
    }

    public boolean update(Trip t) throws SQLException {
        String sql = """
            UPDATE TRIPS SET TRIP_NAME=?, ORIGIN_CITY=?, DESTINATION=?,
            START_DATE=?, END_DATE=?, TRAVELLER_COUNT=?, TOTAL_BUDGET=?,
            TRIP_TYPE=? WHERE TRIP_ID=?
            """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, t.getTripName());
            ps.setString(2, t.getOriginCity());
            ps.setString(3, t.getDestination());
            ps.setDate(4, Date.valueOf(t.getStartDate()));
            ps.setDate(5, Date.valueOf(t.getEndDate()));
            ps.setInt(6, t.getTravellerCount());
            ps.setBigDecimal(7, t.getTotalBudget());
            ps.setString(8, t.getTripType());
            ps.setInt(9, t.getTripId());
            return ps.executeUpdate() > 0;
        }
    }

    public boolean delete(int id) throws SQLException {
        String sql = "DELETE FROM TRIPS WHERE TRIP_ID = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        }
    }
}
