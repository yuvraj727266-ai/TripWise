
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mycompany.tripwise.servlet.TripServlet.TripRecord" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>
<%
    String ctx = request.getContextPath();
    List<TripRecord> trips =
            (List<TripRecord>) request.getAttribute("trips");

    String editId = request.getParameter("edit");
    TripRecord editing = null;

    if (editId != null && trips != null) {
        for (TripRecord t : trips) {
            if (String.valueOf(t.id).equals(editId)) {
                editing = t;
                break;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>My Trips | TripWise</title>
<style>
:root{--primary:#087f8c;--bg:#f5f7fb;--border:#e8edf2;--muted:#8490a3}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:#172033;font-family:Arial,sans-serif}
header{background:#fff;padding:20px 5%;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center}
.brand{font-size:24px;font-weight:800;color:var(--primary);text-decoration:none}
a{color:var(--primary);text-decoration:none}
main{max-width:1300px;margin:35px auto;padding:0 22px}
h1{font-size:30px;margin:0 0 8px}
.muted{color:var(--muted);font-size:12px}
.grid{display:grid;grid-template-columns:340px minmax(0,1fr);gap:22px;margin-top:25px;align-items:start}
.card{background:#fff;border:1px solid var(--border);border-radius:16px;padding:23px;min-width:0}
h2{font-size:17px;margin:0 0 20px}
label{display:block;font-size:12px;font-weight:bold;margin:14px 0 7px}
input,select{width:100%;padding:11px;border:1px solid #dfe5ec;border-radius:8px;background:#fff;color:#172033}
button,.btn{border:0;border-radius:8px;padding:10px 13px;background:var(--primary);color:#fff;font-weight:bold;cursor:pointer;font-size:12px;display:inline-block}
.submit{width:100%;margin-top:18px}
.cancel{background:#edf2f6;color:#344054}
.danger{background:#fff0f1;color:#c53f50}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:12px}
th,td{text-align:left;padding:13px 9px;border-bottom:1px solid #edf0f4;vertical-align:middle}
th{color:var(--muted);font-size:10px;text-transform:uppercase}
td strong{display:block;margin-bottom:5px}
.actions{display:flex;gap:6px;align-items:center}
.actions form{margin:0}
.message,.error{padding:12px;border-radius:8px;margin-top:16px;font-size:12px}
.message{background:#e8f7ef;color:#13794f}
.error{background:#fff0f1;color:#b42335}
.empty{text-align:center;padding:32px;color:var(--muted)}
@media(max-width:950px){.grid{grid-template-columns:1fr}}
@media(max-width:520px){main{padding:0 12px}.card{padding:15px}header{padding:16px}}
</style>
</head>
<body>
<header>
<a class="brand" href="<%=ctx%>/index.jsp">✈ TripWise</a>
<a href="<%=ctx%>/index.jsp">← Dashboard</a>
</header>

<main>
<h1>My Trips</h1>
<p class="muted">Create and manage destinations, dates, travellers and budgets.</p>

<% if ("created".equals(request.getParameter("success"))) { %>
<div class="message">Trip created successfully.</div>
<% } else if ("updated".equals(request.getParameter("success"))) { %>
<div class="message">Trip updated successfully.</div>
<% } else if ("deleted".equals(request.getParameter("success"))) { %>
<div class="message">Trip deleted successfully.</div>
<% } %>

<% if (request.getAttribute("error") != null) { %>
<div class="error"><%=esc(String.valueOf(request.getAttribute("error")))%></div>
<% } %>

<div class="grid">
<section class="card">
<h2><%=editing == null ? "＋ Create a trip" : "Edit trip"%></h2>

<form method="post" action="<%=ctx%>/trips">
<input type="hidden" name="action" value="<%=editing == null ? "create" : "update"%>">
<% if (editing != null) { %>
<input type="hidden" name="tripId" value="<%=editing.id%>">
<% } %>

<label>Trip name</label>
<input name="tripName" maxlength="100" required
value="<%=editing == null ? "" : esc(editing.name)%>" placeholder="Manali Adventure">

<label>Origin city</label>
<input name="origin" maxlength="100" required
value="<%=editing == null ? "" : esc(editing.origin)%>" placeholder="Chandigarh">

<label>Destination</label>
<input name="destination" maxlength="100" required
value="<%=editing == null ? "" : esc(editing.destination)%>" placeholder="Manali">

<label>Start date</label>
<input type="date" name="startDate" required
value="<%=editing == null ? "" : editing.startDate%>">

<label>End date</label>
<input type="date" name="endDate" required
value="<%=editing == null ? "" : editing.endDate%>">

<label>Number of travellers</label>
<input type="number" name="travellers" min="1" max="100" required
value="<%=editing == null ? "1" : editing.travellers%>">

<label>Total budget (₹)</label>
<input type="number" name="budget" min="0" step="0.01" required
value="<%=editing == null ? "" : editing.budget%>" placeholder="25000">

<label>Trip type</label>
<select name="tripType" required>
<%
    String[] types = {"Leisure", "Adventure", "Business", "Family", "Solo", "Other"};
    for (String type : types) {
        boolean selected = editing != null
                && type.equalsIgnoreCase(editing.type);
%>
<option value="<%=type%>" <%=selected ? "selected" : ""%>><%=type%></option>
<% } %>
</select>

<button class="submit" type="submit">
<%=editing == null ? "Create Trip" : "Save Changes"%>
</button>

<% if (editing != null) { %>
<a class="btn cancel" style="margin-top:9px;text-align:center;width:100%"
href="<%=ctx%>/trips">Cancel</a>
<% } %>
</form>
</section>

<section class="card">
<h2>All trips (<%=trips == null ? 0 : trips.size()%>)</h2>
<div class="table-wrap">
<table>
<thead>
<tr>
<th>Trip / Destination</th>
<th>Dates</th>
<th>Travellers</th>
<th>Budget</th>
<th>Actions</th>
</tr>
</thead>
<tbody>
<% if (trips != null && !trips.isEmpty()) {
    for (TripRecord t : trips) { %>
<tr>
<td>
<strong><%=esc(t.name)%></strong>
<span class="muted"><%=esc(t.origin)%> → <%=esc(t.destination)%></span>
</td>
<td><%=esc(t.startDate)%><br><span class="muted">to <%=esc(t.endDate)%></span></td>
<td><%=t.travellers%></td>
<td>₹<%=t.budget == null ? "0.00" : t.budget.toPlainString()%></td>
<td>
<div class="actions">
<a class="btn" href="<%=ctx%>/trips?edit=<%=t.id%>">Edit</a>
<form method="post" action="<%=ctx%>/trips"
onsubmit="return confirm('Delete this trip and its associated records?')">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="tripId" value="<%=t.id%>">
<button class="danger" type="submit">Delete</button>
</form>
</div>
</td>
</tr>
<% } } else { %>
<tr><td colspan="5" class="empty">No trips yet. Create your first trip using the form.</td></tr>
<% } %>
</tbody>
</table>
</div>
</section>
</div>
</main>
</body>
</html>
