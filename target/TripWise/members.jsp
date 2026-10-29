
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="com.mycompany.tripwise.servlet.MemberServlet.TripOption" %>
<%@ page import="com.mycompany.tripwise.servlet.MemberServlet.Member" %>
<%@ page import="com.mycompany.tripwise.servlet.MemberServlet.MemberTotal" %>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;")
                .replace(">","&gt;").replace("\"","&quot;")
                .replace("'","&#39;");
    }
    private String money(BigDecimal amount) {
        return amount == null ? "0.00" : amount.toPlainString();
    }
%>
<%
    String ctx = request.getContextPath();
    List<TripOption> trips = (List<TripOption>) request.getAttribute("trips");
    List<Member> members = (List<Member>) request.getAttribute("members");
    List<MemberTotal> totals =
            (List<MemberTotal>) request.getAttribute("memberTotals");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Travel Group | TripWise</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#f5f7fb;color:#172033;font-family:Arial,sans-serif}
header{background:white;padding:20px 5%;border-bottom:1px solid #e8edf2;display:flex;justify-content:space-between;align-items:center}
.brand{font-size:24px;font-weight:800;color:#087f8c;text-decoration:none}
a{color:#087f8c;text-decoration:none}
main{max-width:1200px;margin:35px auto;padding:0 22px}
h1{font-size:30px;margin-bottom:8px}
.muted{font-size:12px;color:#8490a3}
.grid{display:grid;grid-template-columns:330px minmax(0,1fr);gap:20px;align-items:start;margin-top:25px}
.card{background:white;border:1px solid #e8edf2;border-radius:15px;padding:22px;min-width:0}
h2{font-size:17px;margin:0 0 20px}
label{display:block;font-size:12px;font-weight:bold;margin:14px 0 7px}
input,select{width:100%;padding:11px;border:1px solid #dfe5ec;border-radius:8px;background:white}
button,.btn{border:0;border-radius:8px;padding:10px 13px;background:#087f8c;color:white;font-weight:bold;cursor:pointer;font-size:12px;display:inline-block}
.submit{width:100%;margin-top:18px}
.danger{background:#fff0f1;color:#c53f50}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:12px}
th,td{text-align:left;padding:12px 9px;border-bottom:1px solid #edf0f4}
th{font-size:10px;color:#8490a3;text-transform:uppercase}
.message,.error{padding:12px;border-radius:8px;margin:15px 0;font-size:12px}
.message{background:#e8f7ef;color:#13794f}
.error{background:#fff0f1;color:#b42335}
.member-name{font-weight:bold}
@media(max-width:850px){.grid{grid-template-columns:1fr}}
@media(max-width:550px){main{padding:0 12px}.card{padding:15px}}
</style>
</head>
<body>
<header>
<a class="brand" href="<%=ctx%>/index.jsp">✈ TripWise</a>
<a href="<%=ctx%>/index.jsp">← Dashboard</a>
</header>
<main>
<h1>Travel Group</h1>
<p class="muted">Manage your travel companions and track expenses paid by each person.</p>

<% if ("created".equals(request.getParameter("success"))) { %>
<div class="message">Traveller added successfully.</div>
<% } else if ("deleted".equals(request.getParameter("success"))) { %>
<div class="message">Traveller removed successfully.</div>
<% } %>

<% if (request.getAttribute("error") != null) { %>
<div class="error"><%=esc(String.valueOf(request.getAttribute("error")))%></div>
<% } %>

<div class="grid">
<section class="card">
<h2>＋ Add traveller</h2>
<% if (trips == null || trips.isEmpty()) { %>
<p class="muted">Create a trip before adding travellers.</p>
<a class="btn" href="<%=ctx%>/trips">Create a trip</a>
<% } else { %>
<form method="post" action="<%=ctx%>/members">
<input type="hidden" name="action" value="create">

<label>Select trip</label>
<select name="tripId" required>
<% for (TripOption trip : trips) { %>
<option value="<%=trip.id%>"><%=esc(trip.name)%></option>
<% } %>
</select>

<label>Traveller name</label>
<input name="memberName" maxlength="100" required placeholder="Enter full name">

<button class="submit" type="submit">Add Traveller</button>
</form>
<% } %>
</section>

<section class="card">
<h2>Group members (<%=members == null ? 0 : members.size()%>)</h2>
<div class="table-wrap">
<table>
<thead><tr><th>Traveller</th><th>Trip</th><th>Actual expenses paid</th><th>Action</th></tr></thead>
<tbody>
<% if (members != null && !members.isEmpty()) {
for (Member member : members) {
    BigDecimal paid = BigDecimal.ZERO;
    if (totals != null) {
        for (MemberTotal total : totals) {
            if (total.memberId == member.id) {
                paid = total.paid == null ? BigDecimal.ZERO : total.paid;
                break;
            }
        }
    }
%>
<tr>
<td class="member-name"><%=esc(member.name)%></td>
<td><%=esc(member.tripName)%></td>
<td>₹<%=money(paid)%></td>
<td>
<form method="post" action="<%=ctx%>/members"
onsubmit="return confirm('Remove this traveller? Members assigned to expenses cannot be removed until reassigned.')">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="memberId" value="<%=member.id%>">
<button class="danger" type="submit">Remove</button>
</form>
</td>
</tr>
<% } } else { %>
<tr><td colspan="4" style="text-align:center;padding:30px;color:#8490a3">No travellers added yet.</td></tr>
<% } %>
</tbody>
</table>
</div>
<p class="muted" style="margin-top:15px">
“Actual expenses paid” reflects expenses assigned to a traveller in the database.
</p>
</section>
</div>
</main>
</body>
</html>
