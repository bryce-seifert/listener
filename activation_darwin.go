//go:build darwin

package main

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#import <Cocoa/Cocoa.h>

void setAccessoryActivationPolicy(void) {
	[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
}
*/
import "C"

// hideDockIcon runs the app as an accessory (menu-bar) process so it does not
// appear in the Dock. Needed because GLFW/Fyne can reset activation policy even
// when Info.plist has LSUIElement=true.
func hideDockIcon() {
	C.setAccessoryActivationPolicy()
}
