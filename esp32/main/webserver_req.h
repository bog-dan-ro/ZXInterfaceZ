#ifndef __WEBSERVER_REQ_H__
#define __WEBSERVER_REQ_H__

#include "esp_http_server.h"
#include "cJSON.h"

typedef esp_err_t (*webserver_req_handler_t)(httpd_req_t *req, cJSON *args);

webserver_req_handler_t webserver_req__find_handler(const char *path);

#endif
