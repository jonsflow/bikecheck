package com.bikecheck.android.data.repository

import com.bikecheck.android.data.database.dao.*
import com.bikecheck.android.data.database.entities.*
import com.bikecheck.android.data.network.StravaApiService
import com.bikecheck.android.data.network.models.*
import com.bikecheck.android.utils.Constants
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
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
    
    suspend fun getTokenCount(): Int {
        return tokenInfoDao.getTokenCount()
    }
    
    suspend fun checkAuthenticationSync(): Boolean {
        return try {
            // Debug: Show all tokens in database
            val tokenCount = tokenInfoDao.getTokenCount()
            val allTokens = tokenInfoDao.getAllTokens()
            android.util.Log.d("StravaRepository", "=== TOKEN DEBUG ===")
            android.util.Log.d("StravaRepository", "Total tokens in database: $tokenCount")
            allTokens.forEachIndexed { index, token ->
                android.util.Log.d("StravaRepository", "Token $index: id=${token.id}, accessToken=${token.accessToken.take(10)}..., expiresAt=${token.expiresAt}, athleteId=${token.athleteId}")
            }
            android.util.Log.d("StravaRepository", "=== END TOKEN DEBUG ===")
            
            val token = tokenInfoDao.getToken()
            val hasToken = token != null
            android.util.Log.d("StravaRepository", "Synchronous auth check: token exists = $hasToken, token = ${token?.accessToken?.take(10)}...")
            hasToken
        } catch (e: Exception) {
            android.util.Log.e("StravaRepository", "Error in synchronous auth check", e)
            false
        }
    }
    
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
                android.util.Log.d("StravaRepository", "Token saved successfully: accessToken=${tokenEntity.accessToken.take(10)}..., expiresAt=${tokenEntity.expiresAt}")
                
                // Sync data from Strava after authentication and wait for completion
                val syncResult = syncDataFromStrava()
                if (syncResult.isFailure) {
                    android.util.Log.w("StravaRepository", "Data sync failed after authentication, but continuing: ${syncResult.exceptionOrNull()}")
                }
                
                Result.success(true)
            } else {
                Result.failure(Exception("Authentication failed: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun refreshTokenIfNeeded(): Result<Boolean> {
        return try {
            val currentToken = tokenInfoDao.getToken()
            if (currentToken == null) {
                return Result.failure(Exception("No token found"))
            }

            val currentTime = System.currentTimeMillis() / 1000
            if (currentToken.expiresAt > currentTime) {
                // Token is still valid
                return Result.success(true)
            }

            // Token is expired, refresh it
            val response = stravaApiService.refreshToken(
                clientId = Constants.STRAVA_CLIENT_ID,
                clientSecret = Constants.STRAVA_CLIENT_SECRET,
                refreshToken = currentToken.refreshToken
            )

            if (response.isSuccessful && response.body() != null) {
                val tokenResponse = response.body()!!

                // Update token with new access token
                val updatedToken = currentToken.copy(
                    accessToken = tokenResponse.accessToken,
                    refreshToken = tokenResponse.refreshToken,
                    expiresAt = tokenResponse.expiresAt
                )
                tokenInfoDao.insertToken(updatedToken)

                Result.success(true)
            } else {
                Result.failure(Exception("Token refresh failed: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getValidAccessToken(): String? {
        return try {
            val existingToken = tokenInfoDao.getToken()
            android.util.Log.d("StravaRepository", "Getting valid access token: existingToken=${existingToken?.accessToken?.take(10)}..., expiresAt=${existingToken?.expiresAt}")
            
            // First try to refresh token if needed
            val refreshResult = refreshTokenIfNeeded()
            if (refreshResult.isSuccess) {
                // Get any available token after refresh attempt
                val token = tokenInfoDao.getToken()?.accessToken
                android.util.Log.d("StravaRepository", "Token after refresh: ${token?.take(10)}...")
                token
            } else {
                // If refresh fails, try to use existing token anyway
                val token = tokenInfoDao.getToken()?.accessToken
                android.util.Log.d("StravaRepository", "Using existing token after refresh failed: ${token?.take(10)}...")
                token
            }
        } catch (e: Exception) {
            android.util.Log.e("StravaRepository", "Error getting valid access token", e)
            // Last resort: get any existing token
            try {
                tokenInfoDao.getToken()?.accessToken
            } catch (ex: Exception) {
                null
            }
        }
    }
    
    suspend fun syncDataFromStrava(): Result<Boolean> {
        return try {
            val accessToken = getValidAccessToken()
                ?: return Result.failure(Exception("No valid access token"))
            
            val authHeader = "Bearer $accessToken"
            
            // Sync athlete data (which includes bikes)
            syncAthleteData(authHeader)
            
            // Sync activities data
            syncActivitiesData(authHeader)
            
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private suspend fun syncAthleteData(authHeader: String) {
        val response = stravaApiService.getAthlete(authHeader)
        if (response.isSuccessful && response.body() != null) {
            val athleteResponse = response.body()!!
            val athleteEntity = AthleteEntity(
                id = athleteResponse.id,
                firstname = athleteResponse.firstname,
                profile = athleteResponse.profile
            )
            athleteDao.insertAthlete(athleteEntity)
            
            // Extract and save bikes from athlete response
            athleteResponse.bikes?.let { bikesResponse ->
                val bikeEntities = bikesResponse.map { bikeResponse ->
                    BikeEntity(
                        id = bikeResponse.id,
                        name = bikeResponse.name,
                        distance = bikeResponse.distance,
                        athleteId = athleteResponse.id
                    )
                }
                bikeDao.upsertBikes(bikeEntities)
            }
        }
    }
    
    
    private suspend fun syncActivitiesData(authHeader: String) {
        val response = stravaApiService.getActivities(authHeader)
        if (response.isSuccessful && response.body() != null) {
            val activitiesResponse = response.body()!!
            val activityEntities = activitiesResponse.map { activityResponse ->
                ActivityEntity(
                    id = activityResponse.id,
                    gearId = activityResponse.gearId,
                    name = activityResponse.name,
                    type = activityResponse.type,
                    movingTime = activityResponse.movingTime,
                    startDate = parseStravaDate(activityResponse.startDate),
                    distance = activityResponse.distance,
                    averageSpeed = activityResponse.averageSpeed
                )
            }
            activityDao.insertActivities(activityEntities)
        }
    }
    
    private fun parseStravaDate(dateString: String): Date {
        return try {
            val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.getDefault())
            format.timeZone = TimeZone.getTimeZone("UTC")
            format.parse(dateString) ?: Date()
        } catch (e: Exception) {
            Date() // Fallback to current date if parsing fails
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
            bikeDao.upsertBikes(testBikes)
            
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
                ),
                ServiceIntervalEntity(
                    part = "Shock",
                    startTime = 0.0,
                    intervalTime = 15.0,
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

    suspend fun deleteBike(bikeId: String): Result<Boolean> {
        return try {
            bikeDao.deleteBikeById(bikeId)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
