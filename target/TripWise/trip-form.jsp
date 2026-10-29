
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>TripWise | Trip Form</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: Arial, sans-serif; background: #f3f6fb; color: #172033; }
        header { background: #153e75; color: white; padding: 22px 6%; }
        main { max-width: 760px; margin: 30px auto; padding: 0 18px; }
        .card { background: white; padding: 28px; border-radius: 14px; box-shadow: 0 4px 22px #0f172a0d; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
        .field { display: flex; flex-direction: column; gap: 7px; }
        .full { grid-column: 1 / -1; }
        label { font-size: 14px; font-weight: bold; }
        input, select { width: 100%; padding: 11px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 15px; }
        input:focus, select:focus { outline: 2px solid #93c5fd; border-color: #2563eb; }
        .button { display: inline-block; padding: 12px 18px; border: 0; border-radius: 8px; background: #2563eb; color: white; cursor: pointer; text-decoration: none; font-size: 14px; }
        .secondary { background: #64748b; }
        .buttons { display: flex; gap: 10px; margin-top: 22px; }
        @media (max-width: 560px) { .grid { grid-template-columns: 1fr; } .full { grid-column: auto; } }
    </style>
</head>
<body>
<header>
    <h1>✈ TripWise</h1>
    <p>Make your next trip memorable.</p>
</header>
<main>
    <div class="card">
        <h2>
            <c:choose>
                <c:when test="${trip.tripId > 0}">Edit Trip</c:when>
                <c:otherwise>Plan a New Trip</c:otherwise>
            </c:choose>
        </h2>

        <form method="post" action="${pageContext.request.contextPath}/trips">
            <c:choose>
                <c:when test="${trip.tripId > 0}">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="tripId" value="${trip.tripId}">
                </c:when>
                <c:otherwise>
                    <input type="hidden" name="action" value="create">
                </c:otherwise>
            </c:choose>

            <div class="grid">
                <div class="field full">
                    <label for="tripName">Trip Name</label>
                    <input id="tripName" name="tripName" maxlength="100" required
                           value="<c:out value='${trip.tripName}'/>"
                           placeholder="e.g. Manali Adventure">
                </div>

                <div class="field">
                    <label for="originCity">Origin City</label>
                    <input id="originCity" name="originCity" maxlength="100" required
                           value="<c:out value='${trip.originCity}'/>"
                           placeholder="e.g. Chandigarh">
                </div>

                <div class="field">
                    <label for="destination">Destination</label>
                    <input id="destination" name="destination" maxlength="100" required
                           value="<c:out value='${trip.destination}'/>"
                           placeholder="e.g. Manali">
                </div>

                <div class="field">
                    <label for="startDate">Start Date</label>
                    <input type="date" id="startDate" name="startDate" required
                           value="${trip.startDate}">
                </div>

                <div class="field">
                    <label for="endDate">End Date</label>
                    <input type="date" id="endDate" name="endDate" required
                           value="${trip.endDate}">
                </div>

                <div class="field">
                    <label for="travellerCount">Number of Travellers</label>
                    <input type="number" id="travellerCount" name="travellerCount"
                           min="1" max="100" required value="${trip.travellerCount > 0 ? trip.travellerCount : 1}">
                </div>

                <div class="field">
                    <label for="totalBudget">Total Budget (₹)</label>
                    <input type="number" id="totalBudget" name="totalBudget"
                           min="0" max="9999999999.99" step="0.01" required
                           value="${trip.totalBudget != null ? trip.totalBudget : '10000'}">
                </div>

                <div class="field full">
                    <label for="tripType">Trip Type</label>
                    <select id="tripType" name="tripType" required>
                        <option value="Leisure" ${trip.tripType == 'Leisure' ? 'selected' : ''}>Leisure</option>
                        <option value="Adventure" ${trip.tripType == 'Adventure' ? 'selected' : ''}>Adventure</option>
                        <option value="Family" ${trip.tripType == 'Family' ? 'selected' : ''}>Family</option>
                        <option value="Business" ${trip.tripType == 'Business' ? 'selected' : ''}>Business</option>
                        <option value="Pilgrimage" ${trip.tripType == 'Pilgrimage' ? 'selected' : ''}>Pilgrimage</option>
                    </select>
                </div>
            </div>

            <div class="buttons">
                <button type="submit" class="button">Save Trip</button>
                <a class="button secondary" href="${pageContext.request.contextPath}/trips">Cancel</a>
            </div>
        </form>
    </div>
</main>
</body>
</html>
