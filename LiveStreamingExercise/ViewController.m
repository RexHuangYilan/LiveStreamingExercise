//
//  ViewController.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/15.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"mainTableList" ofType:@"plist"];
    NSArray *setting = [NSArray arrayWithContentsOfFile:filePath];
    self.dataSource = setting;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        UIViewController *target = segue.destinationViewController;
        target.title = cell.textLabel.text;
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *itemObj = self.dataSource[indexPath.row];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:itemObj[@"identifier"]];

    return cell;
}


@end
