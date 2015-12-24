//
//	SwiftDate, an handy tool to manage date and timezones in swift
//	Created by:				Daniele Margutti
//	Main contributors:		Jeroen Houtzager
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

// Backward compatibility resolves issue https://github.com/malcommac/SwiftDate/issues/121
//
@available(*, renamed="DateRegion")
public typealias Region = DateRegion

/// All classes and protocols that can define a DateRegion must comply to the DateRegionSpecifier protocol
public protocol DateRegionSpecifier {}

// These classes comply. 
// Please note: As we cannot extend the protocol `TimeZoneConvertible`, the DateRegionSpecifier conformance 
// is defined on the `TimeZoneConvertible` protocol itself.
//
extension String: DateRegionSpecifier {}
extension NSCalendar: DateRegionSpecifier {}
extension NSTimeZone: DateRegionSpecifier {}
extension NSLocale: DateRegionSpecifier {}
extension CalendarType: DateRegionSpecifier {}
extension NSDateComponents: DateRegionSpecifier {}


/// DateRegion encapsulates all objects you need when representing a date ffrom an absolute time like NSDate.
///
@available(*, introduced=2.1)
public class DateRegion: Equatable {
    
    /// Calendar to interpret date values. You can alter the calendar to adjust the representation of date to your needs.
    ///
    public let calendar: NSCalendar!

    /// Time zone to interpret date values
    /// Because the time zone is part of calendar, this is a shortcut to that variable.
    /// You can alter the time zone to adjust the representation of date to your needs.
    ///
    public let timeZone: NSTimeZone!

    /// Locale to interpret date values
    /// Because the locale is part of calendar, this is a shortcut to that variable.
    /// You can alter the locale to adjust the representation of date to your needs.
    ///
    public let locale: NSLocale!
    
    /// Initialise with a calendar and/or a time zone
    ///
    /// - Parameters:
    ///     - calendar: the calendar to work with to assign, default = the current calendar
    ///     - timeZone: the time zone to work with, default is the default time zone
    ///     - locale: the locale to work with, default is the current locale
    ///     - region: a region to copy
    ///
    /// - Note: parameters higher in the list take precedence over parameters lower in the list. E.g.
    ///     `DateRegion(locale: mylocale, "en_AU", region)` will copy region and set locale to mylocale, not `en_AU`.
    ///
    public init(
        calendar: NSCalendar,
        timeZone: NSTimeZone,
        locale: NSLocale) {
            
            self.calendar = calendar
            self.timeZone = timeZone
            self.locale = locale
            
            // Assign calendar fields
            self.calendar.timeZone = self.timeZone
            self.calendar.locale = self.locale
    }
    
    /// Convenience initialiser for DateRegion where you can use any combination of calendar-, tiem zone- and locale identification objects
    ///
    /// - Parameters:
    ///     - _ : any of NSCalendar, NSLocale, NSTimeZone, DateRegion, String.
    ///
    /// - Remarks: the `String` type parameter can be any of a locale identifier, calendar identifier, time zone abbreviation, time zone name.
    ///
    /// - Note: parameters that are specified left in the list take precedence over parameters right in the list. E.g.
    ///     `DateRegion(locale: mylocale, "en_AU", region)` will copy region and set locale to mylocale, not `en_AU`.
    ///
    public convenience init(_ initObjects: DateRegionSpecifier?...) {

        var calendar: NSCalendar = NSCalendar.currentCalendar()
        var timeZone: NSTimeZone = NSTimeZone.defaultTimeZone()
        var locale: NSLocale = NSLocale.currentLocale()
        
        for initObject in initObjects.reverse() {
            
            guard initObject != nil else {
                continue
            }

            if initObject is NSCalendar {
                calendar = (initObject as! NSCalendar)
                continue
            }
            
            if initObject is NSTimeZone {
                timeZone = (initObject as! NSTimeZone)
                continue
            }
            
            if initObject is NSLocale {
                locale = (initObject as! NSLocale)
                continue
            }
            
            if initObject is CalendarType {
                calendar = (initObject as! CalendarType).toCalendar()
                continue
            }
            
            if initObject is TimeZoneConvertible {
                timeZone = (initObject as! TimeZoneConvertible).timeZone
                continue
            }
            
            if initObject is DateRegion {
                let region = (initObject as! DateRegion)
                calendar = region.calendar
                timeZone = region.timeZone
                locale = region.locale
                continue
            }
            
            if initObject is Int {
                let offset = (initObject as! Int)
                timeZone = NSTimeZone(forSecondsFromGMT: offset)
                continue
            }
            
            if initObject is NSDateComponents {
                let components = (initObject as! NSDateComponents)
                if let generatedCalendar = components.calendar {
                    calendar = generatedCalendar
                    if let generatedLocale = generatedCalendar.locale {
                        locale = generatedLocale
                    }
                }
                if let generatedTimeZone = components.timeZone {
                    timeZone = generatedTimeZone
                }
                continue
            }
            
            if initObject is String {
                let str = (initObject as! String)
                
                if NSLocale.availableLocaleIdentifiers().contains(str) {
                    locale = NSLocale(localeIdentifier: str)
                    continue
                }
                
                if let generatedTimeZone = NSTimeZone(abbreviation: str) {
                    timeZone = generatedTimeZone
                    continue
                }
                
                if let generatedTimeZone = NSTimeZone(name: str) {
                    timeZone = generatedTimeZone
                    continue
                }
                
                if let generatedCalendar = NSCalendar(calendarIdentifier: str) {
                    calendar = generatedCalendar
                    continue
                }
            }
            
            // This line should not be reached unless there is an invalid initialisation object in the initObjects array
            assertionFailure("Illegal initialiser object for DateRegion: \(initObject)")
            
        }
        self.init(calendar: calendar, timeZone: timeZone, locale: locale)
    }
    
    /// Today's date
    ///
    /// - Returns: the date of today at midnight (00:00) in the current calendar and default time zone.
    ///
    public func today() -> DateInRegion {
        return DateInRegion(region: self).startOf(.Day)
    }

    /// Yesterday's date
    ///
    /// - Returns: the date of yesterday at midnight (00:00)
    ///
    public func yesterday() -> DateInRegion {
        return today() - 1.days
    }

    /// Tomorrow's date
    ///
    /// - Returns: the date of tomorrow at midnight (00:00)
    ///
    public func tomorrow() -> DateInRegion {
        return today() + 1.days
    }

}

public func ==(left: DateRegion, right: DateRegion) -> Bool {
    if left.calendar.calendarIdentifier != right.calendar.calendarIdentifier {
        return false
    }

    if left.timeZone.secondsFromGMT != right.timeZone.secondsFromGMT {
        return false
    }

    if left.locale.localeIdentifier != right.locale.localeIdentifier  {
        return false
    }

    return true
}

extension DateRegion: Hashable {
    public var hashValue: Int {
        return calendar.hashValue ^ timeZone.hashValue ^ locale.hashValue
    }
}

extension DateRegion: CustomStringConvertible {
    public var description: String {
        let timeZoneAbbreviation = timeZone.abbreviation ?? ""
        return "\(calendar.calendarIdentifier); \(timeZone.name):\(timeZoneAbbreviation); \(locale.localeIdentifier)"
    }
}