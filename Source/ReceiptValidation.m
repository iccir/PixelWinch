#import <Foundation/Foundation.h>

#import <CommonCrypto/CommonDigest.h>
#import <Security/CMSDecoder.h>
#import <Security/SecAsn1Coder.h>
#import <Security/SecAsn1Templates.h>
#import <Security/SecRequirement.h>
#import <IOKit/IOKitLib.h>
#include <dlfcn.h>


// com.pixelwinch.PixelWinch
static UInt8 sObfuscatedBundleID[] = { 227,239,237,174,240,233,248,229,236,247,233,238,227,232,174,208,233,248,229,236,215,233,238,227,232,0 };


static UInt8 s_anchor_apple_generic[] = { 225,238,227,232,239,242,160,225,240,240,236,229,160,231,229,238,229,242,233,227,0 };

static UInt8 s_IOMACAddress[] = { 201,207,205,193,195,193,228,228,242,229,243,243,0 };

static UInt8 s_SecStaticCodeCreateWithPath[] = { 211,229,227,211,244,225,244,233,227,195,239,228,229,195,242,229,225,244,229,215,233,244,232,208,225,244,232,0 };
typedef OSStatus (*f_SecStaticCodeCreateWithPath)(CFURLRef path, SecCSFlags flags, SecStaticCodeRef * CF_RETURNS_RETAINED staticCode);

static UInt8 s_SecStaticCodeCheckValidity[] = { 211,229,227,211,244,225,244,233,227,195,239,228,229,195,232,229,227,235,214,225,236,233,228,233,244,249,0 };
typedef OSStatus (*f_SecStaticCodeCheckValidity)(SecStaticCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);

static UInt8 s_SecRequirementCreateWithString[] = { 211,229,227,210,229,241,245,233,242,229,237,229,238,244,195,242,229,225,244,229,215,233,244,232,211,244,242,233,238,231,0 };
typedef OSStatus (*f_SecRequirementCreateWithString)(CFStringRef text, SecCSFlags flags, SecRequirementRef * CF_RETURNS_RETAINED requirement);
    
static UInt8 s_SecPolicyCreateBasicX509[] = { 211,229,227,208,239,236,233,227,249,195,242,229,225,244,229,194,225,243,233,227,216,181,176,185,0 };
typedef SecPolicyRef (*f_SecPolicyCreateBasicX509)(void);

static UInt8 s_CMSDecoderCreate[] = { 195,205,211,196,229,227,239,228,229,242,195,242,229,225,244,229,0 };
typedef OSStatus (*f_CMSDecoderCreate)(CMSDecoderRef * CF_RETURNS_RETAINED cmsDecoderOut);

static UInt8 s_CMSDecoderUpdateMessage[] = { 195,205,211,196,229,227,239,228,229,242,213,240,228,225,244,229,205,229,243,243,225,231,229,0 };
typedef OSStatus (*f_CMSDecoderUpdateMessage)(CMSDecoderRef cmsDecoder, const void *msgBytes, size_t msgBytesLen);

static UInt8 s_CMSDecoderFinalizeMessage[] = { 195,205,211,196,229,227,239,228,229,242,198,233,238,225,236,233,250,229,205,229,243,243,225,231,229,0 };
typedef OSStatus (*f_CMSDecoderFinalizeMessage)(CMSDecoderRef cmsDecoder);

static UInt8 s_CMSDecoderCopyContent[] = { 195,205,211,196,229,227,239,228,229,242,195,239,240,249,195,239,238,244,229,238,244,0 };
typedef OSStatus (*f_CMSDecoderCopyContent)(CMSDecoderRef decoder, CFDataRef * CF_RETURNS_RETAINED contentOut);

static UInt8 s_CMSDecoderGetNumSigners[] = { 195,205,211,196,229,227,239,228,229,242,199,229,244,206,245,237,211,233,231,238,229,242,243,0 };
typedef OSStatus (*f_CMSDecoderGetNumSigners)(CMSDecoderRef decoder, size_t *numSignersOut);

static UInt8 s_CMSDecoderCopySignerStatus[] = { 195,205,211,196,229,227,239,228,229,242,195,239,240,249,211,233,231,238,229,242,211,244,225,244,245,243,0 };
typedef OSStatus (*f_CMSDecoderCopySignerStatus)(
    CMSDecoderRef decoder,
    size_t signerIndex,
    CFTypeRef policy,
    Boolean evaluateSecTrust,
    CMSSignerStatus *signerStatusOut,
    SecTrustRef * CF_RETURNS_RETAINED secTrustOut,
    OSStatus * certVerifyResultCodeOut
);

static UInt8 s_SecAsn1CoderCreate[]  = { 211,229,227,193,243,238,177,195,239,228,229,242,195,242,229,225,244,229,0 };
typedef OSStatus (*f_SecAsn1CoderCreate)(SecAsn1CoderRef *coder);

static UInt8 s_SecAsn1CoderRelease[] = { 211,229,227,193,243,238,177,195,239,228,229,242,210,229,236,229,225,243,229,0 };
typedef OSStatus (*f_SecAsn1CoderRelease)(SecAsn1CoderRef coder);

static UInt8 s_SecAsn1Decode[] = { 211,229,227,193,243,238,177,196,229,227,239,228,229,0 };
typedef OSStatus (*f_SecAsn1Decode)(SecAsn1CoderRef coder, const void *src, size_t len, const SecAsn1Template *templates, void *dest);

static UInt8 s_IOMasterPort[] = { 201,207,205,225,243,244,229,242,208,239,242,244,0 };
typedef kern_return_t (*f_IOMasterPort)(mach_port_t bootstrapPort, mach_port_t *masterPort);

static UInt8 s_IOBSDNameMatching[] = { 201,207,194,211,196,206,225,237,229,205,225,244,227,232,233,238,231,0 };
typedef CFMutableDictionaryRef (*f_IOBSDNameMatching)(mach_port_t masterPort, uint32_t options, const char * bsdName);

static UInt8 s_IOServiceGetMatchingServices[] = { 201,207,211,229,242,246,233,227,229,199,229,244,205,225,244,227,232,233,238,231,211,229,242,246,233,227,229,243,0 };
typedef kern_return_t (*f_IOServiceGetMatchingServices)(mach_port_t masterPort, CFDictionaryRef matching CF_RELEASES_ARGUMENT, io_iterator_t * existing);

static UInt8 s_IOIteratorNext[] = { 201,207,201,244,229,242,225,244,239,242,206,229,248,244,0 };
typedef io_object_t (*f_IOIteratorNext)(io_iterator_t iterator);

static UInt8 s_IORegistryEntryGetParentEntry[] = { 201,207,210,229,231,233,243,244,242,249,197,238,244,242,249,199,229,244,208,225,242,229,238,244,197,238,244,242,249,0 };
typedef kern_return_t (*f_IORegistryEntryGetParentEntry)(io_registry_entry_t entry, const io_name_t plane, io_registry_entry_t *parent);

static UInt8 s_IORegistryEntryCreateCFProperty[] = { 201,207,210,229,231,233,243,244,242,249,197,238,244,242,249,195,242,229,225,244,229,195,198,208,242,239,240,229,242,244,249,0 };
typedef CFTypeRef (*f_IORegistryEntryCreateCFProperty)(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

static UInt8 s_IOObjectRelease[] = { 201,207,207,226,234,229,227,244,210,229,236,229,225,243,229,0 };
typedef kern_return_t (*f_IOObjectRelease)(io_object_t object);

static UInt8 s_CC_SHA1[] = { 195,195,223,211,200,193,177,0 };
typedef unsigned char *(*f_CC_SHA1)(const void *data, CC_LONG len, unsigned char *md);


static inline NSString *sGetString(const UInt8 *inName)
{
    const UInt8 *i = inName;

    UInt8 buffer[1024];
    UInt8 *o = buffer;

    while (*i) { *o = (*i - 128); i++; o++; }
    *o = 0;

    return [[NSString alloc] initWithBytes:buffer length:(o - buffer) encoding:NSASCIIStringEncoding];
}


static inline void *sGetFunction(const UInt8 *inName)
{
    const UInt8 *i = inName;

    UInt8 buffer[1024];
    UInt8 *o = buffer;

    while (*i) { *o = (*i - 128); i++; o++; }
    *o = 0;

    return dlsym(RTLD_NEXT, (char *)buffer);
}


typedef struct {
    size_t length;
    unsigned char *data;
} ASN1Data;


typedef struct {
    ASN1Data type;     // INTEGER
    ASN1Data version;  // INTEGER
    ASN1Data value;    // OCTET STRING
} ReceiptAttribute;


typedef struct {
    ReceiptAttribute **attrs;
} ReceiptPayload;


static const SecAsn1Template kReceiptAttributeTemplate[] = {
    { SEC_ASN1_SEQUENCE, 0, NULL, sizeof(ReceiptAttribute) },
    { SEC_ASN1_INTEGER, offsetof(ReceiptAttribute, type), NULL, 0 },
    { SEC_ASN1_INTEGER, offsetof(ReceiptAttribute, version), NULL, 0 },
    { SEC_ASN1_OCTET_STRING, offsetof(ReceiptAttribute, value), NULL, 0 },
    { 0, 0, NULL, 0 }
};


static const SecAsn1Template kSetOfReceiptAttributeTemplate[] = {
    { SEC_ASN1_SET_OF, 0, kReceiptAttributeTemplate, sizeof(ReceiptPayload) },
    { 0, 0, NULL, 0 }
};


inline static BOOL sReceiptValidationCheckBundleIDOnDisk(NSString *expected)
{
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleIdentifier"];
    
    return expected && [bundleID isEqualToString:expected];
}


inline static BOOL sReceiptValidationCheckBundleSignature()
{
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
    
    f_SecStaticCodeCreateWithPath    SecStaticCodeCreateWithPath    = sGetFunction(s_SecStaticCodeCreateWithPath);
    f_SecRequirementCreateWithString SecRequirementCreateWithString = sGetFunction(s_SecRequirementCreateWithString);
    f_SecStaticCodeCheckValidity     SecStaticCodeCheckValidity     = sGetFunction(s_SecStaticCodeCheckValidity);

    SecStaticCodeRef  staticCode  = NULL;
    SecRequirementRef requirement = NULL;

    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)bundleURL, kSecCSDefaultFlags, &staticCode);
    
    if (status == errSecSuccess) {
        NSString *requirementText = sGetString(s_anchor_apple_generic);
        status = SecRequirementCreateWithString((__bridge CFStringRef)requirementText, kSecCSDefaultFlags, &requirement);
    }
    
    if (status == errSecSuccess) {
        status = SecStaticCodeCheckValidity(staticCode, kSecCSDefaultFlags, requirement);
    }

    if (staticCode)  CFRelease(staticCode);
    if (requirement) CFRelease(requirement);
    
    return (status == errSecSuccess);
}


inline static NSData *sReceiptValidationGetReceiptData()
{
    NSURL  *receiptURL  = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];

    if (!receiptData) return nil;

    CMSDecoderRef decoder = NULL;

    OSStatus status = noErr;

    f_CMSDecoderCreate           CMSDecoderCreate           = sGetFunction(s_CMSDecoderCreate);
    f_CMSDecoderUpdateMessage    CMSDecoderUpdateMessage    = sGetFunction(s_CMSDecoderUpdateMessage);
    f_CMSDecoderFinalizeMessage  CMSDecoderFinalizeMessage  = sGetFunction(s_CMSDecoderFinalizeMessage);
    f_CMSDecoderGetNumSigners    CMSDecoderGetNumSigners    = sGetFunction(s_CMSDecoderGetNumSigners);
    f_CMSDecoderCopyContent      CMSDecoderCopyContent      = sGetFunction(s_CMSDecoderCopyContent);
    f_CMSDecoderCopySignerStatus CMSDecoderCopySignerStatus = sGetFunction(s_CMSDecoderCopySignerStatus);
    f_SecPolicyCreateBasicX509   SecPolicyCreateBasicX509   = sGetFunction(s_SecPolicyCreateBasicX509);

    if (status == noErr) {
        status = CMSDecoderCreate(&decoder);
    }

    if (status == noErr) {
        status = CMSDecoderUpdateMessage(decoder, receiptData.bytes, receiptData.length);
    }

    if (status == noErr) {
        status = CMSDecoderFinalizeMessage(decoder);
    }

    NSData *decodedData = nil;

    if (status == noErr) {
        CFDataRef dataRef = NULL;

        status = CMSDecoderCopyContent(decoder, &dataRef);
        
        if (dataRef) {
            decodedData = CFBridgingRelease(dataRef);
        }
    }

    if (status == noErr) {
        size_t numSigners;
        status = CMSDecoderGetNumSigners(decoder, &numSigners);

        if (numSigners == 0) {
            decodedData = nil;
        }
    }

    if (status == noErr) {
        SecPolicyRef policy = SecPolicyCreateBasicX509();

        CMSSignerStatus signerStatus;
        status = CMSDecoderCopySignerStatus(decoder, 0, policy, TRUE, &signerStatus, NULL, NULL);

        if (signerStatus != kCMSSignerValid) {
            decodedData = nil;
        }

        if (policy) CFRelease(policy);
    }

    if (decoder) CFRelease(decoder);

    return status == noErr ? decodedData : nil;
}


inline static NSData *sReceiptValidationGetASN1RawData(ASN1Data asn1Data)
{
    return [NSData dataWithBytes:asn1Data.data length:asn1Data.length];
}


inline static int sReceiptValidationGetIntValueFromASN1Data(const ASN1Data *asn1Data)
{
    int ret = 0;
    for (int i = 0; i < asn1Data->length; i++) {
        ret = (ret << 8) | asn1Data->data[i];
    }
    return ret;
}

    
inline static NSData *sReceiptValidationGetMacAddress(void)
{
    f_IOMasterPort                    IOMasterPort                    = sGetFunction(s_IOMasterPort);
    f_IOBSDNameMatching               IOBSDNameMatching               = sGetFunction(s_IOBSDNameMatching);
    f_IOServiceGetMatchingServices    IOServiceGetMatchingServices    = sGetFunction(s_IOServiceGetMatchingServices);
    f_IOIteratorNext                  IOIteratorNext                  = sGetFunction(s_IOIteratorNext);
    f_IORegistryEntryGetParentEntry   IORegistryEntryGetParentEntry   = sGetFunction(s_IORegistryEntryGetParentEntry);
    f_IORegistryEntryCreateCFProperty IORegistryEntryCreateCFProperty = sGetFunction(s_IORegistryEntryCreateCFProperty);
    f_IOObjectRelease                 IOObjectRelease                 = sGetFunction(s_IOObjectRelease);

    NSString *IOMACAddress = sGetString(s_IOMACAddress);

    mach_port_t masterPort;
    kern_return_t result = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (result != KERN_SUCCESS) return nil;
    
    CFMutableDictionaryRef matching = IOBSDNameMatching(masterPort, 0, "en0");
    if (!matching) return nil;
    
    io_iterator_t iterator;
    result = IOServiceGetMatchingServices(masterPort, matching, &iterator);
    if (result != KERN_SUCCESS) return nil;
    
    CFDataRef macAddressData = nil;
    io_object_t aService;

    while ((aService = IOIteratorNext(iterator)) != 0) {
        io_object_t parentService;

        result = IORegistryEntryGetParentEntry(aService, kIOServicePlane, &parentService);

        if (result == KERN_SUCCESS) {
            if (macAddressData) CFRelease(macAddressData);
            macAddressData = (CFDataRef)IORegistryEntryCreateCFProperty(parentService, (__bridge CFStringRef)IOMACAddress, kCFAllocatorDefault, 0);
            IOObjectRelease(parentService);
        }

        IOObjectRelease(aService);
    }
    IOObjectRelease(iterator);
    
    return macAddressData ? CFBridgingRelease(macAddressData) : nil;
}


__attribute__((unused))
static void ReceiptValidationCheck(void (^successBlock)(), void (^failureBlock)()) 
{
    SecAsn1CoderRef decoder = NULL;
    
    f_SecAsn1CoderCreate  SecAsn1CoderCreate  = sGetFunction(s_SecAsn1CoderCreate);
    f_SecAsn1CoderRelease SecAsn1CoderRelease = sGetFunction(s_SecAsn1CoderRelease);
    f_SecAsn1Decode       SecAsn1Decode       = sGetFunction(s_SecAsn1Decode);
    f_CC_SHA1             CC_SHA1             = sGetFunction(s_CC_SHA1);
    
    NSString *expectedBundleID = sGetString(sObfuscatedBundleID);
    
    NSData *bundleIDData;
    NSData *opaqueValueData;
    NSData *hashData;

    ReceiptPayload payload = { 0 };
    
    BOOL okBundleIDOnDisk    = sReceiptValidationCheckBundleIDOnDisk(expectedBundleID);
    BOOL okBundleSignature   = sReceiptValidationCheckBundleSignature();
    BOOL okBundleIDInReceipt = NO;
    BOOL okHashInReceipt     = NO;
    
    NSData *receiptData = sReceiptValidationGetReceiptData();
    OSStatus status = receiptData ? noErr : 1;

    if (status == noErr) {
        status = SecAsn1CoderCreate(&decoder);
    }
    
    if (status == noErr) {
        status = SecAsn1Decode(decoder, [receiptData bytes], [receiptData length], kSetOfReceiptAttributeTemplate, &payload);
    }

    if (status == noErr) {
        ReceiptAttribute *attribute;
        
        for (int i = 0; (attribute = payload.attrs[i]); i++) {
            int type = sReceiptValidationGetIntValueFromASN1Data(&attribute->type);
            
            if (type == 2) { // Bundle ID
                ASN1Data  outData = {0};
                ASN1Data  inData  = attribute->value;

                if (noErr == SecAsn1Decode(decoder, inData.data, inData.length, kSecAsn1UTF8StringTemplate, &outData)) {
                    if (outData.length == [expectedBundleID length]) {
                        if (strncmp([expectedBundleID UTF8String], (const char *)outData.data, outData.length) == 0) {
                            okBundleIDInReceipt = YES;
                        }
                    }
                }

                bundleIDData = sReceiptValidationGetASN1RawData(attribute->value);

            } else if (type == 4) { // Opaque Value
                opaqueValueData = sReceiptValidationGetASN1RawData(attribute->value);

            } else if (type == 5) { // SHA-1 Hash 
                hashData = sReceiptValidationGetASN1RawData(attribute->value);
            }
        }
    }

    NSData *macAddressData = sReceiptValidationGetMacAddress();
    
    if (macAddressData && ([hashData length] == CC_SHA1_DIGEST_LENGTH)) {
        NSMutableData *digestData = [NSMutableData data];

        [digestData appendData:macAddressData];
        [digestData appendData:opaqueValueData];
        [digestData appendData:bundleIDData];
    
        unsigned char digestBuffer[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1([digestData bytes], (CC_LONG)[digestData length], digestBuffer);
    
        if (memcmp(digestBuffer, [hashData bytes], CC_SHA1_DIGEST_LENGTH) == 0) {
            okHashInReceipt = YES;
        }
    }
    
    if (decoder) SecAsn1CoderRelease(decoder);
    
    if ((status == noErr) && okBundleIDOnDisk && okBundleIDInReceipt && okBundleSignature && okHashInReceipt) {
        successBlock();
    } else {
        failureBlock();
    }
}
