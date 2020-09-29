#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "freertos/queue.h"
#include "wsys.h"
#include "wsys/screen.h"
#include "wsys/menuwindow.h"
#include "fpga.h"
#include "wsys/messagebox.h"
#include "wsys/pixel.h"
#include "wsys/filechooserdialog.h"
#include "menus/nmimenu.h"

struct wsys_event {
    uint8_t type;
    u16_8_t data;
};

static xQueueHandle wsys_evt_queue = NULL;

void wsys__keyboard_event(uint16_t raw, char ascii)
{
    struct wsys_event evt;
    evt.data.v = raw;
    evt.type = 0;
    xQueueSend(wsys_evt_queue, &evt, portMAX_DELAY);
    portYIELD();
}

void wsys__get_screen_from_fpga()
{
    fpga__read_extram_block(0x002006, &spectrum_framebuffer.screen[0], sizeof(spectrum_framebuffer));
}

void wsys__nmiready()
{
    struct wsys_event evt;
    evt.type = EVENT_NMIENTER;
    xQueueSend(wsys_evt_queue, &evt, portMAX_DELAY);
    portYIELD();
}

void wsys__nmileave()
{
    struct wsys_event evt;
    evt.type = EVENT_NMILEAVE;
    xQueueSend(wsys_evt_queue, &evt, portMAX_DELAY);
}


void wsys__start()
{
    wsys__get_screen_from_fpga();
    nmimenu__show();
    screen__redraw();

}

void wsys__reset()
{
    struct wsys_event evt;
    evt.type = 2;
    wsys__send_command(0x00); // Clear sequence immediatly
    xQueueSend(wsys_evt_queue, &evt, portMAX_DELAY);
}



static void wsys__dispatchevent(struct wsys_event evt)
{
    switch(evt.type) {
    case EVENT_KBD:
        screen__keyboard_event(evt.data);
        break;
    case EVENT_RESET:
        break;
    case EVENT_NMIENTER:
        //WSYS_LOGI( "Resetting screen");
        wsys__start();
        break;
    case EVENT_NMILEAVE:
        WSYS_LOGI( "Reset sequences");
        spectrum_framebuffer.seq = 0;
        wsys__send_command(0x00);
        screen__destroyAll();
        break;
    }
}

void wsys__eventloop_iter()
{
    struct wsys_event evt;
    if (xQueueReceive(wsys_evt_queue, &evt, portMAX_DELAY)) {
        wsys__dispatchevent(evt);
    }
    screen__check_redraw();
}

void wsys__task(void *data __attribute__((unused)))
{
    screen__init();
    //xQueueSend(wsys_evt_queue, &gpio_num, NULL);
    while (1) {
        wsys__eventloop_iter();
    }
}


void wsys__sendEvent()
{
}

void wsys__init()
{
    wsys_evt_queue = xQueueCreate(4, sizeof(struct wsys_event));
    xTaskCreate(wsys__task, "wsys_task", 4096, NULL, 9, NULL);
}


void wsys__send_to_fpga()
{
    spectrum_framebuffer.seq++;
    spectrum_framebuffer.seq &= 0x7F;
    WSYS_LOGI("Framebuffer update, seq %d\n", spectrum_framebuffer.seq);
    fpga__write_extram_block(0x020000, &spectrum_framebuffer.screen[0], sizeof(spectrum_framebuffer));
}

void wsys__send_command(uint8_t command)
{
    fpga__write_extram_block(0x021B00, &command, 1);
}
