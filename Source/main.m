//
//  main.m
//  Pixels
//
//  Created by Ricci Adams on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if ENABLE_APP_STORE
#include "ReceiptValidation.h"
#endif

int main(int argc, char *argv[])
{
#if ENABLE_APP_STORE && !defined(DEBUG)
    CheckReceiptAndRun(argc, argv);
#else
    return NSApplicationMain(argc,  (const char **) argv);
#endif
}
