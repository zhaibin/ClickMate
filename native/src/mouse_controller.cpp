#include "mouse_controller.h"
#include <windows.h>
#include <map>
#include <mutex>

// 热键状态管理
static std::map<int, bool> hotkeyStates;
static std::mutex hotkeyMutex;
static HWND messageWindow = nullptr;
static bool isInitialized = false;

// 窗口过程函数
LRESULT CALLBACK HotkeyWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (msg == WM_HOTKEY) {
        int id = static_cast<int>(wParam);
        std::lock_guard<std::mutex> lock(hotkeyMutex);
        hotkeyStates[id] = true;
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

// 初始化热键系统
bool initHotkeySystem() {
    if (isInitialized) {
        return true;
    }

    // 创建隐藏窗口用于接收热键消息
    WNDCLASSEXW wc = {0};
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = HotkeyWndProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = L"MouseControlHotkeyWindow";

    if (!RegisterClassExW(&wc)) {
        DWORD error = GetLastError();
        if (error != ERROR_CLASS_ALREADY_EXISTS) {
            return false;
        }
    }

    messageWindow = CreateWindowExW(
        0,
        L"MouseControlHotkeyWindow",
        L"",
        0,
        0, 0, 0, 0,
        HWND_MESSAGE,
        nullptr,
        GetModuleHandle(nullptr),
        nullptr
    );

    if (!messageWindow) {
        return false;
    }

    isInitialized = true;
    return true;
}

// 清理热键系统
void cleanupHotkeySystem() {
    if (!isInitialized) {
        return;
    }

    if (messageWindow) {
        DestroyWindow(messageWindow);
        messageWindow = nullptr;
    }

    UnregisterClassW(L"MouseControlHotkeyWindow", GetModuleHandle(nullptr));
    isInitialized = false;
}

// 移动鼠标到指定位置
void moveMouse(int x, int y) {
    SetCursorPos(x, y);
}

// 点击鼠标
void clickMouse(MouseButton button) {
    INPUT input = {0};
    input.type = INPUT_MOUSE;

    switch (button) {
        case LEFT_BUTTON:
            input.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
            SendInput(1, &input, sizeof(INPUT));
            input.mi.dwFlags = MOUSEEVENTF_LEFTUP;
            SendInput(1, &input, sizeof(INPUT));
            break;

        case RIGHT_BUTTON:
            input.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
            SendInput(1, &input, sizeof(INPUT));
            input.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
            SendInput(1, &input, sizeof(INPUT));
            break;

        case MIDDLE_BUTTON:
            input.mi.dwFlags = MOUSEEVENTF_MIDDLEDOWN;
            SendInput(1, &input, sizeof(INPUT));
            input.mi.dwFlags = MOUSEEVENTF_MIDDLEUP;
            SendInput(1, &input, sizeof(INPUT));
            break;
    }
}

// 获取当前鼠标位置
void getMousePosition(int* x, int* y) {
    POINT point;
    if (GetCursorPos(&point)) {
        *x = point.x;
        *y = point.y;
    }
}

// 注册全局热键
bool registerHotkey(int id, unsigned int vkCode) {
    if (!isInitialized || !messageWindow) {
        return false;
    }

    // MOD_CONTROL | MOD_SHIFT
    BOOL result = RegisterHotKey(messageWindow, id, MOD_CONTROL | MOD_SHIFT | MOD_NOREPEAT, vkCode);

    if (result) {
        std::lock_guard<std::mutex> lock(hotkeyMutex);
        hotkeyStates[id] = false;
    }

    return result != 0;
}

// 取消注册热键
void unregisterHotkey(int id) {
    if (!isInitialized || !messageWindow) {
        return;
    }

    UnregisterHotKey(messageWindow, id);

    std::lock_guard<std::mutex> lock(hotkeyMutex);
    hotkeyStates.erase(id);
}

// 检查热键是否被按下
bool checkHotkeyPressed(int id) {
    if (!isInitialized || !messageWindow) {
        return false;
    }

    // 处理消息队列
    MSG msg;
    while (PeekMessage(&msg, messageWindow, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    std::lock_guard<std::mutex> lock(hotkeyMutex);
    auto it = hotkeyStates.find(id);
    if (it != hotkeyStates.end() && it->second) {
        it->second = false; // 重置状态
        return true;
    }

    return false;
}
