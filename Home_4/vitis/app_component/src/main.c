#include "xparameters.h"
#include "xgpio.h"
#include "xtmrctr.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "xil_exception.h"

#define LED_GPIO_BASEADDR    XPAR_XGPIO_0_BASEADDR
#define TIMER_BASEADDR       XPAR_AXI_TIMER_0_BASEADDR
#define BUTTON_GPIO_BASEADDR XPAR_XGPIO_1_BASEADDR

#define TIMER_TICK_1US       100U
#define TIMER_RESET_VALUE    (0xFFFFFFFFU - TIMER_TICK_1US + 1U)

#define SPEED_0_TICKS        25U
#define SPEED_1_TICKS        12U
#define SPEED_2_TICKS        6U


static XGpio LedGpio;
static XGpio ButtonGpio;
static XTmrCtr Timer;

static volatile u32 timer_ticks = 0;
static volatile u8 led_position = 0;
static volatile u8 speed_mode = 0;
static volatile u8 stopped = 0;
static volatile u8 button1_prev = 0;
static volatile u8 button2_prev = 0;


/*
 * Timer interrupt callback
 */
static void TimerCallback(void *CallBackRef, u8 TmrCtrNumber)
{
    u32 buttons;
    u8 button1;
    u8 button2;
    u32 speed_limit;

    (void)CallBackRef;
    (void)TmrCtrNumber;


    buttons = XGpio_DiscreteRead(
        &ButtonGpio,
        1
    );


    /*
     * -------------------------------------------------
     * Button 1
     *
     * Active HIGH:
     *
     * 0 = released
     * 1 = pressed
     *
     * Detect rising edge 0 -> 1
     * -------------------------------------------------
     */

    button1 = (buttons >> 1) & 0x1;

    if (button1 && !button1_prev)
    {
        speed_mode++;

        if (speed_mode >= 3)
        {
            speed_mode = 0;
        }

        timer_ticks = 0;
    }

    button1_prev = button1;


    /*
     * -------------------------------------------------
     * Button 2
     *
     * Active HIGH:
     *
     * 0 = released
     * 1 = pressed
     *
     * Detect rising edge 0 -> 1
     * -------------------------------------------------
     */

    button2 = (buttons >> 2) & 0x1;

    if (button2 && !button2_prev)
    {
        stopped ^= 1U;
        timer_ticks = 0;
    }

    button2_prev = button2;


    if (stopped)
    {
        return;
    }


    /*
     * -------------------------------------------------
     * Select LED switching interval
     * -------------------------------------------------
     */

    switch (speed_mode)
    {
        case 0:
            speed_limit = SPEED_0_TICKS;
            break;

        case 1:
            speed_limit = SPEED_1_TICKS;
            break;

        default:
            speed_limit = SPEED_2_TICKS;
            break;
    }


    timer_ticks++;

    if (timer_ticks >= speed_limit)
    {
        timer_ticks = 0;


        /*
         * -------------------------------------------------
         * PL_KEY
         *
         * Active LOW:
         *
         * 1 = released -> forward
         * 0 = pressed  -> reverse
         * -------------------------------------------------
         */

        if (buttons & 0x1)
        {
            led_position++;

            if (led_position >= 4)
            {
                led_position = 0;
            }
        }
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

        XGpio_DiscreteWrite(
            &LedGpio,
            1,
            (1U << led_position)
        );
    }
}


int main(void)
{
    int status;

    /*
     * -------------------------------------------------
     * LED GPIO
     * -------------------------------------------------
     */

    status = XGpio_Initialize(
        &LedGpio,
        LED_GPIO_BASEADDR
    );

    if (status != XST_SUCCESS)
    {
        xil_printf("GPIO init failed\r\n");
        return XST_FAILURE;
    }

    XGpio_SetDataDirection(
        &LedGpio,
        1,
        0x0
    );

    XGpio_DiscreteWrite(
        &LedGpio,
        1,
        0
    );


    /*
     * -------------------------------------------------
     * Button GPIO
     * -------------------------------------------------
     *
     * bit 0 = PL_KEY
     * bit 1 = Button 1
     * bit 2 = Button 2
     */

    status = XGpio_Initialize(
        &ButtonGpio,
        BUTTON_GPIO_BASEADDR
    );

    if (status != XST_SUCCESS)
    {
        xil_printf("Button GPIO init failed\r\n");
        return XST_FAILURE;
    }

    XGpio_SetDataDirection(
        &ButtonGpio,
        1,
        0x7
    );


    /*
     * -------------------------------------------------
     * Timer
     * -------------------------------------------------
     */

    status = XTmrCtr_Initialize(
        &Timer,
        TIMER_BASEADDR
    );

    if (status != XST_SUCCESS)
    {
        xil_printf("Timer init failed\r\n");
        return XST_FAILURE;
    }


    /*
     * Auto reload + interrupt mode
     */

    XTmrCtr_SetOptions(
        &Timer,
        0,
        XTC_AUTO_RELOAD_OPTION | XTC_INT_MODE_OPTION
    );


    /*
     * Register callback
     */

    XTmrCtr_SetHandler(
        &Timer,
        TimerCallback,
        &Timer
    );


    /*
     * Timer period = 1 us
     */

    XTmrCtr_SetResetValue(
        &Timer,
        0,
        TIMER_RESET_VALUE
    );


    /*
     * -------------------------------------------------
     * MicroBlaze interrupt system
     * -------------------------------------------------
     */

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XTmrCtr_InterruptHandler,
        &Timer
    );

    Xil_ExceptionEnable();


    /*
     * -------------------------------------------------
     * Start Timer
     * -------------------------------------------------
     */

    XTmrCtr_Start(
        &Timer,
        0
    );

    xil_printf("Timer started\r\n");

    while (1){}

    return XST_SUCCESS;
}