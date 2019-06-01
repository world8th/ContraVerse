// unify vertex/geometry/fragment input (varying)
#ifdef VSH
#define gin out 
#define vin out 
#define gap  
#define attribute in 
#endif
#ifdef GSH
#define gin out 
#define gap []
#define vin in // useless
#endif
#ifdef FSH
#define gin in 
#define vin in 
#define gap  
#endif
