//
//  SelectStyleMenu.h
//  HLJ-RZYP
//
//  Created by wan on 2020/4/18.
//  Copyright © 2020 兴联云. All rights reserved.
//

#import <UIKit/UIKit.h>

// UIKit中写了一个NSIndexPath的分类，这里为了简化方便直接创建自定义的indexPath
@interface MenuIndexPath: NSObject

@property(nonatomic, assign) NSInteger row;//行
@property(nonatomic, assign) NSInteger column;//列

+ (instancetype)indexPathWithColumn:(NSInteger)column row:(NSInteger)row;

@end


@class SelectStyleMenu;

#pragma mark - datasource数据源
@protocol MenuDataSource <NSObject>

@required
// 有多少个column
- (NSInteger)numberOfColumnsInMenu1:(SelectStyleMenu *)menu;
// 每个column的默认标题
- (NSString *)menu:(SelectStyleMenu *)menu defaultTitleInColumn:(NSInteger)column;
// 每个column标题的imageName,选中图片命名规则:xxx_select,如果为空则使用默认箭头指示器
- (NSString *)menu:(SelectStyleMenu *)menu defalutTitleImageNameInColumn:(NSInteger)column;
// 每个column有多少行
- (NSInteger)menu1:(SelectStyleMenu *)menu numberOfRowsInColumn:(NSInteger)column;
// 每个column中每行的title
- (NSString *)menu1:(SelectStyleMenu *)menu titleForRowAtIndexPath:(MenuIndexPath *)indexPath;

//@optional


@end

#pragma mark - delegate代理
@protocol MenuDelegate <NSObject>

// 某列是否选中
- (void)menu:(SelectStyleMenu *)menu column:(NSInteger)column isSelect:(BOOL)isSelect;
// 选中的列和行
- (void)menu1:(SelectStyleMenu *)menu didSelectRowAtIndexPath:(MenuIndexPath *)indexPath;

@end

@interface SelectStyleMenu : UIView

@property (nonatomic, weak)id<MenuDelegate> delegate;
@property (nonatomic, weak)id<MenuDataSource> dataSource;

/*
 菜单样式
 */
@property (nonatomic, assign)NSInteger fontSize;    // 字体大小，默认14
@property (nonatomic, strong)UIColor *textColor;
@property (nonatomic, strong)UIColor *selectedTextColor;
@property (nonatomic, strong)UIColor *indicatorColor;
@property (nonatomic, strong)UIColor *separatorColor;

@end
