//go:build darwin

package main

/*
#cgo LDFLAGS: -framework CoreGraphics -framework CoreFoundation
#include <CoreGraphics/CoreGraphics.h>
#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>

// Undocumented CGEvent fields used for NSSystemDefined / NX aux control events.
enum {
	bf_kCGEventSubtype = 0x53,
	bf_kCGEventData1   = 0x95,
	bf_kCGEventData2   = 0x96,
};

enum {
	bf_NX_SYSDEFINED                 = 14,
	bf_NX_SUBTYPE_AUX_CONTROL_BUTTONS = 8,
	bf_NX_KEYDOWN                    = 0x0A,
	bf_NX_KEYUP                      = 0x0B,
};

static CGEventRef bf_createMediaKeyEvent(int64_t keyCode, int down) {
	int64_t state = down ? bf_NX_KEYDOWN : bf_NX_KEYUP;
	CGEventFlags flags = (CGEventFlags)(state << 8);
	CGEventRef e = CGEventCreate(NULL);
	if (e == NULL) {
		return NULL;
	}
	CGEventSetType(e, (CGEventType)bf_NX_SYSDEFINED);
	CGEventSetFlags(e, flags);
	CGEventSetIntegerValueField(e, (CGEventField)bf_kCGEventSubtype, bf_NX_SUBTYPE_AUX_CONTROL_BUTTONS);
	CGEventSetIntegerValueField(e, (CGEventField)bf_kCGEventData1, (keyCode << 16) | flags);
	CGEventSetIntegerValueField(e, (CGEventField)bf_kCGEventData2, -1);
	return e;
}

// bf_postMediaKey posts an NX aux-control media key down+up from this process
// so Accessibility TCC applies to Listener (not osascript).
void bf_postMediaKey(int keyCode) {
	CGEventRef down = bf_createMediaKeyEvent((int64_t)keyCode, 1);
	CGEventRef up = bf_createMediaKeyEvent((int64_t)keyCode, 0);
	if (down != NULL) {
		CGEventPost(kCGHIDEventTap, down);
		CFRelease(down);
	}
	usleep(10000);
	if (up != NULL) {
		CGEventPost(kCGHIDEventTap, up);
		CFRelease(up);
	}
}
*/
import "C"

// postDarwinMediaKey posts a system-defined media key event in-process via CoreGraphics.
func postDarwinMediaKey(nxKeyCode int) {
	C.bf_postMediaKey(C.int(nxKeyCode))
}
