/*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#include <cstdio>
#include "IPlugFruity.h"
#include "IPlugPluginBase.h"

using namespace iplug;

TFruityPlugInfo PlugInfo = {
	CurrentSDKVersion,
	"",
	"",
	0,
	0,
	0  // infinite
};

IPlugFruity::IPlugFruity(const InstanceInfo& info, const Config& config)
  : IPlugAPIBase(config, kAPIFRUITY)
  , IPlugProcessor(config, kAPIFRUITY)
  , TCPPFruityPlug(info.Tag, info.Host, info.Hinstance, info.bundleID)
{
  Trace(TRACELOC, "%s", config.pluginName);
  
  PlugInfo.SDKVersion = CurrentSDKVersion;
  PlugInfo.LongName = (char*)config.pluginName;
  PlugInfo.ShortName = (char*)config.pluginName;
  PlugInfo.Flags = FPF_Type_Effect | FPF_Type_Visual;
  
#ifdef __APPLE__
  PlugInfo.Flags |= FPF_MacNeedsNSView;
#endif

  int nInputs = MaxNChannels(ERoute::kInput), nOutputs = MaxNChannels(ERoute::kOutput);
  
  PlugInfo.NumParams = 0;
  mInstanceInfo = info;

  Info = &PlugInfo;

  // Default everything to connected, then disconnect pins if the host says to.
  SetChannelConnections(ERoute::kInput, 0, nInputs, true);
  SetChannelConnections(ERoute::kOutput, 0, nOutputs, true);

  SetBlockSize(DEFAULT_BLOCK_SIZE);
  
  CreateTimer();
}

void IPlugFruity::BeginInformHostOfParamChange(int idx)
{
}

void IPlugFruity::InformHostOfParamChange(int idx, double normalizedValue)
{
}

void IPlugFruity::EndInformHostOfParamChange(int idx)
{
}

void IPlugFruity::InformHostOfPresetChange()
{
}

void IPlugFruity::HostSpecificInit()
{
}

bool IPlugFruity::EditorResize(int viewWidth, int viewHeight)
{
  if (HasUI())
  {
    if (viewWidth != GetEditorWidth() || viewHeight != GetEditorHeight())
    {
      SetEditorSize(viewWidth, viewHeight);
    }

    RECT r;
    GetWindowRect(EditorHandle, &r);
    SetWindowPos(EditorHandle, 0, r.left, r.bottom - viewHeight, viewWidth, viewHeight, 0);

    PlugHost->Dispatcher(HostTag, FHD_EditorResized, 0, 0);    
  }

  return false;
}

void IPlugFruity::SetLatency(int samples)
{
}

bool IPlugFruity::SendMidiMsg(const IMidiMsg& msg)
{
  return false;
}

bool IPlugFruity::SendSysEx(const ISysEx& msg)
{
  return false;
}


void STDMETHODCALLTYPE IPlugFruity::DestroyObject()
{
	//AFX_MANAGE_STATE(AfxGetStaticModuleState());

	//delete editor;
}

//int STDMETHODCALLTYPE IPlugFruity::Dispatcher(int ID, int Index, int Value)
//{
//	//AFX_MANAGE_STATE(AfxGetStaticModuleState());
//
//	//switch (ID)
//	//{
//	//	// show the editor
//	//case FPD_ShowEditor:
//	//	if (Value == 0)
//	//	{
//	//		editor->ShowWindow(SW_HIDE);
//	//		SetParent(editor->m_hWnd, 0);
//	//	}
//	//	else
//	//	{
//	//		SetParent(editor->m_hWnd, (HWND)Value);
//	//		editor->ShowWindow(SW_SHOW);
//	//	}
//	//	EditorHandle = editor->m_hWnd;
//	//	break;
//	//}
//
//	return 0;
//}

void STDMETHODCALLTYPE IPlugFruity::Eff_Render(PWAV32FS SourceBuffer, PWAV32FS DestBuffer, int Length)
{
	//float left, right;

	//left = GainLeft;
	//right = GainRight;

	//for (int i = 0; i < Length; i++)
	//{
	//	(*DestBuffer)[i][0] = (*SourceBuffer)[i][0] * left;
	//	(*DestBuffer)[i][1] = (*SourceBuffer)[i][1] * right;
	//}
}
void __stdcall IPlugFruity::Gen_Render(PWAV32FS DestBuffer, int& Length)
{
}
int __stdcall IPlugFruity::Voice_ProcessEvent(TVoiceHandle Handle, int EventID, int EventValue, int Flags)
{
  return 0;
}
int __stdcall IPlugFruity::Voice_Render(TVoiceHandle Handle, PWAV32FS DestBuffer, int& Length)
{
  return 0;
}
intptr_t STDMETHODCALLTYPE IPlugFruity::Dispatcher(intptr_t ID, intptr_t Index, intptr_t Value)
{ 
	if (FPD_ShowEditor == ID && Value)
	{
		EditorHandle = (HWND)OpenWindow((void*)Value);

		//mPlug->OnGUIOpen();
		//mPlug->ResizeAtGUIOpen(mPlug->GetGUI());

		// don't want idle messages
		//mInstanceInfo.Host->Dispatcher(HostTag, FHD_WantIdle, 0, 0);
	}
	if (FPD_ShowEditor == ID && !Value)
	{
		CloseWindow();
    EditorHandle = (HWND)nullptr;
	}
	return 0;
}
void STDMETHODCALLTYPE IPlugFruity::GetName(int Section, int Index, int Value, char *Name)
{
	//if (Section == FPN_Param)
	//{
	//	switch (Index)
	//	{
	//	case prmGainLeft:  strcpy(Name, "Left Gain");  break;
	//	case prmGainRight:  strcpy(Name, "Right Gain");  break;
	//	}
	//}
	//else if (Section == FPN_ParamValue)
	//{
	//	switch (Index)
	//	{
	//	case prmGainLeft:  sprintf(Name, "%.2fx", GainLeft);  break;
	//	case prmGainRight:  sprintf(Name, "%.2fx", GainRight);  break;
	//	}
	//}
}

void STDMETHODCALLTYPE IPlugFruity::Idle_Public()
{
	/*
	TControl *Control;
	POINT P;

	if (GetCaptureControl() != 0)
	return;

	GetCursorPos(&P);
	Control = FindDragTarget(P, true);
	if (Control != 0)
	{
	if (strcmp(AppHint, Control->Hint.c_str()) != 0)
	{
	strcpy(AppHint, Control->Hint.c_str());
	PlugHost->OnHint(HostTag, AppHint);
	}
	}
	*/
}

int STDMETHODCALLTYPE IPlugFruity::ProcessParam(int Index, int Value, int RECFlags)
{
	//if (Index < NumParams)
	//{
	//	if (RECFlags && REC_FromMIDI != 0)
	//		Value = TranslateMidi(Value, GainMinimum, GainMaximum);

	//	if (RECFlags && REC_UpdateValue != 0)
	//	{
	//		switch (Index)
	//		{
	//		case prmGainLeft:  GainLeftInt = Value;  break;
	//		case prmGainRight:  GainRightInt = Value;  break;
	//		}
	//		GainIntToSingle();
	//	}

	//	else if (RECFlags && REC_GetValue != 0)
	//	{
	//		switch (Index)
	//		{
	//		case prmGainLeft:  Value = GainLeftInt;  break;
	//		case prmGainRight:  Value = GainRightInt;  break;
	//		}
	//	}

	//	if (RECFlags && REC_UpdateControl != 0)
	//		editor->ParamsToControls();
	//}

	//return Value;

	return 0;
}

void STDMETHODCALLTYPE IPlugFruity::SaveRestoreState(IStream *Stream, BOOL Save)
{
	//unsigned long written, read;

	//if (Save)
	//{
	//	Stream->Write(&GainLeftInt, sizeof(long), &written);
	//	Stream->Write(&GainRightInt, sizeof(long), &written);
	//}
	//else
	//{
	//	Stream->Read(&GainLeftInt, sizeof(long), &read);
	//	Stream->Read(&GainRightInt, sizeof(long), &read);

	//	GainIntToSingle();
	//	ProcessAllParams();
	//}
}