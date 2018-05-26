#pragma once

#include "IGraphics_include_in_plug_hdr.h"
#include "IPlugGraphicsDelegate.h"

#define UI_WIDTH 700
#define UI_HEIGHT 700
#define UI_FPS 60
#define BUNDLE_ID "com.OliLarkin.app.IGraphicsTest"

class IGraphicsTest : public IGraphicsEditorDelegate
{
public:
  IGraphicsTest();
  ~ IGraphicsTest() {}

  //IEditorDelegate
  void SetParameterValueFromUI(int paramIdx, double value) override;
  void BeginInformHostOfParamChangeFromUI(int paramIdx) override { };
  void EndInformHostOfParamChangeFromUI(int paramIdx) override { };
};
