//
//  Mars_ImagesTests.m
//  Mars-ImagesTests
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "Mars_ImagesTests.h"
#import "MarsImageNotebook.h"
#import "MarsTime.h"

#define SPIRIT_WEST_LONGITUDE 184.702
#define SPIRIT_LANDING_SECONDS_SINCE_1970_EPOCH 1073137591

@implementation Mars_ImagesTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

//- (void)testExample
//{
//    STFail(@"Unit tests are not implemented yet in Mars-ImagesTests");
//}

- (void)testMarsTime {
    NSDate* spiritLanding = [[NSDate alloc] initWithTimeIntervalSince1970: SPIRIT_LANDING_SECONDS_SINCE_1970_EPOCH];
    double spiritJulian = [MarsTime getJulianDate:spiritLanding];
    STAssertEqualsWithAccuracy(2453008.07397, spiritJulian, 0.00001, @"Spirit landing julian date has invalid value.");
    
    NSArray* marsTimes = [MarsTime getMarsTimes:spiritLanding longitude:SPIRIT_WEST_LONGITUDE];
    STAssertNotNil(marsTimes, @"MarsTimes should not be nil");
    STAssertEquals(14u, [marsTimes count], @"MarsTimes should have 13 elements");
    
    double jdut = [[marsTimes objectAtIndex:0] doubleValue];
    STAssertEqualsWithAccuracy(2453008.07397, jdut, 0.00001, @"Spirit landing jdut invalid");
    
    float tt_utc_diff = [[marsTimes objectAtIndex:1] floatValue];
    STAssertEqualsWithAccuracy(64.184f, tt_utc_diff, 0.001f, @"Spirit landing TT - UTC invalid");
    
    double jdtt = [[marsTimes objectAtIndex:2] doubleValue];
    STAssertEqualsWithAccuracy(2453008.07471, jdtt, 0.00001, @"Spirit landing jdtt invalid");
    
    double deltaJ2000 = [[marsTimes objectAtIndex:3] doubleValue];
    STAssertEqualsWithAccuracy(1463.07471, deltaJ2000, 0.00001, @"Spirit landing deltaJ2000 invalid");
    
    double marsMeanAnomaly = [[marsTimes objectAtIndex:4] doubleValue];
    STAssertEqualsWithAccuracy(786.06851, marsMeanAnomaly, 0.00001, @"Spirit mars mean anomaly invalid");
    
    double angleFictiousMeanSun = [[marsTimes objectAtIndex:5] doubleValue];
    STAssertEqualsWithAccuracy(1037.09363, angleFictiousMeanSun, 0.00001, @"Spirit angleFicitiousMeanSun invalid");
    
    double pbs = [[marsTimes objectAtIndex: 6] doubleValue];
    STAssertEqualsWithAccuracy(0.01614, pbs, 0.00001, @"Spirit pbs invalid");
    
    double v_M_diff = [[marsTimes objectAtIndex: 7] doubleValue];
    STAssertEqualsWithAccuracy(10.22959, v_M_diff, 0.00001, @"Spirit v - M invalid");
    
    double ls = [[marsTimes objectAtIndex: 8] doubleValue];
    STAssertEqualsWithAccuracy(1047.32322, ls, 0.00001, @"Spirit ls invalid");
    
    double eot = [[marsTimes objectAtIndex: 9] doubleValue];
    STAssertEqualsWithAccuracy(-12.77557, eot, 0.00001, @"Spirit EOT invalid");
}

- (void) testGetAnaglyphTitle {
    
    [MarsNotebook instance].currentMission = @"Opportunity";
    
    NSString* hazcamAnaglyphTitle = [[MarsNotebook instance] getAnaglyphTitle:@"Sol 3405 1R430479366EFFC7DGP1311R0M1"];
    STAssertEqualObjects(hazcamAnaglyphTitle, @"Sol 3405 1R430479366EFFC7DGP1311L0M1", @"Right rear Hazcam anaglyph error");

    [MarsNotebook instance].currentMission = @"Curiosity";
    
    NSString* navcamAnaglyphTitle = [[MarsNotebook instance] getAnaglyphTitle:@"Sol 0373 430609363 NRB_430609363EDR_F0140000NCAM00320M_"];
    STAssertEqualObjects(navcamAnaglyphTitle, @"Sol 0373 430609363 NLB_430609363EDR_F0140000NCAM00320M_", @"Right rear Hazcam anaglyph error");
}

@end
