
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mycompany.tripwise.servlet.PackingServlet.TripOption" %>
<%@ page import="com.mycompany.tripwise.servlet.PackingServlet.PackingItem" %>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;")
                .replace(">","&gt;").replace("\"","&quot;")
                .replace("'","&#39;");
    }
%>
<%
    String ctx = request.getContextPath();
    List<TripOption> trips = (List<TripOption>) request.getAttribute("trips");
    List<PackingItem> items = (List<PackingItem>) request.getAttribute("items");

    int packedCount = 0;
    if (items != null) {
        for (PackingItem item : items) {
            if (item.packed) packedCount++;
        }
    }

    int totalCount = items == null ? 0 : items.size();
    int progress = totalCount == 0 ? 0 : packedCount * 100 / totalCount;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Packing Checklist | TripWise</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#f5f7fb;color:#172033;font-family:Arial,sans-serif}
header{background:#fff;padding:20px 5%;border-bottom:1px solid #e8edf2;display:flex;justify-content:space-between;align-items:center}
.brand{font-size:24px;font-weight:800;color:#087f8c;text-decoration:none}
a{color:#087f8c;text-decoration:none}
main{max-width:1050px;margin:35px auto;padding:0 22px}
h1{font-size:30px;margin-bottom:8px}
.muted{font-size:12px;color:#8490a3}
.layout{display:grid;grid-template-columns:320px minmax(0,1fr);gap:20px;margin-top:25px;align-items:start}
.card{background:#fff;border:1px solid #e8edf2;border-radius:16px;padding:23px;min-width:0}
h2{font-size:17px;margin:0 0 20px}
label{display:block;font-size:12px;font-weight:bold;margin:14px 0 7px}
input,select{width:100%;padding:11px;border:1px solid #dfe5ec;border-radius:8px;background:#fff}
button,.btn{border:0;border-radius:8px;padding:10px 13px;background:#087f8c;color:#fff;font-weight:bold;cursor:pointer;font-size:12px;display:inline-block}
.submit{width:100%;margin-top:18px}
.delete{background:#fff0f1;color:#c53f50}
.progress{height:9px;background:#edf0f4;border-radius:20px;overflow:hidden;margin:16px 0 9px}
.bar{height:100%;background:#087f8c;border-radius:20px;transition:width .2s}
.item{display:flex;align-items:center;gap:13px;padding:15px 0;border-bottom:1px solid #edf0f4}
.item:last-child{border-bottom:0}
.item form{margin:0}
.item-info{flex:1;min-width:0}
.item-name{font-size:13px;font-weight:bold;overflow-wrap:anywhere}
.item-trip{font-size:11px;color:#8490a3;margin-top:5px}
.item.packed .item-name{text-decoration:line-through;color:#8490a3}
.checkbox{width:19px;height:19px;accent-color:#087f8c;cursor:pointer}
.message,.error{padding:12px;border-radius:8px;margin:15px 0;font-size:12px}
.message{background:#e8f7ef;color:#13794f}
.error{background:#fff0f1;color:#b42335}
@media(max-width:800px){.layout{grid-template-columns:1fr}}
@media(max-width:500px){main{padding:0 12px}.card{padding:16px}}
</style>
</head>
<body>
<header>
<a class="brand" href="<%=ctx%>/index.jsp">✈ TripWise</a>
<a href="<%=ctx%>/index.jsp">← Dashboard</a>
</header>

<main>
<h1>Packing Checklist</h1>
<p class="muted">Prepare for every trip and keep track of everything you need.</p>

<% if ("created".equals(request.getParameter("success"))) { %>
<div class="message">Packing item added successfully.</div>
<% } else if ("updated".equals(request.getParameter("success"))) { %>
<div class="message">Packing status updated.</div>
<% } else if ("deleted".equals(request.getParameter("success"))) { %>
<div class="message">Packing item deleted.</div>
<% } %>

<% if (request.getAttribute("error") != null) { %>
<div class="error"><%=esc(String.valueOf(request.getAttribute("error")))%></div>
<% } %>

<div class="layout">
<section class="card">
<h2>＋ Add packing item</h2>

<% if (trips == null || trips.isEmpty()) { %>
<p class="muted">Create a trip before adding packing items.</p>
<a class="btn" href="<%=ctx%>/trips">Create a trip</a>
<% } else { %>
<form method="post" action="<%=ctx%>/packing">
<input type="hidden" name="action" value="create">

<label>Trip</label>
<select name="tripId" required>
<% for (TripOption trip : trips) { %>
<option value="<%=trip.id%>"><%=esc(trip.name)%></option>
<% } %>
</select>

<label>Item name</label>
<input name="itemName" maxlength="100" required placeholder="Passport, charger, medicine...">

<button class="submit" type="submit">Add to Checklist</button>
</form>
<% } %>
</section>

<section class="card">
<h2>Your packing progress</h2>
<div style="display:flex;justify-content:space-between;align-items:center;gap:10px">
<strong><%=packedCount%> of <%=totalCount%> items packed</strong>
<strong style="color:#087f8c"><%=progress%>%</strong>
</div>
<div class="progress"><div class="bar" style="width:<%=progress%>%"></div></div>
<p class="muted">Tick an item when it is packed.</p>

<% if (items != null && !items.isEmpty()) {
    for (PackingItem item : items) { %>
<div class="item <%=item.packed ? "packed" : ""%>">
<form method="post" action="<%=ctx%>/packing">
<input type="hidden" name="action" value="toggle">
<input type="hidden" name="itemId" value="<%=item.id%>">
<input type="hidden" name="packed" value="<%=item.packed ? "N" : "Y"%>">
<input class="checkbox" type="checkbox" <%=item.packed ? "checked" : ""%>
       aria-label="Toggle <%=esc(item.name)%>"
       onchange="this.form.submit()">
</form>

<div class="item-info">
<div class="item-name"><%=esc(item.name)%></div>
<div class="item-trip"><%=esc(item.tripName)%></div>
</div>

<form method="post" action="<%=ctx%>/packing"
      onsubmit="return confirm('Delete this packing item?')">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="itemId" value="<%=item.id%>">
<button class="delete" type="submit">Delete</button>
</form>
</div>
<% } } else { %>
<div style="text-align:center;padding:30px;color:#8490a3">
<div style="font-size:34px;margin-bottom:10px">🎒</div>
No packing items yet. Add your first item.
</div>
<% } %>
</section>
</div>
</main>
</body>
</html>
