package com.bikecheck.android.data.network

import com.bikecheck.android.data.network.models.ActivityResponse
import com.bikecheck.android.data.network.models.AthleteResponse
import com.bikecheck.android.data.network.models.TokenResponse
import retrofit2.Response
import retrofit2.http.*

interface StravaApiService {
    @FormUrlEncoded
    @POST("oauth/token")
    suspend fun getToken(
        @Field("client_id") clientId: String,
        @Field("client_secret") clientSecret: String,
        @Field("code") code: String,
        @Field("grant_type") grantType: String = "authorization_code"
    ): Response<TokenResponse>
    
    @FormUrlEncoded
    @POST("oauth/token")
    suspend fun refreshToken(
        @Field("client_id") clientId: String,
        @Field("client_secret") clientSecret: String,
        @Field("refresh_token") refreshToken: String,
        @Field("grant_type") grantType: String = "refresh_token"
    ): Response<TokenResponse>
    
    @GET("api/v3/athlete")
    suspend fun getAthlete(
        @Header("Authorization") authorization: String
    ): Response<AthleteResponse>
    
    @GET("api/v3/athlete/activities")
    suspend fun getActivities(
        @Header("Authorization") authorization: String,
        @Query("page") page: Int = 1,
        @Query("per_page") perPage: Int = 30,
        @Query("type") type: String = "Ride"
    ): Response<List<ActivityResponse>>
    
}