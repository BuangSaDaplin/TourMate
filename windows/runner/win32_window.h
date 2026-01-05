#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <string>

// A base class for a simple Win32 window.
class Win32Window {
 public:
  struct Point {
    long x;
    long y;
  };

  struct Size {
    long width;
    long height;
  };

  explicit Win32Window();
  virtual ~Win32Window();

  // Creates the Win32 window and registers the window class.
  bool CreateAndShow(const std::wstring& title, const Point& origin,
                     const Size& size);

  // Disposes the Win32 window.
  void Destroy();

  // The Win32 window handle.
  HWND GetHandle();

  // Register a callback function that is invoked when the window is about to
  // close.
  void SetQuitOnClose(bool quit_on_close);

 protected:
  // Called when the window is being created.
  virtual bool OnCreate();

  // Called when the window is being destroyed.
  virtual void OnDestroy();

  // Called when the window is being closed.
  virtual LRESULT OnClose();

  // Called when the window is being activated.
  virtual void OnActivate();

  // Called when the window is being deactivated.
  virtual void OnDeactivate();

  // Called when the window's size or position changes.
  virtual void OnBoundsChanged(const Point& origin, const Size& size);

  // Called when the window's DPI changes.
  virtual void OnDpiScaleFactorChanged();

  // Called when the window's theme changes.
  virtual void OnThemeChanged();

  // Called when the window's setting changes.
  virtual void OnSettingChanged(DWORD setting);

  // Called when the window's system command is received.
  virtual LRESULT OnSystemCommand(UINT const command, const Point& location);

  // Called when the window's message is received.
  virtual LRESULT MessageHandler(HWND hwnd, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Set the child content of the window.
  void SetChildContent(HWND content_window);

 private:
  // The Win32 callback function.
  static LRESULT CALLBACK WndProc(HWND const hwnd, UINT const message,
                                  WPARAM const wparam, LPARAM const lparam);

  // The Win32 window handle.
  HWND hwnd_;

  // The child content window handle.
  HWND child_content_hwnd_;

  // Whether to quit the application when the window is closed.
  bool quit_on_close_;
};

#endif  // RUNNER_WIN32_WINDOW_H_
