#ifndef _VMG_PLUGIN_INTERFACE_H_
#define _VMG_PLUGIN_INTERFACE_H_

#if BUILDING_DLL
# define DLLIMPORT __declspec (dllexport)
#else /* Not BUILDING_DLL */
# define DLLIMPORT __declspec (dllimport)
#endif /* Not BUILDING_DLL */

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

DLLIMPORT Cardinal Initialize (struct TPluginData vPluginData);
DLLIMPORT void Finalize (void);


#endif /* VMG_PLUGIN_INTERFACE_H_ */
