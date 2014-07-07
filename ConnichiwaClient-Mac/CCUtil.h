//
//  CCUtil.h
//  ConnichiwaClient-Mac
//
//  Created by Mario Schreiner on 06/07/14.
//  Copyright (c) 2014 Mario Schreiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCUtil : NSObject

/**
 *  Transforms a dictionary into a JSON string and escaped the string, so it can be used safely. The transformation is done via NSJSONSerialization, so the dictionary must contain only objects that can be serialized by NSJSONSerialization.
 *
 *  @param dictionary The dictionary to transform
 *
 *  @return An escaped JSON string that represents the dictionary
 */
+ (NSString *)escapedJSONStringFromDictionary:(NSDictionary *)dictionary;

/**
 *  Transform a given JSON data object, as it is for example created by JSONDataFromDictionary: into a dictionary. NSJSONSerialization is used, to the JSON string must be decodable by NSJSONSerialization.
 *
 *  @param JSON The NSData object representing a JSON string
 *
 *  @return An NSDictionary that represents the JSON
 */
+ (NSDictionary *)dictionaryFromJSONData:(NSData *)JSON;

/**
 *  Transforms a dictionary into a JSON data object. The resulting NSData object can then be decoded by using dictionaryFromJSONData: to retrieve the original dictionary. NSJSONSerialization is used, so the dictionary must contain only objects that can be serialized by NSJSONSerialization.
 *
 *  @param dictionary The dictionary to transform
 *
 *  @return An NSData object that represents the JSON string for the dictioanry
 */
+ (NSData *)JSONDataFromDictionary:(NSDictionary *)dictionary;

@end
