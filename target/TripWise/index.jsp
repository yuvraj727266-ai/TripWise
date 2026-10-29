<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TripWise | Smart Trip Planner</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        :root {
            --bg: #f5f7fb;
            --surface: #ffffff;
            --text: #172033;
            --muted: #8992a5;
            --primary: #087f8c;
            --primary-dark: #066570;
            --border: #edf0f5;
            --green: #20a779;
            --orange: #f4a340;
            --red: #e76b75;
            --sidebar-width: 250px;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font-family: 'DM Sans', sans-serif;
        }

        button, input, select { font: inherit; }
        button, a { -webkit-tap-highlight-color: transparent; }

        .layout { min-height: 100vh; }

        .sidebar {
            position: fixed;
            inset: 0 auto 0 0;
            width: var(--sidebar-width);
            background: #fff;
            border-right: 1px solid var(--border);
            padding: 28px 18px;
            display: flex;
            flex-direction: column;
            z-index: 10;
            overflow-y: auto;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 11px;
            padding: 0 12px;
            margin-bottom: 42px;
        }

        .brand-icon {
            display: grid;
            place-items: center;
            width: 43px;
            height: 43px;
            border-radius: 14px;
            background: var(--primary);
            color: #fff;
            font-size: 23px;
        }

        .brand-name {
            font-family: 'Manrope', sans-serif;
            font-size: 22px;
            font-weight: 800;
            letter-spacing: -1px;
        }

        .brand-name span { color: var(--primary); }

        .nav-label {
            color: #a1a8b7;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 1.6px;
            padding: 0 13px;
            margin: 0 0 12px;
        }

        .nav-list {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 13px;
            text-decoration: none;
            color: #727d91;
            padding: 12px 14px;
            border-radius: 11px;
            font-size: 13px;
            font-weight: 600;
            transition: .2s;
        }

        .nav-link .nav-icon {
            width: 22px;
            text-align: center;
            font-size: 18px;
        }

        .nav-link:hover, .nav-link.active {
            background: #eaf6f6;
            color: var(--primary);
        }

        .sidebar-bottom { margin-top: auto; padding-top: 35px; }

        .help-card {
            background: #f0f8f8;
            border-radius: 15px;
            padding: 17px;
            margin: 0 4px 18px;
        }

        .help-card strong { font-size: 13px; }
        .help-card p {
            font-size: 11px;
            line-height: 1.7;
            color: #758797;
            margin: 8px 0 12px;
        }

        .help-card a {
            color: var(--primary);
            font-size: 12px;
            font-weight: 700;
            text-decoration: none;
        }

        .profile {
            display: flex;
            align-items: center;
            gap: 11px;
            padding: 14px 8px 0;
            border-top: 1px solid var(--border);
        }

        .avatar {
            width: 39px;
            height: 39px;
            border-radius: 50%;
            background: #d8efec;
            display: grid;
            place-items: center;
            font-weight: 800;
            color: var(--primary);
        }

        .profile strong { display: block; font-size: 12px; }
        .profile small { color: var(--muted); font-size: 10px; }

        .main {
            margin-left: var(--sidebar-width);
            padding: 27px 36px 45px;
            max-width: 1800px;
        }

        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 18px;
            margin-bottom: 32px;
        }

        .breadcrumb { font-size: 11px; color: var(--muted); }
        .breadcrumb span { color: var(--primary); font-weight: 700; }

        .top-actions { display: flex; align-items: center; gap: 12px; }

        .date-pill {
            border: 1px solid var(--border);
            background: #fff;
            padding: 10px 13px;
            border-radius: 10px;
            color: #647084;
            font-size: 11px;
        }

        .icon-button {
            width: 39px;
            height: 39px;
            border: 1px solid var(--border);
            background: #fff;
            border-radius: 11px;
            cursor: pointer;
            font-size: 17px;
        }

        .welcome {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 20px;
            margin-bottom: 28px;
        }

        h1, h2, h3, p { margin-top: 0; }

        h1 {
            font-family: 'Manrope', sans-serif;
            font-size: clamp(25px, 3vw, 34px);
            line-height: 1.25;
            letter-spacing: -1.3px;
            margin-bottom: 9px;
        }

        .subtitle { color: var(--muted); font-size: 13px; margin: 0; }

        .primary-btn {
            background: var(--primary);
            color: #fff;
            border: none;
            border-radius: 11px;
            padding: 13px 18px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 9px;
            transition: .2s;
            white-space: nowrap;
        }

        .primary-btn:hover { background: var(--primary-dark); transform: translateY(-1px); }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 17px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px;
            min-width: 0;
        }

        .stat-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 8px;
            margin-bottom: 22px;
        }

        .stat-icon {
            display: grid;
            place-items: center;
            width: 40px;
            height: 40px;
            border-radius: 12px;
            font-size: 19px;
        }

        .teal { color: #087f8c; background: #e4f5f4; }
        .purple { color: #8b6cdb; background: #f0eaff; }
        .amber { color: #d78c22; background: #fff3dd; }
        .rose { color: #dc6675; background: #ffebee; }

        .trend {
            font-size: 10px;
            font-weight: 700;
            color: var(--green);
            background: #e9f8f1;
            border-radius: 7px;
            padding: 6px 7px;
        }

        .stat-label { color: var(--muted); font-size: 11px; margin-bottom: 8px; }

        .stat-value {
            font-family: 'Manrope', sans-serif;
            font-size: clamp(21px, 2.1vw, 29px);
            font-weight: 800;
            letter-spacing: -.8px;
            overflow-wrap: anywhere;
        }

        .stat-foot { color: var(--muted); font-size: 10px; margin-top: 8px; }

        .content-grid {
            display: grid;
            grid-template-columns: minmax(0, 1.65fr) minmax(270px, 1fr);
            gap: 22px;
            margin-bottom: 24px;
        }

        .panel {
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 17px;
            padding: 23px;
            min-width: 0;
        }

        .panel-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 12px;
            margin-bottom: 23px;
        }

        .panel-title {
            font-family: 'Manrope', sans-serif;
            font-size: 15px;
            font-weight: 800;
            margin-bottom: 6px;
        }

        .panel-subtitle { color: var(--muted); font-size: 11px; margin: 0; }

        .select {
            background: #fff;
            color: #657084;
            border: 1px solid var(--border);
            border-radius: 9px;
            padding: 9px;
            font-size: 10px;
            max-width: 130px;
        }

        .chart-wrap { height: 240px; position: relative; }

        .budget-summary {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 18px;
            gap: 10px;
            padding-top: 17px;
            border-top: 1px solid var(--border);
        }

        .budget-summary span { color: var(--muted); font-size: 11px; }
        .budget-summary strong { font-size: 13px; display: block; margin-top: 5px; }

        .progress {
            height: 7px;
            background: #edf0f4;
            border-radius: 20px;
            overflow: hidden;
            margin: 15px 0 9px;
        }

        .progress-bar { height: 100%; width: 0; background: var(--primary); border-radius: inherit; transition: width .3s; }

        .budget-note { font-size: 10px; color: var(--muted); }

        .trip-list { display: flex; flex-direction: column; gap: 17px; }

        .trip-item {
            display: flex;
            align-items: center;
            gap: 12px;
            min-width: 0;
        }

        .trip-thumb {
            flex: 0 0 66px;
            height: 65px;
            border-radius: 12px;
            display: grid;
            place-items: center;
            font-size: 26px;
        }

        .trip-info { flex: 1; min-width: 0; }
        .trip-info strong { display: block; font-size: 12px; margin-bottom: 6px; }
        .trip-info small { color: var(--muted); font-size: 10px; line-height: 1.7; }
        .trip-cost { font-size: 11px; font-weight: 800; white-space: nowrap; }

        .empty-state {
            text-align: center;
            padding: 23px 10px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.8;
        }

        .empty-state .empty-icon { font-size: 30px; margin-bottom: 10px; }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
        }

        .feature-card {
            text-decoration: none;
            color: var(--text);
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 15px;
            padding: 19px;
            transition: .2s;
        }

        .feature-card:hover {
            border-color: #9dd8d7;
            transform: translateY(-3px);
            box-shadow: 0 8px 22px rgba(22, 58, 67, .05);
        }

        .feature-icon {
            display: grid;
            place-items: center;
            width: 42px;
            height: 42px;
            border-radius: 12px;
            background: #eaf6f6;
            font-size: 20px;
            margin-bottom: 15px;
        }

        .feature-card strong { font-size: 12px; display: block; margin-bottom: 7px; }
        .feature-card p { font-size: 10px; line-height: 1.7; color: var(--muted); margin: 0; }

        .section-heading {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 30px 0 17px;
            gap: 12px;
        }

        .section-heading h2 {
            font-family: 'Manrope', sans-serif;
            font-size: 16px;
            margin: 0;
        }

        .text-link {
            text-decoration: none;
            color: var(--primary);
            font-size: 11px;
            font-weight: 700;
        }

        .toast {
            position: fixed;
            bottom: 24px;
            right: 24px;
            background: #172033;
            color: #fff;
            padding: 14px 18px;
            border-radius: 10px;
            font-size: 12px;
            box-shadow: 0 8px 30px #0002;
            display: none;
            z-index: 100;
        }

        .menu-toggle { display: none; }

        @media (max-width: 1200px) {
            .main { padding: 25px; }
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .feature-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .content-grid { grid-template-columns: minmax(0, 1.3fr) minmax(250px, 1fr); }
        }

        @media (max-width: 850px) {
            .sidebar { transform: translateX(-100%); transition: transform .25s; }
            .sidebar.open { transform: translateX(0); box-shadow: 10px 0 30px #0001; }
            .main { margin-left: 0; padding: 20px; }
            .menu-toggle { display: inline-grid; place-items: center; }
            .content-grid { grid-template-columns: 1fr; }
        }

        @media (max-width: 520px) {
            .main { padding: 16px; }
            .topbar { margin-bottom: 24px; }
            .date-pill { display: none; }
            .welcome { align-items: flex-start; flex-direction: column; }
            .stats { gap: 10px; }
            .stat-card { padding: 14px; }
            .stat-top { margin-bottom: 15px; }
            .stat-value { font-size: 22px; }
            .panel { padding: 17px; }
            .feature-grid { grid-template-columns: 1fr 1fr; gap: 10px; }
            .feature-card { padding: 14px; }
            .trip-thumb { flex-basis: 52px; height: 55px; }
            .trip-cost { font-size: 10px; }
        }
    </style>
</head>

<body>
<div class="layout">

    <aside class="sidebar" id="sidebar">
        <a class="brand" href="<%= ctx %>/index.jsp" style="text-decoration:none;color:inherit">
            <div class="brand-icon">✈</div>
            <div class="brand-name">Trip<span>Wise</span></div>
        </a>

        <div class="nav-label">WORKSPACE</div>
        <nav class="nav-list">
            <a class="nav-link active" href="<%= ctx %>/index.jsp"><span class="nav-icon">⌂</span> Dashboard</a>
            <a class="nav-link" href="<%= ctx %>/trips"><span class="nav-icon">▣</span> My Trips</a>
            <a class="nav-link" href="<%= ctx %>/expenses"><span class="nav-icon">₹</span> Expenses</a>
            <a class="nav-link" href="<%= ctx %>/itinerary"><span class="nav-icon">▦</span> Itinerary Planner</a>
            <a class="nav-link" href="<%= ctx %>/members"><span class="nav-icon">♧</span> Travel Group</a>
            <a class="nav-link" href="<%= ctx %>/packing"><span class="nav-icon">✓</span> Packing Checklist</a>
            <a href="splitter">Expense Splitter</a>
        </nav>

        <div class="nav-label" style="margin-top:30px">INSIGHTS</div>
        <nav class="nav-list">
            <a class="nav-link" href="<%= ctx %>/analytics"><span class="nav-icon">▥</span> Analytics</a>
            <a class="nav-link" href="<%= ctx %>/reports"><span class="nav-icon">▤</span> Trip Reports</a>
        </nav>

        <div class="sidebar-bottom">
            <div class="help-card">
                <strong>✦ Travel smarter</strong>
                <p>Plan your next adventure and keep every expense under control.</p>
                <a href="<%= ctx %>/trips">Start planning →</a>
            </div>
            <div class="profile">
                <div class="avatar">TW</div>
                <div>
                    <strong>TripWise Traveller</strong>
                    <small>Personal workspace</small>
                </div>
            </div>
        </div>
    </aside>

    <main class="main">
        <header class="topbar">
            <div style="display:flex;align-items:center;gap:12px">
                <button class="icon-button menu-toggle" id="menuToggle" aria-label="Open navigation">☰</button>
                <div class="breadcrumb">Workspace / <span>Dashboard</span></div>
            </div>
            <div class="top-actions">
                <div class="date-pill" id="todayDate">Loading date...</div>
                <button class="icon-button" id="refreshButton" title="Refresh dashboard" aria-label="Refresh">↻</button>
            </div>
        </header>

        <section class="welcome">
            <div>
                <h1>Your next adventure starts here.</h1>
                <p class="subtitle">Plan trips, manage your budget and make every journey count.</p>
            </div>
            <a href="<%= ctx %>/trips" class="primary-btn">＋ Create New Trip</a>
        </section>

        <section class="stats" aria-label="Trip statistics">
            <article class="stat-card">
                <div class="stat-top">
                    <div class="stat-icon teal">✈</div>
                    <span class="trend">TRIPS</span>
                </div>
                <div class="stat-label">Total Trips</div>
                <div class="stat-value" id="totalTrips">—</div>
                <div class="stat-foot">Trips in your workspace</div>
            </article>

            <article class="stat-card">
                <div class="stat-top">
                    <div class="stat-icon purple">▦</div>
                    <span class="trend">PLANNING</span>
                </div>
                <div class="stat-label">Upcoming Trips</div>
                <div class="stat-value" id="upcomingTrips">—</div>
                <div class="stat-foot">Trips starting in the future</div>
            </article>

            <article class="stat-card">
                <div class="stat-top">
                    <div class="stat-icon amber">₹</div>
                    <span class="trend">BUDGET</span>
                </div>
                <div class="stat-label">Total Planned Budget</div>
                <div class="stat-value" id="totalBudget">₹0</div>
                <div class="stat-foot">Combined budget for all trips</div>
            </article>

            <article class="stat-card">
                <div class="stat-top">
                    <div class="stat-icon rose">↗</div>
                    <span class="trend">SPENDING</span>
                </div>
                <div class="stat-label">Actual Spending</div>
                <div class="stat-value" id="totalSpent">₹0</div>
                <div class="stat-foot">Recorded actual expenses</div>
            </article>
        </section>

        <section class="content-grid">
            <article class="panel">
                <div class="panel-header">
                    <div>
                        <div class="panel-title">Budget Overview</div>
                        <p class="panel-subtitle">Your planned budget versus actual expenses</p>
                    </div>
                    <select class="select" id="chartMode" aria-label="Budget chart type">
                        <option value="doughnut">Doughnut view</option>
                        <option value="bar">Bar view</option>
                    </select>
                </div>

                <div class="chart-wrap">
                    <canvas id="budgetChart" aria-label="Budget versus spending chart"></canvas>
                </div>

                <div class="budget-summary">
                    <div>
                        <span>Total Budget</span>
                        <strong id="chartBudget">₹0</strong>
                    </div>
                    <div>
                        <span>Actual Spent</span>
                        <strong id="chartSpent">₹0</strong>
                    </div>
                    <div>
                        <span>Remaining</span>
                        <strong id="chartRemaining">₹0</strong>
                    </div>
                </div>

                <div class="progress">
                    <div class="progress-bar" id="budgetProgress"></div>
                </div>
                <div class="budget-note" id="budgetNote">Add a trip to start tracking your budget.</div>
            </article>

            <article class="panel">
                <div class="panel-header">
                    <div>
                        <div class="panel-title">Upcoming Adventures</div>
                        <p class="panel-subtitle">Your next planned destinations</p>
                    </div>
                    <a href="<%= ctx %>/trips" class="text-link">View all →</a>
                </div>

                <div class="trip-list" id="upcomingTripList">
                    <div class="empty-state">
                        <div class="empty-icon">🧭</div>
                        Your upcoming trips will appear here once trips are added.
                        <br><br>
                        <a class="text-link" href="<%= ctx %>/trips">Plan your first trip →</a>
                    </div>
                </div>
            </article>
        </section>

        <div class="section-heading">
            <h2>Explore TripWise</h2>
            <span class="subtitle">Everything for a better journey</span>
        </div>

        <section class="feature-grid">
            <a class="feature-card" href="<%= ctx %>/trips">
                <div class="feature-icon">🗺️</div>
                <strong>Trip Management</strong>
                <p>Create trips, choose destinations, set dates and manage budgets.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/expenses">
                <div class="feature-icon">💳</div>
                <strong>Expense Manager</strong>
                <p>Record costs and compare estimated versus actual spending.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/itinerary">
                <div class="feature-icon">📅</div>
                <strong>Day-wise Itinerary</strong>
                <p>Organize activities, dates and estimated activity costs.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/members">
                <div class="feature-icon">👥</div>
                <strong>Group & Split</strong>
                <p>Manage travel companions and calculate individual shares.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/packing">
                <div class="feature-icon">🎒</div>
                <strong>Packing Checklist</strong>
                <p>Organize essentials and check off items as you pack.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/analytics">
                <div class="feature-icon">📊</div>
                <strong>Spending Analytics</strong>
                <p>Review categories, budget usage and opportunities to save.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/reports">
                <div class="feature-icon">📄</div>
                <strong>Trip Reports</strong>
                <p>View and print a summary of your trip and expenses.</p>
            </a>

            <a class="feature-card" href="<%= ctx %>/trips">
                <div class="feature-icon">✦</div>
                <strong>Smart Budget Tips</strong>
                <p>Identify budget overruns and areas where spending can be reduced.</p>
            </a>
        </section>

        <footer style="padding:30px 0 0;text-align:center;color:#9aa3b2;font-size:10px">
            TripWise · Plan better. Travel smarter. Spend wisely.
        </footer>
    </main>
</div>

<div class="toast" id="toast" role="status"></div>

<script>
    const contextPath = '<%= ctx %>';

    const money = amount => new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR',
        maximumFractionDigits: 0
    }).format(Number(amount) || 0);

    document.getElementById('todayDate').textContent =
        new Intl.DateTimeFormat('en-IN', {
            day: 'numeric',
            month: 'short',
            year: 'numeric'
        }).format(new Date());

    let budgetChart;

    function renderChart(budget, spent) {
        const remaining = Math.max(0, budget - spent);
        const mode = document.getElementById('chartMode').value;
        const canvas = document.getElementById('budgetChart');

        if (budgetChart) budgetChart.destroy();

        budgetChart = new Chart(canvas, {
            type: mode,
            data: {
                labels: mode === 'doughnut'
                    ? ['Actual Spent', 'Remaining Budget']
                    : ['Budget', 'Actual Spent', 'Remaining'],
                datasets: [{
                    data: mode === 'doughnut'
                        ? [Math.min(spent, budget), remaining]
                        : [budget, spent, remaining],
                    backgroundColor: ['#087f8c', '#d9efed', '#f4a340'],
                    borderWidth: 0,
                    borderRadius: mode === 'bar' ? 7 : 0,
                    hoverOffset: 5
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: mode === 'doughnut' ? '73%' : '0%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            usePointStyle: true,
                            pointStyle: 'circle',
                            padding: 20,
                            boxWidth: 8,
                            font: { family: 'DM Sans', size: 10 }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: item => ' ' + item.label + ': ' + money(item.raw)
                        }
                    }
                },
                scales: mode === 'bar' ? {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: value => '₹' + Number(value).toLocaleString('en-IN')
                        },
                        grid: { color: '#f0f2f6' }
                    },
                    x: { grid: { display: false } }
                } : {}
            }
        });
    }

    function updateDashboard(data) {
        const budget = Number(data.totalBudget || 0);
        const spent = Number(data.totalSpent || 0);
        const remaining = budget - spent;
        const percent = budget > 0 ? Math.min(100, spent / budget * 100) : 0;

        document.getElementById('totalTrips').textContent = data.totalTrips ?? 0;
        document.getElementById('upcomingTrips').textContent = data.upcomingTrips ?? 0;
        document.getElementById('totalBudget').textContent = money(budget);
        document.getElementById('totalSpent').textContent = money(spent);
        document.getElementById('chartBudget').textContent = money(budget);
        document.getElementById('chartSpent').textContent = money(spent);
        document.getElementById('chartRemaining').textContent = money(remaining);
        document.getElementById('budgetProgress').style.width = percent + '%';

        document.getElementById('budgetNote').textContent = budget === 0
            ? 'Add a trip to start tracking your budget.'
            : remaining < 0
                ? 'You are over budget by ' + money(Math.abs(remaining)) + '.'
                : percent.toFixed(1) + '% of your planned budget has been spent.';

        renderChart(budget, spent);
        renderUpcomingTrips(data.upcomingTripList || []);
    }

    function renderUpcomingTrips(trips) {
        const container = document.getElementById('upcomingTripList');

        if (!trips.length) {
            container.innerHTML =
                '<div class="empty-state">' +
                '<div class="empty-icon">🧭</div>' +
                'No upcoming trips yet.<br><br>' +
                '<a class="text-link" href="' + contextPath +
                '/trips">Plan your first trip →</a></div>';
            return;
        }

        container.replaceChildren();

        trips.slice(0, 4).forEach((trip, index) => {
            const item = document.createElement('div');
            item.className = 'trip-item';

            const thumb = document.createElement('div');
            thumb.className = 'trip-thumb';
            thumb.style.background = ['#e4f3ee', '#f9eddf', '#eae8fa', '#e4edf9'][index % 4];
            thumb.textContent = ['🏞️', '🏖️', '🏙️', '⛰️'][index % 4];

            const info = document.createElement('div');
            info.className = 'trip-info';

            const title = document.createElement('strong');
            title.textContent = trip.tripName || trip.destination || 'My Trip';

            const detail = document.createElement('small');
            detail.textContent = (trip.destination || 'Destination not set') +
                (trip.startDate ? ' · ' + trip.startDate : '');

            info.append(title, detail);

            const cost = document.createElement('div');
            cost.className = 'trip-cost';
            cost.textContent = money(trip.budget || 0);

            item.append(thumb, info, cost);
            container.appendChild(item);
        });
    }

    document.getElementById('chartMode').addEventListener('change', () => {
        const budget = Number(document.getElementById('chartBudget').dataset.value || 0);
        const spent = Number(document.getElementById('chartSpent').dataset.value || 0);
        renderChart(budget, spent);
    });

    // Dashboard API integration will be enabled after the backend endpoint is added.
    // The endpoint must return JSON with totalTrips, upcomingTrips, totalBudget,
    // totalSpent, and upcomingTripList fields.
    async function loadDashboard() {
        const budgetElement = document.getElementById('chartBudget');
        const spentElement = document.getElementById('chartSpent');

        try {
            const response = await fetch(contextPath + '/api/dashboard', {
                headers: { 'Accept': 'application/json' }
            });

            if (!response.ok) {
                throw new Error('Dashboard API is not available yet.');
            }

            const data = await response.json();

            budgetElement.dataset.value = Number(data.totalBudget || 0);
            spentElement.dataset.value = Number(data.totalSpent || 0);

            updateDashboard(data);
        } catch (error) {
            // Keep the UI usable while the database-backed API is being built.
            budgetElement.dataset.value = '0';
            spentElement.dataset.value = '0';
            updateDashboard({
                totalTrips: 0,
                upcomingTrips: 0,
                totalBudget: 0,
                totalSpent: 0,
                upcomingTripList: []
            });
            console.info('TripWise dashboard is waiting for its backend endpoint.');
        }
    }

    document.getElementById('refreshButton').addEventListener('click', loadDashboard);

    document.getElementById('menuToggle').addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('open');
    });

    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', () => {
            document.querySelectorAll('.nav-link').forEach(item => item.classList.remove('active'));
            link.classList.add('active');
        });
    });

    loadDashboard();
</script>
</body>
</html>
