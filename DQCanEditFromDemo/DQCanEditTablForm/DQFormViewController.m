//
//  DQFormViewController.m
//  DQTableFormView
//
//  Created by 邓琪 dengqi on 2016/12/24.
//  Copyright © 2016年 邓琪 dengqi. All rights reserved.
//

#import "DQFormViewController.h"
#import "DQFormHeader.h"
#import "DQTableViewCell.h"
#import "DQCanEditTableViewCell.h"
#import "DQTextField.h"
#import "DQCanEditCell.h"
#import "DQFormCollectionView.h"
#import "DQTextField.h"

static NSString *DQHeaderID = @"DQHeaderID";
static NSString *DQTableCellID = @"DQTableCellID";
static NSString *DQCanEditCellID = @"DQCanEditCellID";

@interface DQFormViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong) UIView *SeFooterView;

@property (nonatomic, strong) NSMutableArray *firstArr;

@property (nonatomic, strong) NSMutableArray *secondArr;

@property (nonatomic, assign) CGFloat firstHeigth;//第一个表格的高度

@property (nonatomic, assign) CGFloat secondHeigth;//第二个表格的高度

@property (nonatomic, assign) CGFloat ClickCellHeigth;//点击输入款的cell的高度
@property (nonatomic, assign) CGPoint saveTableContentOffset;//保存tableView的滚动的位置

@property (nonatomic, strong) UIButton *saveBtn;

@end

@implementation DQFormViewController
-(NSMutableArray *)firstArr{
    if (!_firstArr) {
        _firstArr = [NSMutableArray new];
    }
    return _firstArr;
}

-(NSMutableArray *)secondArr{
    if (!_secondArr) {
        _secondArr = [NSMutableArray new];
    }
    return _secondArr;
}

-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate  = self;
        _tableView.backgroundColor = HEX_COLOR(0xF2F2F2);
        [self.view addSubview:_tableView];
        _tableView.userInteractionEnabled = YES;
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(KeyboardHiddenFromTapGes:)];
        [_tableView addGestureRecognizer:ges];
    }
    
    return _tableView;
}

- (UIView *)SeFooterView{
    if (!_SeFooterView) {
        _SeFooterView = [UIView new];
        _SeFooterView.backgroundColor = [UIColor clearColor];
    }
    
    return _SeFooterView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self BasePropertyInitFunction];
    [self creationUIFunction];
    [self ResquestDateFunction];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoradFunction:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboradHiddenFunction:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GetCellFromNotifiFunction:) name:DQGetCellFromNotifition object:nil];
    
}
- (void)BasePropertyInitFunction{
    
    self.ClickCellHeigth = 0.0f;
    self.saveTableContentOffset = CGPointMake(0, 0);
    self.tableView.scrollsToTop = YES;
}
- (void)creationUIFunction{

    
    [self.tableView registerClass:[DQFormHeader class] forHeaderFooterViewReuseIdentifier:DQHeaderID];
    [self.tableView registerClass:[DQTableViewCell class] forCellReuseIdentifier:DQTableCellID];
    [self.tableView registerClass:[DQCanEditTableViewCell class] forCellReuseIdentifier:DQCanEditCellID];
    
    //保存按钮 这里用来获取改变的数据的 
    self.saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    self.saveBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.saveBtn setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
    [self.saveBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-10);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(35);
        make.width.mas_equalTo(100);
        
    }];
    self.saveBtn.backgroundColor = [UIColor lightGrayColor];
    self.saveBtn.layer.masksToBounds = YES;
    self.saveBtn.layer.cornerRadius = 5.0f;
    self.saveBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.saveBtn.layer.borderWidth = 1.0f;
    [self.saveBtn addTarget:self action:@selector(GetAllCanEditTextFildDataFunction:) forControlEvents:UIControlEventTouchUpInside];

}
- (void)ResquestDateFunction{
    
    NSArray *arr = @[@[@"颜色",@"粉色",@"绿色",@"黄色",@"紫色"],@[@"SM",@"0",@"10",@"2",@"02"],@[@"S",@"10",@"20",@"3",@"03"],@[@"M",@"20",@"0",@"4",@"04"],@[@"L",@"0",@"20",@"5",@"5"],@[@"XL",@"20",@"10",@"6",@"6"],@[@"XXL",@"10",@"10",@"7",@"7"],@[@"XXL",@"10",@"10",@"8",@"8"],@[@"XXL",@"10",@"10",@"9",@"9"],@[@"总计",@"60",@"70",@"10",@"10"]];//二维数组
    // 这里的数据源 必定是二维数组
    self.firstArr = [arr mutableCopy];
    self.secondArr = [arr mutableCopy];
    [self DQCalculateFromCellHigthFunction];
    
}
//计算表格的高度
- (void)DQCalculateFromCellHigthFunction{
    
    NSArray *arr = [self.firstArr firstObject];
    
    self.firstHeigth = 30+30*arr.count+0.5;
    
    self.secondHeigth = 30+30*arr.count+0.5;
}
//键盘上升的通知方法
- (void)keyBoradFunction:(NSNotification *)notifi{
    self.saveTableContentOffset = self.tableView.contentOffset;
    if (self.ClickCellHeigth>0) {
        NSDictionary *KeyboradDict = notifi.userInfo;
        CGFloat duration = [[KeyboradDict objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect keyboardRect;
        NSValue *keyboardObject = [KeyboradDict objectForKey:UIKeyboardFrameEndUserInfoKey];
        [keyboardObject getValue:&keyboardRect];
        CGFloat higth = keyboardRect.size.height + self.ClickCellHeigth + 10;
        
        if (higth>kScreenHeight+self.saveTableContentOffset.y) { ////获取表格 的点击的格子的最大的Y值 和屏幕的加tableView的滚动的Y值 进行比较
            CGRect tableFrame = self.tableView.frame;
            tableFrame.origin.y = tableFrame.origin.y - keyboardRect.size.height;
            [UIView animateWithDuration:duration animations:^{
                
                self.tableView.contentOffset = CGPointMake(0, keyboardRect.size.height);
            }];
            
        }
    }
    
    
}
//键盘下落的通知方法
- (void)keyboradHiddenFunction:(NSNotification *)notifi{
    
    NSDictionary *KeyboradDict = notifi.userInfo;
    CGFloat duration = [[KeyboradDict objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardRect;
    NSValue *keyboardObject = [KeyboradDict objectForKey:UIKeyboardFrameEndUserInfoKey];
    [keyboardObject getValue:&keyboardRect];
    
    [UIView animateWithDuration:duration animations:^{
        //self.tableView.frame = tableFrame;
        self.tableView.contentOffset = self.saveTableContentOffset;
    }];
    
    
}
//取消键盘
- (void)KeyboardHiddenFromTapGes:(UITapGestureRecognizer *)ges{
    
    [self.view endEditing:YES];
    
    
}
//通知 一开始点击哪个表格的通知
- (void)GetCellFromNotifiFunction:(NSNotification *)notifi{
    self.ClickCellHeigth = 0.0f;
    DQTextField *TeFd = (DQTextField *)notifi.object;
    
    if (![TeFd isKindOfClass:[DQTextField class]]) {
        return;
    }
    NSIndexPath *path  = TeFd.Cellpath;
    DQCanEditTableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    CGRect cellRect = cell.frame;
    CGRect rect = TeFd.DQCell.frame;
    //获取表格 的点击的格子的最大的Y值
    self.ClickCellHeigth = CGRectGetMaxY(rect) + CGRectGetMinY(cellRect);
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 1;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 3;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        DQTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQTableCellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (!cell) {
            cell = [[DQTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:DQTableCellID];
        }
        cell.DataArr = self.firstArr;
        return cell;
    }else{
        DQCanEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQCanEditCellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (!cell) {
            cell = [[DQCanEditTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DQCanEditCellID];
            
        }
        cell.CellPath = indexPath;
        cell.DataArr = self.secondArr;
        return cell;
    }
    
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    DQFormHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:DQHeaderID];
    if (section == 0) {
        [header setTitleText:@"健康数据"];
    }else{
        [header setTitleText:@"测量数据"];
        
    }
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        return self.firstHeigth;
    }else{
        
        return self.secondHeigth;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 40.0;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    
    return self.SeFooterView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 10.0;
}

#pragma mark 获取所有的TextFild的数据的方法

- (void)GetAllCanEditTextFildDataFunction:(id)sender{
    [self.view endEditing:YES];
    NSMutableArray *muArr = [NSMutableArray new];
    //这里 我只取一组cell的数据
    DQCanEditTableViewCell *cell  = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    muArr = cell.DataArr;
    
    for (NSArray *obj in muArr) {
        for (NSString *str in obj) {
            NSLog(@"%@",str);
        }
    }
    
    
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
@end
