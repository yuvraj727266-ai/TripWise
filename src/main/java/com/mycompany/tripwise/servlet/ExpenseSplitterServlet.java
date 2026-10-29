
package com.mycompany.tripwise.servlet;

import com.mycompany.tripwise.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@WebServlet("/splitter")
public class ExpenseSplitterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        long tripId = parseId(request.getParameter("tripId"));
        List<TripOption> trips = new ArrayList<>();
        List<Member> members = new ArrayList<>();
        List<Expense> expenses = new ArrayList<>();
        List<Balance> balances = new ArrayList<>();
        List<Settlement> settlements = new ArrayList<>();

        BigDecimal assignedTotal = BigDecimal.ZERO;
        BigDecimal unassignedTotal = BigDecimal.ZERO;
        int unassignedCount = 0;

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

            if (tripId == 0 && !trips.isEmpty()) {
                tripId = trips.get(0).getTripId();
            }

            boolean tripExists = false;
            for (TripOption t : trips) {
                if (t.getTripId() == tripId) {
                    tripExists = true;
                    break;
                }
            }

            if (tripExists) {
                String memberSql =
                        "SELECT MEMBER_ID, MEMBER_NAME FROM TRIP_MEMBERS " +
                        "WHERE TRIP_ID = ? ORDER BY MEMBER_ID";

                try (PreparedStatement ps = con.prepareStatement(memberSql)) {
                    ps.setLong(1, tripId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            members.add(new Member(
                                    rs.getLong("MEMBER_ID"),
                                    rs.getString("MEMBER_NAME")
                            ));
                        }
                    }
                }

                String expenseSql =
                        "SELECT E.EXPENSE_ID, E.CATEGORY, E.DESCRIPTION, " +
                        "E.ACTUAL_AMOUNT, E.ESTIMATED_AMOUNT, E.PAID_BY_MEMBER_ID, " +
                        "M.MEMBER_NAME AS PAID_BY " +
                        "FROM TRIP_EXPENSES E " +
                        "LEFT JOIN TRIP_MEMBERS M ON E.PAID_BY_MEMBER_ID = M.MEMBER_ID " +
                        "WHERE E.TRIP_ID = ? " +
                        "ORDER BY E.EXPENSE_ID DESC";

                try (PreparedStatement ps = con.prepareStatement(expenseSql)) {
                    ps.setLong(1, tripId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            BigDecimal actual = rs.getBigDecimal("ACTUAL_AMOUNT");
                            if (actual == null) actual = BigDecimal.ZERO;

                            BigDecimal estimated = rs.getBigDecimal("ESTIMATED_AMOUNT");
                            if (estimated == null) estimated = BigDecimal.ZERO;

                            long payerId = rs.getLong("PAID_BY_MEMBER_ID");
                            Long payer = rs.wasNull() ? null : payerId;

                            Expense expense = new Expense(
                                    rs.getLong("EXPENSE_ID"),
                                    rs.getString("CATEGORY"),
                                    rs.getString("DESCRIPTION"),
                                    estimated,
                                    actual,
                                    payer,
                                    rs.getString("PAID_BY")
                            );
                            expenses.add(expense);

                            if (payer == null) {
                                unassignedTotal = unassignedTotal.add(actual);
                                unassignedCount++;
                            } else {
                                assignedTotal = assignedTotal.add(actual);
                            }
                        }
                    }
                }

                if (!members.isEmpty()) {
                    BigDecimal share = assignedTotal.divide(
                            BigDecimal.valueOf(members.size()),
                            2,
                            RoundingMode.HALF_UP
                    );

                    for (Member member : members) {
                        balances.add(new Balance(
                                member.getMemberId(),
                                member.getMemberName(),
                                BigDecimal.ZERO,
                                share
                        ));
                    }

                    for (Expense expense : expenses) {
                        if (expense.getPayerId() != null) {
                            for (Balance balance : balances) {
                                if (balance.getMemberId() == expense.getPayerId()) {
                                    balance.addPaid(expense.getActual());
                                    break;
                                }
                            }
                        }
                    }

                    for (Balance balance : balances) {
                        balance.calculateNet();
                    }

                    List<Balance> creditors = new ArrayList<>();
                    List<Balance> debtors = new ArrayList<>();

                    for (Balance balance : balances) {
                        if (balance.getNet().compareTo(BigDecimal.ZERO) > 0) {
                            creditors.add(balance.copyWithAmount(balance.getNet()));
                        } else if (balance.getNet().compareTo(BigDecimal.ZERO) < 0) {
                            debtors.add(balance.copyWithAmount(balance.getNet().abs()));
                        }
                    }

                    creditors.sort(Comparator.comparing(Balance::getAmount).reversed());
                    debtors.sort(Comparator.comparing(Balance::getAmount).reversed());

                    int i = 0;
                    int j = 0;

                    while (i < debtors.size() && j < creditors.size()) {
                        Balance debtor = debtors.get(i);
                        Balance creditor = creditors.get(j);

                        BigDecimal transfer = debtor.getAmount().min(creditor.getAmount());

                        if (transfer.compareTo(BigDecimal.ZERO) > 0) {
                            settlements.add(new Settlement(
                                    debtor.getMemberName(),
                                    creditor.getMemberName(),
                                    transfer
                            ));
                        }

                        debtor.setAmount(debtor.getAmount().subtract(transfer));
                        creditor.setAmount(creditor.getAmount().subtract(transfer));

                        if (debtor.getAmount().compareTo(new BigDecimal("0.005")) < 0) i++;
                        if (creditor.getAmount().compareTo(new BigDecimal("0.005")) < 0) j++;
                    }
                }
            }

        } catch (SQLException e) {
            throw new ServletException("Unable to calculate expense split.", e);
        }

        request.setAttribute("trips", trips);
        request.setAttribute("members", members);
        request.setAttribute("expenses", expenses);
        request.setAttribute("balances", balances);
        request.setAttribute("settlements", settlements);
        request.setAttribute("tripId", tripId);
        request.setAttribute("assignedTotal", assignedTotal);
        request.setAttribute("unassignedTotal", unassignedTotal);
        request.setAttribute("unassignedCount", unassignedCount);
        request.setAttribute("hasMembers", !members.isEmpty());

        request.getRequestDispatcher("/splitter.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        long tripId = parseId(request.getParameter("tripId"));
        long expenseId = parseId(request.getParameter("expenseId"));
        long payerId = parseId(request.getParameter("payerId"));

        if (tripId < 1 || expenseId < 1) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid trip or expense.");
            return;
        }

        try (Connection con = DBConnection.getConnection()) {
            if (con == null) {
                throw new SQLException("Database connection returned null.");
            }

            // Confirm the expense belongs to the selected trip.
            boolean expenseExists = false;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM TRIP_EXPENSES WHERE EXPENSE_ID = ? AND TRIP_ID = ?")) {
                ps.setLong(1, expenseId);
                ps.setLong(2, tripId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) expenseExists = rs.getInt(1) == 1;
                }
            }

            if (!expenseExists) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "This expense does not belong to the selected trip.");
                return;
            }

            if (payerId > 0) {
                boolean memberExists = false;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM TRIP_MEMBERS WHERE MEMBER_ID = ? AND TRIP_ID = ?")) {
                    ps.setLong(1, payerId);
                    ps.setLong(2, tripId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) memberExists = rs.getInt(1) == 1;
                    }
                }

                if (!memberExists) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                            "Select a member from this trip.");
                    return;
                }

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE TRIP_EXPENSES SET PAID_BY_MEMBER_ID = ? " +
                        "WHERE EXPENSE_ID = ? AND TRIP_ID = ?")) {
                    ps.setLong(1, payerId);
                    ps.setLong(2, expenseId);
                    ps.setLong(3, tripId);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE TRIP_EXPENSES SET PAID_BY_MEMBER_ID = NULL " +
                        "WHERE EXPENSE_ID = ? AND TRIP_ID = ?")) {
                    ps.setLong(1, expenseId);
                    ps.setLong(2, tripId);
                    ps.executeUpdate();
                }
            }

        } catch (SQLException e) {
            throw new ServletException("Unable to assign expense payer.", e);
        }

        response.sendRedirect(request.getContextPath() + "/splitter?tripId=" + tripId);
    }

    private long parseId(String value) {
        if (value == null || value.trim().isEmpty()) return 0;
        try {
            long id = Long.parseLong(value.trim());
            return id > 0 ? id : 0;
        } catch (NumberFormatException e) {
            return 0;
        }
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

    public static class Member {
        private final long memberId;
        private final String memberName;

        public Member(long memberId, String memberName) {
            this.memberId = memberId;
            this.memberName = memberName;
        }

        public long getMemberId() { return memberId; }
        public String getMemberName() { return memberName; }
    }

    public static class Expense {
        private final long expenseId;
        private final String category;
        private final String description;
        private final BigDecimal estimated;
        private final BigDecimal actual;
        private final Long payerId;
        private final String paidBy;

        public Expense(long expenseId, String category, String description,
                       BigDecimal estimated, BigDecimal actual,
                       Long payerId, String paidBy) {
            this.expenseId = expenseId;
            this.category = category;
            this.description = description;
            this.estimated = estimated;
            this.actual = actual;
            this.payerId = payerId;
            this.paidBy = paidBy;
        }

        public long getExpenseId() { return expenseId; }
        public String getCategory() { return category; }
        public String getDescription() { return description; }
        public BigDecimal getEstimated() { return estimated; }
        public BigDecimal getActual() { return actual; }
        public Long getPayerId() { return payerId; }
        public String getPaidBy() { return paidBy; }
    }

    public static class Balance {
        private final long memberId;
        private final String memberName;
        private BigDecimal paid;
        private final BigDecimal share;
        private BigDecimal net;
        private BigDecimal amount;

        public Balance(long memberId, String memberName, BigDecimal paid, BigDecimal share) {
            this.memberId = memberId;
            this.memberName = memberName;
            this.paid = paid;
            this.share = share;
            this.net = BigDecimal.ZERO;
            this.amount = BigDecimal.ZERO;
        }

        public void addPaid(BigDecimal value) { paid = paid.add(value); }
        public void calculateNet() { net = paid.subtract(share); }

        public Balance copyWithAmount(BigDecimal value) {
            Balance copy = new Balance(memberId, memberName, paid, share);
            copy.net = net;
            copy.amount = value;
            return copy;
        }

        public long getMemberId() { return memberId; }
        public String getMemberName() { return memberName; }
        public BigDecimal getPaid() { return paid; }
        public BigDecimal getShare() { return share; }
        public BigDecimal getNet() { return net; }
        public BigDecimal getAmount() { return amount; }
        public void setAmount(BigDecimal amount) { this.amount = amount; }
    }

    public static class Settlement {
        private final String fromMember;
        private final String toMember;
        private final BigDecimal amount;

        public Settlement(String fromMember, String toMember, BigDecimal amount) {
            this.fromMember = fromMember;
            this.toMember = toMember;
            this.amount = amount;
        }

        public String getFromMember() { return fromMember; }
        public String getToMember() { return toMember; }
        public BigDecimal getAmount() { return amount; }
    }
}
