//
//  HomeDesignViewController.m
//  HLJ-RZYP
//
//  Created by 万诚 on 2019/7/3.
//  Copyright © 2019 兴联云. All rights reserved.
//

#import "HomeDesignViewController.h"
#import "HomePageThirdCell.h"
#import "HLJSelectStyleMenu.h"

#import "HomeHeadSearchViewController.h"

#import "ProgListModel.h"
#import "NoDataView.h"

#import "DesignDetailViewController.h"
#import "SelectStyleMenu.h"

@interface HomeDesignViewController ()<UITableViewDelegate,UITableViewDataSource,HLJMenuDataSource,HLJMenuDelegate, MenuDataSource, MenuDelegate>
@property(nonatomic,strong) HLJSelectStyleMenu *menu;
@property(nonatomic,strong) SelectStyleMenu *myMenu;
@property(nonatomic,strong) NSArray *priceArr;
@property(nonatomic,strong) NSMutableArray *styleArr;
@property(nonatomic,strong) NSArray *areaArr;
@property(nonatomic,strong) NSArray *maxAreaArr;
@property(nonatomic,strong) NSArray *minAreaArr;
@property(nonatomic,strong) NSMutableArray *allConditionsDataArr;
@property(nonatomic,strong) NSString *style;
@property(nonatomic,strong) NSString *price;
@property(nonatomic,strong) NSString *maxArea;
@property(nonatomic,strong) NSString *minArea;
@property(nonatomic,strong) NoDataView *noDataView;

@property(nonatomic,strong)UITableView *mTableView;
@property(nonatomic,strong)NSMutableArray *dataArr;
@property(nonatomic,assign)NSInteger pageNo;

@property(nonatomic,strong) NSArray *sortArr;

@end

@implementation HomeDesignViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"设计";
    self.pageNo=1;
    self.price=@"0";
    self.style=@"";
    self.minArea=@"";
    self.maxArea=@"";
    self.dataArr=[[NSMutableArray alloc] init];
    self.styleArr=[[NSMutableArray alloc] init];
    [self addRightBtn:[UIImage imageNamed:@"searchicon"] Action:@selector(selectBtnClick)];
    [self MenuHttpRequest];
    [self creatTableView];
    [self httpRequestWithPage];
}
-(void)creatTableView{
    self.mTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, kScreenWidth, kScreenHeight-SafeAreaTopHeight-SafeAreaBottomHeight) style:UITableViewStylePlain];
    self.mTableView.delegate = self;
    self.mTableView.dataSource = self;
    self.mTableView.showsVerticalScrollIndicator=NO;
    // 将估算高度设置为0，防止刷新闪动
    self.mTableView.estimatedRowHeight = 0;
    self.mTableView.estimatedSectionHeaderHeight = 0;
    self.mTableView.estimatedSectionFooterHeight = 0;
    [self.mTableView registerClass:[HomePageThirdCell class] forCellReuseIdentifier:@"HomePageThirdCell"];
    self.mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    MJWeakSelf;
    self.mTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        weakSelf.pageNo = 1;
        [weakSelf httpRequestWithPage];
    }];
    self.mTableView.mj_footer = [MJRefreshAutoFooter footerWithRefreshingBlock:^{
        [weakSelf httpRequestWithPage];
    }];
    [self.view addSubview:self.mTableView];
}
-(void)MenuHttpRequest{
    [XLYHttpRequestClass MalFindMenuListWithFinshBlock:^(id response, NSString *errStr, BOOL noHasNetWork) {
        if (noHasNetWork) {
            [[UIApplication sharedApplication].keyWindow makeToast:@"无网络连接！"];
            return ;
        }
        if (response) {
            [self.styleArr addObject:@{@"id":@"0",@"name":@"全部"}];
            for (NSDictionary *dic in response[@"styleList"]) {
                [self.styleArr addObject:dic];
            }
            [self creatMenu];
            [self creatMyMenu];
        }else{
            [[UIApplication sharedApplication].keyWindow makeToast:errStr];
        }
    }];
}


- (NoDataView *)noDataView {
    if (!_noDataView) {
        _noDataView = [[NoDataView alloc] initWithFrame:self.view.bounds andImage:[UIImage imageNamed:@"sousuo"] andText:@"筛选无结果哦~"];
        [self.view addSubview:_noDataView];
    }
    return _noDataView;
}

-(void)httpRequestWithPage {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [XLYHttpRequestClass MallFindProgListWithPageNo:[NSString stringWithFormat:@"%ld",(long)self.pageNo] styleId:self.style sortType:self.price maxArea:self.maxArea minArea:self.minArea houseId:@"" AndFinshBlock:^(id response, NSString *errStr, BOOL noHasNetWork) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self.mTableView.mj_header endRefreshing];
        [self.mTableView.mj_footer endRefreshing];
        if (noHasNetWork) {
            [[UIApplication sharedApplication].keyWindow makeToast:@"无网络连接！"];
            return;
        }
        if (response) {
            if (self.pageNo == 1) {
                [self.dataArr removeAllObjects];
            }
            NSArray *dataArr = response[@"progList"];
            for (NSDictionary *dic in dataArr) {
                ProgListModel *model =[ProgListModel yy_modelWithDictionary:dic];
                [self.dataArr addObject:model];
            }
            if ([dataArr count] < 10) {
                [self.mTableView.mj_footer endRefreshingWithNoMoreData];
            }
            self.pageNo++;
            // 显示无数据页面
            if (self.dataArr.count == 0) {
                
                [self.noDataView show];
            } else {
                
                [self.noDataView hide];
            }
            [self.mTableView reloadData];
        }else{
            [[UIApplication sharedApplication].keyWindow makeToast:errStr];
        }
    }];
}

#pragma mark -- tableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100+kFit(210);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProgListModel *model=self.dataArr[indexPath.row];
    HomePageThirdCell *plan = [tableView dequeueReusableCellWithIdentifier:@"HomePageThirdCell" forIndexPath:indexPath];
    [plan showUIWithData:model isHomePage:YES];
    plan.selectionStyle = UITableViewCellSelectionStyleNone;
    return plan;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ProgListModel *model=self.dataArr[indexPath.row];
    // 跳转到设计详情
    DesignDetailViewController *designDetailVC = [[DesignDetailViewController alloc] init];
    designDetailVC.progId = model.ID;
    [self.navigationController pushViewController:designDetailVC animated:YES];
}

-(void)creatMenu{
    self.allConditionsDataArr =[[NSMutableArray alloc]init];
    self.priceArr =@[@"综合",@"价格升序",@"价格降序"];
    [self.allConditionsDataArr addObject:self.priceArr];
    
    [self.allConditionsDataArr addObject:self.styleArr];
    
    self.minAreaArr=@[@"全部",@"0",@"30",@"60",@"90",@"120",@"150",@"180"];
    self.maxAreaArr=@[@"全部",@"30",@"60",@"90",@"120",@"150",@"180",@"9999"];
    self.areaArr=@[@"全部",@"0~30m²",@"30~60m²",@"60~90m²",@"90~120m²",@"120~150m²",@"150~180m²",@"180m²以上"];
    [self.allConditionsDataArr addObject:self.areaArr];
    
    self.sortArr = @[@"默认排序", @"按发布时间排序", @"价格由高到低", @"价格由低到高"];
    [self.allConditionsDataArr addObject:self.sortArr];
    
    _menu = [[HLJSelectStyleMenu alloc] initWithOrigin:CGPointMake(0, 0) andHeight:44 LastIsImage:NO isShowTitles:NO];
    _menu.defaultTitlesArr=@[@"价格",@"风格",@"面积"];
    _menu.delegate = self;
    _menu.dataSource = self;
    [_menu selectDeafultIndexPath];
    [self.view addSubview:_menu];
}

- (void)creatMyMenu {
    self.myMenu = [[SelectStyleMenu alloc] init];
    self.myMenu.dataSource = self;
    self.myMenu.delegate = self;
    [self.view addSubview:self.myMenu];
}

- (NSInteger)numberOfColumnsInMenu1:(SelectStyleMenu *)menu {
    return 4;
}

- (NSString *)menu:(SelectStyleMenu *)menu defaultTitleInColumn:(NSInteger)column {
    if(column ==0){
        return @"价格";
    }else if(column ==1){
        return @"风格";
    }else if(column ==2){
        return @"面积";
    } else {
        return @"排序";
    }
}

- (NSString *)menu:(SelectStyleMenu *)menu defalutTitleImageNameInColumn:(NSInteger)column {
    if(column ==0){
        return @"jiantouS";
    }else if(column ==1){
        return nil;
    }else if(column ==2){
        return nil;
    } else {
        return nil;
    }
}

- (NSInteger)menu1:(SelectStyleMenu *)menu numberOfRowsInColumn:(NSInteger)column {
    if(column ==0){
        return self.priceArr.count;
    }else if(column ==1){
        return self.styleArr.count;
    }else if(column ==2){
        return self.areaArr.count;
    } else {
        return self.sortArr.count;
    }
}

- (NSString *)menu1:(SelectStyleMenu *)menu titleForRowAtIndexPath:(MenuIndexPath *)indexPath {
    if(indexPath.column==0){
        return self.priceArr[indexPath.row];
    }else if(indexPath.column==1){
        return self.styleArr[indexPath.row][@"name"];;
    }else if (indexPath.column == 2){
        return self.areaArr[indexPath.row];
    } else {
        return self.sortArr[indexPath.row];
    }
}

- (void)menu1:(SelectStyleMenu *)menu didSelectRowAtIndexPath:(MenuIndexPath *)indexPath {
    NSLog(@"indexPath : %ld列, %ld行", indexPath.column, indexPath.row);
}

- (void)menu:(SelectStyleMenu *)menu column:(NSInteger)column isSelect:(BOOL)isSelect {
    NSLog(@"column : %ld, isSelect : %ld", column, isSelect);
}

#pragma mark -- HLJSelectStyleMenuDelegatr
- (NSInteger)numberOfColumnsInMenu:(HLJSelectStyleMenu *)menu {
    return 3;
}

- (NSInteger)menu:(HLJSelectStyleMenu *)menu numberOfRowsInColumn:(NSInteger)column {
    if(column ==0){
        return self.priceArr.count;
    }else if(column ==1){
        return self.styleArr.count;
    }else{
        return self.areaArr.count;
    }
}
-(NSString *)menu:(HLJSelectStyleMenu *)menu titleForRowAtIndexPath:(HLJIndexPath *)indexPath{
    if(indexPath.column==0){
        return self.priceArr[indexPath.row];
    }else if(indexPath.column==1){
        return self.styleArr[indexPath.row][@"name"];;
    }else{
        return self.areaArr[indexPath.row];
    }
}

- (void)menu:(HLJSelectStyleMenu *)menu didSelectRowAtIndexPath:(HLJIndexPath *)indexPath {
    if (indexPath.item >= 0) {
    }else {
        if (indexPath.column==0) {//价格
            if (indexPath.row==0||indexPath.row==-1) {//表示全部
                self.price = @"";
            }else{
                self.price = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
            }
        }
        if (indexPath.column==1) {//风格
            if (indexPath.row==0||indexPath.row==-1) {//表示全部
                self.style = @"";
            }else{
                self.style = self.allConditionsDataArr[indexPath.column][indexPath.row][@"id"];
            }
        }
        if (indexPath.column==2) {//面积
            if (indexPath.row==0||indexPath.row==-1) {//表示全部
                self.maxArea=@"";
                self.minArea=@"";
            }else{
                self.minArea=self.minAreaArr[indexPath.row];
                self.maxArea=self.maxAreaArr[indexPath.row];
            }
        }
        self.pageNo=1;
        [self httpRequestWithPage];
    }
}
-(void)selectBtnClick{
    HomeHeadSearchViewController *search = [[HomeHeadSearchViewController alloc] init];
    search.searchType=@"方案";
    [self.navigationController pushViewController:search animated:YES];
}

@end

