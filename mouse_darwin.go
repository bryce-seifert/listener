//go:build darwin

package main

/*
#cgo LDFLAGS: -framework ApplicationServices -framework CoreGraphics
#include <ApplicationServices/ApplicationServices.h>
#include <CoreGraphics/CoreGraphics.h>

void bf_getMouse(int *x, int *y) {
	CGEventRef e = CGEventCreate(NULL);
	CGPoint p = CGEventGetLocation(e);
	CFRelease(e);
	*x = (int)p.x;
	*y = (int)p.y;
}

void bf_moveMouse(int x, int y) {
	CGPoint p = CGPointMake((CGFloat)x, (CGFloat)y);
	CGWarpMouseCursorPosition(p);
	CGAssociateMouseAndMouseCursorPosition(true);
}

void bf_clickMouse(int button, int doubleClick) {
	CGEventType downType, upType;
	CGMouseButton btn;
	if (button == 1) {
		downType = kCGEventRightMouseDown;
		upType = kCGEventRightMouseUp;
		btn = kCGMouseButtonRight;
	} else if (button == 2) {
		downType = kCGEventOtherMouseDown;
		upType = kCGEventOtherMouseUp;
		btn = kCGMouseButtonCenter;
	} else {
		downType = kCGEventLeftMouseDown;
		upType = kCGEventLeftMouseUp;
		btn = kCGMouseButtonLeft;
	}
	CGEventRef e = CGEventCreate(NULL);
	CGPoint p = CGEventGetLocation(e);
	CFRelease(e);
	int clicks = doubleClick ? 2 : 1;
	for (int i = 1; i <= clicks; i++) {
		CGEventRef down = CGEventCreateMouseEvent(NULL, downType, p, btn);
		CGEventRef up = CGEventCreateMouseEvent(NULL, upType, p, btn);
		CGEventSetIntegerValueField(down, kCGMouseEventClickState, i);
		CGEventSetIntegerValueField(up, kCGMouseEventClickState, i);
		CGEventPost(kCGHIDEventTap, down);
		CGEventPost(kCGHIDEventTap, up);
		CFRelease(down);
		CFRelease(up);
	}
}
*/
import "C"
import "strings"

func getMousePos() (int, int) {
	var x, y C.int
	C.bf_getMouse(&x, &y)
	return int(x), int(y)
}

func moveMouse(x, y int) {
	C.bf_moveMouse(C.int(x), C.int(y))
}

func clickMouse(button string, double bool) {
	btn := 0
	switch strings.ToLower(button) {
	case "right":
		btn = 1
	case "center", "middle":
		btn = 2
	}
	d := 0
	if double {
		d = 1
	}
	C.bf_clickMouse(C.int(btn), C.int(d))
}
