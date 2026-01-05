#include "flutter_window.h"

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>

#include "generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(flutter::DartProject* project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = {};
  GetClientRect(GetHandle(), &frame);

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, *project_);

  // Ensure that the binary messenger is set up correctly.
  flutter::BinaryMessenger* binary_messenger =
      flutter_controller_->engine()->binary_messenger();
  if (!binary_messenger) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());

  SetChildContent(flutter_controller_->view()->GetHandle());
  return true;
}

void FlutterWindow::OnDestroy() {
  flutter_controller_ = nullptr;
  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter the first chance to handle this message.
  if (flutter_controller_) {
    LRESULT handled;
    if (flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam, &handled)) {
      return handled;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
