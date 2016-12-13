/*!
 * \file MDDebug.h_
 * \brief A formated debug output library.
 * \details Described macros work only with debug project build settings. Only the <b>$epicfail</b> macro works with <b>any project build settings</b>.
 * \autor Anton Degtyar, Mozi Development
 * \version 0.5.1
 * \date 18.04.2011
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MDDebugObject.h"
#import <stdio.h>
#import <unistd.h>
#import <sys/uio.h>
#import <pthread.h>


#ifndef MDDebug_h
#define MDDebug_h

#define COLOR_OUTPUT true

/* BEGIN PRIVATE DEFINES */
    #define COLOR_RED @"\e[fg214,0,0;"
    #define COLOR_YELLOW @"\e[fg208,130,10;"
    #define COLOR_BLUE @"\e[fg0,0,210;"
    #define COLOR_NO @""

    #define _FILE strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__

    #define PRINTFUNCTION(color, format, ...)      objc_print(color, @format, __VA_ARGS__)

    #define LOG_FMT             "%30s : %-4d ~~ "
    #define LOG_ARGS   _FILE, __LINE__

    #define NEWLINE     "\n"

    #if __has_feature(objc_arc)
    #define RELEASE(OBJ)            OBJ = nil
    #else
    #define RELEASE(OBJ)            [OBJ release];
    #endif
/* END PRIVATE DEFINES */


/* BEGIN PRIVATE FUNCTION */
    static inline char *timenow() {
        static char buffer[24];
        time_t rawtime;
        static struct tm *timeinfo;
        
        time(&rawtime);
        timeinfo = localtime(&rawtime);
        
        static double milliseconds = 0.0f;
        milliseconds = CFAbsoluteTimeGetCurrent();
        static double fractpart, intpart;
        fractpart = modf(milliseconds, &intpart);
        fractpart *= 1000;
        
        snprintf(buffer, 24, "%04ld-%02ld-%02ld %02ld:%02ld:%02ld:%03d",
                 (long)timeinfo->tm_year + 1900,
                 (long)timeinfo->tm_mon + 1,
                 (long)timeinfo->tm_mday,
                 (long)timeinfo->tm_hour,
                 (long)timeinfo->tm_min,
                 (long)timeinfo->tm_sec,
                 (int)fractpart);
        
        return buffer;
    }


    static inline void objc_print(NSString *color, NSString *format, ...) {
        @autoreleasepool {
            va_list args;
            va_start(args, format);
            
            static unsigned long appLen = 0;
            static char *app = nil;
            
            static unsigned long pidLen = 0;
            static char *pid = nil;
            
            if (!app) {
                NSString *appName = [[NSProcessInfo processInfo] processName];
                appLen = [appName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                app = (char *)malloc(appLen + 1);
                [appName getCString:app maxLength:(appLen+1) encoding:NSUTF8StringEncoding];
            }
            if (!pid) {
                NSString *processID = [NSString stringWithFormat:@"%i", (int)getpid()];
                pidLen = [processID lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                pid = (char *)malloc(pidLen + 1);
                [processID getCString:pid maxLength:(pidLen+1) encoding:NSUTF8StringEncoding];
            }
            
            static char tid[9];
            mach_port_t machTID = pthread_mach_thread_np(pthread_self());
            unsigned long tidLen = (unsigned long)snprintf(tid, 9, "%x", machTID);
            
            NSString *logStr = [[NSString alloc] initWithFormat:format arguments:args];
            
            static struct iovec v[12];
            
            v[0].iov_base = timenow();
            v[0].iov_len = 23;
            
            v[1].iov_base = (void *)" ";
            v[1].iov_len = 1;
            
            v[2].iov_base = app;
            v[2].iov_len = appLen;
            
            v[3].iov_base = (void *)"[";
            v[3].iov_len = 1;
            
            v[4].iov_base = pid;
            v[4].iov_len = pidLen;
            
            v[5].iov_base = (void *)":";
            v[5].iov_len = 1;
            
            v[6].iov_base = tid;
            v[6].iov_len = tidLen;
            
            v[7].iov_base = (void *)"] ";
            v[7].iov_len = 2;
            
            unsigned long colorNameLength = color.length;
            if (COLOR_OUTPUT && colorNameLength > 0) {
                v[8].iov_base = (char *)[color cStringUsingEncoding:NSUTF8StringEncoding];
                v[8].iov_len = colorNameLength;
                
                v[10].iov_base = (void *)"\e[;";
                v[10].iov_len = 3;
            } else {
                v[8].iov_base = (void *)"";
                v[8].iov_len = 0;
                
                v[10].iov_base = (void *)"";
                v[10].iov_len = 0;
            }
            
            v[9].iov_base = (char *)[logStr cStringUsingEncoding:NSUTF8StringEncoding];
            v[9].iov_len = [logStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            
            v[11].iov_base = (void *)"\n";
            v[11].iov_len = 1;
            
            writev(STDERR_FILENO, v, 12);
            
            RELEASE(logStr);
            va_end(args);
        }
    }


    static inline id $__emptyFunction(id nsObject) {
        return nsObject;
    }
/* END PRIVATE FUNCTION */

/* BEGIN PUBLIC DEFINES*/
#ifdef DEBUG
//Trace function
    #define $tf \
        MDDebugObject *debugObject __attribute__((unused)) = [[MDDebugObject alloc] intitWith:__LINE__];

	/*!
	 * @hideinitializer
	 * Prints a block of code, passed as an argument, and executes it.\n\n
	 * <b>Usage:</b>
	 * @code
	 * $t(NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];)
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 12:18:21.730 Fishmarx[5383:207] main.m:13 ~~ NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	 * @endcode
	 */
	#define $t(...) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT" %s ", _FILE, __LINE__, #__VA_ARGS__);\
				__VA_ARGS__


	/*!
 	 * @hideinitializer
	 * Prints a '@' label.\n\n
	 * <b>Usage:</b>
	 * @code
	 * $
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 12:09:12.036 MyProject[4979:207] main.m:13 ~~ @
	 * @endcode
	 */
	#define $ \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"    @", _FILE, __LINE__);\

	#define $th \
				$l(@"current thread: %@", [NSThread currentThread]);


	/*!
	 * @hideinitializer
	 * Prints function name.\n\n
	 * <b>Usage:</b>
	 * @code
	 * -(void) func { $c
	 *	...
	 * }
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 12:09:12.036 MyProject[4979:207] ~~ main.m:13 call main
	 * @endcode
	 */
    #define $c \
             PRINTFUNCTION(COLOR_NO, LOG_FMT "%s ", _FILE, __LINE__, __FUNCTION__);


	/*!
 	 * @hideinitializer
	 * Prints function name at return statement.\n\n
	 * <b>Usage:</b>
	 * @code
	 * -(int) func {
	 *	$retrun 0;
	 * }
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 12:09:12.036 MyProject[4979:207] main.m:13 ~~ return main
	 * @endcode
	 */
	#define $return \
                return PRINTFUNCTION(COLOR_NO, LOG_FMT "return %s ", _FILE, __LINE__, __FUNCTION__),


	/*!
	 * @hideinitializer
	 * Prints a passed object's string representation and returns that object, so can be used inside of the expressions.\n\n
	 * <b>Usage:</b>
	 * @code
	 * [NSDictionary alloc] initWithObjectsAndKeys:$ns([NSArray alloc] initWithObjects:@"render",
	 *																				 @"opengl",
	 * 																				 @"mode",
	 * 																				 @"vga",
	 * 																				 nil])];
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 12:07:35.455 MyProject[4689:207] main.m:18 ~~ [[NSArray alloc] initWithObjects:@"render", @"opengl", @"mode", @"vga", nil] = (
	 *	render,
	 *	opengl,
	 *	mode,
	 *	vga
	 * )
	 * @endcode
	 */

    #define $ns(...) \
    $__printNSObject(_FILE, __LINE__, #__VA_ARGS__, (__VA_ARGS__))

    __unused static id $__printNSObject(const char *file, const int line, const char *name, id nsObject) {
                PRINTFUNCTION(COLOR_NO, LOG_FMT"%s = %@", file, line, name, nsObject);
                return nsObject;
    }

	/*!
	 * @hideinitializer
	 * Prints a passed expression result.\n\n
	 * <b>Usage:</b>
	 * @code
	 * $w("%f", newFrame.origin.x);
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 12:07:35.455 MyProject[4689:207] main.m:18 ~~ newFrame.origin.x = 456;
	 * @endcode
	 */
	#define $w(type, ...) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"%s = " type, _FILE, __LINE__,  #__VA_ARGS__, (__VA_ARGS__));

	#define	$r(rect) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"%s = (%f; %f), %f * %f", _FILE, __LINE__, #rect, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	#define	$s(size) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"%s = %f * %f", _FILE, __LINE__, #size, size.width, size.height);

	#define	$p(point) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"%s = (%f; %f)", _FILE, __LINE__, #point, point.x, point.y);

	
	/*!
	 * @hideinitializer
	 * Works like NSLog, but prints additional information.\n\n
	 * <b>Usage:</b>
	 * @code
	 * $l(@"%s", "hellomoto!");
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 11:18:22.255 MyProject[3269:207] main.m:57 ~~ hellomoto!
	 * @endcode
	 */
	#define $l(format, ...) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT format, LOG_ARGS, ##__VA_ARGS__)
    #define $le(message, ...) \
                PRINTFUNCTION(COLOR_RED, LOG_FMT message, LOG_ARGS, ##__VA_ARGS__)
    #define $lw(message, ...) \
                PRINTFUNCTION(COLOR_YELLOW, LOG_FMT message, LOG_ARGS, ##__VA_ARGS__)
    #define $li(message, ...) \
                PRINTFUNCTION(COLOR_BLUE, LOG_FMT message, LOG_ARGS, ##__VA_ARGS__)


	/*!
	 * @hideinitializer
	 * Prints 'if' statement result.\n\n
	 * <b>Usage:</b>
	 * @code
	 * $if (something > someone) {
	 * 	...
	 * }
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-26 11:18:22.255 MyProject[3269:207] main.m:57 ~~ if (something > someone) == true
	 * @endcode
	 */
	#define $if(...) \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"if (%s) == %s", _FILE, __LINE__, #__VA_ARGS__, ((__VA_ARGS__) ? "true" : "false")); \
                if (__VA_ARGS__)			


	/*!
	 * @hideinitializer
	 * Sends SIGABT to application if \a condition evaluates to 'true' and prints \a message with call stack.\n\n
	 * <b>Usage:</b>
	 * @code
	 * $fail([insaneStuff happened], @"Insane stuff happened.");
	 * @endcode
	 * <b>Output:</b>
	 * @code
	 * 2011-04-30 18:17:19.282 MyProject[3242:207] CatchDetailsViewController.m:87 ~~ fail: Insane stuff happened.
	 * Stack:
	 * (
	 * 0   Fishmarx                            0x00056e2d -[CatchDetailsViewController initReadOnlyWithCatchId:] + 125
	 * 1   Fishmarx                            0x00003fd9 -[CompetitionsViewController tableView:didSelectRowAtIndexPath:] + 169
	 * 2   UIKit                               0x006c6718 -[UITableView _selectRowAtIndexPath:animated:scrollPosition:notifyDelegate:] + 1140
	 * 3   UIKit                               0x006bcffe -[UITableView _userSelectRowAtIndexPath:] + 219
	 * 4   Foundation                          0x023bbcea __NSFireDelayedPerform + 441
	 * 5   CoreFoundation                      0x029afd43 __CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__ + 19
	 * 6   CoreFoundation                      0x029b1384 __CFRunLoopDoTimer + 1364
	 * 7   CoreFoundation                      0x0290dd09 __CFRunLoopRun + 1817
	 * 8   CoreFoundation                      0x0290d280 CFRunLoopRunSpecific + 208
	 * 9   CoreFoundation                      0x0290d1a1 CFRunLoopRunInMode + 97
	 * 10  GraphicsServices                    0x0348e2c8 GSEventRunModal + 217
	 * 11  GraphicsServices                    0x0348e38d GSEventRun + 115
	 * 12  UIKit                               0x00662b58 UIApplicationMain + 1160
	 * 13  Fishmarx                            0x0000290f main + 127
	 * 14  Fishmarx                            0x00002815 start + 53
	 * )
	 * @endcode
	 */
	#define $fail(condition, format, ...) \
				if (condition) { \
                    PRINTFUNCTION(COLOR_NO, LOG_FMT"fail: " format "%@", _FILE, __LINE__, ##__VA_ARGS__, [NSThread callStackSymbols]); \
					abort(); \
				}

#else
    #define $tf

	#define $t(...) \
				$__emptyFunction (__VA_ARGS__)

	#define $

	#define $c

	#define $return \
				return

    #define $ns(...) \
                $__emptyFunction (__VA_ARGS__)

	#define $r(...)

	#define $s(...)

	#define $p(...)

    #define $w(type, ...)

	#define $l(format, ...)

    #define $li(format, ...)

    #define $lw(format, ...)

    #define $le(format, ...)

	#define $if(...) \
				if (__VA_ARGS__)

    #define $fail(condition, format, ...)
#endif


#define $epicfail(condition, format, ...) \
            if (condition) { \
                PRINTFUNCTION(COLOR_NO, LOG_FMT"fail: " format "%@", _FILE, __LINE__, ##__VA_ARGS__, [NSThread callStackSymbols]); \
                abort(); \
            }
#endif
