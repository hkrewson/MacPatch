//
//  PatchScanAndUpdateOperation.m
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

#import "PatchScanAndUpdateOperation.h"
#import "MPAgent.h"

@interface PatchScanAndUpdateOperation (Private)

- (void)runPatchScan;
- (void)runPatchScanAndUpdate;

@end

@implementation PatchScanAndUpdateOperation

@synthesize scanType;
@synthesize isExecuting;
@synthesize isFinished;

- (id)init
{
	if ((self = [super init])) {
		scanType = 0;
		isExecuting = NO;
        isFinished  = NO;
		si	= [MPAgent sharedInstance];
		fm	= [NSFileManager defaultManager];
	}	
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL) isConcurrent 
{
    return YES;
}

- (void) finish 
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void) start 
{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
		[self performSelectorInBackground:@selector(main) withObject:nil];
        isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)main
{
	@try {
		if (scanType == 0) {
			[self runPatchScan];
		} else if (scanType == 1) {
			[self runPatchScanAndUpdate];
		}
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"[NSException]: %@",e);
	}
	[self finish];
}

- (void)runPatchScan 
{
	logit(lcl_vInfo,@"Running client vulnerability scan.");
	NSAutoreleasePool *taskpool = [[NSAutoreleasePool alloc] init];
	NSString *appPath = [MP_ROOT_CLIENT stringByAppendingPathComponent:@"MPAgentExec"];
	if (![fm fileExistsAtPath:appPath]) {
		logit(lcl_vError,@"Unable to find MPAgentExec app.");
	} else {
		if ([si checkSignature:appPath]) {
			NSError *error = nil;
			NSString *result;
			MPNSTask *mpr = [[MPNSTask alloc] init];
			result = [mpr runTask:appPath binArgs:[NSArray arrayWithObjects:@"-s", nil] error:&error];
			
			if (error) {
				logit(lcl_vError,@"%@",[error description]);
			}
			
			logit(lcl_vDebug,@"%@",result);
			logit(lcl_vInfo,@"Vulnerability scan has been completed.");
			logit(lcl_vInfo,@"See the MPAgentExec.log file for more information.");
			[mpr release];
		}
	}	
	[taskpool release];
}

- (void)runPatchScanAndUpdate
{
	logit(lcl_vInfo,@"Running client vulnerability update.");
	NSAutoreleasePool *taskpool = [[NSAutoreleasePool alloc] init];
	NSString *appPath = [MP_ROOT_CLIENT stringByAppendingPathComponent:@"MPAgentExec"];
	if (![fm fileExistsAtPath:appPath]) {
		logit(lcl_vError,@"Unable to find MPAgentExec app.");
	} else {
		if ([si checkSignature:appPath]) {	
			NSError *error = nil;
			NSString *result;
			MPNSTask *mpr = [[MPNSTask alloc] init];
			result = [mpr runTask:appPath binArgs:[NSArray arrayWithObjects:@"-u", nil] error:&error];
			
			if (error) {
				logit(lcl_vError,@"%@",[error description]);
			}
			
			logit(lcl_vDebug,@"%@",result);
			logit(lcl_vInfo,@"Vulnerability scan & update has been completed.");
			logit(lcl_vInfo,@"See the MPAgentExec.log file for more information.");
			[mpr release];
		}
	}	
	[taskpool release];
}

@end