#ifndef MOUSE_CONTROLLER_H
#define MOUSE_CONTROLLER_H

#ifdef _WIN32
    #ifdef BUILDING_DLL
        #define DLL_EXPORT __declspec(dllexport)
    #else
        #define DLL_EXPORT __declspec(dllimport)
    #endif
#else
    #define DLL_EXPORT
#endif

extern "C" {
    // 鼠标按钮类型
    enum MouseButton {
        LEFT_BUTTON = 0,
        RIGHT_BUTTON = 1,
        MIDDLE_BUTTON = 2
    };

    // 移动鼠标到指定位置
    DLL_EXPORT void moveMouse(int x, int y);

    // 点击鼠标
    DLL_EXPORT void clickMouse(MouseButton button);

    // 获取当前鼠标位置
    DLL_EXPORT void getMousePosition(int* x, int* y);

    // 注册全局热键 (Ctrl + Shift + key)
    DLL_EXPORT bool registerHotkey(int id, unsigned int vkCode);

    // 取消注册热键
    DLL_EXPORT void unregisterHotkey(int id);

    // 检查热键是否被按下 (非阻塞)
    DLL_EXPORT bool checkHotkeyPressed(int id);

    // 初始化热键系统
    DLL_EXPORT bool initHotkeySystem();

    // 清理热键系统
    DLL_EXPORT void cleanupHotkeySystem();
}

#endif // MOUSE_CONTROLLER_H
