//
//  BugsnagSystemInfo.h
//  Pods
//
//  Created by Jamie Lynch on 11/08/2017.
//
//

#import <Foundation/Foundation.h>

#define BSG_KSSystemField_AppStartTime "app_start_time"
#define BSG_KSSystemField_AppUUID "app_uuid"
#define BSG_KSSystemField_BootTime "boot_time"
#define BSG_KSSystemField_BundleID "CFBundleIdentifier"
#define BSG_KSSystemField_BundleName "CFBundleName"
#define BSG_KSSystemField_BundleShortVersion "CFBundleShortVersionString"
#define BSG_KSSystemField_BundleVersion "CFBundleVersion"
#define BSG_KSSystemField_CPUArch "cpu_arch"
#define BSG_KSSystemField_CPUType "cpu_type"
#define BSG_KSSystemField_CPUSubType "cpu_subtype"
#define BSG_KSSystemField_BinaryCPUType "binary_cpu_type"
#define BSG_KSSystemField_BinaryCPUSubType "binary_cpu_subtype"
#define BSG_KSSystemField_DeviceAppHash "device_app_hash"
#define BSG_KSSystemField_Executable "CFBundleExecutable"
#define BSG_KSSystemField_ExecutablePath "CFBundleExecutablePath"
#define BSG_KSSystemField_Jailbroken "jailbroken"
#define BSG_KSSystemField_KernelVersion "kernel_version"
#define BSG_KSSystemField_Machine "machine"
#define BSG_KSSystemField_Memory "memory"
#define BSG_KSSystemField_Model "model"
#define BSG_KSSystemField_OSVersion "os_version"
#define BSG_KSSystemField_ParentProcessID "parent_process_id"
#define BSG_KSSystemField_ProcessID "process_id"
#define BSG_KSSystemField_ProcessName "process_name"
#define BSG_KSSystemField_SystemName "system_name"
#define BSG_KSSystemField_SystemVersion "system_version"
#define BSG_KSSystemField_TimeZone "time_zone"
#define BSG_KSSystemField_BuildType "build_type"

@interface BugsnagSystemInfo : NSObject // TODO remove unused methods etc

/** Get the system info.
 *
 * @return The system info.
 */
+ (NSDictionary*) systemInfo;
+ (NSString*) deviceAndAppHash;
+ (NSString *)modelName;
+ (NSString *)modelNumber;
+ (NSNumber *)usableMemory;
+ (NSString*) appUUID;

@end
