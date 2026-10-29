
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseSplitterServlet.TripOption" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseSplitterServlet.Member" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseSplitterServlet.Expense" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseSplitterServlet.Balance" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseSplitterServlet.Settlement" %>

<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }

    private String money(BigDecimal value) {
        if (value == null) value = BigDecimal.ZERO;
        return "₹" + String.format("%,.2f", value);
    }
%>

<%
    List<TripOption> trips = (List<TripOption>) request.getAttribute("trips");
    List<Member> members = (List<Member>) request.getAttribute("members");
    List<Expense> expenses = (List<Expense>) request.getAttribute("expenses");
    List<Balance> balances = (List<Balance>) request.getAttribute("balances");
    List<Settlement> settlements = (List<Settlement>) request.getAttribute("settlements");

    if (trips == null) trips = new java.util.ArrayList<>();
    if (members == null) members = new java.util.ArrayList<>();
    if (expenses == null) expenses = new java.util.ArrayList<>();
    if (balances == null) balances = new java.util.ArrayList<>();
    if (settlements == null) settlements = new java.util.ArrayList<>();

    long tripId = request.getAttribute("tripId") == null
            ? 0L : (Long) request.getAttribute("tripId");

    BigDecimal assignedTotal = (BigDecimal) request.getAttribute("assignedTotal");
    BigDecimal unassignedTotal = (BigDecimal) request.getAttribute("unassignedTotal");

    if (assignedTotal == null) assignedTotal = BigDecimal.ZERO;
    if (unassignedTotal == null) unassignedTotal = BigDecimal.ZERO;

    int unassignedCount = request.getAttribute("unassignedCount") == null
            ? 0 : (Integer) request.getAttribute("unassignedCount");

    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Expense Splitter | TripWise</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f5f7fb;
            color: #182230;
        }

        .layout { display: flex; min-height: 100vh; }

        .sidebar {
            width: 235px;
            flex-shrink: 0;
            background: #151b35;
            color: white;
            padding: 25px 16px;
        }

        .brand {
            font-size: 25px;
            font-weight: 800;
            padding: 0 12px 28px;
        }

        .brand span { color: #a5b4fc; }

        .nav-label {
            color: #9ca3c7;
            font-size: 11px;
            letter-spacing: 1.5px;
            padding: 12px;
        }

        .nav a {
            display: block;
            padding: 12px;
            margin: 4px 0;
            border-radius: 9px;
            color: #d5d9ed;
            text-decoration: none;
            font-size: 14px;
        }

        .nav a:hover, .nav a.active {
            background: #30385f;
            color: white;
        }

        main { flex: 1; min-width: 0; padding: 30px; }

        .top {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 15px;
            flex-wrap: wrap;
            margin-bottom: 24px;
        }

        h1 { font-size: 29px; margin: 0 0 8px; }
        .subtitle { margin: 0; color: #667085; font-size: 14px; }

        .card {
            background: white;
            border: 1px solid #e6e9f0;
            border-radius: 15px;
            padding: 22px;
            margin-bottom: 20px;
            box-shadow: 0 4px 18px rgba(20,30,70,.025);
        }

        .filter {
            display: flex;
            gap: 12px;
            align-items: end;
            flex-wrap: wrap;
        }

        .field { flex: 1; min-width: 230px; }

        label {
            display: block;
            font-size: 13px;
            font-weight: 650;
            margin-bottom: 8px;
        }

        select {
            width: 100%;
            border: 1px solid #d9deea;
            border-radius: 9px;
            padding: 11px;
            background: white;
            font-size: 13px;
        }

        .btn {
            display: inline-block;
            border: 0;
            background: #4f46e5;
            color: white;
            text-decoration: none;
            border-radius: 9px;
            padding: 11px 15px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            white-space: nowrap;
        }

        .btn:hover { background: #4338ca; }
        .btn-small { padding: 8px 10px; font-size: 12px; }

        .stats {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-label { color: #667085; font-size: 13px; margin-bottom: 10px; }
        .stat-value { font-size: 24px; font-weight: 800; overflow-wrap: anywhere; }
        .stat-note { color: #667085; font-size: 12px; margin-top: 8px; }

        .section-heading {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
            margin-bottom: 8px;
        }

        h2 { font-size: 18px; margin: 0; }
        .description { color: #667085; font-size: 13px; line-height: 1.6; margin: 8px 0 18px; }

        .table-wrap { overflow-x: auto; }

        table { width: 100%; border-collapse: collapse; min-width: 700px; }

        th, td {
            text-align: left;
            padding: 13px 10px;
            border-bottom: 1px solid #e9ecf2;
            font-size: 13px;
            vertical-align: middle;
        }

        th {
            background: #fafbfe;
            color: #667085;
            font-weight: 650;
        }

        tbody tr:last-child td { border-bottom: 0; }
        .muted { color: #667085; }

        .payer-form {
            display: flex;
            align-items: center;
            gap: 7px;
            min-width: 235px;
        }

        .payer-form select { min-width: 130px; }

        .balance-positive { color: #07805c; font-weight: 750; }
        .balance-negative { color: #dc2626; font-weight: 750; }

        .status {
            display: inline-block;
            border-radius: 20px;
            padding: 5px 9px;
            background: #fef3c7;
            color: #92400e;
            font-size: 11px;
            font-weight: 750;
        }

        .settlement {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            padding: 16px 0;
            border-bottom: 1px solid #e9ecf2;
        }

        .settlement:last-child { border-bottom: 0; }

        .settlement-people {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 8px;
            font-size: 14px;
        }

        .person {
            display: inline-block;
            background: #eef2ff;
            color: #3730a3;
            padding: 7px 10px;
            border-radius: 8px;
            font-weight: 700;
        }

        .amount { font-weight: 800; color: #07805c; white-space: nowrap; }

        .notice {
            padding: 13px 15px;
            border-radius: 10px;
            font-size: 13px;
            line-height: 1.6;
            margin-bottom: 18px;
        }

        .notice-warning { background: #fff7e6; color: #92400e; border: 1px solid #f6dfaa; }
        .notice-info { background: #eef2ff; color: #3730a3; border: 1px solid #dce3ff; }
        .notice-success { background: #ecfdf3; color: #166534; border: 1px solid #bbf7d0; }

        .empty { padding: 25px 10px; text-align: center; color: #667085; font-size: 14px; }
        .footer { color: #98a2b3; text-align: center; font-size: 12px; padding: 10px 0 20px; }

        @media (max-width: 1000px) {
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }

        @media (max-width: 700px) {
            .layout { display: block; }
            .sidebar { width: 100%; padding: 18px; }
            .brand { padding: 0 8px 12px; }
            .nav { display: flex; overflow-x: auto; gap: 5px; }
            .nav-label { display: none; }
            .nav a { white-space: nowrap; padding: 10px; }
            main { padding: 18px 12px; }
            h1 { font-size: 24px; }
            .card { padding: 16px; }
            .stats { gap: 10px; }
            .stat-value { font-size: 20px; }
        }

        @media print {
            .sidebar, .no-print, .filter-card, .payer-column, .footer { display: none !important; }
            .layout { display: block; }
            main { padding: 0; }
            body { background: white; }
            .card { box-shadow: none; break-inside: avoid; }
        }
    </style>
</head>

<body>
<div class="layout">
    <aside class="sidebar no-print">
        <div class="brand">Trip<span>Wise</span></div>
        <div class="nav-label">Workspace</div>
        <nav class="nav">
            <a href="<%= contextPath %>/">Dashboard</a>
            <a href="<%= contextPath %>/trips">My Trips</a>
            <a href="<%= contextPath %>/expenses">Expenses</a>
            <a href="<%= contextPath %>/itinerary">Itinerary</a>
            <a href="<%= contextPath %>/members">Travellers</a>
            <a href="<%= contextPath %>/packing">Packing List</a>
            <a href="<%= contextPath %>/analytics">Analytics</a>
            <a href="<%= contextPath %>/reports">Reports</a>
            <a class="active" href="<%= contextPath %>/splitter">Expense Splitter</a>
        </nav>
    </aside>

    <main>
        <div class="top">
            <div>
                <h1>Expense Splitter</h1>
                <p class="subtitle">Split shared trip expenses fairly and calculate who owes whom.</p>
            </div>
            <div class="no-print">
                <button class="btn" type="button" onclick="window.print()">Print Settlement</button>
            </div>
        </div>

        <section class="card filter-card no-print">
            <form action="<%= contextPath %>/splitter" method="get" class="filter">
                <div class="field">
                    <label for="tripId">Choose trip</label>
                    <select name="tripId" id="tripId" required>
                        <% for (TripOption t : trips) { %>
                            <option value="<%= t.getTripId() %>"
                                <%= t.getTripId() == tripId ? "selected" : "" %>>
                                <%= esc(t.getTripName()) %> — <%= esc(t.getDestination()) %>
                            </option>
                        <% } %>
                    </select>
                </div>
                <button type="submit" class="btn">Calculate Split</button>
            </form>
        </section>

        <% if (trips.isEmpty()) { %>
            <section class="card">
                <div class="empty">
                    <h2>No trips found</h2>
                    <p>Create a trip first, then add travellers and expenses.</p>
                    <a class="btn" href="<%= contextPath %>/trips">Create a Trip</a>
                </div>
            </section>
        <% } else if (members.isEmpty()) { %>
            <section class="card">
                <div class="empty">
                    <h2>Add travellers to calculate a split</h2>
                    <p>This trip does not have any registered members yet.</p>
                    <a class="btn" href="<%= contextPath %>/members">Add Travellers</a>
                </div>
            </section>
        <% } else { %>

            <% if (unassignedCount > 0) { %>
                <div class="notice notice-warning">
                    <strong><%= unassignedCount %> expense(s) have no payer assigned.</strong>
                    Their combined actual amount is <strong><%= money(unassignedTotal) %></strong>.
                    Assign a payer to each expense below before treating the settlement as final.
                    The current calculation includes only expenses with a recorded payer.
                </div>
            <% } else { %>
                <div class="notice notice-success">
                    All recorded expenses have a payer assigned. The settlement below is calculated
                    from the actual amounts of these expenses.
                </div>
            <% } %>

            <section class="stats">
                <div class="card">
                    <div class="stat-label">Expenses Included in Split</div>
                    <div class="stat-value"><%= money(assignedTotal) %></div>
                    <div class="stat-note">Actual expenses with an assigned payer</div>
                </div>
                <div class="card">
                    <div class="stat-label">Registered Members</div>
                    <div class="stat-value"><%= members.size() %></div>
                    <div class="stat-note">Everyone shares the included total equally</div>
                </div>
                <div class="card">
                    <div class="stat-label">Equal Share per Member</div>
                    <div class="stat-value">
                        <%= money(assignedTotal.divide(
                            BigDecimal.valueOf(members.size()), 2,
                            java.math.RoundingMode.HALF_UP)) %>
                    </div>
                    <div class="stat-note">Based on the included actual expenses</div>
                </div>
            </section>

            <section class="card">
                <div class="section-heading">
                    <h2>Assign Who Paid Each Expense</h2>
                </div>
                <p class="description">
                    Choose the member who actually paid each expense. Changes are saved to your
                    existing <code>TRIP_EXPENSES.PAID_BY_MEMBER_ID</code> column.
                    Only the actual amount is used for the settlement calculation.
                </p>

                <% if (expenses.isEmpty()) { %>
                    <div class="empty">
                        No expenses found for this trip.
                        <br><br>
                        <a class="btn" href="<%= contextPath %>/expenses">Add Expenses</a>
                    </div>
                <% } else { %>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Expense</th>
                                    <th>Actual Amount</th>
                                    <th>Current Payer</th>
                                    <th class="payer-column">Assign / Update Payer</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (Expense e : expenses) { %>
                                <tr>
                                    <td>
                                        <strong><%= esc(e.getCategory()) %></strong>
                                        <div class="muted" style="margin-top:4px;">
                                            <%= esc(e.getDescription()) %>
                                        </div>
                                    </td>
                                    <td><strong><%= money(e.getActual()) %></strong></td>
                                    <td>
                                        <% if (e.getPaidBy() == null) { %>
                                            <span class="status">Not assigned</span>
                                        <% } else { %>
                                            <%= esc(e.getPaidBy()) %>
                                        <% } %>
                                    </td>
                                    <td class="payer-column">
                                        <form class="payer-form" method="post"
                                              action="<%= contextPath %>/splitter">
                                            <input type="hidden" name="tripId" value="<%= tripId %>">
                                            <input type="hidden" name="expenseId" value="<%= e.getExpenseId() %>">

                                            <select name="payerId" aria-label="Select expense payer">
                                                <option value="0">Unassigned</option>
                                                <% for (Member m : members) { %>
                                                    <option value="<%= m.getMemberId() %>"
                                                        <%= e.getPayerId() != null
                                                            && e.getPayerId().longValue() == m.getMemberId()
                                                            ? "selected" : "" %>>
                                                        <%= esc(m.getMemberName()) %>
                                                    </option>
                                                <% } %>
                                            </select>
                                            <button type="submit" class="btn btn-small">Save</button>
                                        </form>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } %>
            </section>

            <section class="card">
                <div class="section-heading">
                    <h2>Member Balances</h2>
                </div>
                <p class="description">
                    A positive balance means the member paid more than their equal share and
                    should receive money back. A negative balance means the member owes money.
                </p>

                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Member</th>
                                <th>Paid</th>
                                <th>Equal Share</th>
                                <th>Net Balance</th>
                                <th>Result</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% for (Balance b : balances) {
                            int comparison = b.getNet().compareTo(BigDecimal.ZERO);
                        %>
                            <tr>
                                <td><strong><%= esc(b.getMemberName()) %></strong></td>
                                <td><%= money(b.getPaid()) %></td>
                                <td><%= money(b.getShare()) %></td>
                                <td class="<%= comparison > 0 ? "balance-positive" :
                                    comparison < 0 ? "balance-negative" : "" %>">
                                    <%= comparison > 0 ? "+" : "" %><%= money(b.getNet()) %>
                                </td>
                                <td>
                                    <% if (comparison > 0) { %>
                                        Receives money
                                    <% } else if (comparison < 0) { %>
                                        Owes money
                                    <% } else { %>
                                        Settled
                                    <% } %>
                                </td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="card">
                <div class="section-heading">
                    <h2>Suggested Settlements</h2>
                    <span class="status"><%= settlements.size() %> transfer(s)</span>
                </div>
                <p class="description">
                    Follow these suggested transfers to balance the included expenses using
                    as few payments as practical.
                </p>

                <% if (unassignedCount > 0) { %>
                    <div class="notice notice-warning">
                        These transfers are provisional until all expenses have an assigned payer.
                    </div>
                <% } %>

                <% if (settlements.isEmpty()) { %>
                    <div class="empty">
                        <% if (assignedTotal.compareTo(BigDecimal.ZERO) == 0) { %>
                            There are no assigned actual expenses to split yet.
                        <% } else { %>
                            Everyone is already balanced. No transfer is needed.
                        <% } %>
                    </div>
                <% } else { %>
                    <% for (Settlement s : settlements) { %>
                        <div class="settlement">
                            <div class="settlement-people">
                                <span class="person"><%= esc(s.getFromMember()) %></span>
                                <span>pays &rarr;</span>
                                <span class="person"><%= esc(s.getToMember()) %></span>
                            </div>
                            <div class="amount"><%= money(s.getAmount()) %></div>
                        </div>
                    <% } %>
                <% } %>
            </section>

        <% } %>

        <div class="footer">TripWise · Expense Splitter</div>
    </main>
</div>
</body>
</html>
