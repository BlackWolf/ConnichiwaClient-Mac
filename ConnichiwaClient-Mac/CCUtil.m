//
//  CCUtil.m
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import "CCUtil.h"


/**
 *  The options used when creating JSON strings. In debug mode, we use a pretty representation, otherwise a shorter, less readable presentation
 */
#ifdef CWDEBUG
NSJSONWritingOptions const JSON_WRITING_OPTIONS = NSJSONWritingPrettyPrinted;
#else
NSJSONWritingOptions const JSON_WRITING_OPTIONS = kNilOptions;
#endif



@implementation CCUtil


/**
 *  Creates a JSON string from a NSDictionary that can be safely send over JavaScriptCore's evaluteScript:.
 *  The dictionary must be convertable to JSON as defined by NSJSONSerialization
 *
 *  @param dictionary The dictionary to translate into JSON
 *
 *  @return The JSON string representing the Dictionary.
 */
+ (NSString *)escapedJSONStringFromDictionary:(NSDictionary *)dictionary
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:JSON_WRITING_OPTIONS error:&error];
    
    if (error)
    {
        [NSException raise:@"Invalid Dictionary for serialization" format:@"Dictionary could not be serialized to JSON: %@", dictionary];
    }
    
    //Create the actual JSON
    //The JSON spec says that quotes and newlines must be escaped - not doing so will produce an "unexpected EOF" error
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    json = [json stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    json = [json stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    json = [json stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    json = [json stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    return json;
}


+ (NSDictionary *)dictionaryFromJSONData:(NSData *)JSON
{
    return [NSJSONSerialization JSONObjectWithData:JSON options:0 error:nil];
}


+ (NSData *)JSONDataFromDictionary:(NSDictionary *)dictionary
{
    return [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
}


@end
