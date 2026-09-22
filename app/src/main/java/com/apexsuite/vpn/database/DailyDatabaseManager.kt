package com.apexsuite.vpn.database

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.text.SimpleDateFormat
import java.util.*

class DailyDatabaseManager(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "apex_daily_sync.db"
        private const val DATABASE_VERSION = 1

        const val TABLE_SERVERS = "daily_servers"
        const val TABLE_STATS = "daily_stats"
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE $TABLE_SERVERS (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                protocol TEXT,
                address TEXT,
                port INTEGER,
                config_json TEXT,
                last_updated TEXT
            )
        """)

        db.execSQL("""
            CREATE TABLE $TABLE_STATS (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date_stamp TEXT UNIQUE,
                bytes_downloaded LONG,
                bytes_uploaded LONG,
                ping_avg LONG
            )
        """)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_SERVERS")
        db.execSQL("DROP TABLE IF EXISTS $TABLE_STATS")
        onCreate(db)
    }

    fun syncDailyData(serverListJson: String) {
        val db = this.writableDatabase
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        
        db.beginTransaction()
        try {
            db.execSQL("DELETE FROM $TABLE_SERVERS")
            // إضافة البيانات اليومية الجديدة
            db.execSQL("INSERT INTO $TABLE_SERVERS (protocol, address, port, config_json, last_updated) VALUES ('VLESS', 'node.apex.net', 443, ?, ?)", arrayOf(serverListJson, today))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
            db.close()
        }
    }
}
