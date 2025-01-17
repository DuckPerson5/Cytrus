//
//  CytrusObjC.mm
//  Cytrus
//
//  Created by Jarrod Norwell on 1/8/24.
//

#import "CytrusObjC.h"

#include "Configuration/Configuration.h"
#include "EmulationWindow/EmulationWindow_Vulkan.h"
#include "InputManager/InputManager.h"

#include <dlfcn.h>
#include <memory>

#include "common/dynamic_library/dynamic_library.h"
#include "common/settings.h"
#include "core/core.h"
#include "core/frontend/applets/default_applets.h"

#include <future>
#include <thread>
#include <map>

#include "core/frontend/applets/swkbd.h"
#include "video_core/gpu.h"
#include "video_core/renderer_base.h"

namespace SoftwareKeyboard {

class Keyboard final : public Frontend::SoftwareKeyboard {
public:
    ~Keyboard();
    
    void Execute(const Frontend::KeyboardConfig& config) override;
    void ShowError(const std::string& error) override;
    
    void KeyboardText(std::condition_variable& cv);
    std::pair<std::string, uint8_t> GetKeyboardText(const Frontend::KeyboardConfig& config);
    
private:
    __block NSString *_Nullable keyboardText = @"";
    __block uint8_t buttonPressed = 0;
};

} // namespace SoftwareKeyboard


//

@implementation KeyboardConfig
-(KeyboardConfig *) initWithHintText:(NSString *)hintText buttonConfig:(KeyboardButtonConfig)buttonConfig {
    if (self = [super init]) {
        self.hintText = hintText;
        self.buttonConfig = buttonConfig;
    } return self;
}
@end

namespace SoftwareKeyboard {

Keyboard::~Keyboard() = default;

void Keyboard::Execute(const Frontend::KeyboardConfig& config) {
    SoftwareKeyboard::Execute(config);
    
    std::pair<std::string, uint8_t> it = this->GetKeyboardText(config);
    if (this->config.button_config != Frontend::ButtonConfig::None)
        it.second = static_cast<uint8_t>(this->config.button_config);
    
    NSLog(@"%s, %hhu", it.first.c_str(), it.second);
    Finalize(it.first, it.second);
}

void Keyboard::ShowError(const std::string& error) {
    printf("error = %s\n", error.c_str());
}

void Keyboard::KeyboardText(std::condition_variable& cv) {
    [[NSNotificationCenter defaultCenter] addObserverForName:@"closeKeyboard" object:NULL queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification) {
        this->buttonPressed = (NSUInteger)notification.userInfo[@"buttonPressed"];
        
        NSString *_Nullable text = notification.userInfo[@"keyboardText"];
        if (text != NULL)
            this->keyboardText = text;
        
        cv.notify_all();
    }];
}

std::pair<std::string, uint8_t> Keyboard::GetKeyboardText(const Frontend::KeyboardConfig& config) {
    std::mutex mutex;
    std::condition_variable conditional_variable;
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"openKeyboard"
                                                                                         object:[[KeyboardConfig alloc] initWithHintText:[NSString stringWithCString:config.hint_text.c_str() encoding:NSUTF8StringEncoding] buttonConfig:(KeyboardButtonConfig)config.button_config]]];
    
    auto t1 = std::async(&Keyboard::KeyboardText, this, std::ref(conditional_variable));
    std::unique_lock<std::mutex> lock(mutex);
    conditional_variable.wait(lock);
    
    return std::make_pair([this->keyboardText UTF8String], this->buttonPressed);
}
}

//

Core::System& cytrusEmulator{Core::System::GetInstance()};
std::unique_ptr<EmulationWindow_Vulkan> window, window2;

@implementation CytrusObjC
-(CytrusObjC *) init {
    if (self = [super init]) {
        _gameInformation = [GameInformation sharedInstance];
        
        Common::Log::Initialize();
        Common::Log::SetColorConsoleBackendEnabled(true);
        Common::Log::Start();
        
        Common::Log::Filter filter;
        filter.ParseFilterString(Settings::values.log_filter.GetValue());
        Common::Log::SetGlobalFilter(filter);
        
        Config config;
        
        cytrusEmulator.ApplySettings();
        Settings::LogSettings();
        
        Frontend::RegisterDefaultApplets(cytrusEmulator);
        cytrusEmulator.RegisterSoftwareKeyboard(std::make_shared<SoftwareKeyboard::Keyboard>());
        
        InputManager::Init();
    } return self;
}

+(CytrusObjC *) sharedInstance {
    static dispatch_once_t onceToken;
    static CytrusObjC *sharedInstance = NULL;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(void) configurePrimaryLayer:(CAMetalLayer *)primaryLayer withPrimarySize:(CGSize)primarySize
               secondaryLayer:(CAMetalLayer *)secondaryLayer withSecondarySize:(CGSize)secondarySize {
    window = std::make_unique<EmulationWindow_Vulkan>((__bridge CA::MetalLayer *)primaryLayer,
                                                      std::make_shared<Common::DynamicLibrary>(dlopen("@rpath/MoltenVK.framework/MoltenVK", RTLD_NOW)),
                                                      false, primarySize);
    
    window2 = std::make_unique<EmulationWindow_Vulkan>((__bridge CA::MetalLayer *)secondaryLayer,
                                                      std::make_shared<Common::DynamicLibrary>(dlopen("@rpath/MoltenVK.framework/MoltenVK", RTLD_NOW)),
                                                      true, secondarySize);
    _size = secondarySize;
    
    window->MakeCurrent();
    window2->MakeCurrent();
}

-(void) insertGame:(NSURL *)url {
    void(cytrusEmulator.Load(*window, [url.path UTF8String], window2.get()));
    
    std::atomic_bool stop_run;
    cytrusEmulator.GPU().Renderer().Rasterizer()->LoadDiskResources(stop_run, [](VideoCore::LoadCallbackStage stage, std::size_t value, std::size_t total) {
        LOG_DEBUG(Frontend, "Loading stage {} progress {} {}", static_cast<u32>(stage), value,
                  total);
    });
}

-(void) step {
    void(cytrusEmulator.RunLoop());
}

-(void) orientationChanged:(UIInterfaceOrientation)orientation with:(CGSize)secondaryScreenSize {
    _size = secondaryScreenSize;
    
    window->OrientationChanged(orientation, window->surface);
    window2->OrientationChanged(orientation, window2->surface);
}

-(void) touchBeganAtPoint:(CGPoint)point {
    float h_ratio, w_ratio;
    h_ratio = window2->GetFramebufferLayout().height / (_size.height * [[UIScreen mainScreen] nativeScale]);
    w_ratio = window2->GetFramebufferLayout().width / (_size.width * [[UIScreen mainScreen] nativeScale]);
    
    window2->TouchPressed((point.x) * [[UIScreen mainScreen] nativeScale] * w_ratio, ((point.y) * [[UIScreen mainScreen] nativeScale] * h_ratio));
}

-(void) touchEnded {
    window2->TouchReleased();
}

-(void) touchMovedAtPoint:(CGPoint)point {
    float h_ratio, w_ratio;
    h_ratio = window2->GetFramebufferLayout().height / (_size.height * [[UIScreen mainScreen] nativeScale]);
    w_ratio = window2->GetFramebufferLayout().width / (_size.width * [[UIScreen mainScreen] nativeScale]);
    
    window2->TouchMoved((point.x) * [[UIScreen mainScreen] nativeScale] * w_ratio, ((point.y) * [[UIScreen mainScreen] nativeScale] * h_ratio));
}

-(void) thumbstickMoved:(VirtualControllerAnalogType)analog x:(CGFloat)x y:(CGFloat)y {
    InputManager::AnalogHandler()->MoveJoystick([[NSNumber numberWithUnsignedInteger:analog] intValue], x, y);
}

-(void) virtualControllerButtonDown:(VirtualControllerButtonType)button {
    InputManager::ButtonHandler()->PressKey([[NSNumber numberWithUnsignedInteger:button] intValue]);
}

-(void) virtualControllerButtonUp:(VirtualControllerButtonType)button {
    InputManager::ButtonHandler()->ReleaseKey([[NSNumber numberWithUnsignedInteger:button] intValue]);
}

-(void) settingsSaved {
    Config config;
    cytrusEmulator.ApplySettings();
    Settings::LogSettings();
}
@end
