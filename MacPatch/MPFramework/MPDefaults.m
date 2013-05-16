//
//  MPDefaults.m
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

#import "MPDefaults.h"
#import "Constants.h"

#undef  ql_component
#define ql_component lcl_cMPDefaults

@implementation MPDefaults

#pragma mark -
#pragma mark init

//=========================================================== 
//  init 
//=========================================================== 

- (id)init 
{
	return [self initWithPlist:AGENT_PREFS_PLIST];
}

- (id)initWithPlist:(NSString *)sPlistPath
{
	self = [super init];
	if (self) {
		qldebug(@"Reading plist from file '%@'",sPlistPath);
		[self readPlist:sPlistPath]; 
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)aDictionary
{
	self = [super init];
	if (self) {
		[self setDefaults:aDictionary];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -
#pragma mark Getters & Setters
//=========================================================== 
//  Getters & Setters 
//=========================================================== 

- (NSDictionary *)defaults
{
    return [[defaults retain] autorelease]; 
}

- (void)setDefaults:(NSDictionary *)aDefaults
{
    if (defaults != aDefaults) {
        [defaults release];
        defaults = [aDefaults copy];
    }
}

#pragma mark -
#pragma mark Class Methods
//=========================================================== 
//  methods
//=========================================================== 

- (void)readPlist:(NSString *)aPlist
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:aPlist]) {
		NSString *error;
		NSPropertyListFormat format;
		NSData *data = [NSData dataWithContentsOfFile:aPlist];
		NSMutableDictionary *thePlist = [NSPropertyListSerialization propertyListFromData:data 
																		 mutabilityOption:NSPropertyListImmutable 
																				   format:&format 
																		 errorDescription:&error];
		if (!thePlist) {
			qlerror(@"Error reading plist from file '%@', error = '%@'",aPlist,error);
			[error release];  
			return;
		} 
		[self setDefaults:[NSDictionary dictionaryWithDictionary:thePlist]];
	} else {
		qlerror(@"Error plist file '%@' does not exist.",aPlist);
		exit(1);
	}
    
}

- (id)readPlist:(NSString *)aPlist objectForKey:(NSString *)aKey
{
	id result;
	[self readPlist:aPlist];
	result = [[self defaults] objectForKey:aKey];
	return (id)result;
}

@end