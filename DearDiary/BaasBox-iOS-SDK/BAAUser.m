//
//  BAAUser.m
//
//  Created by Cesare Rocchi on 8/14/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//


//http://stablekernel.com/blog/speeding-up-nscoding-with-macros/
#define OBJC_STRINGIFY(x) @#x
#define encodeObject(x) [aCoder encodeObject:x forKey:OBJC_STRINGIFY(x)]
#define decodeObject(x) x = [aDecoder decodeObjectForKey:OBJC_STRINGIFY(x)]
#define encodeBool(x) [aCoder encodeBool:x forKey:OBJC_STRINGIFY(x)]
#define decodeBool(x) x = [aDecoder decodeBoolForKey:OBJC_STRINGIFY(x)]
#define encodeInteger(x) [aCoder encodeInteger:x forKey:OBJC_STRINGIFY(x)]
#define decodeInteger(x) x = [aDecoder decodeIntegerForKey:OBJC_STRINGIFY(x)]

#import "BAAUser.h"
#import <objc/runtime.h>

@interface BAAUser () {

}

@end

@implementation BAAUser


- (instancetype) initWithDictionary:(NSDictionary *)dict {

    self = [super init];
    
    if (self) {
        
        _username = dict[@"user"][@"name"];
        _roles = dict[@"user"][@"roles"];
        _visibleByAnonymousUsers = dict[@"visibleByAnonymousUsers"];
        _visibleByFriends = dict[@"visibleByFriend"];
        _visibleByRegisteredUsers = dict[@"_visibleByRegisteredUsers"];
        _visibleByTheUser = dict[@"_visibleByTheUser"];
        
    }
    
    return self;
    
}

#pragma mark - Load

+ (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadCurrentUserWithCompletion:^(BAAUser *user, NSError *error) {
        
        if (completionBlock){
            completionBlock(user, error);
        }
        
    }];
    
}

+ (void) logoutWithCompletion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client logoutWithCompletion:^(BOOL success, NSError *error) {
       
        if (completionBlock) {
            completionBlock(success, error);
        }
        
    }];
    
}

+ (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadUsersWithParameters:parameters
                         completion:^(NSArray *users, NSError *error) {
                             
                             if (completionBlock) {
                                 
                                 if (error == nil) {
                                     
                                     completionBlock(users, nil);
                                     
                                 } else {
                                     
                                     completionBlock(nil, error);
                                     
                                 }
                             }
                             
                         }];
    
}

+ (void) loadUserDetails:(NSString *)username completion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    
    [client loadUsersDetails:username
                  completion:^(BAAUser *user, NSError *error) {
        
                      if (completionBlock)
                          completionBlock(user, error);
                      
    }];
    
}

- (void) loadFollowingWithCompletion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadFollowingForUser:self
                      completion:^(NSArray *users, NSError *error) {
                          
                          if (completionBlock)
                              completionBlock(users, error);
                          
                      }];
    
}

- (void) loadFollowersWithCompletion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadFollowersOfUser:self
                      completion:^(NSArray *users, NSError *error) {
                          
                          if (completionBlock)
                              completionBlock(users, error);
                          
                      }];
    
}

#pragma mark - Update

- (void) updateWithCompletion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client updateUserWithCompletion:completionBlock];

}

#pragma mark - Follow/Unfollow

+ (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client followUser:user
            completion:^(BAAUser *user, NSError *error) {
                
                if (completionBlock)
                    completionBlock(user, error);
                
            }];
    
}

+ (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client unfollowUser:user
              completion:^(BOOL success, NSError *error) {
                  
                  if (completionBlock)
                      completionBlock(success, error);
                  
              }];
    
}

- (void) changeOldPassword:(NSString *)oldPassword toNewPassword:(NSString *)newPassword completionBlock:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client changeOldPassword:oldPassword
                toNewPassword:newPassword
                   completion:completionBlock];
    
}

- (void) resetPasswordWithCompletion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client resetPasswordForUser:self
                  withCompletion:completionBlock];
    
}


#pragma mark - Helpers

- (NSDictionary*) objectAsDictionary {
    
    NSArray *exclude = @[@"authenticationToken", @"pushNotificationToken", @"pushEnabled", @"roles"];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSUInteger propertiesCount;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertiesCount);
    
    for (int i = 0 ; i < propertiesCount; i++) {
        objc_property_t property = propertyList[i];
        const char *propertyChar = property_getName(property);
        NSString *propertyName = [NSString stringWithCString:propertyChar
                                                    encoding:NSASCIIStringEncoding];
        
        if (![exclude containsObject:propertyName]) {
            
            id value = [self valueForKey:propertyName];
            if (value)
                [result setObject:value forKey:propertyName];
            
        }
        
    }
    
    free(propertyList);
    //    NSLog(@"result is %@", result);
    return [NSDictionary dictionaryWithDictionary:result];
    
}

- (NSString *) jsonString {
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self objectAsDictionary]
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *res = [[NSString alloc] initWithData:jsonData
                                          encoding:NSUTF8StringEncoding];
    return res;
    
}

- (NSMutableDictionary *) visibleByAnonymousUsers {
    
    if (_visibleByAnonymousUsers == nil)
        _visibleByAnonymousUsers = [NSMutableDictionary dictionary];
    
    return _visibleByAnonymousUsers;
    
}

- (NSMutableDictionary *) visibleByTheUser {
    
    if (_visibleByTheUser == nil)
        _visibleByTheUser = [NSMutableDictionary dictionary];
    
    return _visibleByTheUser;
    
}

- (NSMutableDictionary *) visibleByFriends {
    
    if (_visibleByFriends == nil)
        _visibleByFriends = [NSMutableDictionary dictionary];
    
    return _visibleByFriends;
    
}

- (NSMutableDictionary *) visibleByRegisteredUsers {
    
    if (_visibleByRegisteredUsers == nil)
        _visibleByRegisteredUsers = [NSMutableDictionary dictionary];
    
    return _visibleByRegisteredUsers;
    
}

-(NSString *)description {
    
    return [[self objectAsDictionary] description];
    
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if(self) {
        
        decodeObject(_username);
        decodeObject(_authenticationToken);
        decodeObject(_pushNotificationToken);
        decodeBool(_pushEnabled);
        
    }
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    encodeObject(_username);
    encodeObject(_authenticationToken);
    encodeObject(_pushNotificationToken);
    encodeBool(_pushEnabled);
    
}

@end
