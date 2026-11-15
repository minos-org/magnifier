// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the DYNAMIC_MODE_COMPATIBLE_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// DYNAMIC_MODE_COMPATIBLE_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef DYNAMIC_MODE_COMPATIBLE_EXPORTS
#define DYNAMIC_MODE_COMPATIBLE_API __declspec(dllexport)
#else
#define DYNAMIC_MODE_COMPATIBLE_API __declspec(dllimport)
#endif

// This class is exported from the dynamic_mode_compatible.dll
class DYNAMIC_MODE_COMPATIBLE_API Cdynamic_mode_compatible {
public:
	Cdynamic_mode_compatible(void);
	// TODO: add your methods here.
};

extern DYNAMIC_MODE_COMPATIBLE_API int ndynamic_mode_compatible;

DYNAMIC_MODE_COMPATIBLE_API int fndynamic_mode_compatible(void);

////////////////////////////////////////////////////////////////////////////////

/* Definition of Pascal data types */

/* Cardinal is a unsigned 32-bits integer */
#define Cardinal unsigned int

/* Integer is a signed 32-bits integer */
#define Integer int

/* PInteger is a pointer to a Integer */
#define PInteger Integer*

/*  Plugin data structure */
struct TPluginData
{
    Cardinal DesktopWidth;
    Cardinal DesktopHeight;
    double* Magnification;
    PInteger GlassTop;
    PInteger GlassLeft;
    PInteger GlassWidth;
    PInteger GlassHeight;
    Integer  PluginData;
};

/* Prototypes of the exported functions */

DYNAMIC_MODE_COMPATIBLE_API Cardinal Initialize (struct TPluginData vPluginData);
DYNAMIC_MODE_COMPATIBLE_API void Finalize (void);
