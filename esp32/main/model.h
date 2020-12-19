#ifndef __MODEL_H__
#define __MODEL_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    MODEL_UNKNOWN,
    MODEL_16K,
    MODEL_48K,
    MODEL_128K,
    MODEL_2APLUS,
    MODEL_3A
} model_t;

model_t model__get(void);
void model__set(model_t);


#ifdef __cplusplus
}
#endif

#endif