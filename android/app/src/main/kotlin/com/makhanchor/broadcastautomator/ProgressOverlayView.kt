package com.makhanchor.broadcastautomator

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

/**
 * Floating system overlay displayed over WhatsApp during auto broadcast.
 * Fully styled to match the Flutter SendingProgressOverlay card UI.
 */
class ProgressOverlayView(context: Context) : LinearLayout(context) {

    private val dragHandle: View
    private val headerRow: LinearLayout
    private val titleView: TextView
    private val statusDotView: View
    private val statusTextView: TextView
    private val minimizeButton: TextView
    private val bubbleButton: TextView
    private val bubbleView: LinearLayout
    private val collapsibleContent: LinearLayout

    private val progressLabelView: TextView
    private val fractionView: TextView
    private val barView: ProgressBar

    private val avatarView: TextView
    private val contactNameView: TextView
    private val hourglassView: TextView

    private val sentValView: TextView
    private val pendingValView: TextView
    private val failedValView: TextView

    private val timeRemainingView: TextView

    private val toggleButton: TextView
    private val stopButton: TextView

    private var windowManager: WindowManager? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var isCollapsed = false
    private var isBubble = false

    private var initialX = 0
    private var initialY = 0
    private var touchX = 0f
    private var touchY = 0f

    init {
        orientation = VERTICAL
        setPadding(dp(20), dp(14), dp(20), dp(18))
        background = roundedBox(
            bgColor = 0xFF18191B.toInt(),
            borderColor = 0xFF2D3139.toInt(),
            strokeWidthDp = 1.5f,
            cornerRadiusDp = 24f,
        )
        elevation = dp(8).toFloat()

        // 1. Drag Handle
        dragHandle = View(context).apply {
            background = roundedBox(0xFF3F444D.toInt(), 0, 0f, 999f)
            layoutParams = LayoutParams(dp(40), dp(4)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(12)
            }
        }
        addView(dragHandle)

        // 2. Header Row
        headerRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val titleCol = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
        }

        titleView = TextView(context).apply {
            setTextColor(Color.WHITE)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            maxLines = 1
        }
        titleCol.addView(titleView)

        val statusRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(4)
            }
        }
        statusDotView = View(context).apply {
            background = roundedBox(0xFF25D366.toInt(), 0, 0f, 999f)
            layoutParams = LayoutParams(dp(8), dp(8))
        }
        statusTextView = TextView(context).apply {
            setTextColor(0xFF9EA5B0.toInt())
            textSize = 12f
            setPadding(dp(6), 0, 0, 0)
        }
        statusRow.addView(statusDotView)
        statusRow.addView(statusTextView)
        titleCol.addView(statusRow)

        bubbleButton = TextView(context).apply {
            text = "💬"
            setTextColor(0xFF9EA5B0.toInt())
            textSize = 14f
            gravity = Gravity.CENTER
            background = roundedBox(0xFF282C35.toInt(), 0, 0f, 999f)
            layoutParams = LayoutParams(dp(32), dp(32)).apply {
                marginStart = dp(8)
            }
        }

        minimizeButton = TextView(context).apply {
            text = "▼"
            setTextColor(0xFF9EA5B0.toInt())
            textSize = 12f
            gravity = Gravity.CENTER
            background = roundedBox(0xFF282C35.toInt(), 0, 0f, 999f)
            layoutParams = LayoutParams(dp(32), dp(32)).apply {
                marginStart = dp(8)
            }
        }
        headerRow.addView(titleCol)
        headerRow.addView(bubbleButton)
        headerRow.addView(minimizeButton)
        addView(headerRow)

        // 3. Collapsible Container
        collapsibleContent = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        // Progress Header
        val progressHeader = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(14)
            }
        }
        progressLabelView = TextView(context).apply {
            text = "Sending in progress..."
            setTextColor(Color.WHITE)
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
        }
        fractionView = TextView(context).apply {
            setTextColor(0xFF9EA5B0.toInt())
            textSize = 12f
        }
        progressHeader.addView(progressLabelView)
        progressHeader.addView(fractionView)
        collapsibleContent.addView(progressHeader)

        // Progress Bar
        barView = ProgressBar(
            context,
            null,
            android.R.attr.progressBarStyleHorizontal,
        ).apply {
            max = 100
            progressTintList = android.content.res.ColorStateList.valueOf(0xFF25D366.toInt())
            progressBackgroundTintList =
                android.content.res.ColorStateList.valueOf(0xFF2D3139.toInt())
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dp(8)).apply {
                topMargin = dp(8)
            }
        }
        collapsibleContent.addView(barView)

        // Current Contact Card
        val contactCard = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            background = roundedBox(
                bgColor = 0xFF22252B.toInt(),
                borderColor = 0xFF2D3139.toInt(),
                strokeWidthDp = 1f,
                cornerRadiusDp = 16f,
            )
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(14)
            }
        }
        avatarView = TextView(context).apply {
            setTextColor(0xFF25D366.toInt())
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = roundedBox(0xFF1A382B.toInt(), 0, 0f, 999f)
            layoutParams = LayoutParams(dp(40), dp(40))
        }
        val contactInfoCol = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(12)
            }
        }
        val contactLabel = TextView(context).apply {
            text = "Current Contact"
            setTextColor(0xFF8E96A4.toInt())
            textSize = 11f
        }
        contactNameView = TextView(context).apply {
            setTextColor(Color.WHITE)
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            maxLines = 1
        }
        contactInfoCol.addView(contactLabel)
        contactInfoCol.addView(contactNameView)

        hourglassView = TextView(context).apply {
            text = "⏱"
            setTextColor(0xFF9EA5B0.toInt())
            textSize = 16f
        }
        contactCard.addView(avatarView)
        contactCard.addView(contactInfoCol)
        contactCard.addView(hourglassView)
        collapsibleContent.addView(contactCard)

        // Stats Row (3 Cards: Sent, Pending, Failed)
        val statsRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(14)
            }
        }
        sentValView = createStatCard(statsRow, "Sent", 0xFF25D366.toInt())
        pendingValView = createStatCard(statsRow, "Pending", Color.WHITE)
        failedValView = createStatCard(statsRow, "Failed", 0xFFFF5252.toInt())
        collapsibleContent.addView(statsRow)

        // Estimated Time Remaining
        val timeRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(12)
            }
        }
        timeRemainingView = TextView(context).apply {
            setTextColor(0xFF8E96A4.toInt())
            textSize = 11f
        }
        timeRow.addView(timeRemainingView)
        collapsibleContent.addView(timeRow)

        // Control Buttons Row
        val buttonRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(14)
            }
        }
        toggleButton = createPillButton("Pause", 0xFF2D323E.toInt(), 0xFF3F4554.toInt(), Color.WHITE)
        stopButton = createPillButton("Stop", 0xFF3D1B1B.toInt(), 0xFF6E2424.toInt(), 0xFFFF6B6B.toInt())

        buttonRow.addView(toggleButton, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        buttonRow.addView(stopButton, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply {
            marginStart = dp(12)
        })
        collapsibleContent.addView(buttonRow)

        addView(collapsibleContent)

        // 4. Bubble View (Hidden by default)
        bubbleView = LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER
            visibility = View.GONE
            background = roundedBox(0xFF25D366.toInt(), 0, 0f, 999f)
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            
            val textInside = TextView(context).apply {
                text = "💬"
                textSize = 20f
                gravity = Gravity.CENTER
                setTextColor(Color.WHITE)
            }
            addView(textInside)
        }
        addView(bubbleView)

        // Click listeners & Touch listeners
        toggleButton.setOnClickListener {
            sendAction(WhatsAppAutomationService.ACTION_PAUSE_RESUME)
        }
        stopButton.setOnClickListener {
            sendAction(WhatsAppAutomationService.ACTION_STOP)
        }
        minimizeButton.setOnClickListener {
            toggleMinimize()
        }
        bubbleButton.setOnClickListener {
            toggleBubbleMode()
        }
        bubbleView.setOnClickListener {
            toggleBubbleMode()
        }

        setupDrag(headerRow)
        setupDrag(dragHandle)
        setupDrag(bubbleView)
    }

    private fun createStatCard(parent: LinearLayout, labelText: String, valColor: Int): TextView {
        val card = LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(8), dp(8), dp(8), dp(8))
            background = roundedBox(
                bgColor = 0xFF22252B.toInt(),
                borderColor = 0xFF2D3139.toInt(),
                strokeWidthDp = 1f,
                cornerRadiusDp = 12f,
            )
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply {
                if (parent.childCount > 0) marginStart = dp(8)
            }
        }
        val lbl = TextView(context).apply {
            text = labelText
            setTextColor(0xFF8E96A4.toInt())
            textSize = 11f
            gravity = Gravity.CENTER
        }
        val valTv = TextView(context).apply {
            text = "0"
            setTextColor(valColor)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        card.addView(lbl)
        card.addView(valTv)
        parent.addView(card)
        return valTv
    }

    private fun createPillButton(label: String, bgColor: Int, borderColor: Int, textColor: Int): TextView =
        TextView(context).apply {
            text = label
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(textColor)
            gravity = Gravity.CENTER
            background = roundedBox(bgColor, borderColor, 1f, 12f)
            setPadding(dp(0), dp(10), dp(0), dp(10))
        }

    private fun roundedBox(
        bgColor: Int,
        borderColor: Int = 0,
        strokeWidthDp: Float = 0f,
        cornerRadiusDp: Float = 0f,
    ) = GradientDrawable().apply {
        setColor(bgColor)
        cornerRadius = dp(cornerRadiusDp.toInt()).toFloat()
        if (strokeWidthDp > 0 && borderColor != 0) {
            setStroke(dp(strokeWidthDp.toInt()), borderColor)
        }
    }

    private fun sendAction(action: String) {
        context.sendBroadcast(
            Intent(action).setPackage(context.packageName),
        )
    }

    private fun toggleMinimize() {
        isCollapsed = !isCollapsed
        collapsibleContent.visibility = if (isCollapsed) View.GONE else View.VISIBLE
        minimizeButton.text = if (isCollapsed) "▲" else "▼"
    }

    private fun toggleBubbleMode() {
        val wm = windowManager ?: return
        val lp = layoutParams ?: return
        isBubble = !isBubble

        if (isBubble) {
            dragHandle.visibility = View.GONE
            headerRow.visibility = View.GONE
            collapsibleContent.visibility = View.GONE
            bubbleView.visibility = View.VISIBLE

            background = null
            setPadding(0, 0, 0, 0)

            val bubbleSize = dp(56)
            lp.width = bubbleSize
            lp.height = bubbleSize
            wm.updateViewLayout(this, lp)
        } else {
            bubbleView.visibility = View.GONE
            dragHandle.visibility = View.VISIBLE
            headerRow.visibility = View.VISIBLE
            collapsibleContent.visibility = if (isCollapsed) View.GONE else View.VISIBLE

            setPadding(dp(20), dp(14), dp(20), dp(18))
            background = roundedBox(
                bgColor = 0xFF18191B.toInt(),
                borderColor = 0xFF2D3139.toInt(),
                strokeWidthDp = 1.5f,
                cornerRadiusDp = 24f,
            )

            val displayMetrics = context.resources.displayMetrics
            val width = dp(340).coerceAtMost(displayMetrics.widthPixels - dp(32))
            lp.width = width
            lp.height = WindowManager.LayoutParams.WRAP_CONTENT
            wm.updateViewLayout(this, lp)
        }
    }

    private fun setupDrag(target: View) {
        target.setOnTouchListener { v, event ->
            val wm = windowManager
            val lp = layoutParams
            if (wm != null && lp != null) {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = lp.x
                        initialY = lp.y
                        touchX = event.rawX
                        touchY = event.rawY
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        lp.x = initialX + (event.rawX - touchX).toInt()
                        lp.y = initialY + (event.rawY - touchY).toInt()
                        wm.updateViewLayout(this, lp)
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        val diffX = Math.abs(event.rawX - touchX)
                        val diffY = Math.abs(event.rawY - touchY)
                        if (diffX < 10 && diffY < 10) {
                            v.performClick()
                        }
                        true
                    }
                    else -> false
                }
            } else {
                false
            }
        }
    }

    fun update(state: BroadcastState) {
        titleView.text = if (state.campaignName.isNotEmpty()) state.campaignName else "Broadcast"
        val percent =
            if (state.total > 0) (state.currentIndex * 100 / state.total) else 0
        fractionView.text = "${state.currentIndex} / ${state.total}"
        barView.progress = percent

        val pending = (state.total - (state.sent + state.failed)).coerceAtLeast(0)
        sentValView.text = "${state.sent}"
        pendingValView.text = "$pending"
        failedValView.text = "${state.failed}"

        if (state.paused) {
            statusDotView.background = roundedBox(0xFFFF9800.toInt(), 0, 0f, 999f)
            statusTextView.text = "Paused"
            progressLabelView.text = "Broadcast Paused"
            toggleButton.text = "Resume"
        } else {
            statusDotView.background = roundedBox(0xFF25D366.toInt(), 0, 0f, 999f)
            val currentStatus = state.statusText ?: "Sending in progress..."
            statusTextView.text = currentStatus
            progressLabelView.text = currentStatus
            toggleButton.text = "Pause"
        }

        val name = state.currentContactName.ifEmpty { state.currentContactPhone }
        contactNameView.text = if (name.isNotEmpty()) name else "Preparing..."
        avatarView.text = getInitials(state.currentContactName, state.currentContactPhone)

        val remainingContacts = (state.total - state.currentIndex).coerceAtLeast(0)
        val secPerContact = state.delaySeconds + 3
        val remainingSec = remainingContacts * secPerContact
        val min = remainingSec / 60
        val sec = remainingSec % 60
        val timeStr = if (min > 0) "${min}m ${sec}s" else "${sec}s"
        timeRemainingView.text = "⏱ Estimated Time Remaining: $timeStr"
    }

    private fun getInitials(name: String, phone: String): String {
        val trimmed = name.trim()
        if (trimmed.isNotEmpty()) {
            val parts = trimmed.split("\\s+".toRegex())
            return if (parts.size >= 2) {
                "${parts[0].first().uppercaseChar()}${parts[1].first().uppercaseChar()}"
            } else if (trimmed.length >= 2) {
                trimmed.substring(0, 2).uppercase()
            } else {
                trimmed.uppercase()
            }
        }
        val phoneDigits = phone.filter { it.isDigit() }
        return if (phoneDigits.length >= 2) phoneDigits.takeLast(2) else "WA"
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    companion object {
        /** Factory that also adds the view to the window manager. */
        fun show(
            context: Context,
            state: BroadcastState,
        ): ProgressOverlayView {
            val view = ProgressOverlayView(context)
            view.update(state)
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val displayMetrics = context.resources.displayMetrics
            val width = view.dp(340).coerceAtMost(displayMetrics.widthPixels - view.dp(32))

            val params = WindowManager.LayoutParams(
                width,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = view.dp(50)
            }

            view.windowManager = wm
            view.layoutParams = params

            try {
                wm.addView(view, params)
            } catch (_: Exception) {
                return view
            }
            return view
        }
    }
}

/** Snapshot of the broadcast progress shown in the overlay. */
data class BroadcastState(
    val campaignId: String,
    val campaignName: String,
    val running: Boolean,
    val paused: Boolean,
    val currentIndex: Int,
    val total: Int,
    val sent: Int,
    val failed: Int,
    val currentContactName: String = "",
    val currentContactPhone: String = "",
    val delaySeconds: Int = 6,
    val statusText: String? = null,
)
