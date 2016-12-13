//
//  Defines.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/12/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#ifndef uChatu_Defines_h
#define uChatu_Defines_h

#define SCREEN_SIZE [UIScreen mainScreen].bounds.size
#define IPHONE_4 ([[UIScreen mainScreen] bounds].size.height == 480.0f)
#define IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IPHONE_6 ([[UIScreen mainScreen] bounds].size.height == 667.0f)
#define IPHONE_6PLUS ([[UIScreen mainScreen] bounds].size.height == 736.0f)

#define LAST_MESSAGE_DATE_DEFAULT [NSDate dateWithTimeIntervalSince1970:1422748800] // 01.02.2015


#define SAVE_BUTTON_ACTIVE_COLOR [UIColor colorWithRed:2/255.0f green:138/255.0f blue:253/255.0f alpha:1.0]
#define NAVIGATION_BAR_TITLE_FONT [UIFont fontWithName:@"HelveticaNeue-medium" size:18]

#define NOTIFICATION_GENERAL_SOUND 1007 

#define DEFAULT_MESSAGE_CELL_HEIGHT 63

//  NSNotification names
static NSString * const kXMPPStreamDidConectNotification = @"XMPPStreamDidConectNotification";
static NSString * const kXMPPStremConnectionWasChanged = @"xmppStremConnectionWasChanged";
static NSString * const kReachabilityManagerNetworkStatusChanged = @"ReachabilityManagerNenworkStatusChanged";
static NSString * const kUserSettingsChangedNotification = @"userSettingsChangedNotification";
static NSString * const kLogoutButtonTappedNotification = @"logoutButtonTappedNotification";
static NSString * const kAvatarImageWasDownloaded = @"AvatarImageWasDownloaded";
static NSString * const kAttachedImageWasTappedNotification = @"AttachedImageWasTappedNotification";
static NSString * const kChatsTableViewCellShouldShowLeftAccessoryButtonsNotification = @"ChatsTableViewCellShouldShowLeftAccessoryButtonsNotification";
static NSString * const kChatsTableViewCellShouldHideLeftAccessoryButtonsNotification = @"ChatsTableViewCellShouldHideLeftAccessoryButtonsNotification";
static NSString * const kAttachedObjectWasFetchedNotification = @"AttachedObjectWasFetchedNotification";
static NSString * const kApplicationGoesToSleepNotification = @"ApplicationGoesToSleepNotification";
static NSString * const kXMPPRoomJoinedToWrongRoom = @"XMPPRoomJoinedToWrongRoom";
static NSString * const kXMPPStreamDidAutentificateNotification = @"XMPPStreamDidAutentificateNotification";
static NSString * const kUnreadMessageCountChanged = @"unreadMessageCountChanged";

// Alert Messages
static NSString * const alertEmptyFields = @"Email or Password cannot be empty";
static NSString * const alertPasswordDoNotMatch = @"Passwords do not match";
static NSString * const userDoesNotExistMSG = @"This user does not exist";
static NSString * const emailIsIncorrectMSG = @"Email is incorrect";
static NSString * const incorrectInputDataMSG = @"Password is incorrect";
static NSString * const internetConnectionFailedMSG = @"Connection Failed\nCheck your internet connection and try again";
static NSString * const kInternetRestoredMSG = @"Internet connection restored";
static NSString * const changesNotSavedMSG = @"You have made changes.\nWould you like to SAVE them?";
static NSString * const phoneNumInvalidMSG = @"Warning\nPhone Number is empty";
static NSString * const choosePhoneNumberMSG = @"Please select Country Code";
static NSString * const checkCorrectPhoneNumMSG = @"Is this correct?\nYou entered your phone as";
static NSString * const twitterCantPostMSG = @"It seems that we cannot talk to Twitter at the moment or you have not yet added your Twitter account to this device. Go to the Settings application to add your Twitter account to this device.";
static NSString * const fbCantPostMSG = @"It seems that we cannot talk to Facebook at the moment or you have not yet added your Facebook account to this device. Go to the Settings application to add your Facebook account to this device.";
static NSString * const inviteToChatMSG = @"would like to role-chat with you";
static NSString * const declinedInviteToChatMSG = @"declined your invite";
static NSString * const acceptedInviteToChatMSG = @"accepted your invite. Go to Chat Rooms and start chatting";
static NSString * const kWaitingResponseMSG = @"Waiting for response";
static NSString * const kRequestRejectedMSG = @"Sorry your request is rejected";
static NSString * const kWaitingResponseCode = @"Wa1tingF0rResp0nseC0DE_MSG_21-02-2015-12-00";
static NSString * const kDeclinedAccessCode = @"Decl1nedAccEssC0DE_MSG_21-02-2015-12-00";
static NSString * const kSetPhoneNumberMSG = @"Would you like to add phone number so your friends will be able to find you?";
static NSString * const kThanksForComplaintMSG = @"Thank you for your report. We will remove this image if it violates our guidelines";
static NSString * const kThanksForComplaintProfileMSG = @"Thank you for your report. We will remove this profile if it violates our guidelines";


// Lockbox keys
static NSString * const lastSuccessLoggedEmailKey = @"lastSuccessLoggedEmail";
static NSString * const isTransferDataToVersionTwoDatabaseKey = @"isTransferDataToVersionTwoDatabase";

static NSString * const isUserAvatarChanged = @"isUserAvatarChanged";
static NSString * const isFriendAvatarChanged = @"isFriendAvatarChanged";

//  PARSE CLASS NAMES
static NSString * const timeUserLoginClass = @"TimeUserLogin";
static NSString * const userSettingsClass = @"UserSettings";

//  columns for timeUserLoginClass
static NSString * const timeLoginCol = @"timeLogin";
static NSString * const userCol = @"user";
static NSString * const userNameCol = @"userName";

//  columns for userSettingsClass
static NSString * const usersNameCol = @"userName";
static NSString * const usersEmailCol = @"userEmail";
static NSString * const usersPasswordCol = @"usersPassword";
static NSString * const avatarImageCol = @"avatarImage";
static NSString * const friendsNameCol = @"friendsName";
static NSString * const friendsAgeCol = @"friendsAge";
static NSString * const friendsPersonalityCol = @"friendsPersonality";
static NSString * const friendsOccupationCol = @"friendsOccupation";
static NSString * const friendsAvatarImageCol = @"friendsAvatarImage";
static NSString * const attachedToUserCol = @"attachedToUser";
static NSString * const addedUserImageCol = @"addedUserImage";
static NSString * const addedFriendImageCol = @"addedFriendImage";
static NSString * const lastChangedCol = @"lastChanged";


// Keys for CountryCode Dictionary
static NSString * const kCountryName = @"countryName";
static NSString * const kCountryCode = @"countryCode";

// Keys for NotificationObject Dictionary
static NSString * const kIsTableView = @"IsTableView";
static NSString * const kIndexPath = @"IndexPath";

// CoreData keys
static NSString * const objectIdKey = @"objectId";
static NSString * const userIdKey = @"userId";
static NSString * const emailKey = @"email";
static NSString * const createdAtKey = @"createdAt";
static NSString * const messageKey = @"message";
static NSString * const messageTypeKey = @"messageType";

//XMPPMessage Dictionary keys
static NSString * const kXMPPmessageID = @"XMPPmessageID";
static NSString * const kXMPPmessageText = @"XMPPmessageTextKey";
static NSString * const kXMPPmessageRoomJID = @"XMPPmessageRoomJID";
static NSString * const kXMPPmessageOwner = @"XMPPmessageOwner";
static NSString * const kXMPPFullImagemageURL = @"XMPPFullImagemageURLKey";
static NSString * const kXMPPThumbnailImagemageURL = @"XMPPThumbnailImagemageURLKey";
static NSString * const kXMPPcreatedAt = @"XMPPcreatedAtKey";
static NSString * const kXMPPThumbnailWidth = @"XMPPThumbnailWidth";
static NSString * const kXMPPThumbnailHeight = @"XMPPThumbnailHeight";

// SegueIdentifiers
static NSString * const imaginaryFriendSettingsIdentifier = @"ImaginaryFriendSettingsIdentifier";


static NSString * const userAvatarFileName = @"userAvatarImage.png";
static NSString * const friendAvatarFileName = @"friendAvatarImage.png";

// Sounds names
static NSString * const facebookMessageSound = @"facebook_chat_sound";

// Email for Report Inappropriate
static NSString * const reportEmail = @"admin@uchatu.com";

#endif
