#include "xil_io.h"
#include "xil_printf.h"
#include "xil_types.h"


/*
 * ============================================================
 * Base addresses
 * ============================================================
 */

#define GPIO_BASE       0x40000000U
#define DMA_BASE        0x41E00000U
#define FRAME_BUFFER    0x00010000U
#define FRAME_SIZE      64000U

/*
 * ============================================================
 * AXI GPIO registers
 * ============================================================
 */

#define GPIO_CH1_DATA   0x00U
#define GPIO_CH1_TRI    0x04U
#define GPIO_CH2_DATA   0x08U
#define GPIO_CH2_TRI    0x0CU

/*
 * ============================================================
 * AXI DMA S2MM registers
 * ============================================================
 */

#define S2MM_DMACR     0x30U
#define S2MM_DMASR     0x34U
#define S2MM_DA        0x48U
#define S2MM_DA_MSB    0x4CU
#define S2MM_LENGTH    0x58U

/*
 * ============================================================
 * AXI DMA control bits
 * ============================================================
 */

#define DMA_DMACR_RS       0x00000001U
#define DMA_DMACR_RESET    0x00000004U

#define DMA_DMASR_HALTED   0x00000001U
#define DMA_DMASR_IDLE     0x00000002U

#define DMA_DMASR_IOC_IRQ  0x00001000U
#define DMA_DMASR_DLY_IRQ  0x00002000U
#define DMA_DMASR_ERR_IRQ  0x00004000U

/*
 * ============================================================
 * GPIO helper functions
 * ============================================================
 */

static void gpio_init(void)
{
    /*
     * Channel 1 = input
     */
    Xil_Out32(
        GPIO_BASE + GPIO_CH1_TRI,
        0xFFFFFFFFU
    );

    /*
     * Channel 2 = output
     */
    Xil_Out32(
        GPIO_BASE + GPIO_CH2_TRI,
        0x00000000U
    );

    /*
     * START = 0
     */
    Xil_Out32(
        GPIO_BASE + GPIO_CH2_DATA,
        0x00000000U
    );
}

static u32 button_read(void)
{
    return Xil_In32(
        GPIO_BASE + GPIO_CH1_DATA
    ) & 0x1U;
}

static void frame_start_pulse(void)
{
    /*
     * START = 1
     */
    Xil_Out32(
        GPIO_BASE + GPIO_CH2_DATA,
        0x00000001U
    );

    /*
     * START = 0
     */
    Xil_Out32(
        GPIO_BASE + GPIO_CH2_DATA,
        0x00000000U
    );
}

/*
 * ============================================================
 * DMA initialization
 * ============================================================
 */

static int dma_init(void)
{
    u32 status;

    /*
     * Reset S2MM channel
     */
    Xil_Out32(
        DMA_BASE + S2MM_DMACR,
        DMA_DMACR_RESET
    );

    /*
     * Wait until reset is completed.
     */
    do
    {
        status = Xil_In32(
            DMA_BASE + S2MM_DMACR
        );

    } while (status & DMA_DMACR_RESET);

    /*
     * Read DMA status
     */
    status = Xil_In32(
        DMA_BASE + S2MM_DMASR
    );

    return 0;
}

/*
 * ============================================================
 * Start one S2MM transfer
 * ============================================================
 */

static int dma_start(void)
{
    u32 status;

    /*
     * Destination address.
     *
     * Frame will be written to:
     *
     * 0x00010000
     *
     */
    Xil_Out32(
        DMA_BASE + S2MM_DA,
        FRAME_BUFFER
    );

    /*
     * Upper 32 bits = 0
     */
    Xil_Out32(
        DMA_BASE + S2MM_DA_MSB,
        0x00000000U
    );

    /*
     * Start S2MM channel.
     */
    Xil_Out32(
        DMA_BASE + S2MM_DMACR,
        DMA_DMACR_RS
    );

    /*
     * Read status for diagnostics.
     */
    status = Xil_In32(
        DMA_BASE + S2MM_DMASR
    );

    /*
     * Writing LENGTH starts the transfer.
     */
    Xil_Out32(
        DMA_BASE + S2MM_LENGTH,
        FRAME_SIZE
    );

    return 0;
}

/*
 * ============================================================
 * Wait for DMA completion
 * ============================================================
 */

static int dma_wait(void)
{
    u32 status;

    while (1)
    {
        status = Xil_In32(
            DMA_BASE + S2MM_DMASR
        );

        /*
         * DMA error
         */
        if (status & DMA_DMASR_ERR_IRQ)
        {
            xil_printf(
                "ERROR: DMA status = 0x%08X\r\n",
                status
            );

            return -1;
        }

        /*
         * IOC interrupt status.
         *
         * We are polling it rather than using
         * a MicroBlaze interrupt for now.
         */
        if (status & DMA_DMASR_IOC_IRQ)
        {
            xil_printf(
                "DMA transfer complete\r\n"
            );

            return 0;
        }
    }
}

int main(void)
{

    gpio_init();
    dma_init();

    while (1)
    {
        if (button_read())
        {
            dma_start();
            frame_start_pulse();

            /*
             * Wait until 64000 bytes
             * have been received.
             */
            if (dma_wait() == 0)
            {
                xil_printf(
                    "FRAME CAPTURE COMPLETE\r\n"
                );
            }

            /*
             * Wait until button is released.
             *
             * This prevents one long button press
             * from starting multiple frames.
             */
            while (button_read())
            {
                ;
            }

        }
    }

    return 0;
}