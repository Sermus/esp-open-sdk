#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_common.h>

void test_task(void *pvParameters)
{
    os_printf("Hello World\n");    
    vTaskDelete(NULL);
}

void user_init(void)
{
    os_printf("Creating test task\n");
    xTaskCreate(test_task, "test_task", 1024, NULL, 1, NULL);
}
