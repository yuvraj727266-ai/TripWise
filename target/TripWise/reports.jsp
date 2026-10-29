
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mycompany.tripwise.servlet.ReportServlet.TripOption" %>
<%@ page import="com.mycompany.tripwise.servlet.ReportServlet.TripDetails" %>
<%@ page import="com.mycompany.tripwise.servlet.ReportServlet.ExpenseRow" %>
<%@ page import="com.mycompany.tripwise.servlet.ReportServlet.MemberRow" %>
<%@ page import="com.mycompany.tripwise.servlet.ReportServlet.ActivityRow" %>
<%@ page import="com.mycompany.tripwise.servlet.ReportServlet.PackingRow" %>

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
    List<TripOption> trips =
        (List<TripOption>) request.getAttribute("trips");
    TripDetails trip = (TripDetails) request.getAttribute("selectedTrip");

    List<ExpenseRow> expenses =
        (List<ExpenseRow>) request.getAttribute("expenses");
    List<MemberRow> members =
        (List<MemberRow>) request.getAttribute("members");
    List<ActivityRow> activities =
        (List<ActivityRow>) request.getAttribute("activities");
    List<PackingRow> packingItems =
        (List<PackingRow>) request.getAttribute("packingItems");

    BigDecimal estimatedTotal =
        (BigDecimal) request.getAttribute("estimatedTotal");
    BigDecimal actualTotal =
        (BigDecimal) request.getAttribute("actualTotal");
    BigDecimal budgetRemaining =
        (BigDecimal) request.getAttribute("budgetRemaining");

    if (trips == null) trips = new java.util.ArrayList<>();
    if (expenses == null) expenses = new java.util.ArrayList<>();
    if (members == null) members = new java.util.ArrayList<>();
    if (activities == null) activities = new java.util.ArrayList<>();
    if (packingItems == null) packingItems = new java.util.ArrayList<>();

    if (estimatedTotal == null) estimatedTotal = BigDecimal.ZERO;
    if (actualTotal == null) actualTotal = BigDecimal.ZERO;
    if (budgetRemaining == null) budgetRemaining = BigDecimal.ZERO;

    int packedCount = 0;
    for (PackingRow item : packingItems) {
        if (item.isPacked()) packedCount++;
    }

    int completedActivities = 0;
    for (ActivityRow activity : activities) {
        if ("COMPLETED".equalsIgnoreCase(activity.getActivityStatus())) {
            completedActivities++;
        }
    }

    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trip Reports | TripWise</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            background: #f4f6fb;
            color: #182230;
            font-family: "Segoe UI", Arial, sans-serif;
        }

        .layout { display: flex; min-height: 100vh; }

        .sidebar {
            width: 235px;
            background: #151b35;
            color: white;
            padding: 25px 16px;
            flex-shrink: 0;
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
            gap: 16px;
            flex-wrap: wrap;
            margin-bottom: 22px;
        }

        h1 { font-size: 28px; margin: 0 0 8px; }
        .subtitle { margin: 0; color: #667085; font-size: 14px; }

        .actions { display: flex; gap: 10px; flex-wrap: wrap; }

        .btn {
            display: inline-block;
            border: 0;
            border-radius: 9px;
            padding: 11px 16px;
            background: #4f46e5;
            color: white;
            text-decoration: none;
            font-weight: 650;
            font-size: 13px;
            cursor: pointer;
        }

        .btn-secondary { background: white; color: #344054; border: 1px solid #dfe3eb; }

        .card {
            background: white;
            border: 1px solid #e6e9f0;
            border-radius: 14px;
            padding: 22px;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgba(20, 30, 70, .025);
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
            padding: 12px;
            border: 1px solid #d9deea;
            border-radius: 9px;
            background: white;
            color: #182230;
            font-size: 14px;
        }

        .section-title {
            font-size: 17px;
            margin: 0 0 18px;
            font-weight: 750;
        }

        .trip-hero {
            background: linear-gradient(125deg, #202952, #4f46e5);
            color: white;
            border: 0;
        }

        .trip-hero .eyebrow {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1.6px;
            color: #c7d2fe;
            margin-bottom: 10px;
        }

        .trip-hero h2 { font-size: 30px; margin: 0 0 8px; }
        .trip-hero p { margin: 0; color: #e0e7ff; font-size: 14px; }

        .hero-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-top: 25px;
        }

        .hero-item {
            background: rgba(255,255,255,.1);
            border: 1px solid rgba(255,255,255,.14);
            border-radius: 11px;
            padding: 14px;
            min-width: 0;
        }

        .hero-item span {
            display: block;
            font-size: 12px;
            color: #dbe2ff;
            margin-bottom: 8px;
        }

        .hero-item strong { font-size: 16px; overflow-wrap: anywhere; }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 20px;
        }

        .stat-label { color: #667085; font-size: 13px; margin-bottom: 10px; }
        .stat-value { font-size: 23px; font-weight: 800; overflow-wrap: anywhere; }
        .green { color: #159b72; }
        .red { color: #dc2626; }

        .section-heading {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
            margin-bottom: 14px;
        }

        .count {
            font-size: 12px;
            color: #4f46e5;
            background: #eef2ff;
            padding: 6px 10px;
            border-radius: 20px;
            font-weight: 700;
        }

        .table-wrap { overflow-x: auto; }

        table { border-collapse: collapse; width: 100%; min-width: 600px; }

        th, td {
            text-align: left;
            padding: 12px 10px;
            border-bottom: 1px solid #e9ecf2;
            font-size: 13px;
            vertical-align: top;
        }

        th {
            color: #667085;
            background: #fafbfe;
            font-weight: 650;
        }

        tbody tr:last-child td { border-bottom: 0; }

        .muted { color: #667085; }
        .empty { color: #667085; text-align: center; padding: 25px 10px; font-size: 14px; }

        .status {
            display: inline-block;
            border-radius: 20px;
            padding: 5px 9px;
            font-size: 11px;
            font-weight: 700;
            background: #f2f4f7;
            color: #475467;
        }

        .status-done { background: #dcfce7; color: #166534; }
        .status-pending { background: #fef3c7; color: #92400e; }

        .packing-progress {
            height: 8px;
            background: #e9ecf5;
            border-radius: 20px;
            overflow: hidden;
            margin-top: 12px;
        }

        .packing-fill {
            height: 100%;
            background: #159b72;
            border-radius: 20px;
        }

        .footer { text-align: center; color: #98a2b3; font-size: 12px; padding: 8px 0 20px; }

        @media (max-width: 1100px) {
            .stats, .hero-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }

        @media (max-width: 700px) {
            .layout { display: block; }
            .sidebar { width: 100%; padding: 18px; }
            .brand { padding: 0 8px 12px; }
            .nav { display: flex; overflow-x: auto; gap: 5px; }
            .nav-label { display: none; }
            .nav a { white-space: nowrap; padding: 10px; }
            main { padding: 18px 12px; }
            .card { padding: 16px; }
            h1 { font-size: 24px; }
            .trip-hero h2 { font-size: 25px; }
            .stat-value { font-size: 19px; }
        }

        @media print {
            body { background: white; }
            .sidebar, .no-print, .filter-card, .footer { display: none !important; }
            .layout { display: block; }
            main { padding: 0; }
            .card { box-shadow: none; break-inside: avoid; margin-bottom: 12px; }
            .trip-hero {
                background: white !important;
                color: #182230 !important;
                border: 1px solid #ddd;
            }
            .trip-hero .eyebrow, .trip-hero p, .hero-item span {
                color: #475467 !important;
            }
            .hero-item {
                background: white !important;
                border-color: #ddd !important;
            }
            .hero-item strong { color: #182230 !important; }
            h1 { font-size: 24px; }
            th, td { padding: 8px; }
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
            <a class="active" href="<%= contextPath %>/reports">Reports</a>
        </nav>
    </aside>

    <main>
        <div class="top">
            <div>
                <h1>Trip Reports</h1>
                <p class="subtitle">A printable summary of your trip, spending, activities and packing progress.</p>
            </div>

            <% if (trip != null) { %>
            <div class="actions no-print">
                <button class="btn" onclick="window.print()">Print / Save PDF</button>
            </div>
            <% } %>
        </div>

        <section class="card filter-card no-print">
            <form action="<%= contextPath %>/reports" method="get" class="filter">
                <div class="field">
                    <label for="tripId">Select a trip to generate its report</label>
                    <select id="tripId" name="tripId" required>
                        <% for (TripOption option : trips) { %>
                            <option value="<%= option.getTripId() %>"
                                <%= trip != null && trip.getTripId() == option.getTripId()
                                    ? "selected" : "" %>>
                                <%= esc(option.getTripName()) %> — <%= esc(option.getDestination()) %>
                            </option>
                        <% } %>
                    </select>
                </div>
                <button class="btn" type="submit">Generate Report</button>
            </form>
        </section>

        <% if (trip == null) { %>
            <section class="card">
                <div class="empty">
                    <h2>No trip report available</h2>
                    <p>Create a trip first, then return here to generate its report.</p>
                    <a class="btn no-print" href="<%= contextPath %>/trips">Go to My Trips</a>
                </div>
            </section>
        <% } else { %>

            <section class="card trip-hero">
                <div class="eyebrow">TripWise · Trip Summary Report</div>
                <h2><%= esc(trip.getTripName()) %></h2>
                <p><%= esc(trip.getOriginCity()) %> &rarr; <%= esc(trip.getDestination()) %></p>

                <div class="hero-grid">
                    <div class="hero-item">
                        <span>Departure</span>
                        <strong><%= esc(trip.getStartDate()) %></strong>
                    </div>
                    <div class="hero-item">
                        <span>Return</span>
                        <strong><%= esc(trip.getEndDate()) %></strong>
                    </div>
                    <div class="hero-item">
                        <span>Trip Type</span>
                        <strong><%= esc(trip.getTripType()) %></strong>
                    </div>
                    <div class="hero-item">
                        <span>Travellers (planned)</span>
                        <strong><%= trip.getTravellerCount() %></strong>
                    </div>
                </div>
            </section>

            <section class="stats">
                <div class="card">
                    <div class="stat-label">Trip Budget</div>
                    <div class="stat-value"><%= money(trip.getTotalBudget()) %></div>
                </div>
                <div class="card">
                    <div class="stat-label">Estimated Expenses</div>
                    <div class="stat-value"><%= money(estimatedTotal) %></div>
                </div>
                <div class="card">
                    <div class="stat-label">Actual Expenses</div>
                    <div class="stat-value"><%= money(actualTotal) %></div>
                </div>
                <div class="card">
                    <div class="stat-label">Budget Remaining</div>
                    <div class="stat-value <%= budgetRemaining.compareTo(BigDecimal.ZERO) < 0 ? "red" : "green" %>">
                        <%= money(budgetRemaining) %>
                    </div>
                </div>
            </section>

            <section class="card">
                <div class="section-heading">
                    <h2 class="section-title">Expense Details</h2>
                    <span class="count"><%= expenses.size() %> expenses</span>
                </div>

                <% if (expenses.isEmpty()) { %>
                    <div class="empty">No expenses have been recorded for this trip.</div>
                <% } else { %>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Category</th>
                                    <th>Description</th>
                                    <th>Paid By</th>
                                    <th>Estimated</th>
                                    <th>Actual</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (ExpenseRow expense : expenses) { %>
                                <tr>
                                    <td><%= esc(expense.getExpenseDate()) %></td>
                                    <td><%= esc(expense.getCategory()) %></td>
                                    <td><%= esc(expense.getDescription()) %></td>
                                    <td><%= expense.getPaidBy() == null ? "Not assigned" : esc(expense.getPaidBy()) %></td>
                                    <td><%= money(expense.getEstimated()) %></td>
                                    <td><strong><%= money(expense.getActual()) %></strong></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } %>
            </section>

            <section class="card">
                <div class="section-heading">
                    <h2 class="section-title">Travellers</h2>
                    <span class="count"><%= members.size() %> registered</span>
                </div>

                <% if (members.isEmpty()) { %>
                    <div class="empty">No travellers have been added to this trip yet.</div>
                <% } else { %>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Traveller Name</th>
                                    <th>Recorded Actual Expenses Paid</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% int memberIndex = 1;
                               for (MemberRow member : members) { %>
                                <tr>
                                    <td><%= memberIndex++ %></td>
                                    <td><strong><%= esc(member.getMemberName()) %></strong></td>
                                    <td><%= money(member.getTotalPaid()) %></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                    <p class="muted" style="font-size:12px;">
                        Amounts reflect expenses explicitly assigned to each traveller.
                        Unassigned expenses are not attributed to a traveller.
                    </p>
                <% } %>
            </section>

            <section class="card">
                <div class="section-heading">
                    <h2 class="section-title">Itinerary</h2>
                    <span class="count"><%= completedActivities %> of <%= activities.size() %> completed</span>
                </div>

                <% if (activities.isEmpty()) { %>
                    <div class="empty">No itinerary activities have been planned.</div>
                <% } else { %>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Day</th>
                                    <th>Date</th>
                                    <th>Activity</th>
                                    <th>Estimated Cost</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (ActivityRow activity : activities) {
                                boolean done = "COMPLETED".equalsIgnoreCase(activity.getActivityStatus());
                            %>
                                <tr>
                                    <td>Day <%= activity.getDayNumber() %></td>
                                    <td><%= esc(activity.getActivityDate()) %></td>
                                    <td><%= esc(activity.getActivityName()) %></td>
                                    <td><%= money(activity.getEstimatedCost()) %></td>
                                    <td>
                                        <span class="status <%= done ? "status-done" : "status-pending" %>">
                                            <%= esc(activity.getActivityStatus()) %>
                                        </span>
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
                    <h2 class="section-title">Packing Checklist</h2>
                    <span class="count"><%= packedCount %> of <%= packingItems.size() %> packed</span>
                </div>

                <% if (packingItems.isEmpty()) { %>
                    <div class="empty">No packing items have been added to this trip.</div>
                <% } else { %>
                    <div class="packing-progress">
                        <div class="packing-fill"
                             style="width:<%= Math.round(packedCount * 100.0 / packingItems.size()) %>%;"></div>
                    </div>
                    <p class="muted" style="font-size:13px;">
                        Packing progress: <%= Math.round(packedCount * 100.0 / packingItems.size()) %>%
                    </p>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Item</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (PackingRow item : packingItems) { %>
                                <tr>
                                    <td><%= esc(item.getItemName()) %></td>
                                    <td>
                                        <span class="status <%= item.isPacked() ? "status-done" : "status-pending" %>">
                                            <%= item.isPacked() ? "Packed" : "Not packed" %>
                                        </span>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } %>
            </section>

            <section class="card">
                <h2 class="section-title">Financial Summary</h2>
                <div class="table-wrap">
                    <table>
                        <tbody>
                            <tr>
                                <td>Total trip budget</td>
                                <td><strong><%= money(trip.getTotalBudget()) %></strong></td>
                            </tr>
                            <tr>
                                <td>Total estimated expenses recorded</td>
                                <td><%= money(estimatedTotal) %></td>
                            </tr>
                            <tr>
                                <td>Total actual expenses recorded</td>
                                <td><%= money(actualTotal) %></td>
                            </tr>
                            <tr>
                                <td>Difference between actual and estimated expenses</td>
                                <td>
                                    <strong><%= money(actualTotal.subtract(estimatedTotal)) %></strong>
                                </td>
                            </tr>
                            <tr>
                                <td>Budget remaining (budget minus recorded actual expenses)</td>
                                <td>
                                    <strong class="<%= budgetRemaining.compareTo(BigDecimal.ZERO) < 0 ? "red" : "green" %>">
                                        <%= money(budgetRemaining) %>
                                    </strong>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <p class="muted" style="font-size:12px;margin-top:15px;">
                    This report reflects the records currently saved in TripWise.
                    Amounts are based on recorded expenses, not necessarily every cost of the trip.
                </p>
            </section>

        <% } %>

        <div class="footer">TripWise · Generated from your saved trip records</div>
    </main>
</div>
</body>
</html>
