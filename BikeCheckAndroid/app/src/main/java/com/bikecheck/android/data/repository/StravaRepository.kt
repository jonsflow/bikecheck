package com.bikecheck.android.data.repository

import com.bikecheck.android.data.database.dao.*
import com.bikecheck.android.data.database.entities.*
import com.bikecheck.android.data.network.StravaApiService
import com.bikecheck.android.data.network.models.*
import com.bikecheck.android.utils.Constants
import kotlinx.coroutines.flow.Flow
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StravaRepository @Inject constructor(
    private val stravaApiService: StravaApiService,
    private val tokenInfoDao: TokenInfoDao,
    private val athleteDao: AthleteDao,
    private val bikeDao: BikeDao,
    private val activityDao: ActivityDao,
    private val serviceIntervalDao: ServiceIntervalDao
) {
    val isSignedIn: Flow<Boolean> = tokenInfoDao.hasTokens()
    
    suspend fun authenticate(authCode: String): Result<Boolean> {
        return try {
            val response = stravaApiService.getToken(
                clientId = Constants.STRAVA_CLIENT_ID,
                clientSecret = Constants.STRAVA_CLIENT_SECRET,
                code = authCode
            )
            
            if (response.isSuccessful && response.body() != null) {
                val tokenResponse = response.body()!!
                
                // Save athlete first if included
                tokenResponse.athlete?.let { athleteResponse ->
                    val athleteEntity = AthleteEntity(
                        id = athleteResponse.id,
                        firstname = athleteResponse.firstname,
                        profile = athleteResponse.profile
                    )
                    athleteDao.insertAthlete(athleteEntity)
                }
                
                // Save token
                val tokenEntity = TokenInfoEntity(
                    accessToken = tokenResponse.accessToken,
                    refreshToken = tokenResponse.refreshToken,
                    expiresAt = tokenResponse.expiresAt,
                    athleteId = tokenResponse.athlete?.id
                )
                tokenInfoDao.insertToken(tokenEntity)
                
                Result.success(true)
            } else {
                Result.failure(Exception("Authentication failed: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun insertTestData(): Result<Boolean> {
        return try {
            // Clear existing data
            clearAllData()
            
            // Insert test athlete
            val testAthlete = AthleteEntity(
                id = 26493868L,
                firstname = "Test User",
                profile = "https://dgalywyr863hv.cloudfront.net/pictures/athletes/26493868/8338609/1/large.jpg"
            )
            athleteDao.insertAthlete(testAthlete)
            
            // Insert test token
            val testToken = TokenInfoEntity(
                accessToken = "test_access_token",
                refreshToken = "test_refresh_token",
                expiresAt = 9999999999L, // Demo mode flag
                athleteId = testAthlete.id
            )
            tokenInfoDao.insertToken(testToken)
            
            // Insert test bikes
            val testBikes = listOf(
                BikeEntity(id = "b1", name = "Kenevo", distance = 99999.0, athleteId = testAthlete.id),
                BikeEntity(id = "b2", name = "StumpJumper", distance = 99999.0, athleteId = testAthlete.id),
                BikeEntity(id = "b3", name = "Checkpoint", distance = 99999.0, athleteId = testAthlete.id),
                BikeEntity(id = "b4", name = "TimberJACKED", distance = 99999.0, athleteId = testAthlete.id)
            )
            bikeDao.insertBikes(testBikes)
            
            // Insert test activities
            val testActivities = listOf(
                ActivityEntity(
                    id = 1111111L,
                    gearId = "b1",
                    name = "Test Activity 1",
                    type = "Ride",
                    movingTime = 645L,
                    startDate = Date(System.currentTimeMillis() - 5 * 24 * 60 * 60 * 1000),
                    distance = 15000.0,
                    averageSpeed = 12.05
                ),
                ActivityEntity(
                    id = 2222222L,
                    gearId = "b1",
                    name = "Test Activity 2",
                    type = "Ride",
                    movingTime = 1585L,
                    startDate = Date(System.currentTimeMillis() - 3 * 24 * 60 * 60 * 1000),
                    distance = 23000.0,
                    averageSpeed = 15.06
                )
            )
            activityDao.insertActivities(testActivities)
            
            // Insert test service intervals
            val testServiceIntervals = listOf(
                ServiceIntervalEntity(
                    part = "chain",
                    startTime = 0.0,
                    intervalTime = 5.0,
                    notify = true,
                    bikeId = "b1"
                ),
                ServiceIntervalEntity(
                    part = "Fork Lowers",
                    startTime = 0.0,
                    intervalTime = 10.0,
                    notify = true,
                    bikeId = "b1"
                )
            )
            testServiceIntervals.forEach { serviceIntervalDao.insertServiceInterval(it) }
            
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private suspend fun clearAllData() {
        serviceIntervalDao.deleteAllServiceIntervals()
        activityDao.deleteAllActivities()
        bikeDao.deleteAllBikes()
        tokenInfoDao.deleteAllTokens()
        athleteDao.deleteAllAthletes()
    }
}