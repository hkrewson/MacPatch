//
//  MPCatalog.m
/*
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "MPCatalog.h"
#import <IOKit/IOKitLib.h>

static MPCatalog *_instance;

@implementation MPCatalog

@synthesize g_Defaults;
@synthesize g_OSVers;
@synthesize g_cuuid;
@synthesize g_serialNo;
@synthesize g_osVer;
@synthesize g_osType;
@synthesize g_agentVer;
@synthesize g_Tasks;
@synthesize g_TasksHash;
@synthesize g_AppHashes;
@synthesize g_agentPid;
// SWDist
@synthesize g_SWDistTasks;
@synthesize g_SWDistTasksHash;
@synthesize g_SWDistTasksJSONHash;

+ (MPCatalog *)sharedInstance
{
	@synchronized(self) {
		
        if (_instance == nil) {
            _instance = [[super allocWithZone:NULL] init];
            MPDefaults *mpd = [[MPDefaults alloc] init];
			NSDictionary *osDict = [[NSDictionary alloc] initWithDictionary:[_instance getOSInfo]];
			[_instance setG_Defaults:[mpd defaults]];
			[_instance setG_OSVers:[_instance systemVersionDictionary]];
			[_instance setG_cuuid:[_instance collectCUUIDFromHost]];
			[_instance setG_serialNo:[_instance getHostSerialNumber]];
			[_instance setG_osVer:[osDict objectForKey:@"ProductVersion"]];
			[_instance setG_osType:[osDict objectForKey:@"ProductName"]];
			[_instance setG_agentVer:@"0"];
			[_instance setG_AppHashes:[NSMutableDictionary dictionary]];
            [_instance setG_agentPid:NULL];
            [_instance setG_SWDistTasksHash:@"NA"];
            [_instance setG_SWDistTasksJSONHash:@"NA"];
			[mpd release];
            [osDict release];
        }
    }
    return _instance;
}

#pragma mark Singleton Methods

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedInstance]retain];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned long)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (id)autorelease
{
    return self;
}

#pragma mark -
#pragma mark OS/Client Info
- (NSString *)collectCUUIDFromHost
{
	NSString *result = NULL;
	io_struct_inband_t iokit_entry;
	uint32_t bufferSize = 4096; // this signals the longest entry we will take
	io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
	IORegistryEntryGetProperty(ioRegistryRoot, kIOPlatformUUIDKey, iokit_entry, &bufferSize);
	result = [NSString stringWithCString:iokit_entry encoding:NSASCIIStringEncoding];
	
	IOObjectRelease((unsigned int) iokit_entry);
	IOObjectRelease(ioRegistryRoot);
    
	return result;
}

- (NSDictionary *)systemVersionDictionary
{
	NSDictionary *sysVer = NULL;
	
	SInt32 OSmajor, OSminor, OSrevision;
	OSErr err1 = Gestalt(gestaltSystemVersionMajor, &OSmajor);
	OSErr err2 = Gestalt(gestaltSystemVersionMinor, &OSminor);
	OSErr err3 = Gestalt(gestaltSystemVersionBugFix, &OSrevision);
	if (!err1 && !err2 && !err3)
	{
		sysVer = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:OSmajor],[NSNumber numberWithInt:OSminor],[NSNumber numberWithInt:OSrevision],nil]
											 forKeys:[NSArray arrayWithObjects:@"major",@"minor",@"revision",nil]];
	}
	return sysVer;
}

- (NSString *)getHostSerialNumber
{
	NSString *result = nil;
    
	io_registry_entry_t rootEntry = IORegistryEntryFromPath( kIOMasterPortDefault, "IOService:/" );
	CFTypeRef serialAsCFString = NULL;
    
	serialAsCFString = IORegistryEntryCreateCFProperty( rootEntry,
													   CFSTR(kIOPlatformSerialNumberKey),
													   kCFAllocatorDefault,
													   0);
    
	IOObjectRelease( rootEntry );
	if (serialAsCFString == NULL) {
		result = @"NA";
	} else {
		result = [NSString stringWithFormat:@"%@",(NSString *)serialAsCFString];
		CFRelease(serialAsCFString);
	}
	
	return result;
}

- (NSDictionary *)getOSInfo
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *results = nil;
	NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
	
	if ([fm fileExistsAtPath:serverVerPath] == TRUE) {
		results = [NSDictionary dictionaryWithContentsOfFile:serverVerPath];
	} else {
		if ([fm fileExistsAtPath:clientVerPath] == TRUE) {
			results = [NSDictionary dictionaryWithContentsOfFile:clientVerPath];
		}
	}
	
	return results;
}

#pragma mark -

- (BOOL)validateAppHashes:(NSString *)aStringPath
{
	BOOL result = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:aStringPath]) {
		logit(lcl_vError,@"Path to %@ not found.",[aStringPath lastPathComponent]);
		return false;
	}
	if ([g_AppHashes objectForKey:[aStringPath lastPathComponent]]) {
		NSString *_appHash = [aStringPath getMD5FromFile];
		if ([[g_AppHashes objectForKey:[aStringPath lastPathComponent]] isEqualToString:_appHash]) {
			result = YES;
			goto done;
		}
	}
	
	// Check Signature
	if ([self checkSignature:aStringPath]) {
		[g_AppHashes setValue:[aStringPath getMD5FromFile] forKey:[aStringPath lastPathComponent]];
		result = YES;
		goto done;
	} else {
		result = NO;
		goto done;
	}
	
done:
	return result;
}

- (BOOL)checkSignature:(NSString *)aStringPath
{
	BOOL result = NO;
	NSArray *_fingerPrintBaseArray = [NSArray arrayWithObjects:@"a42b1c000514941e965efa6d9c80df6572ef028f",@"d82b0abf5523dbdb6b605e570ce3a005b7a3f80d",nil];
	
	NSTask * task = [[NSTask alloc] init];
	NSPipe * newPipe = [NSPipe pipe];
	NSFileHandle * readHandle = [newPipe fileHandleForReading];
	NSData * inData;
	NSString * tempString;
	[task setLaunchPath:@"/usr/bin/codesign"];
	NSArray *args = [NSArray arrayWithObjects:@"-h", @"-dvvv", @"-r-", aStringPath, nil];
	[task setArguments:args];
	[task setStandardOutput:newPipe];
	[task setStandardError:newPipe];
	[task launch];
	inData = [readHandle readDataToEndOfFile];
	tempString = [[[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding] autorelease];
	logit(lcl_vDebug,@"Codesign result:\n%@",tempString);
	[task release];
    
	if ([tempString rangeOfString:@"missing or invalid"].length > 0 || [tempString rangeOfString:@"modified"].length > 0 || [tempString rangeOfString:@"CSSMERR_TP_NOT_TRUSTED"].length > 0)
	{
		logit(lcl_vError,@"%@ is not signed or trusted.",aStringPath);
		goto done;
	} else if ([tempString rangeOfString:@"Apple Root CA"].length > 0) {
		logit(lcl_vDebug,@"%@ is signed and trusted.",aStringPath);
		result = YES;
		goto done;
	}
	
	for (NSString *fingerPrint in _fingerPrintBaseArray) {
		if ([tempString rangeOfString:fingerPrint].length > 0) {
			logit(lcl_vDebug,@"%@ is signed and trusted.",aStringPath);
			result = YES;
			break;
		}
	}
	
	if (result != YES) {
		logit(lcl_vError,@"%@ is not signed or trusted.",aStringPath);
	}
done:
	return result;
}

@end