/*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#ifndef _IPLUGAPI_
#define _IPLUGAPI_
// Only load one API class!

/**
 * @file
 * @copydoc IPlugFruity
 */

#include "IPlugAPIBase.h"
#include "IPlugProcessor.h"
#include "fp_plugclass.h"
#include "fp_cplug.h"
//#include "fp_def.h"
//#include "fp_extra.h"
//#include "generictransport.h"


BEGIN_IPLUG_NAMESPACE

/** Used to pass various instance info to the API class */
struct InstanceInfo
{
	TFruityPlugHost *Host = NULL;
	int Tag = 0;
	HINSTANCE Hinstance = NULL;
  const char* bundleID = NULL;
};

/**  Fruity API base class for an IPlug plug-in
*   @ingroup APIClasses */
class IPlugFruity : public IPlugAPIBase
                  , public IPlugProcessor
				          , public TCPPFruityPlug
{
public:
  IPlugFruity(const InstanceInfo& info, const Config& config);

  //IPlugAPIBase
  void BeginInformHostOfParamChange(int idx) override;
  void InformHostOfParamChange(int idx, double normalizedValue) override;
  void EndInformHostOfParamChange(int idx) override;
  void InformHostOfPresetChange() override;
  void HostSpecificInit() override;
  bool EditorResize(int viewWidth, int viewHeight) override;

  //IPlugProcessor
  void SetLatency(int samples) override;
  bool SendMidiMsg(const IMidiMsg& msg) override;
  bool SendSysEx(const ISysEx& msg) override;

private:
  // Fruity stuff
  virtual void STDMETHODCALLTYPE DestroyObject();
 // virtual int STDMETHODCALLTYPE Dispatcher(int ID, int Index, int Value);
  virtual void STDMETHODCALLTYPE Idle_Public();
  virtual void STDMETHODCALLTYPE SaveRestoreState(IStream *Stream, BOOL Save);

  // names (see FPN_Param) (Name must be at least 256 chars long)
  virtual void STDMETHODCALLTYPE GetName(int Section, int Index, int Value, char *Name);

  // events
  virtual int STDMETHODCALLTYPE ProcessParam(int Index, int Value, int RECFlags);

  // effect processing (source & dest can be the same)
  virtual void STDMETHODCALLTYPE Eff_Render(PWAV32FS SourceBuffer, PWAV32FS DestBuffer, int Length);

  // generator processing (can render less than length)
  virtual void STDMETHODCALLTYPE Gen_Render(PWAV32FS DestBuffer, int& Length);

  // voice handling
  virtual int STDMETHODCALLTYPE Voice_ProcessEvent(TVoiceHandle Handle, int EventID, int EventValue, int Flags);
  virtual int STDMETHODCALLTYPE Voice_Render(TVoiceHandle Handle, PWAV32FS DestBuffer, int& Length);


  intptr_t STDMETHODCALLTYPE Dispatcher(intptr_t ID, intptr_t Index, intptr_t Value);

  IByteChunk mState;     // Persistent storage if the host asks for plugin state.
  IByteChunk mBankState; // Persistent storage if the host asks for bank state.
protected:
  TFruityPlugInfo mPlugInfo;
  InstanceInfo mInstanceInfo;
};

#ifndef REAPER_PLUGIN
IPlugFruity* MakePlug(const InstanceInfo& info);
#endif

END_IPLUG_NAMESPACE

#endif
