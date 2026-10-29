
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mycompany.tripwise.servlet.AnalyticsServlet.CategoryStat" %>
<%@ page import="com.mycompany.tripwise.servlet.AnalyticsServlet.TripStat" %>

<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }

    private String jsString(String value) {
        if (value == null) return "\"\"";
        return "\"" + value.replace("\\", "\\\\")
                           .replace("\"", "\\\"")
                           .replace("\r", "\\r")
                           .replace("\n", "\\n")
                           .replace("<", "\\u003c")
                           .replace(">", "\\u003e")
                           .replace("&", "\\u0026") + "\"";
    }

    private String money(BigDecimal amount) {
        if (amount == null) return "₹0.00";
        return "₹" + String.format("%,.2f", amount);
    }
%>

<%
    BigDecimal totalBudget = (BigDecimal) request.getAttribute("totalBudget");
    BigDecimal estimatedExpenses = (BigDecimal) request.getAttribute("estimatedExpenses");
    BigDecimal actualExpenses = (BigDecimal) request.getAttribute("actualExpenses");

    if (totalBudget == null) totalBudget = BigDecimal.ZERO;
    if (estimatedExpenses == null) estimatedExpenses = BigDecimal.ZERO;
    if (actualExpenses == null) actualExpenses = BigDecimal.ZERO;

    List<CategoryStat> categoryStats =
        (List<CategoryStat>) request.getAttribute("categoryStats");
    List<TripStat> tripStats =
        (List<TripStat>) request.getAttribute("tripStats");

    if (categoryStats == null) categoryStats = new java.util.ArrayList<>();
    if (tripStats == null) tripStats = new java.util.ArrayList<>();

    BigDecimal budgetRemaining = totalBudget.subtract(actualExpenses);
    BigDecimal variance = actualExpenses.subtract(estimatedExpenses);

    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics & Insights | TripWise</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --bg: #f5f7fb;
            --card: #ffffff;
            --text: #182230;
            --muted: #667085;
            --border: #e7eaf0;
            --primary: #4f46e5;
            --green: #159b72;
            --orange: #d97706;
            --red: #dc2626;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Inter, "Segoe UI", Arial, sans-serif;
            color: var(--text);
            background: var(--bg);
        }

        .layout { min-height: 100vh; display: flex; }

        .sidebar {
            width: 235px;
            background: #151b35;
            color: white;
            padding: 26px 16px;
            flex-shrink: 0;
        }

        .brand {
            font-size: 25px;
            font-weight: 800;
            padding: 0 12px 30px;
        }

        .brand span { color: #a5b4fc; }

        .nav-label {
            color: #9ca3c7;
            font-size: 11px;
            letter-spacing: 1.5px;
            padding: 12px;
            text-transform: uppercase;
        }

        .nav a {
            display: block;
            color: #d5d9ed;
            text-decoration: none;
            padding: 12px;
            margin: 4px 0;
            border-radius: 9px;
            font-size: 14px;
        }

        .nav a:hover, .nav a.active { background: #30385f; color: white; }

        main { flex: 1; min-width: 0; padding: 32px; }

        .top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
            margin-bottom: 26px;
        }

        h1 { font-size: 29px; margin: 0 0 8px; }
        .subtitle { color: var(--muted); margin: 0; font-size: 14px; }

        .button {
            background: var(--primary);
            color: white;
            text-decoration: none;
            border-radius: 9px;
            padding: 11px 16px;
            font-size: 14px;
            font-weight: 650;
            border: 0;
            cursor: pointer;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 22px;
        }

        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 15px;
            padding: 21px;
            box-shadow: 0 4px 18px rgba(20, 30, 70, 0.025);
        }

        .stat-label { color: var(--muted); font-size: 13px; margin-bottom: 12px; }
        .stat-value { font-size: 25px; font-weight: 800; overflow-wrap: anywhere; }
        .stat-note { color: var(--muted); font-size: 12px; margin-top: 9px; }
        .green { color: var(--green); }
        .orange { color: var(--orange); }
        .red { color: var(--red); }

        .section-grid {
            display: grid;
            grid-template-columns: minmax(0, 1.15fr) minmax(0, 1fr);
            gap: 18px;
            margin-bottom: 22px;
        }

        .card-heading {
            font-size: 17px;
            font-weight: 750;
            margin: 0 0 6px;
        }

        .card-subtitle { color: var(--muted); font-size: 13px; margin: 0 0 20px; }
        .chart-box { height: 290px; position: relative; }

        .table-wrap { width: 100%; overflow-x: auto; }

        table { width: 100%; border-collapse: collapse; min-width: 690px; }
        th, td {
            text-align: left;
            padding: 14px 12px;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
            white-space: nowrap;
        }

        th {
            color: var(--muted);
            font-weight: 650;
            background: #fafbfe;
        }

        tbody tr:last-child td { border-bottom: 0; }
        .trip-name { font-weight: 700; }
        .destination { color: var(--muted); font-size: 12px; margin-top: 4px; }

        .status {
            display: inline-block;
            padding: 6px 9px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 750;
        }

        .status-ok { background: #dcfce7; color: #166534; }
        .status-near { background: #fef3c7; color: #92400e; }
        .status-over { background: #fee2e2; color: #991b1b; }

        .progress {
            height: 6px;
            border-radius: 10px;
            background: #e9ecf5;
            overflow: hidden;
            margin-top: 7px;
            min-width: 70px;
        }

        .progress-fill { height: 100%; border-radius: 10px; background: var(--primary); }
        .insights { display: grid; gap: 12px; }

        .insight {
            display: flex;
            gap: 12px;
            align-items: flex-start;
            background: #fafbff;
            border: 1px solid var(--border);
            border-radius: 11px;
            padding: 14px;
        }

        .insight-icon {
            display: grid;
            place-items: center;
            width: 34px;
            height: 34px;
            flex-shrink: 0;
            border-radius: 10px;
            background: #eef2ff;
        }

        .insight strong { display: block; font-size: 13px; margin: 2px 0 5px; }
        .insight p { margin: 0; font-size: 12px; color: var(--muted); line-height: 1.6; }

        .empty { text-align: center; color: var(--muted); padding: 35px 12px; font-size: 14px; }
        .footer { text-align: center; color: var(--muted); font-size: 12px; padding: 24px 0 4px; }

        @media (max-width: 1100px) {
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .section-grid { grid-template-columns: 1fr; }
        }

        @media (max-width: 700px) {
            .layout { display: block; }
            .sidebar { width: 100%; padding: 18px; }
            .brand { padding: 0 8px 14px; }
            .nav { display: flex; overflow-x: auto; gap: 5px; }
            .nav-label { display: none; }
            .nav a { white-space: nowrap; padding: 10px; }
            main { padding: 20px 14px; }
            h1 { font-size: 24px; }
            .stats { gap: 10px; }
            .card { padding: 16px; }
            .stat-value { font-size: 20px; }
        }

        @media print {
            .sidebar, .button { display: none !important; }
            .layout { display: block; }
            main { padding: 0; }
            body { background: white; }
            .card { box-shadow: none; break-inside: avoid; }
        }
    </style>
</head>

<body>
<div class="layout">
    <aside class="sidebar">
        <div class="brand">Trip<span>Wise</span></div>
        <div class="nav-label">Workspace</div>
        <nav class="nav">
            <a href="<%= contextPath %>/">Dashboard</a>
            <a href="<%= contextPath %>/trips">My Trips</a>
            <a href="<%= contextPath %>/expenses">Expenses</a>
            <a href="<%= contextPath %>/itinerary">Itinerary</a>
            <a href="<%= contextPath %>/members">Travellers</a>
            <a href="<%= contextPath %>/packing">Packing List</a>
            <a class="active" href="<%= contextPath %>/analytics">Analytics</a>
            <a href="<%= contextPath %>/reports">Reports</a>
        </nav>
    </aside>

    <main>
        <div class="top">
            <div>
                <h1>Analytics & Insights</h1>
                <p class="subtitle">Understand your spending and keep every trip within budget.</p>
            </div>
            <button class="button" onclick="window.print()">Print Analytics</button>
        </div>

        <section class="stats">
            <div class="card">
                <div class="stat-label">Total Trip Budgets</div>
                <div class="stat-value"><%= money(totalBudget) %></div>
                <div class="stat-note">Combined budget of all trips</div>
            </div>

            <div class="card">
                <div class="stat-label">Estimated Expenses</div>
                <div class="stat-value"><%= money(estimatedExpenses) %></div>
                <div class="stat-note">Planned expense amounts</div>
            </div>

            <div class="card">
                <div class="stat-label">Actual Expenses</div>
                <div class="stat-value"><%= money(actualExpenses) %></div>
                <div class="stat-note">Recorded actual spending</div>
            </div>

            <div class="card">
                <div class="stat-label">Budget Remaining</div>
                <div class="stat-value <%= budgetRemaining.compareTo(BigDecimal.ZERO) < 0 ? "red" : "green" %>">
                    <%= money(budgetRemaining) %>
                </div>
                <div class="stat-note">Combined budget minus actual spending</div>
            </div>
        </section>

        <section class="section-grid">
            <div class="card">
                <h2 class="card-heading">Category-wise Spending</h2>
                <p class="card-subtitle">Estimated costs compared with actual costs.</p>
                <% if (categoryStats.isEmpty()) { %>
                    <div class="empty">No expense data yet. Add expenses to see your category analysis.</div>
                <% } else { %>
                    <div class="chart-box"><canvas id="categoryChart"></canvas></div>
                <% } %>
            </div>

            <div class="card">
                <h2 class="card-heading">Trip Budget Comparison</h2>
                <p class="card-subtitle">Actual spending versus the budget set for each trip.</p>
                <% if (tripStats.isEmpty()) { %>
                    <div class="empty">No trips found. Create a trip to see the comparison.</div>
                <% } else { %>
                    <div class="chart-box"><canvas id="budgetChart"></canvas></div>
                <% } %>
            </div>
        </section>

        <section class="card" style="margin-bottom:22px;">
            <h2 class="card-heading">Trip Budget Breakdown</h2>
            <p class="card-subtitle">Check each trip's spending, remaining budget and status.</p>

            <% if (tripStats.isEmpty()) { %>
                <div class="empty">
                    You haven't created a trip yet.
                    <br><br>
                    <a class="button" href="<%= contextPath %>/trips">Create Your First Trip</a>
                </div>
            <% } else { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Trip</th>
                                <th>Budget</th>
                                <th>Estimated</th>
                                <th>Actual Spent</th>
                                <th>Remaining</th>
                                <th>Budget Used</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% for (TripStat trip : tripStats) {
                            String statusClass = "status-ok";
                            if ("Over budget".equals(trip.getBudgetStatus())) {
                                statusClass = "status-over";
                            } else if ("Near budget".equals(trip.getBudgetStatus())) {
                                statusClass = "status-near";
                            }

                            double progress = Math.min(100.0, trip.getUsedPercent());
                            String progressColor = "var(--primary)";
                            if ("Over budget".equals(trip.getBudgetStatus())) {
                                progressColor = "var(--red)";
                            } else if ("Near budget".equals(trip.getBudgetStatus())) {
                                progressColor = "var(--orange)";
                            }
                        %>
                            <tr>
                                <td>
                                    <div class="trip-name"><%= esc(trip.getTripName()) %></div>
                                    <div class="destination"><%= esc(trip.getDestination()) %></div>
                                </td>
                                <td><%= money(trip.getBudget()) %></td>
                                <td><%= money(trip.getEstimated()) %></td>
                                <td><strong><%= money(trip.getActual()) %></strong></td>
                                <td class="<%= trip.getRemaining().compareTo(BigDecimal.ZERO) < 0 ? "red" : "" %>">
                                    <%= money(trip.getRemaining()) %>
                                </td>
                                <td>
                                    <%= String.format("%.1f", trip.getUsedPercent()) %>%
                                    <div class="progress">
                                        <div class="progress-fill"
                                             style="width:<%= progress %>%;background:<%= progressColor %>;"></div>
                                    </div>
                                </td>
                                <td>
                                    <span class="status <%= statusClass %>">
                                        <%= esc(trip.getBudgetStatus()) %>
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
            <h2 class="card-heading">Smart Budget Insights</h2>
            <p class="card-subtitle">Rule-based suggestions calculated from your current trip and expense data.</p>

            <div class="insights">
                <%
                    boolean hasOverBudget = false;
                    boolean hasNearBudget = false;
                    TripStat highestTrip = null;
                    BigDecimal highestActual = BigDecimal.ZERO;

                    for (TripStat trip : tripStats) {
                        if ("Over budget".equals(trip.getBudgetStatus())) {
                            hasOverBudget = true;
                        } else if ("Near budget".equals(trip.getBudgetStatus())) {
                            hasNearBudget = true;
                        }

                        if (trip.getActual().compareTo(highestActual) > 0) {
                            highestActual = trip.getActual();
                            highestTrip = trip;
                        }
                    }
                %>

                <% if (tripStats.isEmpty()) { %>
                    <div class="insight">
                        <div class="insight-icon">🧭</div>
                        <div>
                            <strong>Start by creating a trip</strong>
                            <p>Add a trip and enter its budget. Then record estimated and actual expenses to receive budget insights.</p>
                        </div>
                    </div>
                <% } else { %>

                    <% if (hasOverBudget) { %>
                        <div class="insight">
                            <div class="insight-icon">⚠️</div>
                            <div>
                                <strong>One or more trips are over budget</strong>
                                <p>Actual expenses exceed the budget for at least one trip. Review non-essential spending and update any inaccurate expense records.</p>
                            </div>
                        </div>
                    <% } else if (hasNearBudget) { %>
                        <div class="insight">
                            <div class="insight-icon">📊</div>
                            <div>
                                <strong>Some trips are nearing their budgets</strong>
                                <p>At least one trip has used 80% or more of its budget. Check upcoming costs before making additional plans.</p>
                            </div>
                        </div>
                    <% } else { %>
                        <div class="insight">
                            <div class="insight-icon">✅</div>
                            <div>
                                <strong>Your trips are within their budgets</strong>
                                <p>No trip currently exceeds 80% of its positive budget. Keep recording expenses to maintain an accurate picture.</p>
                            </div>
                        </div>
                    <% } %>

                    <% if (variance.compareTo(BigDecimal.ZERO) > 0) { %>
                        <div class="insight">
                            <div class="insight-icon">💸</div>
                            <div>
                                <strong>Actual spending is above estimates</strong>
                                <p>Your recorded actual expenses exceed estimates by <b><%= money(variance) %></b>. Review the expense records to find where costs increased.</p>
                            </div>
                        </div>
                    <% } else if (variance.compareTo(BigDecimal.ZERO) < 0) { %>
                        <div class="insight">
                            <div class="insight-icon">🌱</div>
                            <div>
                                <strong>Spending is below estimates</strong>
                                <p>Your recorded actual expenses are <b><%= money(variance.abs()) %></b> below estimates overall.</p>
                            </div>
                        </div>
                    <% } else { %>
                        <div class="insight">
                            <div class="insight-icon">🧾</div>
                            <div>
                                <strong>Estimated and actual expenses match</strong>
                                <p>Based on the current records, total actual spending equals total estimated expenses.</p>
                            </div>
                        </div>
                    <% } %>

                    <% if (highestTrip != null) { %>
                        <div class="insight">
                            <div class="insight-icon">📍</div>
                            <div>
                                <strong>Highest-spending trip: <%= esc(highestTrip.getTripName()) %></strong>
                                <p>This trip currently has the highest actual spending at <b><%= money(highestTrip.getActual()) %></b>. Review its expense breakdown if you want to identify possible savings.</p>
                            </div>
                        </div>
                    <% } %>

                    <% if (categoryStats.isEmpty()) { %>
                        <div class="insight">
                            <div class="insight-icon">➕</div>
                            <div>
                                <strong>Add expense records for more insights</strong>
                                <p>Category comparisons become available after you record trip expenses.</p>
                            </div>
                        </div>
                    <% } else { %>
                        <%
                            CategoryStat highestCategory = categoryStats.get(0);
                            for (CategoryStat category : categoryStats) {
                                if (category.getActual().compareTo(highestCategory.getActual()) > 0) {
                                    highestCategory = category;
                                }
                            }
                        %>
                        <div class="insight">
                            <div class="insight-icon">🔎</div>
                            <div>
                                <strong>Review the <%= esc(highestCategory.getCategory()) %> category</strong>
                                <p>It has the highest actual spending among your expense categories at <b><%= money(highestCategory.getActual()) %></b>. Check whether any costs can be reduced on future trips.</p>
                            </div>
                        </div>
                    <% } %>
                <% } %>
            </div>
        </section>

        <div class="footer">TripWise · Smart Trip Planner & Budget Optimizer</div>
    </main>
</div>

<script>
    const categoryLabels = [
        <% for (int i = 0; i < categoryStats.size(); i++) { %>
            <%= i > 0 ? "," : "" %><%= jsString(categoryStats.get(i).getCategory()) %>
        <% } %>
    ];

    const categoryEstimated = [
        <% for (int i = 0; i < categoryStats.size(); i++) { %>
            <%= i > 0 ? "," : "" %><%= categoryStats.get(i).getEstimated().toPlainString() %>
        <% } %>
    ];

    const categoryActual = [
        <% for (int i = 0; i < categoryStats.size(); i++) { %>
            <%= i > 0 ? "," : "" %><%= categoryStats.get(i).getActual().toPlainString() %>
        <% } %>
    ];

    const tripLabels = [
        <% for (int i = 0; i < tripStats.size(); i++) { %>
            <%= i > 0 ? "," : "" %><%= jsString(tripStats.get(i).getTripName()) %>
        <% } %>
    ];

    const tripBudgets = [
        <% for (int i = 0; i < tripStats.size(); i++) { %>
            <%= i > 0 ? "," : "" %><%= tripStats.get(i).getBudget().toPlainString() %>
        <% } %>
    ];

    const tripActuals = [
        <% for (int i = 0; i < tripStats.size(); i++) { %>
            <%= i > 0 ? "," : "" %><%= tripStats.get(i).getActual().toPlainString() %>
        <% } %>
    ];

    const chartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { position: 'bottom' },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        return context.dataset.label + ': ₹' +
                            Number(context.raw).toLocaleString('en-IN', {
                                maximumFractionDigits: 2
                            });
                    }
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                ticks: {
                    callback: function(value) {
                        return '₹' + Number(value).toLocaleString('en-IN');
                    }
                }
            }
        }
    };

    if (document.getElementById('categoryChart') && categoryLabels.length > 0) {
        new Chart(document.getElementById('categoryChart'), {
            type: 'bar',
            data: {
                labels: categoryLabels,
                datasets: [
                    {
                        label: 'Estimated',
                        data: categoryEstimated,
                        backgroundColor: '#a5b4fc',
                        borderRadius: 5
                    },
                    {
                        label: 'Actual',
                        data: categoryActual,
                        backgroundColor: '#4f46e5',
                        borderRadius: 5
                    }
                ]
            },
            options: chartOptions
        });
    }

    if (document.getElementById('budgetChart') && tripLabels.length > 0) {
        new Chart(document.getElementById('budgetChart'), {
            type: 'bar',
            data: {
                labels: tripLabels,
                datasets: [
                    {
                        label: 'Trip Budget',
                        data: tripBudgets,
                        backgroundColor: '#a5b4fc',
                        borderRadius: 5
                    },
                    {
                        label: 'Actual Spent',
                        data: tripActuals,
                        backgroundColor: '#159b72',
                        borderRadius: 5
                    }
                ]
            },
            options: chartOptions
        });
    }
</script>
</body>
</html>
