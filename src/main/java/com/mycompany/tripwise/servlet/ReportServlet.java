
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

@WebServlet("/reports")
public class ReportServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        List<TripOption> trips = new ArrayList<>();
        TripDetails selectedTrip = null;
        List<ExpenseRow> expenses = new ArrayList<>();
        List<MemberRow> members = new ArrayList<>();
        List<ActivityRow> activities = new ArrayList<>();
        List<PackingRow> packingItems = new ArrayList<>();

        long selectedTripId = 0;
        String requestedId = request.getParameter("tripId");

        if (requestedId != null && !requestedId.trim().isEmpty()) {
            try {
                selectedTripId = Long.parseLong(requestedId.trim());
                if (selectedTripId < 1) {
                    selectedTripId = 0;
                }
            } catch (NumberFormatException ignored) {
                selectedTripId = 0;
            }
        }

        String tripsSql =
                "SELECT TRIP_ID, TRIP_NAME, DESTINATION FROM TRIPS ORDER BY TRIP_ID DESC";

        try (Connection con = DBConnection.getConnection()) {
            if (con == null) {
                throw new SQLException("Database connection returned null.");
            }

            try (PreparedStatement ps = con.prepareStatement(tripsSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    trips.add(new TripOption(
                            rs.getLong("TRIP_ID"),
                            rs.getString("TRIP_NAME"),
                            rs.getString("DESTINATION")
                    ));
                }
            }

            if (selectedTripId == 0 && !trips.isEmpty()) {
                selectedTripId = trips.get(0).getTripId();
            }

            if (selectedTripId > 0) {
                String tripSql =
                        "SELECT TRIP_ID, TRIP_NAME, ORIGIN_CITY, DESTINATION, " +
                        "START_DATE, END_DATE, TRAVELLER_COUNT, TOTAL_BUDGET, " +
                        "TRIP_TYPE, CREATED_AT FROM TRIPS WHERE TRIP_ID = ?";

                try (PreparedStatement ps = con.prepareStatement(tripSql)) {
                    ps.setLong(1, selectedTripId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            selectedTrip = new TripDetails(
                                    rs.getLong("TRIP_ID"),
                                    rs.getString("TRIP_NAME"),
                                    rs.getString("ORIGIN_CITY"),
                                    rs.getString("DESTINATION"),
                                    rs.getDate("START_DATE") == null ? "" :
                                            rs.getDate("START_DATE").toString(),
                                    rs.getDate("END_DATE") == null ? "" :
                                            rs.getDate("END_DATE").toString(),
                                    rs.getInt("TRAVELLER_COUNT"),
                                    rs.getBigDecimal("TOTAL_BUDGET"),
                                    rs.getString("TRIP_TYPE"),
                                    rs.getTimestamp("CREATED_AT") == null ? "" :
                                            rs.getTimestamp("CREATED_AT").toString()
                            );
                        }
                    }
                }

                if (selectedTrip != null) {
                    String expenseSql =
                            "SELECT E.EXPENSE_ID, E.CATEGORY, E.DESCRIPTION, " +
                            "E.ESTIMATED_AMOUNT, E.ACTUAL_AMOUNT, E.EXPENSE_DATE, " +
                            "M.MEMBER_NAME AS PAID_BY " +
                            "FROM TRIP_EXPENSES E " +
                            "LEFT JOIN TRIP_MEMBERS M ON E.PAID_BY_MEMBER_ID = M.MEMBER_ID " +
                            "WHERE E.TRIP_ID = ? ORDER BY E.EXPENSE_DATE, E.EXPENSE_ID";

                    try (PreparedStatement ps = con.prepareStatement(expenseSql)) {
                        ps.setLong(1, selectedTripId);

                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                expenses.add(new ExpenseRow(
                                        rs.getLong("EXPENSE_ID"),
                                        rs.getString("CATEGORY"),
                                        rs.getString("DESCRIPTION"),
                                        zeroIfNull(rs.getBigDecimal("ESTIMATED_AMOUNT")),
                                        zeroIfNull(rs.getBigDecimal("ACTUAL_AMOUNT")),
                                        rs.getDate("EXPENSE_DATE") == null ? "" :
                                                rs.getDate("EXPENSE_DATE").toString(),
                                        rs.getString("PAID_BY")
                                ));
                            }
                        }
                    }

                    String memberSql =
                            "SELECT M.MEMBER_ID, M.MEMBER_NAME, " +
                            "NVL(SUM(E.ACTUAL_AMOUNT), 0) AS TOTAL_PAID " +
                            "FROM TRIP_MEMBERS M " +
                            "LEFT JOIN TRIP_EXPENSES E " +
                            "ON E.PAID_BY_MEMBER_ID = M.MEMBER_ID " +
                            "WHERE M.TRIP_ID = ? " +
                            "GROUP BY M.MEMBER_ID, M.MEMBER_NAME " +
                            "ORDER BY M.MEMBER_ID";

                    try (PreparedStatement ps = con.prepareStatement(memberSql)) {
                        ps.setLong(1, selectedTripId);

                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                members.add(new MemberRow(
                                        rs.getLong("MEMBER_ID"),
                                        rs.getString("MEMBER_NAME"),
                                        zeroIfNull(rs.getBigDecimal("TOTAL_PAID"))
                                ));
                            }
                        }
                    }

                    String activitySql =
                            "SELECT ACTIVITY_ID, DAY_NUMBER, ACTIVITY_NAME, " +
                            "ACTIVITY_DATE, ESTIMATED_COST, ACTIVITY_STATUS " +
                            "FROM ITINERARY WHERE TRIP_ID = ? " +
                            "ORDER BY DAY_NUMBER, ACTIVITY_DATE, ACTIVITY_ID";

                    try (PreparedStatement ps = con.prepareStatement(activitySql)) {
                        ps.setLong(1, selectedTripId);

                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                activities.add(new ActivityRow(
                                        rs.getLong("ACTIVITY_ID"),
                                        rs.getInt("DAY_NUMBER"),
                                        rs.getString("ACTIVITY_NAME"),
                                        rs.getDate("ACTIVITY_DATE") == null ? "" :
                                                rs.getDate("ACTIVITY_DATE").toString(),
                                        zeroIfNull(rs.getBigDecimal("ESTIMATED_COST")),
                                        rs.getString("ACTIVITY_STATUS")
                                ));
                            }
                        }
                    }

                    String packingSql =
                            "SELECT ITEM_ID, ITEM_NAME, IS_PACKED " +
                            "FROM PACKING_ITEMS WHERE TRIP_ID = ? ORDER BY ITEM_ID";

                    try (PreparedStatement ps = con.prepareStatement(packingSql)) {
                        ps.setLong(1, selectedTripId);

                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                packingItems.add(new PackingRow(
                                        rs.getLong("ITEM_ID"),
                                        rs.getString("ITEM_NAME"),
                                        "Y".equalsIgnoreCase(rs.getString("IS_PACKED"))
                                ));
                            }
                        }
                    }
                }
            }

        } catch (SQLException e) {
            throw new ServletException("Unable to generate the trip report.", e);
        }

        BigDecimal estimatedTotal = BigDecimal.ZERO;
        BigDecimal actualTotal = BigDecimal.ZERO;

        for (ExpenseRow expense : expenses) {
            estimatedTotal = estimatedTotal.add(expense.getEstimated());
            actualTotal = actualTotal.add(expense.getActual());
        }

        BigDecimal budget = selectedTrip == null
                ? BigDecimal.ZERO : zeroIfNull(selectedTrip.getTotalBudget());

        request.setAttribute("trips", trips);
        request.setAttribute("selectedTrip", selectedTrip);
        request.setAttribute("expenses", expenses);
        request.setAttribute("members", members);
        request.setAttribute("activities", activities);
        request.setAttribute("packingItems", packingItems);
        request.setAttribute("estimatedTotal", estimatedTotal);
        request.setAttribute("actualTotal", actualTotal);
        request.setAttribute("budgetRemaining", budget.subtract(actualTotal));

        request.getRequestDispatcher("/reports.jsp").forward(request, response);
    }

    private static BigDecimal zeroIfNull(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    public static class TripOption {
        private final long tripId;
        private final String tripName;
        private final String destination;

        public TripOption(long tripId, String tripName, String destination) {
            this.tripId = tripId;
            this.tripName = tripName;
            this.destination = destination;
        }

        public long getTripId() { return tripId; }
        public String getTripName() { return tripName; }
        public String getDestination() { return destination; }
    }

    public static class TripDetails {
        private final long tripId;
        private final String tripName;
        private final String originCity;
        private final String destination;
        private final String startDate;
        private final String endDate;
        private final int travellerCount;
        private final BigDecimal totalBudget;
        private final String tripType;
        private final String createdAt;

        public TripDetails(long tripId, String tripName, String originCity,
                           String destination, String startDate, String endDate,
                           int travellerCount, BigDecimal totalBudget,
                           String tripType, String createdAt) {
            this.tripId = tripId;
            this.tripName = tripName;
            this.originCity = originCity;
            this.destination = destination;
            this.startDate = startDate;
            this.endDate = endDate;
            this.travellerCount = travellerCount;
            this.totalBudget = zeroIfNull(totalBudget);
            this.tripType = tripType;
            this.createdAt = createdAt;
        }

        public long getTripId() { return tripId; }
        public String getTripName() { return tripName; }
        public String getOriginCity() { return originCity; }
        public String getDestination() { return destination; }
        public String getStartDate() { return startDate; }
        public String getEndDate() { return endDate; }
        public int getTravellerCount() { return travellerCount; }
        public BigDecimal getTotalBudget() { return totalBudget; }
        public String getTripType() { return tripType; }
        public String getCreatedAt() { return createdAt; }
    }

    public static class ExpenseRow {
        private final long expenseId;
        private final String category;
        private final String description;
        private final BigDecimal estimated;
        private final BigDecimal actual;
        private final String expenseDate;
        private final String paidBy;

        public ExpenseRow(long expenseId, String category, String description,
                          BigDecimal estimated, BigDecimal actual,
                          String expenseDate, String paidBy) {
            this.expenseId = expenseId;
            this.category = category;
            this.description = description;
            this.estimated = zeroIfNull(estimated);
            this.actual = zeroIfNull(actual);
            this.expenseDate = expenseDate;
            this.paidBy = paidBy;
        }

        public long getExpenseId() { return expenseId; }
        public String getCategory() { return category; }
        public String getDescription() { return description; }
        public BigDecimal getEstimated() { return estimated; }
        public BigDecimal getActual() { return actual; }
        public String getExpenseDate() { return expenseDate; }
        public String getPaidBy() { return paidBy; }
    }

    public static class MemberRow {
        private final long memberId;
        private final String memberName;
        private final BigDecimal totalPaid;

        public MemberRow(long memberId, String memberName, BigDecimal totalPaid) {
            this.memberId = memberId;
            this.memberName = memberName;
            this.totalPaid = zeroIfNull(totalPaid);
        }

        public long getMemberId() { return memberId; }
        public String getMemberName() { return memberName; }
        public BigDecimal getTotalPaid() { return totalPaid; }
    }

    public static class ActivityRow {
        private final long activityId;
        private final int dayNumber;
        private final String activityName;
        private final String activityDate;
        private final BigDecimal estimatedCost;
        private final String activityStatus;

        public ActivityRow(long activityId, int dayNumber, String activityName,
                           String activityDate, BigDecimal estimatedCost,
                           String activityStatus) {
            this.activityId = activityId;
            this.dayNumber = dayNumber;
            this.activityName = activityName;
            this.activityDate = activityDate;
            this.estimatedCost = zeroIfNull(estimatedCost);
            this.activityStatus = activityStatus;
        }

        public long getActivityId() { return activityId; }
        public int getDayNumber() { return dayNumber; }
        public String getActivityName() { return activityName; }
        public String getActivityDate() { return activityDate; }
        public BigDecimal getEstimatedCost() { return estimatedCost; }
        public String getActivityStatus() { return activityStatus; }
    }

    public static class PackingRow {
        private final long itemId;
        private final String itemName;
        private final boolean packed;

        public PackingRow(long itemId, String itemName, boolean packed) {
            this.itemId = itemId;
            this.itemName = itemName;
            this.packed = packed;
        }

        public long getItemId() { return itemId; }
        public String getItemName() { return itemName; }
        public boolean isPacked() { return packed; }
    }
}
