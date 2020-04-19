//
//  SelectStyleMenu.m
//  HLJ-RZYP
//
//  Created by wan on 2020/4/18.
//  Copyright © 2020 兴联云. All rights reserved.
//

#import "SelectStyleMenu.h"

#define screenWidth     [[UIScreen mainScreen] bounds].size.width
#define screenHeight    [[UIScreen mainScreen] bounds].size.height

static CGFloat const menuHeight = 44.f;
static CGFloat const tableViewRowHeight = 44.f;
static CGFloat const tableViewHeight = 300.f;
static CGFloat const animateTime = 0.2f;

@implementation MenuIndexPath

- (instancetype)initWithColumn:(NSInteger)column row:(NSInteger)row {
    if (self = [super init]) {
        _column = column;
        _row = row;
    }
    return self;
}

+ (instancetype)indexPathWithColumn:(NSInteger)column row:(NSInteger)row {
    return [[self alloc] initWithColumn:column row:row];
}

@end


@interface SelectStyleMenu () <UITableViewDelegate, UITableViewDataSource> {
    struct {
        unsigned int numberOfColumnsInMenu :1;
        unsigned int defaultTitleInColumn :1;
        unsigned int defalutTitleImageNameInColumn :1;
        unsigned int numberOfRowsInColumn :1;
        unsigned int titleForRowsAtIndexPath :1;
    }_dataSourceFlag;
}

@property (nonatomic, strong)UITableView *menuTableView;  //菜单列表
@property (nonatomic, strong)UIView *backGroundView;

@property (nonatomic, assign)BOOL isShow;
@property (nonatomic, assign)NSInteger menuColumn;  // 菜单列数
@property (nonatomic, assign)NSInteger currentMenuIndex;  //当前菜单index
@property (nonatomic, strong)NSMutableArray *currentSelectedRows;  // 当前选中的行

// 图层数组
@property (nonatomic, strong)NSMutableArray *titlesArr;
@property (nonatomic, strong)NSMutableArray *indicatorsArr;

@end

@implementation SelectStyleMenu

#pragma mark - 初始化
- (id)init {
    return [self initSelectStyleMenu];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initSelectStyleMenu];
}

- (id)initWithCoder:(NSCoder *)coder {
    return [self initSelectStyleMenu];
}

- (instancetype)initSelectStyleMenu {
    self = [super initWithFrame:CGRectMake(0.f, 44.f, screenWidth, menuHeight)];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuTapped:)];
        [self addGestureRecognizer:tap];
        
        // 菜单列表
        self.menuTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.f, 44.f + menuHeight, screenWidth, 0.f) style:UITableViewStylePlain];
        self.menuTableView.delegate = self;
        self.menuTableView.dataSource = self;
        self.menuTableView.rowHeight = tableViewRowHeight;
        
        // 背景视图
        self.backGroundView = [[UIView alloc] init];
        self.backGroundView.frame = CGRectMake(0.f, 44.f + menuHeight, screenWidth, screenHeight - 44.f - menuHeight);
        self.backGroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        self.backGroundView.opaque = NO;
        UITapGestureRecognizer *backTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backTapped:)];
        [self.backGroundView addGestureRecognizer:backTap];
    }
    return self;
}

#pragma mark - 懒加载菜单样式参数
- (NSInteger)fontSize {
    if (!_fontSize) {
        _fontSize = 14;
    }
    return _fontSize;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    }
    return _textColor;
}

- (UIColor *)selectedTextColor {
    if (!_selectedTextColor) {
        _selectedTextColor = [UIColor colorWithRed:85/255.0 green:197/255.0 blue:85/255.0 alpha:1];
    }
    return _selectedTextColor;
}

- (UIColor *)separatorColor {
    if (!_separatorColor) {
        _separatorColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }
    return _separatorColor;
}

- (UIColor *)indicatorColor {
    if (!_indicatorColor) {
        _indicatorColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }
    return _indicatorColor;
}

#pragma mark - 设置dataSource
- (void)setDataSource:(id<MenuDataSource>)dataSource {
    if (_dataSource == dataSource) {
        return;
    }
    _dataSource = dataSource;
    
    //判断是否响应了某方法
    _dataSourceFlag.numberOfColumnsInMenu = [_dataSource respondsToSelector:@selector(numberOfColumnsInMenu1:)];
    _dataSourceFlag.defaultTitleInColumn = [_dataSource respondsToSelector:@selector(menu:defaultTitleInColumn:)];
    _dataSourceFlag.defalutTitleImageNameInColumn = [_dataSource respondsToSelector:@selector(menu:defalutTitleImageNameInColumn:)];
    _dataSourceFlag.numberOfRowsInColumn = [_dataSource respondsToSelector:@selector(menu1:numberOfRowsInColumn:)];
    _dataSourceFlag.titleForRowsAtIndexPath = [_dataSource respondsToSelector:@selector(menu1:titleForRowAtIndexPath:)];
    
    if (_dataSourceFlag.numberOfColumnsInMenu) {
        self.menuColumn = [_dataSource numberOfColumnsInMenu1:self];
    } else {
        NSAssert(0 == 1, @"菜单数据源不能为空");
    }
    
    // 构建选中行数组，默认选中第一个
    self.currentSelectedRows = [NSMutableArray array];
    for (int i = 0;i < self.menuColumn;i++) {
        [self.currentSelectedRows addObject:@(0)];
    }
    
    // 画出菜单
    self.titlesArr = [NSMutableArray array];
    self.indicatorsArr = [NSMutableArray array];
    
    // 画出来的CATextLayer会按position边距居中显示，所以直接按两倍分割，每一个title就会在自己的两个间距中间居中显示
    CGFloat textLayerSpace = self.frame.size.width / (self.menuColumn * 2);
    CGFloat lineSpace = self.frame.size.width / self.menuColumn;
    for (int i = 0; i < self.menuColumn; i++) {
        // titleLayer 标题
        NSString *title = _dataSourceFlag.defaultTitleInColumn ? [self.dataSource menu:self defaultTitleInColumn:i] : @"";
        CGSize titleSize = [self calculateTitleSizeWithString:title];
        CGPoint titlePosition = CGPointMake((i * 2 + 1) * textLayerSpace, menuHeight / 2);
        CATextLayer *textLayer = [self createTitleLayerWithString:title titleSize:titleSize position:titlePosition];
        [self.layer addSublayer:textLayer];
        [self.titlesArr addObject:textLayer];
        
        // indicatorLayer 指示器
        CGPoint indicatorPosition = CGPointMake(textLayer.position.x + titleSize.width / 2 + 8.f, menuHeight / 2);
        CALayer *indicatorLayer = [self createIndicatorWithPosition:indicatorPosition column:i];
        [self.layer addSublayer:indicatorLayer];
        [self.indicatorsArr addObject:indicatorLayer];
        
        // separatorLayer 分隔线
        if (i != self.menuColumn - 1) {
            CGPoint separatorPosition = CGPointMake((i + 1) * lineSpace, menuHeight / 2);
            CAShapeLayer *separatorLayer = [self createSeparatorWithPostion:separatorPosition];
            [self.layer addSublayer:separatorLayer];
        }
    }
}

#pragma mark - 绘图
// 标题
- (CATextLayer *)createTitleLayerWithString:(NSString *)string titleSize:(CGSize)size position:(CGPoint)position {
    
    CGFloat sizeWidth = (size.width < (self.frame.size.width / self.menuColumn - 25)) ? size.width : self.frame.size.width / self.menuColumn - 25;
    CATextLayer *layer = [[CATextLayer alloc] init];
    layer.bounds = CGRectMake(0.f, 0.f, sizeWidth, size.height);
    layer.position = position;
    layer.string = string;
    layer.fontSize = self.fontSize;
    layer.alignmentMode = kCAAlignmentCenter;
    layer.truncationMode = kCATruncationEnd;
    layer.foregroundColor = self.textColor.CGColor;
//    layer.backgroundColor = [UIColor redColor].CGColor;
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    return layer;
}
//计算String的宽度
- (CGSize)calculateTitleSizeWithString:(NSString *)string {
    NSDictionary *dic = @{NSFontAttributeName: [UIFont systemFontOfSize:self.fontSize]};
    CGSize size = [string boundingRectWithSize:CGSizeMake(0, menuHeight) options:NSStringDrawingUsesLineFragmentOrigin |
                   NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
    return CGSizeMake(size.width, size.height);
}
// 指示器
- (CALayer *)createIndicatorWithPosition:(CGPoint)position column:(NSInteger)column {
    
    if (_dataSourceFlag.defalutTitleImageNameInColumn && [self.dataSource menu:self defalutTitleImageNameInColumn:column]) {
        // 图片指示器
        NSString *imageName = [self.dataSource menu:self defalutTitleImageNameInColumn:column];
        CALayer *imagelayer = [CALayer layer];
        //设置layer的属性
        imagelayer.bounds=CGRectMake(0, 0, 12, 12);
        imagelayer.position=position;
        //设置需要显示的图片
        imagelayer.contents=(id)[UIImage imageNamed:imageName].CGImage;
        return imagelayer;
    } else {
        // 默认箭头指示器
        CAShapeLayer *layer = [CAShapeLayer new];
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0.f, 0.f)];
        [path addLineToPoint:CGPointMake(5.f, 5.f)];
        [path addLineToPoint:CGPointMake(10.f, 0.f)];
        [path closePath];
        layer.path = path.CGPath;
        layer.fillColor = self.indicatorColor.CGColor;
        
        // 设置buounds和position位置
        CGPathRef bound = CGPathCreateCopyByStrokingPath(layer.path, nil, layer.lineWidth, kCGLineCapButt, kCGLineJoinMiter, layer.miterLimit);
        layer.bounds = CGPathGetBoundingBox(bound);
        CGPathRelease(bound);
        layer.position = position;
        
        return layer;
    }
}
// 分隔线
- (CAShapeLayer *)createSeparatorWithPostion:(CGPoint)position {
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];

    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(position.x, menuHeight / 4)];
    [path addLineToPoint:CGPointMake(position.x, menuHeight / 4 * 3)];
    layer.path = path.CGPath;
    layer.lineWidth = 1;
    layer.strokeColor = self.separatorColor.CGColor;
    return layer;
}

#pragma mark - 动画
// 标题动画
- (void)animateTitle:(CATextLayer *)title indicator:(CALayer *)indicator column:(NSInteger)column show:(BOOL)show complete:(void(^)(void))complete {
    // 调整title位置
    CGSize size = [self calculateTitleSizeWithString:title.string];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / self.menuColumn - 25.f)) ? size.width : self.frame.size.width / self.menuColumn - 25.f;
    title.bounds = CGRectMake(0.f, 0.f, sizeWidth, size.height);
    // 修改标题颜色
    if (show) {
        title.foregroundColor = self.selectedTextColor.CGColor;
    } else {
        title.foregroundColor = self.textColor.CGColor;
    }
    // 调整指示器位置
    CGPoint indicatorPosition = CGPointMake(title.position.x + sizeWidth / 2 + 8.f, menuHeight / 2);
    indicator.position = indicatorPosition;
    if ([indicator isMemberOfClass:[CAShapeLayer class]]) {
        // 默认箭头指示器
        // 添加动画
        [CATransaction begin];
        [CATransaction setAnimationDuration:animateTime];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.4 :0.0 :0.2 :1.0]];
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
        animation.values = show ? @[@0, @(M_PI)] : @[@(M_PI), @0];
        if (!animation.removedOnCompletion) {
            [indicator addAnimation:animation forKey:animation.keyPath];
        } else {
            [indicator addAnimation:animation forKey:animation.keyPath];
            [indicator setValue:animation.values.lastObject forKeyPath:animation.keyPath];
        }
        [CATransaction commit];
        
        CAShapeLayer *newIndicator = (CAShapeLayer *)indicator;
        if (show) {
            newIndicator.fillColor = self.selectedTextColor.CGColor;
        } else {
            newIndicator.fillColor = self.indicatorColor.CGColor;
        }
    } else {
        // 图片指示器
        NSString *imageName = [self.dataSource menu:self defalutTitleImageNameInColumn:column];
        NSLog(@"imageNmae ： %@", imageName);
        if (show) {
            indicator.contents = (id)[UIImage imageNamed:@"jiantouSe"].CGImage;
        } else {
            indicator.contents = (id)[UIImage imageNamed:imageName].CGImage;
        }
    }
    if (complete) {
        complete();
    }
}
// 表视图动画
- (void)animateTableView:(UITableView *)tableView show:(BOOL)show complete:(void(^)(void))complete {
    
    if (show) {
        // eg:同一视图多次添加到父视图其实也只会添加一次
        // 添加背景视图
        [self.superview addSubview:self.backGroundView];
        
        // 添加菜单tableview
        tableView.frame = CGRectMake(0.f, 44.f + menuHeight, screenWidth, 0.f);
        [self.superview addSubview:tableView];
        
        // 计算高度
        CGFloat num = [tableView numberOfRowsInSection:0];
        CGFloat height = num * tableViewRowHeight > tableViewHeight ? tableViewHeight : num * tableViewRowHeight;
        
        [UIView animateWithDuration:animateTime animations:^{
            self.backGroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
            tableView.frame = CGRectMake(0.f, 44.f + menuHeight, screenWidth, height);
        }];
    } else {
        // 调整高度后移除
        [UIView animateWithDuration:animateTime animations:^{
            self.backGroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
            tableView.frame = CGRectMake(0.f, 44.f + menuHeight, screenWidth, 0.f);
        } completion:^(BOOL finished) {
            [self.backGroundView removeFromSuperview];
            [tableView removeFromSuperview];
        }];
    }
    if (complete) {
        complete();
    }
}
// 整个菜单动画
- (void)animateMenu:(CATextLayer *)title indicator:(CALayer *)indicator view:(UITableView *)tableView column:(NSInteger)column show:(BOOL)show complete:(void(^)(void))complete {
    [self animateTitle:title indicator:indicator column:column show:show complete:^{
        [self animateTableView:tableView show:show complete:^{
            if (complete) {
                complete();
            }
        }];
    }];
}

#pragma mark - UITableView的dataSource和delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_dataSourceFlag.numberOfRowsInColumn) {
        return [self.dataSource menu1:self numberOfRowsInColumn:self.currentMenuIndex];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"menuTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        // 设置cell样式
        cell.textLabel.textColor = self.textColor;
        cell.tintColor = self.selectedTextColor;
        cell.textLabel.font = [UIFont systemFontOfSize:self.fontSize];
    }
    if (_dataSourceFlag.titleForRowsAtIndexPath) {
        cell.textLabel.text = [_dataSource menu1:self titleForRowAtIndexPath:[MenuIndexPath indexPathWithColumn:self.currentMenuIndex row:indexPath.row]];
    }

    // 设置选中样式
    if (indexPath.row == [self.currentSelectedRows[self.currentMenuIndex] integerValue]) {
        cell.textLabel.textColor = self.selectedTextColor;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.textLabel.textColor = self.textColor;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 设置选中行，代理回调
    [self setMenuWithSelectedRow:indexPath.row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(menu1:didSelectRowAtIndexPath:)]) {
        [self.delegate menu1:self didSelectRowAtIndexPath:[MenuIndexPath indexPathWithColumn:self.currentMenuIndex row:indexPath.row]];
    }
}

#pragma mark - 方法实现
- (void)menuTapped:(UITapGestureRecognizer *)gesture {
    // 获取触摸的点，转换为index
    CGPoint touchPoint = [gesture locationInView:self];
    NSInteger touchIndex = touchPoint.x / (self.frame.size.width / self.menuColumn);
    
#warning 优化，记录上一次的选中，只收回上次选中即可
    // 将当前点击的column之外的column给收回
    for (int i = 0; i < self.menuColumn; i++) {
        if (i != touchIndex) {
            [self animateTitle:self.titlesArr[i] indicator:self.indicatorsArr[i] column:i show:NO complete:nil];
        }
    }
    
    if (touchIndex == self.currentMenuIndex && self.isShow) {
        
        // 图片指示器
        if (_dataSourceFlag.defalutTitleImageNameInColumn && [self.dataSource menu:self defalutTitleImageNameInColumn:self.currentMenuIndex]) {
            // 收回标题
            [self animateTitle:self.titlesArr[self.currentMenuIndex] indicator:self.indicatorsArr[self.currentMenuIndex] column:self.currentMenuIndex show:NO complete:^{
                self.isShow = NO;
            }];
            // 代理回调
            if (self.delegate && [self.delegate respondsToSelector:@selector(menu:column:isSelect:)]) {
                [self.delegate menu:self column:touchIndex isSelect:NO];
            }
            return;
        }
        
        // 收回menu
        [self animateMenu:self.titlesArr[self.currentMenuIndex] indicator:self.indicatorsArr[self.currentMenuIndex]  view:self.menuTableView column:self.currentMenuIndex show:NO complete:^{
            self.isShow = NO;
        }];
    } else {
        // 弹出menu
        self.currentMenuIndex = touchIndex;
        [self.menuTableView reloadData];
        
        // 图片指示器
        if (_dataSourceFlag.defalutTitleImageNameInColumn && [self.dataSource menu:self defalutTitleImageNameInColumn:self.currentMenuIndex]) {
            // 先收回menu
            [self animateMenu:self.titlesArr[self.currentMenuIndex] indicator:self.indicatorsArr[self.currentMenuIndex] view:self.menuTableView column:self.currentMenuIndex show:NO complete:^{
                self.isShow = NO;
            }];
            // 再选中标题
            [self animateTitle:self.titlesArr[self.currentMenuIndex] indicator:self.indicatorsArr[self.currentMenuIndex] column:self.currentMenuIndex show:YES complete:^{
                self.isShow = YES;
            }];
            // 代理回调
            if (self.delegate && [self.delegate respondsToSelector:@selector(menu:column:isSelect:)]) {
                [self.delegate menu:self column:touchIndex isSelect:YES];
            }
            return;
        }
        
        [self animateMenu:self.titlesArr[self.currentMenuIndex] indicator:self.indicatorsArr[self.currentMenuIndex] view:self.menuTableView column:self.currentMenuIndex show:YES complete:^{
            self.isShow = YES;
        }];
    }
}

- (void)backTapped:(UITapGestureRecognizer *)gesture {
    // 收回menu
    [self animateMenu:self.titlesArr[self.currentMenuIndex] indicator:self.indicatorsArr[self.currentMenuIndex] view:self.menuTableView column:self.currentMenuIndex show:NO complete:^{
        self.isShow = NO;
    }];
}

- (void)setMenuWithSelectedRow:(NSInteger)row {
    // 设置选中行
    self.currentSelectedRows[self.currentMenuIndex] = @(row);
    
    CATextLayer *title = (CATextLayer *)self.titlesArr[self.currentMenuIndex];
    // 修改标题
//    title.string = [self.dataSource menu1:self titleForRowAtIndexPath:[MenuIndexPath indexPathWithColumn:self.currentMenuIndex row:row]];
    // 收回menu
    [self animateMenu:title indicator:self.indicatorsArr[self.currentMenuIndex] view:self.menuTableView column:self.currentMenuIndex show:NO complete:^{
        self.isShow = NO;
    }];
}


@end
