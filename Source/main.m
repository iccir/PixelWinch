//  (c) 2011-2018, Ricci Adams.  All rights reserved.


#import <Cocoa/Cocoa.h>

#if ENABLE_APP_STORE
#include "ReceiptValidation.m"
#endif

int main(int argc, char *argv[])
{
#if ENABLE_APP_STORE && !DEBUG
    __block int returnCode = 0;

    ReceiptValidationCheck(^{
        returnCode = NSApplicationMain(argc,  (const char **) argv);
    }, ^{
        returnCode = 173;
        exit(173);
    });
    
    return returnCode;
#else
    return NSApplicationMain(argc,  (const char **) argv);
#endif
}
