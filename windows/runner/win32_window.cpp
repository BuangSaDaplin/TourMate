#include "win32_window.h"

#include <dwmapi.h>
#include <shellapi.h>

#include <algorithm>
#include <iostream>
#include <string>

// Converts a Win32 RECT to a Win32Window::Point.
Win32Window::Point RectToPoint(const RECT& rect) {
  Win32Window::Point point;
  point.x = rect.left;
  point.y = rect.top;
  return point;
}

// Converts a Win32 RECT to a Win32Window::Size.
Win32Window::Size RectToSize(const RECT& rect) {
  Win32Window::Size size;
  size.width = rect.right - rect.left;
  size.height = rect.bottom - rect.top;
  return size;
}

// The Windows DPI system is a bit complex. This function attempts to be
// useful on all supported versions of Windows.
static double GetDpiScaleFactorForWindow(HWND hwnd) {
  auto get_dpi_for_window = reinterpret_cast<decltype(&GetDpiForWindow)>(
      GetProcAddress(GetModuleHandle(TEXT("user32")), "GetDpiForWindow"));
  if (get_dpi_for_window) {
    return static_cast<double>(get_dpi_for_window(hwnd)) / 96.0;
  }
  HDC hdc = GetDC(hwnd);
  if (!hdc) {
    return 1.0;
  }
  double scale_factor =
      static_cast<double>(GetDeviceCaps(hdc, LOGPIXELSX)) / 96.0;
  ReleaseDC(hwnd, hdc);
  return scale_factor;
}

Win32Window::Win32Window() {}

Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::CreateAndShow(const std::wstring& title, const Point& origin,
                                const Size& size) {
  Destroy();

  WNDCLASS window_class{};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = L"Win32Window";
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon =
      LoadIcon(window_class.hInstance, MAKEINTRESOURCE(102));
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = Win32Window::WndProc;
  RegisterClass(&window_class);

  const DWORD style = WS_OVERLAPPEDWINDOW;
  const DWORD extended_style = WS_EX_APPWINDOW;

  RECT window_rect = {0, 0, size.width, size.height};
  AdjustWindowRectEx(&window_rect, style, false, extended_style);

  hwnd_ = CreateWindowEx(
      extended_style, window_class.lpszClassName, title.c_str(), style,
      origin.x, origin.y, window_rect.right - window_rect.left,
      window_rect.bottom - window_rect.top, nullptr, nullptr,
      GetModuleHandle(nullptr), this);

  if (!hwnd_) {
    return false;
  }

  ShowWindow(hwnd_, SW_SHOWNORMAL);
  UpdateWindow(hwnd_);

  return OnCreate();
}

void Win32Window::Destroy() {
  if (hwnd_) {
    OnDestroy();
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

HWND Win32Window::GetHandle() { return hwnd_; }

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() { return true; }

void Win32Window::OnDestroy() {}

LRESULT Win32Window::OnClose() {
  if (quit_on_close_) {
    Destroy();
  }
  return 0;
}

void Win32Window::OnActivate() {}

void Win32Window::OnDeactivate() {}

void Win32Window::OnBoundsChanged(const Point& origin, const Size& size) {}

void Win32Window::OnDpiScaleFactorChanged() {}

void Win32Window::OnThemeChanged() {}

void Win32Window::OnSettingChanged(DWORD setting) {}

LRESULT Win32Window::OnSystemCommand(UINT const command, const Point& location) {
  return 0;
}

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT const message,
                                    WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  return DefWindowProc(hwnd, message, wparam, lparam);
}

void Win32Window::SetChildContent(HWND content_window) {
  child_content_hwnd_ = content_window;
  if (hwnd_ && child_content_hwnd_) {
    SetParent(child_content_hwnd_, hwnd_);
    RECT frame;
    GetClientRect(hwnd_, &frame);
    MoveWindow(child_content_hwnd_, frame.left, frame.top,
               frame.right - frame.left, frame.bottom - frame.top, true);
    ShowWindow(child_content_hwnd_, SW_SHOW);
  }
}

LRESULT CALLBACK Win32Window::WndProc(HWND const hwnd, UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window = reinterpret_cast<Win32Window*>(
        reinterpret_cast<CREATESTRUCT*>(lparam)->lpCreateParams);
    SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window));
    window->hwnd_ = hwnd;
  } else if (Win32Window* window =
                 reinterpret_cast<Win32Window*>(GetWindowLongPtr(
                     hwnd, GWLP_USERDATA))) {
    switch (message) {
      case WM_DESTROY:
        window->OnDestroy();
        if (window->quit_on_close_) {
          PostQuitMessage(0);
        }
        return 0;
      case WM_CLOSE:
        return window->OnClose();
      case WM_ACTIVATE:
        if (LOWORD(wparam) == WA_INACTIVE) {
          window->OnDeactivate();
        } else {
          window->OnActivate();
        }
        return 0;
      case WM_SIZE:
        // If the size is 0, the window is being minimized.
        // If the size is SIZE_MAXIMIZED, the window is being maximized.
        if (wparam != SIZE_MINIMIZED) {
          RECT rect;
          GetClientRect(hwnd, &rect);
          window->OnBoundsChanged(RectToPoint(rect), RectToSize(rect));
        }
        return 0;
      case WM_DPICHANGED:
        window->OnDpiScaleFactorChanged();
        return 0;
      case WM_SETTINGCHANGE:
        window->OnSettingChanged(wparam);
        return 0;
      case WM_SYSCOMMAND:
        return window->OnSystemCommand(wparam, {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)});
      case WM_THEMECHANGE:
        window->OnThemeChanged();
        return 0;
    }
    return window->MessageHandler(hwnd, message, wparam, lparam);
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}
