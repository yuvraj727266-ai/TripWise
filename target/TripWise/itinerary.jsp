
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="com.mycompany.tripwise.servlet.ItineraryServlet.Activity" %>
<%@ page import="com.mycompany.tripwise.servlet.ItineraryServlet.TripOption" %>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;")
                .replace(">","&gt;").replace("\"","&quot;")
                .replace("'","&#39;");
    }
    private String amount(BigDecimal n) {
        return n == null ? "0.00" : n.toPlainString();
    }
%>
<%
    String ctx = request.getContextPath();
    List<TripOption> trips = (List<TripOption>) request.getAttribute("trips");
    List<Activity> activities = (List<Activity>) request.getAttribute("activities");

    String editId = request.getParameter("edit");
    Activity editing = null;

    if (editId != null && activities != null) {
        for (Activity a : activities) {
            if (String.valueOf(a.id).equals(editId)) {
                editing = a;
                break;
            }
        }
    }

    BigDecimal totalCost = BigDecimal.ZERO;
    if (activities != null) {
        for (Activity a : activities) {
            if (a.cost != null) totalCost = totalCost.add(a.cost);
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Itinerary Planner | TripWise</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#f5f7fb;color:#172033;font-family:Arial,sans-serif}
header{background:#fff;padding:20px 5%;border-bottom:1px solid #e8edf2;display:flex;justify-content:space-between;align-items:center}
.brand{font-size:24px;font-weight:800;color:#087f8c;text-decoration:none}
a{color:#087f8c;text-decoration:none}
main{max-width:1300px;margin:35px auto;padding:0 22px}
h1{font-size:30px;margin-bottom:8px}
.muted{color:#8490a3;font-size:12px}
.stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:15px;margin:25px 0}
.card{background:#fff;border:1px solid #e8edf2;border-radius:15px;padding:22px;min-width:0}
.stats span{font-size:12px;color:#8490a3}
.stats strong{display:block;font-size:25px;margin-top:10px}
.grid{display:grid;grid-template-columns:330px minmax(0,1fr);gap:20px;align-items:start}
h2{font-size:17px;margin:0 0 20px}
label{display:block;font-size:12px;font-weight:bold;margin:14px 0 7px}
input,select{width:100%;padding:11px;border:1px solid #dfe5ec;border-radius:8px;background:white}
button,.btn{border:0;border-radius:8px;padding:10px 12px;background:#087f8c;color:white;font-weight:bold;cursor:pointer;font-size:12px;display:inline-block}
.submit{width:100%;margin-top:18px}
.cancel{background:#edf2f6;color:#344054}
.danger{background:#fff0f1;color:#c53f50}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:12px}
th,td{text-align:left;padding:12px 8px;border-bottom:1px solid #edf0f4;vertical-align:middle}
th{font-size:10px;color:#8490a3;text-transform:uppercase}
.actions{display:flex;gap:6px;align-items:center;flex-wrap:wrap}
.actions form{margin:0}
.message,.error{padding:12px;border-radius:8px;margin:15px 0;font-size:12px}
.message{background:#e8f7ef;color:#13794f}
.error{background:#fff0f1;color:#b42335}
@media(max-width:950px){.grid{grid-template-columns:1fr}}
@media(max-width:600px){main{padding:0 12px}.stats{grid-template-columns:1fr}.card{padding:15px}}
</style>
</head>
<body>
<header>
<a class="brand" href="<%=ctx%>/index.jsp">✈ TripWise</a>
<a href="<%=ctx%>/index.jsp">← Dashboard</a>
</header>

<main>
<h1>Itinerary Planner</h1>
<p class="muted">Organize activities, dates and estimated costs for each travel day.</p>

<% if ("created".equals(request.getParameter("success"))) { %>
<div class="message">Activity added successfully.</div>
<% } else if ("updated".equals(request.getParameter("success"))) { %>
<div class="message">Activity updated successfully.</div>
<% } else if ("deleted".equals(request.getParameter("success"))) { %>
<div class="message">Activity deleted successfully.</div>
<% } %>

<% if (request.getAttribute("error") != null) { %>
<div class="error"><%=esc(String.valueOf(request.getAttribute("error")))%></div>
<% } %>

<section class="stats">
<div class="card"><span>Total Activities</span><strong><%=activities == null ? 0 : activities.size()%></strong></div>
<div class="card"><span>Planned Activity Costs</span><strong>₹<%=amount(totalCost)%></strong></div>
<div class="card"><span>Completed Activities</span>
<strong><%
int completed = 0;
if (activities != null) {
    for (Activity a : activities) {
        if ("COMPLETED".equalsIgnoreCase(a.status)) completed++;
    }
}
out.print(completed);
%></strong></div>
</section>

<div class="grid">
<section class="card">
<h2><%=editing == null ? "＋ Add activity" : "Edit activity"%></h2>

<% if (trips == null || trips.isEmpty()) { %>
<p class="muted">Create a trip before planning activities.</p>
<a class="btn" href="<%=ctx%>/trips">Create a trip</a>
<% } else { %>
<form method="post" action="<%=ctx%>/itinerary">
<input type="hidden" name="action" value="<%=editing == null ? "create" : "update"%>">
<% if (editing != null) { %>
<input type="hidden" name="activityId" value="<%=editing.id%>">
<% } %>

<label>Trip</label>
<select name="tripId" required>
<% for (TripOption t : trips) { %>
<option value="<%=t.id%>" <%=editing != null && editing.tripId == t.id ? "selected" : ""%>><%=esc(t.name)%></option>
<% } %>
</select>

<label>Day number</label>
<input type="number" name="day" min="1" required value="<%=editing == null ? "1" : editing.day%>">

<label>Activity name</label>
<input name="activityName" maxlength="150" required value="<%=editing == null ? "" : esc(editing.name)%>" placeholder="Visit Solang Valley">

<label>Activity date</label>
<input type="date" name="activityDate" required value="<%=editing == null ? java.time.LocalDate.now().toString() : editing.date%>">

<label>Estimated cost (₹)</label>
<input type="number" name="cost" min="0" step="0.01" required value="<%=editing == null ? "0" : amount(editing.cost)%>">

<label>Status</label>
<select name="status" required>
<% String[] statuses={"PLANNED","COMPLETED","CANCELLED"};
for(String s:statuses) {
boolean selected=editing!=null && s.equalsIgnoreCase(editing.status);
%>
<option value="<%=s%>" <%=selected?"selected":""%>><%=s%></option>
<% } %>
</select>

<button class="submit" type="submit"><%=editing == null ? "Add Activity" : "Save Changes"%></button>

<% if(editing != null) { %>
<a class="btn cancel" style="display:block;text-align:center;margin-top:9px" href="<%=ctx%>/itinerary">Cancel</a>
<% } %>
</form>
<% } %>
</section>

<section class="card">
<h2>Planned Activities</h2>
<div class="table-wrap">
<table>
<thead>
<tr><th>Trip / Activity</th><th>Day</th><th>Date</th><th>Cost</th><th>Status</th><th>Actions</th></tr>
</thead>
<tbody>
<% if(activities != null && !activities.isEmpty()) {
for(Activity a:activities) { %>
<tr>
<td><strong><%=esc(a.name)%></strong><span class="muted"><%=esc(a.tripName)%></span></td>
<td><%=a.day%></td>
<td><%=esc(a.date)%></td>
<td>₹<%=amount(a.cost)%></td>
<td><%=esc(a.status)%></td>
<td><div class="actions">
<a class="btn" href="<%=ctx%>/itinerary?edit=<%=a.id%>">Edit</a>
<form method="post" action="<%=ctx%>/itinerary" onsubmit="return confirm('Delete this activity?')">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="activityId" value="<%=a.id%>">
<button class="danger" type="submit">Delete</button>
</form>
</div></td>
</tr>
<% } } else { %>
<tr><td colspan="6" style="text-align:center;padding:30px;color:#8490a3">No activities yet. Add your first itinerary activity.</td></tr>
<% } %>
</tbody>
</table>
</div>
</section>
</div>
</main>
</body>
</html>
