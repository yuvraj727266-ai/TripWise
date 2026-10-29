
package com.mycompany.tripwise;

import java.math.BigDecimal;
import java.time.LocalDate;

public class Trip {
    private int tripId;
    private String tripName;
    private String originCity;
    private String destination;
    private LocalDate startDate;
    private LocalDate endDate;
    private int travellerCount;
    private BigDecimal totalBudget;
    private String tripType;

    public int getTripId() { return tripId; }
    public void setTripId(int tripId) { this.tripId = tripId; }

    public String getTripName() { return tripName; }
    public void setTripName(String tripName) { this.tripName = tripName; }

    public String getOriginCity() { return originCity; }
    public void setOriginCity(String originCity) { this.originCity = originCity; }

    public String getDestination() { return destination; }
    public void setDestination(String destination) { this.destination = destination; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public int getTravellerCount() { return travellerCount; }
    public void setTravellerCount(int travellerCount) {
        this.travellerCount = travellerCount;
    }

    public BigDecimal getTotalBudget() { return totalBudget; }
    public void setTotalBudget(BigDecimal totalBudget) {
        this.totalBudget = totalBudget;
    }

    public String getTripType() { return tripType; }
    public void setTripType(String tripType) { this.tripType = tripType; }
}
