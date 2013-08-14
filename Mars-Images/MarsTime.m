//
//  MarsTime.m
//  Mars-Images
//
//  Created by Mark Powell on 5/21/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "MarsTime.h"

#define DEG_TO_RAD M_PI/180.0

//    i 	Ai 	τi 	φi
//    1 	0.0071 	2.2353 	49.409
//    2 	0.0057 	2.7543 	168.173
//    3 	0.0039 	1.1177 	191.837
//    4 	0.0037 	15.7866 21.736
//    5 	0.0021 	2.1354 	15.704
//    6 	0.0020 	2.4694 	95.528
//    7 	0.0018 	32.8493 49.095
static float A[] = { 0.0071, 0.0057, 0.0039, 0.0037, 0.0021, 0.0020, 0.0018 };
static float tau[] = { 2.2353, 2.7543, 1.1177, 15.7866, 2.1354, 2.4694, 32.8493 };
static float psi[] = { 49.409, 168.173, 191.837, 21.736, 15.704, 95.528, 49.095 };

@implementation MarsTime

/* TABLE OF LEAP SECONDS: ftp://maia.usno.navy.mil/ser7/tai-utc.dat
 1961 JAN  1 =JD 2437300.5  TAI-UTC=   1.4228180 S + (MJD - 37300.) X 0.001296 S
 1961 AUG  1 =JD 2437512.5  TAI-UTC=   1.3728180 S + (MJD - 37300.) X 0.001296 S
 1962 JAN  1 =JD 2437665.5  TAI-UTC=   1.8458580 S + (MJD - 37665.) X 0.0011232S
 1963 NOV  1 =JD 2438334.5  TAI-UTC=   1.9458580 S + (MJD - 37665.) X 0.0011232S
 1964 JAN  1 =JD 2438395.5  TAI-UTC=   3.2401300 S + (MJD - 38761.) X 0.001296 S
 1964 APR  1 =JD 2438486.5  TAI-UTC=   3.3401300 S + (MJD - 38761.) X 0.001296 S
 1964 SEP  1 =JD 2438639.5  TAI-UTC=   3.4401300 S + (MJD - 38761.) X 0.001296 S
 1965 JAN  1 =JD 2438761.5  TAI-UTC=   3.5401300 S + (MJD - 38761.) X 0.001296 S
 1965 MAR  1 =JD 2438820.5  TAI-UTC=   3.6401300 S + (MJD - 38761.) X 0.001296 S
 1965 JUL  1 =JD 2438942.5  TAI-UTC=   3.7401300 S + (MJD - 38761.) X 0.001296 S
 1965 SEP  1 =JD 2439004.5  TAI-UTC=   3.8401300 S + (MJD - 38761.) X 0.001296 S
 1966 JAN  1 =JD 2439126.5  TAI-UTC=   4.3131700 S + (MJD - 39126.) X 0.002592 S
 1968 FEB  1 =JD 2439887.5  TAI-UTC=   4.2131700 S + (MJD - 39126.) X 0.002592 S
 1972 JAN  1 =JD 2441317.5  TAI-UTC=  10.0       S + (MJD - 41317.) X 0.0      S
 1972 JUL  1 =JD 2441499.5  TAI-UTC=  11.0       S + (MJD - 41317.) X 0.0      S
 1973 JAN  1 =JD 2441683.5  TAI-UTC=  12.0       S + (MJD - 41317.) X 0.0      S
 1974 JAN  1 =JD 2442048.5  TAI-UTC=  13.0       S + (MJD - 41317.) X 0.0      S
 1975 JAN  1 =JD 2442413.5  TAI-UTC=  14.0       S + (MJD - 41317.) X 0.0      S
 1976 JAN  1 =JD 2442778.5  TAI-UTC=  15.0       S + (MJD - 41317.) X 0.0      S
 1977 JAN  1 =JD 2443144.5  TAI-UTC=  16.0       S + (MJD - 41317.) X 0.0      S
 1978 JAN  1 =JD 2443509.5  TAI-UTC=  17.0       S + (MJD - 41317.) X 0.0      S
 1979 JAN  1 =JD 2443874.5  TAI-UTC=  18.0       S + (MJD - 41317.) X 0.0      S
 1980 JAN  1 =JD 2444239.5  TAI-UTC=  19.0       S + (MJD - 41317.) X 0.0      S
 1981 JUL  1 =JD 2444786.5  TAI-UTC=  20.0       S + (MJD - 41317.) X 0.0      S
 1982 JUL  1 =JD 2445151.5  TAI-UTC=  21.0       S + (MJD - 41317.) X 0.0      S
 1983 JUL  1 =JD 2445516.5  TAI-UTC=  22.0       S + (MJD - 41317.) X 0.0      S
 1985 JUL  1 =JD 2446247.5  TAI-UTC=  23.0       S + (MJD - 41317.) X 0.0      S
 1988 JAN  1 =JD 2447161.5  TAI-UTC=  24.0       S + (MJD - 41317.) X 0.0      S
 1990 JAN  1 =JD 2447892.5  TAI-UTC=  25.0       S + (MJD - 41317.) X 0.0      S
 1991 JAN  1 =JD 2448257.5  TAI-UTC=  26.0       S + (MJD - 41317.) X 0.0      S
 1992 JUL  1 =JD 2448804.5  TAI-UTC=  27.0       S + (MJD - 41317.) X 0.0      S
 1993 JUL  1 =JD 2449169.5  TAI-UTC=  28.0       S + (MJD - 41317.) X 0.0      S
 1994 JUL  1 =JD 2449534.5  TAI-UTC=  29.0       S + (MJD - 41317.) X 0.0      S
 1996 JAN  1 =JD 2450083.5  TAI-UTC=  30.0       S + (MJD - 41317.) X 0.0      S
 1997 JUL  1 =JD 2450630.5  TAI-UTC=  31.0       S + (MJD - 41317.) X 0.0      S
 1999 JAN  1 =JD 2451179.5  TAI-UTC=  32.0       S + (MJD - 41317.) X 0.0      S
 2006 JAN  1 =JD 2453736.5  TAI-UTC=  33.0       S + (MJD - 41317.) X 0.0      S
 2009 JAN  1 =JD 2454832.5  TAI-UTC=  34.0       S + (MJD - 41317.) X 0.0      S
 2012 JUL  1 =JD 2456109.5  TAI-UTC=  35.0       S + (MJD - 41317.) X 0.0      S
 */

/* return the TAI-UTC lookup table value of leap seconds for a given date */
+ (float) taiutc: (NSDate*) date {
    double julianDate = [MarsTime getJulianDate:date];
    if (julianDate >= 2456109.5)
        return 35.0;
    else if (julianDate >= 2454832.5)
        return 34.0;
    else if (julianDate >= 2453736.5)
        return 33.0;
    else if (julianDate >= 2451179.5)
        return 32.0;
    else if (julianDate >= 2450630.5)
        return 31.0;
    else if (julianDate >= 2450083.5)
        return 30.0;
    else if (julianDate >= 2449534.5)
        return 29.0;
    else if (julianDate >= 2449169.5)
        return 28.0;
    else if (julianDate >= 2448804.5)
        return 27.0;
    else if (julianDate >= 2448257.5)
        return 26.0;
    else if (julianDate >= 2447892.5)
        return 25.0;
    else if (julianDate >= 2447161.5)
        return 24.0;
    else if (julianDate >= 2446247.5)
        return 23.0;
    else if (julianDate >= 2445516.5)
        return 22.0;
    else if (julianDate >= 2445151.5)
        return 21.0;
    else if (julianDate >= 2444786.5)
        return 20.0;
    else if (julianDate >= 2444239.5)
        return 19.0;
    else if (julianDate >= 2443874.5)
        return 18.0;
    else if (julianDate >= 2443509.5)
        return 17.0;
    else if (julianDate >= 2443144.5)
        return 16.0;
    else if (julianDate >= 2442778.5)
        return 15.0;
    else if (julianDate >= 2442413.5)
        return 14.0;
    else if (julianDate >= 2442048.5)
        return 13.0;
    else if (julianDate >= 2441683.5)
        return 12.0;
    else if (julianDate >= 2441499.5)
        return 11.0;
    else if (julianDate >= 2441317.5)
        return 10.0;
    else if (julianDate >= 2439887.5)
        return 4.2131700;
    else if (julianDate >= 2439126.5)
        return 4.3131700;
    else if (julianDate >= 2439004.5)
        return 3.8401300;
    else if (julianDate >= 2438942.5)
        return 3.7401300;
    else if (julianDate >= 2438820.5)
        return 3.6401300;
    else if (julianDate >= 2438761.5)
        return 3.5401300;
    else if (julianDate >= 2438639.5)
        return 3.4401300;
    else if (julianDate >= 2438486.5)
        return 3.3401300;
    else if (julianDate >= 2438395.5)
        return 3.2401300;
    else if (julianDate >= 2438334.5)
        return 1.9458580;
    else if (julianDate >= 2437665.5)
        return 1.8458580;
    else if (julianDate >= 2437512.5)
        return 1.3728180;
    else if (julianDate >= 2437300.5)
        return 1.4228180;
    
    NSLog(@"No lookup table value for date %@", date);
    return 0;
}

+ (double) canonicalValue24:(double)hours {
    if (hours < 0)
        return 24 + hours;
    else if (hours > 24)
        return hours - 24;
    return hours;
}

+ (NSArray*) getMarsTimes: (NSDate*) date
                longitude: (float) longitude {
    //A-1 millis since Jan 1 1970
//    NSTimeInterval millis = 1000 * [date timeIntervalSince1970];
    
    //A-2 convert to Julian date: JDUT = 2440587.5 + (millis / 8.64×107 ms/day)
    double jdut = [MarsTime getJulianDate: date];
    
    //A-3 Determine time offset from J2000 epoch: T = (JDUT - 2451545.0) / 36525. 
//    double t = (jdut - 2451545.0) / 36525.0;
    
    //A-4 Determine UTC to TT conversion (consult table of leap seconds) To obtain the TT-UTC difference, add 32.184 seconds to the value of TAI-UTC
    float tt_utc_diff = 32.184 + [MarsTime taiutc: date];
    
    //A-5 Determine Julian Date: JDTT = JDUT + [(TT - UTC) / 86400 s·day-1]
    double jdtt = jdut + tt_utc_diff / 86400.0;
    
    //A-6 Determine time offset from J2000 epoch (TT). (AM2000, eq. 15): ΔtJ2000 = JDTT - 2451545.0
    double deltaJ2000 = jdtt - 2451545.0;
    
    //B-1 Determine Mars mean anomaly. (AM2000, eq. 16): M = 19.3870° + 0.52402075° ΔtJ2000
    double marsMeanAnomaly = 19.3870 + 0.52402075 * deltaJ2000;
    
    //B-2 Determine angle of Fiction Mean Sun. (AM2000, eq. 17): αFMS = 270.3863° + 0.52403840° ΔtJ2000
    double angleFictiousMeanSun = 270.3863 + 0.52403840 * deltaJ2000;
    
    //B-3 PBS = Σ(i=1,7) Ai cos [ (0.985626° ΔtJ2000 / τi) + φi]
    //    where 0.985626° = 360° / 365.25, and
    //    i 	Ai 	τi 	φi
    //    1 	0.0071 	2.2353 	49.409
    //    2 	0.0057 	2.7543 	168.173
    //    3 	0.0039 	1.1177 	191.837
    //    4 	0.0037 	15.7866 21.736
    //    5 	0.0021 	2.1354 	15.704
    //    6 	0.0020 	2.4694 	95.528
    //    7 	0.0018 	32.8493 49.095
    double pbs = 0.0;
    for (int i = 0; i < 7; i++) {
        pbs += A[i] * cos((0.985626 * deltaJ2000 / tau[i] + psi[i]) * DEG_TO_RAD);
    }

    //B-4 Determine Equation of Center. (Bracketed term in AM2000, eqs. 19 and 20)
    //The equation of center is the true anomaly minus mean anomaly.
    //ν - M = (10.691° + 3.0° × 10-7 ΔtJ2000) sin M + 0.623° sin 2M + 0.050° sin 3M + 0.005° sin 4M + 0.0005° sin 5M + PBS
    double v_M_diff = (10.691 + .0000003 * deltaJ2000) * sin(marsMeanAnomaly * DEG_TO_RAD) +
    0.623 * sin(2*marsMeanAnomaly * DEG_TO_RAD) + 0.050 * sin(3*marsMeanAnomaly * DEG_TO_RAD) +
    0.005 * sin(4*marsMeanAnomaly * DEG_TO_RAD) + 0.0005 * sin(5*marsMeanAnomaly * DEG_TO_RAD) + pbs;

    //B-5 Determine areocentric solar longitude. (AM2000, eq. 19): Ls = αFMS + (ν - M)
    double ls = angleFictiousMeanSun + v_M_diff;
    
    //C-1 Determine equation of time: EOT = 2.861° sin 2Ls - 0.071° sin 4Ls + 0.002° sin 6Ls - (ν - M)
    double eot = 2.861 * sin(2*ls*DEG_TO_RAD) - 0.071 * sin(4*ls*DEG_TO_RAD) + 0.002 * sin(6*ls*DEG_TO_RAD) - v_M_diff;
    
    //C-2 Determine Coordinated Mars Time. (AM2000, eq. 22, modified): MTC = mod24 { 24 h × ( [(JDTT - 2451549.5) / 1.027491252] + 44796.0 - 0.00096 ) }
    double msd = ((jdtt - 2451549.5) / 1.027491252) + 44796.0 - 0.00096;
    double mtc = fmod(24 * msd, 24.0);

    //C-3. Determine Local Mean Solar Time.
    //The Local Mean Solar Time for a given planetographic longitude, Λ, in degrees west, is easily determined by offsetting from the mean solar time on the prime meridian.
    //LMST = MTC - Λ (24 h / 360°) = MTC - Λ (1 h / 15°)
    double lmst = [MarsTime canonicalValue24: (mtc - longitude / 15.0)];
    
    //C-4. Determine Local True Solar Time. (AM2000, eq. 23)
    //LTST = LMST + EOT (24 h / 360°) = LMST + EOT (1 h / 15°)
    double ltst = lmst + eot / 15.0;
    
    NSArray* times = [[NSArray alloc] initWithObjects:
                      [NSNumber numberWithDouble:jdut],
                      [NSNumber numberWithFloat:tt_utc_diff],
                      [NSNumber numberWithDouble:jdtt],
                      [NSNumber numberWithDouble:deltaJ2000],
                      [NSNumber numberWithDouble:marsMeanAnomaly],
                      [NSNumber numberWithDouble:angleFictiousMeanSun],
                      [NSNumber numberWithDouble:pbs],
                      [NSNumber numberWithDouble:v_M_diff],
                      [NSNumber numberWithDouble:ls],
                      [NSNumber numberWithDouble:eot],
                      [NSNumber numberWithDouble:msd],
                      [NSNumber numberWithDouble:mtc],
                      [NSNumber numberWithDouble:lmst],
                      [NSNumber numberWithDouble:ltst], nil];
    return times;
}

+ (double) getJulianDate: (NSDate*) date {
    return [date timeIntervalSince1970] / 86400.0 + 2440587.5;
}

@end
