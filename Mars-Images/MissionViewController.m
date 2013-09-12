//
//  MissionViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "MissionViewController.h"
#import "MarsNotebook.h"

@interface MissionViewController ()

@end

@implementation MissionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void) viewDidLoad {
    //set the initial selection of the picker row for the currently selected mission
    NSArray *missionNames = [MarsNotebook instance].missionNames;
    for (int i = 0; i < [missionNames count]; i++) {
        if ([[missionNames objectAtIndex:i] isEqualToString:[MarsNotebook instance].currentMission]) {
            [self.pickerView selectRow:i inComponent:0 animated:YES];
            break;
        }
    }
}

#pragma mark - device rotation support

- (NSUInteger) supportedInterfaceOrientationsForWindow {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    // Handle the selection
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSArray* missionNames = [MarsNotebook instance].missionNames;
    NSString *mission = [missionNames objectAtIndex:row];
    
    if (!([mission isEqualToString:[MarsNotebook instance].currentMission])) {
        
        /* update current mission for app internally */
        [MarsNotebook instance].currentMission = mission;
        
        /* update current mission in app settings (informs listeners to refresh UI) */
        [prefs setObject:mission forKey:@"mission"];
        [prefs synchronize];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [MarsNotebook instance].missionNames.count;
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *missionNames = [MarsNotebook instance].missionNames;
    return [missionNames objectAtIndex:row];
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 300; //sectionWidth
}

- (void)viewDidUnload {
    [self setPickerView:nil];
    [super viewDidUnload];
}
@end
