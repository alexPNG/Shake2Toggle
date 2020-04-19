// Shake2Toggle by alex_png
// Control your device by shaking it!
// https://github.com/alexPNG

#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>
#import <spawn.h>
#import <sys/wait.h>
#import "ALApplicationList.h"
#import "MediaRemote.h"

// I’m too lazy to create headers, sorry about that

// Dark Mode
@interface UISUserInterfaceStyleMode : NSObject
@property (nonatomic, assign) long long modeValue;
@end

// Thanks to Skitty for CBBlueLightClient
typedef struct {
	BOOL active;
	BOOL enabled;
	BOOL sunSchedulePermitted;
	int mode;
	unsigned long long disableFlags;
	BOOL available;
} Status;

// Night Shift
@interface CBBlueLightClient : NSObject
- (BOOL)setActive:(BOOL)arg1;
- (BOOL)setEnabled:(BOOL)arg1;
- (BOOL)getBlueLightStatus:(Status *)arg1;
@end

// Preferences stuff
static NSMutableDictionary *settings;
static NSString *selectedApp;
static BOOL useDarkMode;
static BOOL useNightShift;
static BOOL useFlashlight;
static BOOL useLockDevice;
static BOOL useScreenshot;
static BOOL useToggleShuffle;
static BOOL useToggleRepeat;
static BOOL usePlayPause;
static BOOL useNextTrack;
static BOOL useLikeTrack;
static BOOL usePortraitLock;
static BOOL useLPM;
static BOOL useApplication;
static BOOL usePowerMenu;
static BOOL useDND;

// Thanks, Kritanta!
@class AVFlashlightInternal;
@interface AVFlashlight : NSObject {
	AVFlashlightInternal* _internal;
}

// Flashlight
@property (getter=isAvailable,nonatomic,readonly) BOOL available; 
@property (nonatomic,readonly) float flashlightLevel; 
+(BOOL)hasFlashlight;
+(void)initialize;
-(float)flashlightLevel;
-(void)_setupFlashlight;
-(BOOL)turnPowerOnWithError:(id*)arg1 ;
-(void)turnPowerOff;
-(BOOL)setFlashlightLevel:(float)arg1 withError:(id*)arg2 ;
-(BOOL)isAvailable;
-(id)init;
-(void)dealloc;
@end

static AVFlashlight *fleshilght;
static BOOL flashlightEnabled = NO;

// Set flashlight conditions
void toggleFlashlight() 
{
    if (flashlightEnabled) // if on
    {
        [fleshilght setFlashlightLevel:0 withError:nil];
        flashlightEnabled = NO;
    }
    else // if off
    {
        [fleshilght setFlashlightLevel:1 withError:nil];
        flashlightEnabled = YES;
    }
}

// Lock device and screenshot
@interface SpringBoard : NSObject  
-(void)_simulateLockButtonPress;
-(void)takeScreenshot;
@end

// Shake to Shuffle/Skip/etc...
@interface SBMediaController : NSObject
+ (instancetype)sharedInstance;
-(BOOL)_sendMediaCommand:(unsigned)command;
@end

// Commands for MediaRemote - I didn’t delete the ones I’m not using because they might come in handy
typedef NS_ENUM(uint32_t, MRMediaRemoteCommand) {
    MRMediaRemoteCommandPlay,
    MRMediaRemoteCommandPause,
    MRMediaRemoteCommandTogglePlayPause,
    MRMediaRemoteCommandStop,
    MRMediaRemoteCommandNextTrack,
    MRMediaRemoteCommandPreviousTrack,
    MRMediaRemoteCommandAdvanceShuffleMode,
    MRMediaRemoteCommandAdvanceRepeatMode,
    MRMediaRemoteCommandBeginFastForward,
    MRMediaRemoteCommandEndFastForward,
    MRMediaRemoteCommandBeginRewind,
    MRMediaRemoteCommandEndRewind,
    MRMediaRemoteCommandRewind15Seconds,
    MRMediaRemoteCommandFastForward15Seconds,
    MRMediaRemoteCommandRewind30Seconds,
    MRMediaRemoteCommandFastForward30Seconds,
    MRMediaRemoteCommandToggleRecord,
    MRMediaRemoteCommandSkipForward,
    MRMediaRemoteCommandSkipBackward,
    MRMediaRemoteCommandChangePlaybackRate,
    MRMediaRemoteCommandRateTrack,
    MRMediaRemoteCommandLikeTrack,
    MRMediaRemoteCommandDislikeTrack,
    MRMediaRemoteCommandBookmarkTrack,
    MRMediaRemoteCommandSeekToPlaybackPosition,
    MRMediaRemoteCommandChangeRepeatMode,
    MRMediaRemoteCommandChangeShuffleMode,
    MRMediaRemoteCommandEnableLanguageOption,
    MRMediaRemoteCommandDisableLanguageOption
};

// Orientation Lock
@interface SBOrientationLockManager
+(instancetype)sharedInstance;
-(BOOL)isUserLocked;
-(void)lock;
-(void)unlock;
@end

// Low Power Mode
@interface _CDBatterySaver
+(id)batterySaver;
-(BOOL)setPowerMode:(long long)arg1 error:(id *)arg2;
@end

//Do Not Disturb (Thanks, gilshahar!)
@class DNDModeAssertionLifetime;

@interface DNDModeAssertionDetails : NSObject
+ (id)userRequestedAssertionDetailsWithIdentifier:(NSString *)identifier modeIdentifier:(NSString *)modeIdentifier lifetime:(DNDModeAssertionLifetime *)lifetime;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

@interface DNDModeAssertionService : NSObject
+ (id)serviceForClientIdentifier:(NSString *)clientIdentifier;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

static BOOL DNDEnabled;
static DNDModeAssertionService *assertionService;

// Applications
@interface UIApplication (PrivateMethods)
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspend;
@end

@interface UIImage () // Thanks, AuxiliumTeam
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

// Power Menu
@interface FBSystemService : NSObject
+(id)sharedInstance;
-(void)shutdownAndReboot:(BOOL)arg1;
-(void)exitAndRelaunch:(BOOL)arg1;
-(void)nonExistantMethod;
-(void)UICache;
@end

void respring() {
  [[objc_getClass("FBSystemService") sharedInstance] exitAndRelaunch:YES];
}
void safeMode() {
  [[objc_getClass("FBSystemService") sharedInstance] nonExistantMethod];
}
void restart() {
  [[objc_getClass("FBSystemService") sharedInstance] shutdownAndReboot:YES];
}
void powerOff() {
  [[objc_getClass("FBSystemService") sharedInstance] shutdownAndReboot:FALSE];
}
void UICache() {
    pid_t pid;
    int status;
    const char* args[] = {"uicache", NULL};
    posix_spawn(&pid, "/usr/bin/uicache", NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
}



// Preferences Update
static void refreshPrefs() {
NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.alexpng.shake2toggle"];
selectedApp = [prefs objectForKey:@"app"];
	CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.alexpng.shake2toggle"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, CFSTR("com.alexpng.shake2toggle"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		CFRelease(keyList);
	} else {
		settings = nil;
	}
	if (!settings) {
		settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.alexpng.shake2toggle.plist"];
	}
	useDarkMode = [([settings objectForKey:@"useDarkMode"] ?: @(NO)) boolValue];
	useNightShift = [([settings objectForKey:@"useNightShift"] ?: @(NO)) boolValue];
	useFlashlight = [([settings objectForKey:@"useFlashlight"] ?: @(NO)) boolValue];
	useLockDevice = [([settings objectForKey:@"useLockDevice"] ?: @(NO)) boolValue];
	useScreenshot = [([settings objectForKey:@"useScreenshot"] ?: @(NO)) boolValue];
	useToggleShuffle = [([settings objectForKey:@"useToggleShuffle"] ?: @(NO)) boolValue];
	useToggleRepeat = [([settings objectForKey:@"useToggleRepeat"] ?: @(NO)) boolValue];
	usePlayPause = [([settings objectForKey:@"usePlayPause"] ?: @(NO)) boolValue];
	useNextTrack = [([settings objectForKey:@"useNextTrack"] ?: @(NO)) boolValue];
	useLikeTrack = [([settings objectForKey:@"useLikeTrack"] ?: @(NO)) boolValue];
	usePortraitLock = [([settings objectForKey:@"usePortraitLock"] ?: @(NO)) boolValue];
	useLPM = [([settings objectForKey:@"useLPM"] ?: @(NO)) boolValue];
	useApplication = [([settings objectForKey:@"useApplication"] ?: @(NO)) boolValue];
	usePowerMenu = [([settings objectForKey:@"usePowerMenu"] ?: @(NO)) boolValue];
	useDND = [([settings objectForKey:@"useDND"] ?: @(NO)) boolValue];
	}
static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  refreshPrefs();
}

//Setting the tweak up
%hook UIWindow

// Detect when the device is shaken
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    %orig;
    if(event.subtype == UIEventSubtypeMotionShake && self.keyWindow) // Special thanks to Muirey for self.keyWindow fix
    {
		if (useDarkMode) {
       AudioServicesPlaySystemSound(1519); // Haptic feedback
			BOOL darkEnabled;
			if (@available(iOS 13, *)) {
darkEnabled = ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark);
   UISUserInterfaceStyleMode *styleMode = [[%c(UISUserInterfaceStyleMode) alloc] init];
	        if (darkEnabled) {
					styleMode.modeValue = 1;
				} else if (!darkEnabled)  {
					styleMode.modeValue = 2;
			}
			    } else {
//Set Alert For Those Below iOS 13
UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Shake2Toggle"
                                                    message:@"Oops! The feature you're trying to use is only available for devices running iOS 13."
                                            preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                   }];

                    [alert addAction:yesButton];
                    [self.rootViewController presentViewController:alert animated:YES completion:nil];
			}
              }			
		if (useNightShift) {
       AudioServicesPlaySystemSound(1519); // Haptic feedback
			Status status;
			CBBlueLightClient *nightShift = [[%c(CBBlueLightClient) alloc] init];
			[nightShift getBlueLightStatus:&status];
			BOOL shiftEnabled = status.enabled;
			if (shiftEnabled) {
				[nightShift setEnabled:NO];
			} else if (!shiftEnabled)  {
				[nightShift setEnabled:YES];
			}
		}
   if (useFlashlight) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
     toggleFlashlight();
      }
  if (useLockDevice) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
[((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
      }
  if (useScreenshot) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
[((SpringBoard *)[%c(SpringBoard) sharedApplication]) takeScreenshot];
      }
  if (useNextTrack) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
MRMediaRemoteSendCommand(kMRNextTrack, nil);
      }
  if (useToggleShuffle) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
MRMediaRemoteSendCommand(kMRToggleShuffle, nil);
      }
  if (useToggleRepeat) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
MRMediaRemoteSendCommand(kMRToggleRepeat, nil);
      }
  if (usePlayPause) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);
       }
  if (useLikeTrack) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
MRMediaRemoteSendCommand(kMRLikeTrack, nil);
       }
  if (usePortraitLock) {

SBOrientationLockManager *orientationManager = [%c(SBOrientationLockManager) sharedInstance];

if ([[%c(SBOrientationLockManager) sharedInstance] isUserLocked]) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
[orientationManager unlock];

} else {

AudioServicesPlaySystemSound(1519); // Haptic feedback
[orientationManager lock];
       }
     }
  if (useLPM) {

if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {

AudioServicesPlaySystemSound(1519); // Haptic feedback
[[objc_getClass("_CDBatterySaver") batterySaver] setPowerMode:0 error:nil];

} else {

AudioServicesPlaySystemSound(1519); // Haptic feedback
[[objc_getClass("_CDBatterySaver") batterySaver] setPowerMode:1 error:nil];
         }
      }

  if (useApplication) {
AudioServicesPlaySystemSound(1519); // Haptic feedback
	refreshPrefs();
  [[UIApplication sharedApplication] launchApplicationWithIdentifier:selectedApp suspended:FALSE];
       }

  if (usePowerMenu) {
AudioServicesPlaySystemSound(1519); // Haptic feedback

//Power Menu Window
UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Power Menu"
                                                    message:@"Select an option to perform"
    preferredStyle:UIAlertControllerStyleAlert];

//Respring Button
UIAlertAction* respringButton = [UIAlertAction                  actionWithTitle:@"Respring Device"
style:UIAlertActionStyleDefault
handler:^(UIAlertAction * action) {
respring();                                                 
}];

// Safe Mode Button
UIAlertAction* safeModeButton = [UIAlertAction
actionWithTitle:@"Enter Safe Mode"
style:UIAlertActionStyleDefault
handler:^(UIAlertAction * action) {
safeMode();
}];


// UICache Button
UIAlertAction* uicacheButton = [UIAlertAction
actionWithTitle:@"Run UICache"
style:UIAlertActionStyleDefault
handler:^(UIAlertAction * action) {
UICache();
}];


// Reboot Button
UIAlertAction* restartButton = [UIAlertAction
actionWithTitle:@"Reboot Device"
style:UIAlertActionStyleDefault
handler:^(UIAlertAction * action) {
restart();
}];

// Power Off Button
UIAlertAction* powerOffButton = [UIAlertAction
actionWithTitle:@"Power Off Device"
style:UIAlertActionStyleDefault
handler:^(UIAlertAction * action) {
powerOff();
}];

// Cancel Button
UIAlertAction* cancelButton = [UIAlertAction
actionWithTitle:@"Cancel"
style:UIAlertActionStyleDestructive
handler:^(UIAlertAction * action) {
}];

[alert addAction:respringButton];
[alert addAction:safeModeButton];
[alert addAction:uicacheButton];
[alert addAction:restartButton];
[alert addAction:powerOffButton];
[alert addAction:cancelButton];
                    [self.rootViewController presentViewController:alert animated:YES completion:nil];
      }

//Do Not Disturb
  if (useDND) {
AudioServicesPlaySystemSound(1519); // Haptic feedback

  if(DNDEnabled == false){
    if (!assertionService) {
      assertionService = (DNDModeAssertionService *)[objc_getClass("DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
    }
    DNDModeAssertionDetails *newAssertion = [objc_getClass("DNDModeAssertionDetails") userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
    [assertionService takeModeAssertionWithDetails:newAssertion error:NULL];

  } else if(DNDEnabled == true){

if (!assertionService) {
        assertionService = (DNDModeAssertionService *)[objc_getClass("DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
      }
      [assertionService invalidateAllActiveModeAssertionsWithError:NULL];
    }
}



   }
}

%end

//Hook to Do Not Disturb to fetch its status
%hook DNDState
-(BOOL)isActive {
  //save the DND state.
	DNDEnabled = %orig;
	return DNDEnabled;
}
%end

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, CFSTR("com.alexpng.shake2toggle.prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	refreshPrefs();

	%init;

	fleshilght = [[AVFlashlight alloc] init];

}
