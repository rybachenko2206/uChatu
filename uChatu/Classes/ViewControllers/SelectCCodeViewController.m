//
//  SelectCCodeViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/21/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"
#import "TVSection.h"
#import "CountryCodeCell.h"

#import "SelectCCodeViewController.h"

@interface SelectCCodeViewController () <UITableViewDataSource, UITableViewDelegate> {
    UIBarButtonItem *backBtnItem;
    CountryCodeCell *selectedCell;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *sectionsArray;

@end

@implementation SelectCCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Choose Country";
    
    backBtnItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_back_button"]
                                                   style:UIBarButtonItemStyleBordered
                                                  target:self
                                                  action:@selector(backButtonTapped)];
    backBtnItem.tintColor = [UIColor blackColor];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.sectionsArray = [NSMutableArray new];
    
    NSArray *countries = [self getCountriesFromPlist];
    [self fillSectionsArrayWithCountries:countries];
}

- (UINavigationItem *)navigationItem {
    UINavigationItem *navItem = [super navigationItem];
    navItem.leftBarButtonItem = backBtnItem;
    return navItem;
}


#pragma mark - Action methods

- (void)backButtonTapped {
    if ([self.delegate respondsToSelector:@selector(countrySelected:)]) {
        [self.delegate countrySelected:selectedCell.country];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Delegated methods:

#pragma mark - —UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    TVSection *currSection = self.sectionsArray[section];
    return currSection.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CountryCodeCell";
    CountryCodeCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                            forIndexPath:indexPath];
    TVSection *section = self.sectionsArray[indexPath.section];
    cell.country = section.items[indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.sectionsArray objectAtIndex:section] sectionName];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *sectionNames = [[NSMutableArray alloc] initWithCapacity:_sectionsArray.count];
    for (TVSection *section in _sectionsArray) {
        [sectionNames addObject:section.sectionName];
    }
    
    return sectionNames;
}


#pragma mark - —UITableViewDelegate

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 0.1;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 0.1;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [selectedCell setSelected:NO];
    selectedCell = (CountryCodeCell *)[tableView cellForRowAtIndexPath:indexPath];
    [selectedCell setSelected:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Private methods

- (NSArray *)getCountriesFromPlist {
    NSString *pathToPlist = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"CountryCodes.plist"];
    NSDictionary *pList = [NSDictionary dictionaryWithContentsOfFile:pathToPlist];
    
    NSMutableArray *countries = [[NSMutableArray alloc] initWithCapacity:pList.count];
    for (NSString *key in pList) {
        NSNumber *code = [pList valueForKey:key];
        NSDictionary *dict = @{kCountryName : key,
                               kCountryCode : code};
        [countries addObject:dict];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kCountryName ascending:YES];
    countries = (NSMutableArray *)[countries sortedArrayUsingDescriptors:@[sortDescriptor]];
    return countries;
}

- (void)fillSectionsArrayWithCountries:(NSArray *)countries {
    NSString *currLetter = nil;
    for (NSDictionary *dict in countries) {
        NSString *firstLetter = [dict[kCountryName] substringToIndex:1];
        
        TVSection *section = nil;
        
        if (![currLetter isEqualToString:firstLetter]) {
            section = [TVSection new];
            section.sectionName = firstLetter;
            section.items = [NSMutableArray array];
            currLetter = firstLetter;
            [self.sectionsArray addObject:section];
        } else {
            section = [self.sectionsArray lastObject];
        }
        [section.items addObject:dict];
    }
}


@end
