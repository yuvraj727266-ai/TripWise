
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseServlet.Expense" %>
<%@ page import="com.mycompany.tripwise.servlet.ExpenseServlet.TripOption" %>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;")
                .replace(">","&gt;").replace("\"","&quot;")
                .replace("'","&#39;");
    }
    private String money(BigDecimal n) {
        return n == null ? "0.00" : n.toPlainString();
    }
%>
<%
    String ctx = request.getContextPath();
    List<Expense> expenses = (List<Expense>) request.getAttribute("expenses");
    List<TripOption> trips = (List<TripOption>) request.getAttribute("trips");
    String editId = request.getParameter("edit");
    Expense editing = null;

    if (editId != null && expenses != null) {
        for (Expense e : expenses) {
            if (String.valueOf(e.id).equals(editId)) {
                editing = e;
                break;
            }
        }
    }

    BigDecimal estimatedTotal = BigDecimal.ZERO;
    BigDecimal actualTotal = BigDecimal.ZERO;
    if (expenses != null) {
        for (Expense e : expenses) {
            if (e.estimated != null) estimatedTotal = estimatedTotal.add(e.estimated);
            if (e.actual != null) actualTotal = actualTotal.add(e.actual);
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Expenses | TripWise</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#f5f7fb;color:#172033;font-family:Arial,sans-serif}
header{background:#fff;padding:20px 5%;border-bottom:1px solid #e8edf2;display:flex;justify-content:space-between;align-items:center}
.brand{font-size:24px;font-weight:800;color:#087f8c;text-decoration:none}
a{color:#087f8c;text-decoration:none}
main{max-width:1300px;margin:35px auto;padding:0 22px}
h1{font-size:30px;margin-bottom:8px}
.muted{font-size:12px;color:#8490a3}
.cards{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:15px;margin:25px 0}
.stat,.panel{background:white;border:1px solid #e8edf2;border-radius:15px;padding:21px;min-width:0}
.stat span{font-size:12px;color:#8490a3}
.stat strong{display:block;font-size:25px;margin-top:12px}
.grid{display:grid;grid-template-columns:330px minmax(0,1fr);gap:20px;align-items:start}
h2{font-size:17px;margin:0 0 20px}
label{display:block;font-size:12px;font-weight:bold;margin:14px 0 7px}
input,select{width:100%;padding:11px;border:1px solid #dfe5ec;border-radius:8px;background:#fff}
button,.btn{border:0;border-radius:8px;padding:10px 13px;background:#087f8c;color:white;font-weight:bold;cursor:pointer;font-size:12px;display:inline-block}
.submit{width:100%;margin-top:18px}
.cancel{background:#edf2f6;color:#344054}
.danger{background:#fff0f1;color:#c53f50}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:12px}
th,td{text-align:left;padding:12px 9px;border-bottom:1px solid #edf0f4;vertical-align:middle}
th{font-size:10px;color:#8490a3;text-transform:uppercase}
.actions{display:flex;gap:6px;align-items:center}
.actions form{margin:0}
.message,.error{padding:12px;border-radius:8px;margin:15px 0;font-size:12px}
.message{background:#e8f7ef;color:#13794f}
.error{background:#fff0f1;color:#b42335}
@media(max-width:950px){.grid{grid-template-columns:1fr}}
@media(max-width:600px){main{padding:0 12px}.cards{grid-template-columns:1fr}.panel,.stat{padding:15px}}
</style>
</head>
<body>
<header>
<a class="brand" href="<%=ctx%>/index.jsp">✈ TripWise</a>
<a href="<%=ctx%>/index.jsp">← Dashboard</a>
</header>

<main>
<h1>Expense Manager</h1>
<p class="muted">Track trip costs, compare estimates with actual spending, and stay on budget.</p>

<% if ("created".equals(request.getParameter("success"))) { %>
<div class="message">Expense added successfully.</div>
<% } else if ("updated".equals(request.getParameter("success"))) { %>
<div class="message">Expense updated successfully.</div>
<% } else if ("deleted".equals(request.getParameter("success"))) { %>
<div class="message">Expense deleted successfully.</div>
<% } %>

<% if (request.getAttribute("error") != null) { %>
<div class="error"><%=esc(String.valueOf(request.getAttribute("error")))%></div>
<% } %>

<section class="cards">
<div class="stat"><span>Total Estimated Expenses</span><strong>₹<%=money(estimatedTotal)%></strong></div>
<div class="stat"><span>Total Actual Expenses</span><strong>₹<%=money(actualTotal)%></strong></div>
<div class="stat"><span>Difference (Actual − Estimated)</span><strong>₹<%=money(actualTotal.subtract(estimatedTotal))%></strong></div>
</section>

<div class="grid">
<section class="panel">
<h2><%=editing == null ? "＋ Add expense" : "Edit expense"%></h2>

<% if (trips == null || trips.isEmpty()) { %>
<p class="muted">Create a trip before adding expenses.</p>
<a class="btn" href="<%=ctx%>/trips">Create a trip</a>
<% } else { %>
<form method="post" action="<%=ctx%>/expenses">
<input type="hidden" name="action" value="<%=editing == null ? "create" : "update"%>">
<% if (editing != null) { %>
<input type="hidden" name="expenseId" value="<%=editing.id%>">
<% } %>

<label>Trip</label>
<select name="tripId" required>
<% for (TripOption t : trips) { %>
<option value="<%=t.id%>" <%=editing != null && editing.tripId == t.id ? "selected" : ""%>>
<%=esc(t.name)%>
</option>
<% } %>
</select>

<label>Category</label>
<select name="category" required>
<%
String[] categories={"Transport","Accommodation","Food","Activities","Shopping","Medical","Other"};
for(String c:categories) {
boolean selected=editing!=null && c.equalsIgnoreCase(editing.category);
%>
<option value="<%=c%>" <%=selected?"selected":""%>><%=c%></option>
<% } %>
</select>

<label>Description</label>
<input name="description" maxlength="200" required
value="<%=editing == null ? "" : esc(editing.description)%>"
placeholder="Hotel booking, train tickets...">

<label>Estimated amount (₹)</label>
<input type="number" name="estimated" min="0" step="0.01" required
value="<%=editing == null ? "" : money(editing.estimated)%>">

<label>Actual amount (₹)</label>
<input type="number" name="actual" min="0" step="0.01"
value="<%=editing == null ? "0" : money(editing.actual)%>">

<label>Expense date</label>
<input type="date" name="expenseDate" required
value="<%=editing == null ? java.time.LocalDate.now().toString() : editing.date%>">

<button class="submit" type="submit"><%=editing == null ? "Add Expense" : "Save Changes"%></button>

<% if(editing != null) { %>
<a class="btn cancel" style="display:block;text-align:center;margin-top:9px" href="<%=ctx%>/expenses">Cancel</a>
<% } %>
</form>
<% } %>
</section>

<section class="panel">
<h2>All Expenses (<%=expenses == null ? 0 : expenses.size()%>)</h2>
<div class="table-wrap">
<table>
<thead><tr><th>Trip / Description</th><th>Category</th><th>Date</th><th>Estimated</th><th>Actual</th><th>Actions</th></tr></thead>
<tbody>
<% if(expenses != null && !expenses.isEmpty()) {
for(Expense e:expenses) { %>
<tr>
<td><strong><%=esc(e.description)%></strong><span class="muted"><%=esc(e.tripName)%></span></td>
<td><%=esc(e.category)%></td>
<td><%=esc(e.date)%></td>
<td>₹<%=money(e.estimated)%></td>
<td>₹<%=money(e.actual)%></td>
<td><div class="actions">
<a class="btn" href="<%=ctx%>/expenses?edit=<%=e.id%>">Edit</a>
<form method="post" action="<%=ctx%>/expenses" onsubmit="return confirm('Delete this expense?')">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="expenseId" value="<%=e.id%>">
<button class="danger" type="submit">Delete</button>
</form>
</div></td>
</tr>
<% } } else { %>
<tr><td colspan="6" style="text-align:center;padding:30px;color:#8490a3">No expenses recorded yet.</td></tr>
<% } %>
</tbody>
</table>
</div>
</section>
</div>
</main>
</body>
</html>
