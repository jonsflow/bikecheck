package com.bikecheck.android.data.database.entities

import androidx.room.Embedded
import androidx.room.Relation

data class BikeWithServiceIntervals(
    @Embedded val bike: BikeEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "bikeId"
    )
    val serviceIntervals: List<ServiceIntervalEntity>
)

data class ServiceIntervalWithBike(
    @Embedded val serviceInterval: ServiceIntervalEntity,
    @Relation(
        parentColumn = "bikeId",
        entityColumn = "id"
    )
    val bike: BikeEntity
) {
    // Convenience properties for easier access
    val id: String get() = serviceInterval.id
    val part: String get() = serviceInterval.part
    val startTime: Double get() = serviceInterval.startTime
    val intervalTime: Double get() = serviceInterval.intervalTime
    val notify: Boolean get() = serviceInterval.notify
    val bikeId: String get() = serviceInterval.bikeId
    val bikeName: String get() = bike.name
}