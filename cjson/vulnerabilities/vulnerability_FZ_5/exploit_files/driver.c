#include "cJSON.h"
int main(void){
  cJSON* shared = cJSON_CreateArray();
  cJSON_AddItemToArray(shared, cJSON_CreateNumber(1));
  cJSON* obj = cJSON_CreateObject();
  cJSON_AddItemReferenceToObject(obj, "r", shared);
  cJSON_Delete(obj);
  cJSON_Delete(shared);
  return 0;
}
