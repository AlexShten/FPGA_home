#include "xgpio.h"
#include "xtmrctr.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "xinterrupt_wrap.h"


/* ============================================================
 * GPIO
 * ============================================================ */

#define LED_GPIO_BASEADDR      XPAR_XGPIO_0_BASEADDR
#define BUTTON_GPIO_BASEADDR   XPAR_XGPIO_1_BASEADDR

/* Button masks */

#define PL_KEY_MASK       0x01    /* M19, active-low  */
#define SPEED_KEY_MASK    0x02    /* P15, active-high */
#define STOP_KEY_MASK     0x04    /* P16, active-high */


/* ============================================================
 * AXI Timer
 * ============================================================ */

#define TIMER_BASEADDR    XPAR_AXI_TIMER_0_BASEADDR

#define TIMER_CLOCK_HZ    50000000U

/*
 * Timer interrupt period = 1 ms
 *
 * 50 MHz * 1 ms = 50000 clocks
 */

#define TIMER_TICK_MS     1U

#define TIMER_TICKS       \
    (TIMER_CLOCK_HZ / 1000U)


/* ============================================================
 * LED speeds
 * ============================================================ */

static const u32 speed_period_ms[] =
{
    1000U,
    500U,
    250U,
    125U
};

#define SPEED_COUNT 4
#define DEBOUNCE_TIME_MS 50U

/* ============================================================
 * Hardware objects
 * ============================================================ */

static XGpio LedGpio;
static XGpio ButtonGpio;
static XTmrCtr Timer;


/* ============================================================
 * Application state
 * ============================================================ */

static volatile u32 led_position = 0;
static volatile int direction = 1;
static volatile int running = 1;
static volatile u32 speed_index = 0;

/*
 * Number of 1-ms ticks since the last LED movement.
 */

static volatile u32 led_timer_ms = 0;


/* ============================================================
 * Button debounce state
 * ============================================================ */

typedef struct
{
    u8 raw_state;
    u8 stable_state;
    u8 counter;

} ButtonDebounceState;


/* ============================================================
 * Button events
 *
 * These flags are set by Timer ISR and processed in main().
 * ============================================================ */

static volatile u8 direction_event = 0;
static volatile u8 speed_event = 0;
static volatile u8 stop_event = 0;

/* ============================================================
 * Timer reload value
 *
 * 1 ms interrupt
 * ============================================================ */

static u32 TimerReloadValue(void)
{
    return 0xFFFFFFFFU -
           TIMER_TICKS +
           1U;
}


/* ============================================================
 * Debounce one button
 *
 * raw_state:
 *
 *      0 = released
 *      1 = pressed
 *
 * Returns:
 *
 *      1 = new confirmed press
 *      0 = nothing
 *
 * ============================================================ */

static volatile u8 button_stable = 0;
static volatile u8 button_last_raw = 0;
static volatile u8 button_count = 0;
 
static void ProcessButtons(u32 buttons)
{
    u8 current;

    /*
     * Normalize button polarity:
     *
     * bit 0: PL_KEY   active LOW
     * bit 1: SPEED    active HIGH
     * bit 2: STOP     active HIGH
     */
    current = 0;

    if (!(buttons & PL_KEY_MASK))
        current |= 0x01;

    if (buttons & SPEED_KEY_MASK)
        current |= 0x02;

    if (buttons & STOP_KEY_MASK)
        current |= 0x04;


    /*
     * Raw state changed -> restart debounce.
     */
    if (current != button_last_raw) {
        button_last_raw = current;
        button_count = 0;
        return;
    }


    /*
     * State has remained unchanged long enough.
     */
    if (button_count < DEBOUNCE_TIME_MS)
        button_count++;

    if (button_count == DEBOUNCE_TIME_MS) {

        /*
         * Generate events only for newly pressed buttons.
         */
        u8 pressed;

        pressed = current & ~button_stable;

        if (pressed & 0x01)
            direction_event = 1;

        if (pressed & 0x02)
            speed_event = 1;

        if (pressed & 0x04)
            stop_event = 1;

        button_stable = current;
    }
}


/* ============================================================
 * Timer interrupt handler
 * ============================================================ */

static void TimerHandler(
    void *CallBackRef,
    u8 TmrCtrNumber)
{
    u32 buttons;

    (void)CallBackRef;
    (void)TmrCtrNumber;


    /* --------------------------------------------------------
     * Read buttons
     * -------------------------------------------------------- */

    buttons =
        XGpio_DiscreteRead(
            &ButtonGpio,
            1);


    /* --------------------------------------------------------
     * Debounce
     * -------------------------------------------------------- */

    buttons = XGpio_DiscreteRead(&ButtonGpio, 1);

    ProcessButtons(buttons);


    /* --------------------------------------------------------
     * LED movement timer
     * -------------------------------------------------------- */

    if (running)
    {
        led_timer_ms++;


        /*
         * Time for next LED?
         */

        if (led_timer_ms >=
            speed_period_ms[speed_index])
        {
            led_timer_ms = 0;


            /* Forward */

            if (direction > 0)
            {
                led_position++;

                if (led_position >= 4)
                {
                    led_position = 0;
                }
            }


            /* Reverse */

            else
            {
                if (led_position == 0)
                {
                    led_position = 3;
                }
                else
                {
                    led_position--;
                }
            }


            /*
             * Update LEDs.
             */

            XGpio_DiscreteWrite(
                &LedGpio,
                1,
                1U << led_position);
        }
    }
}

int main(void)
{
    int status;


    /* --------------------------------------------------------
     * Initialize LED GPIO
     * -------------------------------------------------------- */

    status = XGpio_Initialize(
        &LedGpio,
        LED_GPIO_BASEADDR);

    if (status != XST_SUCCESS)
    {
        xil_printf(
            "LED GPIO initialization failed\r\n");

        return XST_FAILURE;
    }


    XGpio_SetDataDirection(
        &LedGpio,
        1,
        0x0);


    /* --------------------------------------------------------
     * Initialize Button GPIO
     * -------------------------------------------------------- */

    status = XGpio_Initialize(
        &ButtonGpio,
        BUTTON_GPIO_BASEADDR);

    if (status != XST_SUCCESS)
    {
        xil_printf(
            "Button GPIO initialization failed\r\n");

        return XST_FAILURE;
    }


    XGpio_SetDataDirection(
        &ButtonGpio,
        1,
        0x7);


    /* --------------------------------------------------------
     * Initialize AXI Timer
     * -------------------------------------------------------- */

    status = XTmrCtr_Initialize(
        &Timer,
        TIMER_BASEADDR);

    if (status != XST_SUCCESS)
    {
        xil_printf(
            "Timer initialization failed\r\n");

        return XST_FAILURE;
    }


    /* --------------------------------------------------------
     * Setup interrupt
     * -------------------------------------------------------- */

    status = XSetupInterruptSystem(
        &Timer,
        (XInterruptHandler)
            XTmrCtr_InterruptHandler,
        Timer.Config.IntrId,
        Timer.Config.IntrParent,
        XINTERRUPT_DEFAULT_PRIORITY);

    if (status != XST_SUCCESS)
    {
        xil_printf(
            "Interrupt setup failed\r\n");

        return XST_FAILURE;
    }


    /* --------------------------------------------------------
     * Timer callback
     * -------------------------------------------------------- */

    XTmrCtr_SetHandler(
        &Timer,
        TimerHandler,
        &Timer);


    /* --------------------------------------------------------
     * Timer configuration
     * -------------------------------------------------------- */

    XTmrCtr_SetResetValue(
        &Timer,
        0,
        TimerReloadValue());


    XTmrCtr_SetOptions(
        &Timer,
        0,
        XTC_INT_MODE_OPTION |
        XTC_AUTO_RELOAD_OPTION);


    /* --------------------------------------------------------
     * Initial state
     * -------------------------------------------------------- */

    led_position = 0;
    direction = 1;
    running = 1;
    speed_index = 0;
    led_timer_ms = 0;


    /*
     * LED0 ON
     */

    XGpio_DiscreteWrite(
        &LedGpio,
        1,
        1U << led_position);

    /* --------------------------------------------------------
     * Start Timer
     * -------------------------------------------------------- */

    XTmrCtr_Start(
        &Timer,
        0);

    /* --------------------------------------------------------
     * Main loop
     * -------------------------------------------------------- */

    while (1)
    {
        /*
         * Direction button event.
         */

        if (direction_event)
        {
            direction_event = 0;

            direction = -direction;


            xil_printf(
                "Direction: %s\r\n",
                direction > 0
                    ? "forward"
                    : "reverse");
        }


        /*
         * Speed button event.
         */

        if (speed_event)
        {
            speed_event = 0;


            speed_index++;

            if (speed_index >= SPEED_COUNT)
            {
                speed_index = 0;
            }


            /*
             * Reset LED timer so that
             * new speed starts from zero.
             */

            led_timer_ms = 0;


            xil_printf(
                "Speed: %d ms\r\n",
                speed_period_ms[
                    speed_index]);
        }


        /*
         * STOP/RUN button event.
         */

        if (stop_event)
        {
            stop_event = 0;

            running = !running;


            if (running)
            {
                /*
                 * Start a new movement interval.
                 */

                led_timer_ms = 0;

                xil_printf("RUN\r\n");
            }
            else
            {
                xil_printf("STOP\r\n");
            }
        }
    }


    return XST_SUCCESS;
}