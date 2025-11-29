// mouse_controller_macos.mm
// macOS implementation of mouse controller using CoreGraphics and Carbon APIs

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include <map>
#include <mutex>

// Hotkey state management
static std::map<int, bool> hotkeyStates;
static std::mutex hotkeyMutex;
static std::map<int, EventHotKeyRef> hotkeyRefs;
static bool isInitialized = false;

// Hotkey handler
static OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData) {
    EventHotKeyID hotKeyID;
    GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID);
    
    std::lock_guard<std::mutex> lock(hotkeyMutex);
    hotkeyStates[hotKeyID.id] = true;
    
    return noErr;
}

extern "C" {

// Mouse button types
enum MouseButton {
    LEFT_BUTTON = 0,
    RIGHT_BUTTON = 1,
    MIDDLE_BUTTON = 2
};

// Initialize hotkey system
bool initHotkeySystem() {
    if (isInitialized) {
        return true;
    }
    
    // Install event handler for hotkeys
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    
    OSStatus status = InstallApplicationEventHandler(&hotkeyHandler, 1, &eventType, NULL, NULL);
    
    if (status != noErr) {
        NSLog(@"Failed to install hotkey handler: %d", (int)status);
        return false;
    }
    
    isInitialized = true;
    NSLog(@"Hotkey system initialized successfully");
    return true;
}

// Cleanup hotkey system
void cleanupHotkeySystem() {
    if (!isInitialized) {
        return;
    }
    
    // Unregister all hotkeys
    std::lock_guard<std::mutex> lock(hotkeyMutex);
    for (auto& pair : hotkeyRefs) {
        UnregisterEventHotKey(pair.second);
    }
    hotkeyRefs.clear();
    hotkeyStates.clear();
    
    isInitialized = false;
    NSLog(@"Hotkey system cleaned up");
}

// Move mouse to specified position
void moveMouse(int x, int y) {
    CGPoint point = CGPointMake(x, y);
    CGEventRef moveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, moveEvent);
    CFRelease(moveEvent);
}

// Click mouse button
void clickMouse(MouseButton button) {
    CGPoint currentPos;
    
    // Get current mouse position
    CGEventRef event = CGEventCreate(NULL);
    currentPos = CGEventGetLocation(event);
    CFRelease(event);
    
    CGEventType downType, upType;
    CGMouseButton cgButton;
    
    switch (button) {
        case LEFT_BUTTON:
            downType = kCGEventLeftMouseDown;
            upType = kCGEventLeftMouseUp;
            cgButton = kCGMouseButtonLeft;
            break;
        case RIGHT_BUTTON:
            downType = kCGEventRightMouseDown;
            upType = kCGEventRightMouseUp;
            cgButton = kCGMouseButtonRight;
            break;
        case MIDDLE_BUTTON:
            downType = kCGEventOtherMouseDown;
            upType = kCGEventOtherMouseUp;
            cgButton = kCGMouseButtonCenter;
            break;
        default:
            return;
    }
    
    // Mouse down
    CGEventRef mouseDown = CGEventCreateMouseEvent(NULL, downType, currentPos, cgButton);
    CGEventPost(kCGHIDEventTap, mouseDown);
    CFRelease(mouseDown);
    
    // Small delay between down and up
    usleep(10000); // 10ms
    
    // Mouse up
    CGEventRef mouseUp = CGEventCreateMouseEvent(NULL, upType, currentPos, cgButton);
    CGEventPost(kCGHIDEventTap, mouseUp);
    CFRelease(mouseUp);
}

// Get current mouse position
void getMousePosition(int* x, int* y) {
    CGEventRef event = CGEventCreate(NULL);
    CGPoint point = CGEventGetLocation(event);
    CFRelease(event);
    
    *x = (int)point.x;
    *y = (int)point.y;
}

// Convert virtual key code to macOS key code
// macOS uses different key codes than Windows
static UInt32 convertVKCodeToMacKeyCode(unsigned int vkCode) {
    // Map Windows VK codes to macOS key codes
    // Numbers 0-9: Windows 0x30-0x39, macOS kVK_ANSI_0 = 0x1D, etc.
    // Letters A-Z: Windows 0x41-0x5A, macOS has different mapping
    
    static std::map<unsigned int, UInt32> keyMap = {
        // Numbers
        {0x30, kVK_ANSI_0}, {0x31, kVK_ANSI_1}, {0x32, kVK_ANSI_2},
        {0x33, kVK_ANSI_3}, {0x34, kVK_ANSI_4}, {0x35, kVK_ANSI_5},
        {0x36, kVK_ANSI_6}, {0x37, kVK_ANSI_7}, {0x38, kVK_ANSI_8},
        {0x39, kVK_ANSI_9},
        // Letters
        {0x41, kVK_ANSI_A}, {0x42, kVK_ANSI_B}, {0x43, kVK_ANSI_C},
        {0x44, kVK_ANSI_D}, {0x45, kVK_ANSI_E}, {0x46, kVK_ANSI_F},
        {0x47, kVK_ANSI_G}, {0x48, kVK_ANSI_H}, {0x49, kVK_ANSI_I},
        {0x4A, kVK_ANSI_J}, {0x4B, kVK_ANSI_K}, {0x4C, kVK_ANSI_L},
        {0x4D, kVK_ANSI_M}, {0x4E, kVK_ANSI_N}, {0x4F, kVK_ANSI_O},
        {0x50, kVK_ANSI_P}, {0x51, kVK_ANSI_Q}, {0x52, kVK_ANSI_R},
        {0x53, kVK_ANSI_S}, {0x54, kVK_ANSI_T}, {0x55, kVK_ANSI_U},
        {0x56, kVK_ANSI_V}, {0x57, kVK_ANSI_W}, {0x58, kVK_ANSI_X},
        {0x59, kVK_ANSI_Y}, {0x5A, kVK_ANSI_Z},
    };
    
    auto it = keyMap.find(vkCode);
    if (it != keyMap.end()) {
        return it->second;
    }
    return vkCode; // Return as-is if not found
}

// Register global hotkey (Ctrl + Shift + key)
// On macOS, we use Cmd + Shift instead of Ctrl + Shift for better compatibility
bool registerHotkey(int id, unsigned int vkCode) {
    if (!isInitialized) {
        NSLog(@"Hotkey system not initialized");
        return false;
    }
    
    // Unregister existing hotkey with same ID
    {
        std::lock_guard<std::mutex> lock(hotkeyMutex);
        auto it = hotkeyRefs.find(id);
        if (it != hotkeyRefs.end()) {
            UnregisterEventHotKey(it->second);
            hotkeyRefs.erase(it);
        }
    }
    
    EventHotKeyID hotKeyID;
    hotKeyID.signature = 'MCHR'; // Mouse Controller Hotkey Registry
    hotKeyID.id = id;
    
    EventHotKeyRef hotKeyRef;
    
    // Use Cmd + Shift modifiers (more standard on macOS)
    UInt32 modifiers = cmdKey | shiftKey;
    UInt32 macKeyCode = convertVKCodeToMacKeyCode(vkCode);
    
    OSStatus status = RegisterEventHotKey(macKeyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
    
    if (status != noErr) {
        NSLog(@"Failed to register hotkey id=%d, vkCode=0x%X, macKeyCode=0x%X, status=%d", id, vkCode, macKeyCode, (int)status);
        return false;
    }
    
    std::lock_guard<std::mutex> lock(hotkeyMutex);
    hotkeyRefs[id] = hotKeyRef;
    hotkeyStates[id] = false;
    
    NSLog(@"Registered hotkey id=%d, vkCode=0x%X, macKeyCode=0x%X (Cmd+Shift+Key)", id, vkCode, macKeyCode);
    return true;
}

// Unregister hotkey
void unregisterHotkey(int id) {
    std::lock_guard<std::mutex> lock(hotkeyMutex);
    
    auto it = hotkeyRefs.find(id);
    if (it != hotkeyRefs.end()) {
        UnregisterEventHotKey(it->second);
        hotkeyRefs.erase(it);
        hotkeyStates.erase(id);
        NSLog(@"Unregistered hotkey id=%d", id);
    }
}

// Check if hotkey was pressed (non-blocking)
bool checkHotkeyPressed(int id) {
    if (!isInitialized) {
        return false;
    }
    
    // Process pending events
    @autoreleasepool {
        NSEvent* event;
        while ((event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                           untilDate:nil
                                              inMode:NSDefaultRunLoopMode
                                             dequeue:YES])) {
            [NSApp sendEvent:event];
        }
    }
    
    std::lock_guard<std::mutex> lock(hotkeyMutex);
    auto it = hotkeyStates.find(id);
    if (it != hotkeyStates.end() && it->second) {
        it->second = false; // Reset state
        return true;
    }
    
    return false;
}

} // extern "C"

