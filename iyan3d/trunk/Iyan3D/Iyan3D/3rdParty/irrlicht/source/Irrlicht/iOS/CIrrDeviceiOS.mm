	// Copyright (C) 2002-2008 Nikolaus Gebhardt
	// Copyright (C) 2008 Redshift Software, Inc.
	// Copyright (C) 2012 Patryk Nadrowski
	// This file is part of the "Irrlicht Engine".
	// For conditions of distribution and use, see copyright notice in irrlicht.h

#import "CIrrDeviceiOS.h"

#ifdef _IRR_COMPILE_WITH_IPHONE_DEVICE_

#include "CIrrDeviceiOS.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/utsname.h>
#include <time.h>
#include "IEventReceiver.h"
#include "os.h"
#include "CTimer.h"
#include "irrString.h"
#include "Keycodes.h"
#include "COSOperator.h"
#include "CColorConverter.h"
#include "SIrrCreationParameters.h"
#include <CoreFoundation/CFRunLoop.h>
#include "SExposedVideoData.h"
#include "IFileSystem.h"

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/CAEAGLLayer.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/EAGL.h>

	// Objective-C part.

@interface IrrIPhoneView : UIView <UIKeyInput>
{
    irr::CIrrDeviceIPhone* Device;
}
- (void) dealloc;
- (void) setDevice:(irr::CIrrDeviceIPhone*)device;
@end

@implementation IrrIPhoneView
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (void) dealloc
{
	[super dealloc];
}

- (BOOL) isMultipleTouchEnabled
{
	return YES;
}

- (void) setDevice:(irr::CIrrDeviceIPhone*)device
{
	Device = device;
	UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
    [self addGestureRecognizer:pinchRecognizer];

	UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
	[panRecognizer setMaximumNumberOfTouches:2];
	[panRecognizer setMinimumNumberOfTouches:2];
    [self addGestureRecognizer:panRecognizer];
}

- (void) pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
	irr::SEvent ev;
	ev.EventType = irr::EET_MULTI_TOUCH_EVENT;
	ev.MultiTouchInput.Event = irr::EMTIE_PINCH;
	ev.MultiTouchInput.clear();
	ev.MultiTouchInput.scale = pinchRecognizer.scale;
	Device->postEventFromUser(ev);
}

- (void) panDetected:(UIPanGestureRecognizer*)panRecognizer {
	irr::SEvent ev;
	ev.EventType = irr::EET_MULTI_TOUCH_EVENT;
	ev.MultiTouchInput.Event = irr::EMTIE_PAN;
	ev.MultiTouchInput.clear();
	ev.MultiTouchInput.X[0] = [panRecognizer translationInView:self].x;
	ev.MultiTouchInput.Y[0] = [panRecognizer translationInView:self].y;
	Device->postEventFromUser(ev);
}

- (void) deleteBackward
{
	irr::SEvent ev;
	ev.EventType = irr::EET_KEY_INPUT_EVENT;
	ev.KeyInput.Key = irr::KEY_BACK;
	Device->postEventFromUser(ev);
	
	NSLog(@"\nKey Input: Back Pressed\n");
}

- (void) insertText:(NSString *)text
{
	irr::SEvent ev;
	ev.EventType = irr::EET_KEY_INPUT_EVENT;
	const char *str = [text cStringUsingEncoding:NSASCIIStringEncoding];
	if(str && strlen(str)) {
		ev.KeyInput.c = *str;
		Device->postEventFromUser(ev);
	}
}

- (BOOL) hasText
{
	return true;
}

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
    
    float scale = 1.0f;
    
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
        scale = [[UIScreen mainScreen] scale];
    
	
		// event as mouse.
	irr::SEvent ev;
	ev.EventType = irr::EET_MOUSE_INPUT_EVENT;
	ev.MouseInput.Event = irr::EMIE_LMOUSE_PRESSED_DOWN;
	ev.MouseInput.X = touchPoint.x*scale;
	ev.MouseInput.Y = touchPoint.y*scale;
	ev.MouseInput.ButtonStates = 0;
    Device->postEventFromUser(ev);
    
		// event as multi touch
	CGPoint nowTouchPoint, prevTouchPoint;
	ev.EventType = irr::EET_MULTI_TOUCH_EVENT;
	ev.MultiTouchInput.Event = irr::EMTIE_PRESSED_DOWN;
	ev.MultiTouchInput.clear();
	int idx = 0;
    
	for (touch in touches)
		{
		if (idx >= irr::NUMBER_OF_MULTI_TOUCHES)
            break;
		
		prevTouchPoint = [touch previousLocationInView:self];
		nowTouchPoint = [touch locationInView:self];
		ev.MultiTouchInput.Touched[idx] = 1;
		ev.MultiTouchInput.PrevX[idx] = prevTouchPoint.x*scale;
		ev.MultiTouchInput.PrevY[idx] = prevTouchPoint.y*scale;
		ev.MultiTouchInput.X[idx] = nowTouchPoint.x*scale;
		ev.MultiTouchInput.Y[idx] = nowTouchPoint.y*scale;
		idx ++;
		}
    
	Device->postEventFromUser(ev);
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
    
    float scale = 1.0f;
    
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
        scale = [[UIScreen mainScreen] scale];
    
	irr::SEvent ev;
	ev.EventType = irr::EET_MOUSE_INPUT_EVENT;
	ev.MouseInput.Event = irr::EMIE_MOUSE_MOVED;
	ev.MouseInput.X = touchPoint.x*scale;
	ev.MouseInput.Y = touchPoint.y*scale;
	ev.MouseInput.ButtonStates = 0;
	Device->postEventFromUser(ev);
	
	CGPoint nowTouchPoint, prevTouchPoint;
	ev.EventType = irr::EET_MULTI_TOUCH_EVENT;
	ev.MultiTouchInput.Event = irr::EMTIE_MOVED;
	ev.MultiTouchInput.clear();
	int idx = 0;
    
	for (touch in touches)
		{
		if (idx >= irr::NUMBER_OF_MULTI_TOUCHES)
            break;
		
		prevTouchPoint = [touch previousLocationInView:self];
		nowTouchPoint = [touch locationInView:self];
		ev.MultiTouchInput.Touched[idx] = 1;
		ev.MultiTouchInput.PrevX[idx] = prevTouchPoint.x*scale;
		ev.MultiTouchInput.PrevY[idx] = prevTouchPoint.y*scale;
		ev.MultiTouchInput.X[idx] = nowTouchPoint.x*scale;
		ev.MultiTouchInput.Y[idx] = nowTouchPoint.y*scale;
		idx ++;
		}
    
	Device->postEventFromUser(ev);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
		//NSLog(@">> IrrIPhoneView.touchesEnded");
    
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
    
    float scale = 1.0f;
    
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
        scale = [[UIScreen mainScreen] scale];
    
	irr::SEvent ev;
	ev.EventType = irr::EET_MOUSE_INPUT_EVENT;
	ev.MouseInput.Event = irr::EMIE_LMOUSE_LEFT_UP;
	ev.MouseInput.X = touchPoint.x*scale;
	ev.MouseInput.Y = touchPoint.y*scale;
	ev.MouseInput.ButtonStates = 0;
	Device->postEventFromUser(ev);
    
    
	CGPoint nowTouchPoint, prevTouchPoint;
	ev.EventType = irr::EET_MULTI_TOUCH_EVENT;
	ev.MultiTouchInput.Event = irr::EMTIE_LEFT_UP;
	ev.MultiTouchInput.clear();
	int idx = 0;
    
	for (touch in touches)
		{
		if (idx >= irr::NUMBER_OF_MULTI_TOUCHES)
            break;
		
		prevTouchPoint = [touch previousLocationInView:self];
		nowTouchPoint = [touch locationInView:self];
		ev.MultiTouchInput.Touched[idx] = 1;
		ev.MultiTouchInput.PrevX[idx] = prevTouchPoint.x*scale;
		ev.MultiTouchInput.PrevY[idx] = prevTouchPoint.y*scale;
		ev.MultiTouchInput.X[idx] = nowTouchPoint.x*scale;
		ev.MultiTouchInput.Y[idx] = nowTouchPoint.y*scale;
		idx ++;
		}
    
	Device->postEventFromUser(ev);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
		//NSLog(@">> IrrIPhoneView.touchesCancelled");
    
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
    
    float scale = 1.0f;
    
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
       scale = [[UIScreen mainScreen] scale];
    
	irr::SEvent ev;
	ev.EventType = irr::EET_MOUSE_INPUT_EVENT;
	ev.MouseInput.Event = irr::EMIE_LMOUSE_LEFT_UP;
	ev.MouseInput.X = touchPoint.x*scale;
	ev.MouseInput.Y = touchPoint.y*scale;
	ev.MouseInput.ButtonStates = 0;
    
	Device->postEventFromUser(ev);
}

@end

@interface IrrIPhoneDevice : NSObject <UIApplicationDelegate>
{
@public
	
	EAGLContext* context;
	IrrIPhoneView* view;
	irr::CIrrDeviceIPhone* dev;
    CMMotionManager* motionManager;
    CMAttitude* referenceAttitude;
}
- (id) initWithDevice: (irr::CIrrDeviceIPhone*) device;
- (void) dealloc;
- (void) applicationWillResignActive: (UIApplication*) application;
- (void) applicationDidBecomeActive: (UIApplication*) application;
- (void) applicationWillTerminate: (UIApplication*) application;
- (void) displayCreateInWindow: (UIView**)rview Width: (int) w Height: (int) h DriverType: (bool) type;
- (void) displayInitialize: (EAGLContext**) context_ View: (IrrIPhoneView**) view_;
- (void) displayBegin;
- (void) displayEnd;
- (BOOL) activateAccelerometer: (float) updateInterval;
- (BOOL) deactivateAccelerometer;
- (BOOL) isAccelerometerActive;
- (BOOL) isAccelerometerAvailable;
- (void) getAccelerometerData:(double&) X ValueY: (double&) Y ValueZ: (double&) Z;
- (BOOL) activateGyroscope: (float) updateInterval;
- (BOOL) deactivateGyroscope;
- (BOOL) isGyroscopeActive;
- (BOOL) isGyroscopeAvailable;
- (void) getGyroscopeData:(double&) X ValueY: (double&) Y ValueZ: (double&) Z;
- (BOOL) activateDeviceMotion: (float) updateInterval;
- (BOOL) deactivateDeviceMotion;
- (BOOL) isDeviceMotionActive;
- (BOOL) isDeviceMotionAvailable;
- (void) getDeviceMotionData:(double&) X ValueY: (double&) Y ValueZ: (double&) Z;
- (void) enableKeyInput;
- (void) disableKeyInput;
- (void*) getEAGLContext;
- (void) setEAGLContext:(void*)eacontext;
@end

@implementation IrrIPhoneDevice
- (id) initWithDevice: (irr::CIrrDeviceIPhone*) device
{
	if ((self = [super init]))
		{
		context = nil;
		view = nil;
		dev = device;
        motionManager = [[CMMotionManager alloc] init];
        referenceAttitude = nil;
		}
	return self;
}
- (void) dealloc
{
    [self deactivateAccelerometer];
    [self deactivateGyroscope];
    [self deactivateDeviceMotion];
    [motionManager release];
	[super dealloc];
}
- (void) applicationWillResignActive: (UIApplication *) application
{
    dev->setWindowActive(0);
}
- (void) applicationDidBecomeActive: (UIApplication *) application
{
	dev->setWindowActive(1);
}
- (void) applicationWillTerminate: (UIApplication *) application
{
	dev->closeDevice();
}

- (void) displayCreateInWindow: (UIView**)rview Width: (int) w Height: (int) h DriverType: (bool) type
{
	CGRect rect = CGRectMake(0, 0, (*rview).frame.size.width, (*rview).frame.size.height);
    view = [[IrrIPhoneView alloc] initWithFrame:rect];
    
	if ([view respondsToSelector:@selector(setContentScaleFactor:)])
        view.ContentScaleFactor = [[UIScreen mainScreen] scale];
    
	view.layer.opaque = YES;
    [(*rview) addSubview:view];
    [view setDevice:dev];
	
    if(type)
        context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
    else
        context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES1];
	[EAGLContext setCurrentContext:context];
}
- (void) displayInitialize: (EAGLContext**) context_ View: (IrrIPhoneView**) view_
{
	*context_ = context;
	*view_ = view;
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)view.layer];
}
- (void) displayBegin
{
	if (context != [EAGLContext currentContext])
		{
			[EAGLContext setCurrentContext: context];
		}
}
- (void) displayEnd
{
	if (context == [EAGLContext currentContext])
	{
		[context presentRenderbuffer: GL_RENDERBUFFER_OES];
	}
}
- (BOOL) activateAccelerometer: (float) updateInterval;
{
    if (motionManager.isAccelerometerAvailable && !motionManager.isAccelerometerActive)
		{
        motionManager.accelerometerUpdateInterval = updateInterval;
        [motionManager startAccelerometerUpdates];
        return TRUE;
		}
    
    return FALSE;
}
- (void) enableKeyInput
{
	[view becomeFirstResponder];
}
- (void) disableKeyInput
{
	[view resignFirstResponder];
}
-(void*) getEAGLContext
{
	return context;
}
-(void)setEAGLContext:(void*) eacontext
{
	EAGLContext* newContext = (EAGLContext*)eacontext;
	[EAGLContext setCurrentContext:newContext];
}

- (BOOL) deactivateAccelerometer
{
    if (motionManager.isAccelerometerAvailable && motionManager.isAccelerometerActive)
		{
        [motionManager stopAccelerometerUpdates];
        return TRUE;
		}
    
    return FALSE;
}
- (BOOL) isAccelerometerActive
{
    if (motionManager.isAccelerometerActive)
        return TRUE;
    
    return FALSE;
}
- (BOOL) isAccelerometerAvailable
{
    if (motionManager.isAccelerometerAvailable)
        return TRUE;
    
    return FALSE;
}
- (void) getAccelerometerData:(double&) X ValueY: (double&) Y ValueZ: (double&) Z
{
    X = motionManager.accelerometerData.acceleration.x;
    Y = motionManager.accelerometerData.acceleration.y;
    Z = motionManager.accelerometerData.acceleration.z;
}
- (BOOL) activateGyroscope: (float) updateInterval;
{
    if (motionManager.isGyroAvailable && !motionManager.isGyroActive)
		{
        motionManager.gyroUpdateInterval = updateInterval;
        [motionManager startGyroUpdates];
        return TRUE;
		}
    
    return FALSE;
}
- (BOOL) deactivateGyroscope
{
    if (motionManager.isGyroAvailable && motionManager.isGyroActive)
		{
        [motionManager stopGyroUpdates];
        return TRUE;
		}
    
    return FALSE;
}
- (BOOL) isGyroscopeActive
{
    if (motionManager.isGyroActive)
        return TRUE;
    
    return FALSE;
}
- (BOOL) isGyroscopeAvailable
{
    if (motionManager.isGyroAvailable)
        return TRUE;
    
    return FALSE;
}
- (void) getGyroscopeData:(double&) X ValueY: (double&) Y ValueZ: (double&) Z
{
    X = motionManager.gyroData.rotationRate.x;
    Y = motionManager.gyroData.rotationRate.y;
    Z = motionManager.gyroData.rotationRate.z;
}
- (BOOL) activateDeviceMotion: (float) updateInterval;
{
    referenceAttitude = nil;
    
    if (motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive)
		{
        motionManager.deviceMotionUpdateInterval = updateInterval;
        [motionManager startDeviceMotionUpdates];
        return TRUE;
		}
    
    return FALSE;
}
- (BOOL) deactivateDeviceMotion
{
    if (motionManager.isDeviceMotionAvailable && motionManager.isDeviceMotionActive)
		{
        [motionManager stopDeviceMotionUpdates];
        return TRUE;
		}
    
    return FALSE;
}
- (BOOL) isDeviceMotionActive
{
    if (motionManager.isDeviceMotionActive)
        return TRUE;
    
    return FALSE;
}
- (BOOL) isDeviceMotionAvailable
{
    if (motionManager.isDeviceMotionAvailable)
        return TRUE;
    
    return FALSE;
}
- (void) getDeviceMotionData:(double&) X ValueY: (double&) Y ValueZ: (double&) Z
{
    CMAttitude* currentAttitude = motionManager.deviceMotion.attitude;
    
    if(referenceAttitude != nil)
        [currentAttitude multiplyByInverseOfAttitude: referenceAttitude];
    else
        referenceAttitude = [motionManager.deviceMotion.attitude retain];
    
    X = currentAttitude.roll;
    Y = currentAttitude.pitch;
    Z = currentAttitude.yaw;
}
@end

// C++ part.

namespace irr
{
    namespace video
    {
	IVideoDriver* createOGLES1Driver(const SIrrlichtCreationParameters& params,
									 video::SExposedVideoData& data, io::IFileSystem* io,
									 CIrrDeviceIPhone* device);
	
	IVideoDriver* createOGLES2Driver(const SIrrlichtCreationParameters& params,
									 video::SExposedVideoData& data, io::IFileSystem* io,
									 CIrrDeviceIPhone* device);
    }
}
namespace irr
{
    
    CIrrDeviceIPhone::CIrrDeviceIPhone(const SIrrlichtCreationParameters& params)
	: CIrrDeviceStub(params)
	, Close(false)
	, Closed(false)
	, WindowActive(false)
	, WindowMinimized(false)
    {
#ifdef _DEBUG
	setDebugName("CIrrDeviceIPhone");
#endif
	DeviceM = [[IrrIPhoneDevice alloc] initWithDevice: this];
	
        // print version, distribution etc.
	struct utsname info;
	uname(&info);
	Operator = new COSOperator((core::stringc("")
								+info.sysname+" "
								+info.release+" "
								+info.version+" "
								+info.machine).c_str());
	os::Printer::log(Operator->getOperationSystemVersion(), ELL_INFORMATION);
	
        // create display
	if (CreationParams.DriverType != video::EDT_NULL)
        {
            // create the display, only if we do not use the null device
		if (!createDisplay())
			return;
        }
	
	NSBundle* Bundle = [NSBundle mainBundle];
	NSString* BundlePath = [Bundle bundlePath];
	
	core::stringc NewPath = [BundlePath cStringUsingEncoding:NSASCIIStringEncoding];
	
	FileSystem->changeWorkingDirectoryTo(NewPath);
	
        // create driver
	createDriver();
	
	if (!VideoDriver)
		return;
	
	createGUIAndScene();
	
	WindowActive = true;
    }
	
    CIrrDeviceIPhone::~CIrrDeviceIPhone()
    {
    }
    
    bool CIrrDeviceIPhone::createDisplay()
    {
	bool driverType = (CreationParams.DriverType == video::EDT_OGLES2) ? true : false;
	
	[((IrrIPhoneDevice*)DeviceM) displayCreateInWindow: (UIView**)&CreationParams.WindowId Width: CreationParams.WindowSize.Width Height: CreationParams.WindowSize.Height DriverType: driverType];
	
	return true;
    }
    
    void CIrrDeviceIPhone::displayInitialize(void** context, void** view)
    {
	[((IrrIPhoneDevice*)DeviceM) displayInitialize: (EAGLContext**)context View: (IrrIPhoneView**)view];
    }
    
    void CIrrDeviceIPhone::displayBegin()
    {
	[((IrrIPhoneDevice*)DeviceM) displayBegin];
    }
    
    void CIrrDeviceIPhone::displayEnd()
    {
	[((IrrIPhoneDevice*)DeviceM) displayEnd];
    }
	
    void CIrrDeviceIPhone::createDriver()
    {
	switch(CreationParams.DriverType)
        {
            case video::EDT_OGLES1:
#ifdef _IRR_COMPILE_WITH_OGLES1_
            {
			video::SExposedVideoData data;
			VideoDriver = video::createOGLES1Driver(CreationParams, data, FileSystem, this);
            }
#else
			os::Printer::log("No OpenGL-ES1 support compiled in.", ELL_ERROR);
#endif
			break;
			
            case video::EDT_OGLES2:
#ifdef _IRR_COMPILE_WITH_OGLES2_
            {
			video::SExposedVideoData data;
			VideoDriver = video::createOGLES2Driver(CreationParams, data, FileSystem, this);
            }
#else
			os::Printer::log("No OpenGL-ES2 support compiled in.", ELL_ERROR);
#endif
			break;
			
            case video::EDT_SOFTWARE:
            case video::EDT_BURNINGSVIDEO:
            case video::EDT_DIRECT3D8:
            case video::EDT_DIRECT3D9:
            case video::EDT_OPENGL:
			os::Printer::log("This driver is not available. Try OpenGL-ES1 renderer.",
							 ELL_ERROR);
			break;
			
            case video::EDT_NULL:
			VideoDriver = video::createNullDriver(FileSystem, CreationParams.WindowSize);
			break;
			
            default:
			os::Printer::log("Unable to create video driver of unknown type.", ELL_ERROR);
			break;
        }
    }
	
    bool CIrrDeviceIPhone::run()
    {
	os::Timer::tick();
	
        //! Update events
	
        //! Accelerometer
	if([((IrrIPhoneDevice*)DeviceM) isAccelerometerActive])
        {
		irr::SEvent ev;
		ev.EventType = irr::EET_ACCELEROMETER_EVENT;
		
		[((IrrIPhoneDevice*)DeviceM) getAccelerometerData: ev.AccelerometerEvent.X ValueY: ev.AccelerometerEvent.Y ValueZ: ev.AccelerometerEvent.Z];
        
		postEventFromUser(ev);
        }
	
        //! Gyroscope
	if([((IrrIPhoneDevice*)DeviceM) isGyroscopeActive])
        {
		irr::SEvent ev;
		ev.EventType = irr::EET_GYROSCOPE_EVENT;
		
		[((IrrIPhoneDevice*)DeviceM) getGyroscopeData: ev.GyroscopeEvent.X ValueY: ev.GyroscopeEvent.Y ValueZ: ev.GyroscopeEvent.Z];
		
		postEventFromUser(ev);
        }
	
        //! Device Motion
	if([((IrrIPhoneDevice*)DeviceM) isDeviceMotionActive])
        {
		irr::SEvent ev;
		ev.EventType = irr::EET_DEVICE_MOTION_EVENT;
		
		[((IrrIPhoneDevice*)DeviceM) getDeviceMotionData: ev.DeviceMotionEvent.X ValueY: ev.DeviceMotionEvent.Y ValueZ: ev.DeviceMotionEvent.Z];
		
		postEventFromUser(ev);
        }
	
	yield();
	Closed = Close;
	return !Close;
    }
	
    void CIrrDeviceIPhone::yield()
    {
	struct timespec ts = {0,0};
	nanosleep(&ts, NULL);
    }
	
    void CIrrDeviceIPhone::sleep(u32 timeMs, bool pauseTimer=false)
    {
	bool wasStopped = Timer ? Timer->isStopped() : true;
	
	struct timespec ts;
	ts.tv_sec = (time_t) (timeMs / 1000);
	ts.tv_nsec = (long) (timeMs % 1000) * 1000000;
	
	if (pauseTimer && !wasStopped)
		Timer->stop();
	
	nanosleep(&ts, NULL);
	
	if (pauseTimer && !wasStopped)
		Timer->start();
    }
	
    void CIrrDeviceIPhone::setWindowCaption(const wchar_t* text)
    {
    }
	
    bool CIrrDeviceIPhone::present(video::IImage* image, void * windowId, core::rect<s32>* src)
    {
	return false;
    }
	
    void CIrrDeviceIPhone::closeDevice()
    {
	WindowActive = false;
	Close = true;
	CFRunLoopStop(CFRunLoopGetMain());
	while (!Closed) yield();
    }
	
    bool CIrrDeviceIPhone::isWindowActive() const
    {
	return WindowActive;
    }
	
    bool CIrrDeviceIPhone::isWindowFocused() const
    {
	return isWindowActive();
    }
	
    bool CIrrDeviceIPhone::isWindowMinimized() const
    {
	return !isWindowActive();
    }
	
    void CIrrDeviceIPhone::setResizable(bool resize)
    {
    }
	
    void CIrrDeviceIPhone::minimizeWindow()
    {
    }
	
    void CIrrDeviceIPhone::maximizeWindow()
    {
    }
	
    void CIrrDeviceIPhone::restoreWindow()
    {
    }
	
    void CIrrDeviceIPhone::setWindowActive(bool active)
    {
	WindowActive = active;
    }
    
    bool CIrrDeviceIPhone::activateAccelerometer(float updateInterval)
    {
	return [((IrrIPhoneDevice*)DeviceM) activateAccelerometer: updateInterval];
    }
	
    bool CIrrDeviceIPhone::deactivateAccelerometer()
    {
	return [((IrrIPhoneDevice*)DeviceM) deactivateAccelerometer];
    }
    
    bool CIrrDeviceIPhone::isAccelerometerActive()
    {
	return [((IrrIPhoneDevice*)DeviceM) isAccelerometerActive];
    }
	
    bool CIrrDeviceIPhone::isAccelerometerAvailable()
    {
	return [((IrrIPhoneDevice*)DeviceM) isAccelerometerAvailable];
    }
	
    bool CIrrDeviceIPhone::activateGyroscope(float updateInterval)
    {
	return [((IrrIPhoneDevice*)DeviceM) activateGyroscope: updateInterval];
    }
	
    bool CIrrDeviceIPhone::deactivateGyroscope()
    {
	return [((IrrIPhoneDevice*)DeviceM) deactivateGyroscope];
    }
    
    bool CIrrDeviceIPhone::isGyroscopeActive()
    {
	return [((IrrIPhoneDevice*)DeviceM) isGyroscopeActive];
    }
	
    bool CIrrDeviceIPhone::isGyroscopeAvailable()
    {
	return [((IrrIPhoneDevice*)DeviceM) isGyroscopeAvailable];
    }
    
    bool CIrrDeviceIPhone::activateDeviceMotion(float updateInterval)
    {
	return [((IrrIPhoneDevice*)DeviceM) activateDeviceMotion: updateInterval];
    }
    
    bool CIrrDeviceIPhone::deactivateDeviceMotion()
    {
	return [((IrrIPhoneDevice*)DeviceM) deactivateDeviceMotion];
    }
    
    bool CIrrDeviceIPhone::isDeviceMotionActive()
    {
	return [((IrrIPhoneDevice*)DeviceM) isDeviceMotionActive];
    }
    
    bool CIrrDeviceIPhone::isDeviceMotionAvailable()
    {
	return [((IrrIPhoneDevice*)DeviceM) isDeviceMotionAvailable];
    }
    
	void CIrrDeviceIPhone::enableKeyInput()
	{
	[((IrrIPhoneDevice*)DeviceM) enableKeyInput];
	}
	
	void CIrrDeviceIPhone::disableKeyInput()
	{
	[((IrrIPhoneDevice*)DeviceM) disableKeyInput];
	}
	
	void* CIrrDeviceIPhone::getEAGLContext()
	{
		return [((IrrIPhoneDevice*)DeviceM) getEAGLContext];
	}
	void CIrrDeviceIPhone::setEAGLContext(void* context)
	{
	 [((IrrIPhoneDevice*)DeviceM) setEAGLContext:context];
	}


} // end namespace

#endif // _IRR_COMPILE_WITH_IPHONE_DEVICE_
