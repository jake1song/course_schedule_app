package com.szk333333.course_schedule_app

import android.content.Context
import android.content.Intent
import cn.jpush.android.api.NotificationMessage
import cn.jpush.android.service.JPushMessageReceiver

class AppJPushReceiver : JPushMessageReceiver() {
    override fun onNotifyMessageOpened(context: Context, message: NotificationMessage) {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("jpush_message_id", message.msgId)
            putExtra("jpush_title", message.notificationTitle)
            putExtra("jpush_alert", message.notificationContent)
            putExtra("jpush_extras", message.notificationExtras)
        }
        context.startActivity(intent)
    }
}
