//
//  HHSingleLineChartView.m
//  GlobalTimes
//
//  Created by apple on 16/9/10.
//  Copyright © 2016年 Hannah. All rights reserved.
//

#import "HHSingleLineChartView.h"




#define HHViewSelfHeight self.bounds.size.height
#define HHViewSelfWidth self.bounds.size.width
#define HHLeftMargin kRelativeWidth(50)
#define HHTopMargin kRelativeHeight(25)
#define HHRightMargin kRelativeWidth(20)
#define HHBottomMargin kRelativeHeight(20)
#define HHPointleftRightMargin kRelativeWidth(20)
#define HHLineChartBtnTag 10000000


static int count;   // 点个数，x轴格子数
static int yCount;  // y轴格子数
static CGFloat everyX;  // x轴每个格子宽度
static CGFloat everyY;  // y轴每个格子高度
static long long maxY;    // 最大的y值
static CGFloat allH;    // 整个图表高度
static CGFloat allW;    // 整个图表宽度


@interface HHSingleLineChartView ()
{

    UIBezierPath *_path;
    CGFloat _yMaxValue;
    CGFloat _yAveValue;
    int _maxIndex;
    int _firstNoneZeroIndex;
}


@property (nonatomic, copy) NSString *yMaxStr;
@property (nonatomic, copy) NSString *yMidStr;

@property (nonatomic, copy) NSArray *xDatas;
@property (nonatomic, copy) NSArray *yDatas;
@property (nonatomic, copy) NSArray *popImgs;

@property (nonatomic, strong) NSMutableArray *xLableArr;
@property (nonatomic, strong) NSMutableArray *pointArr;
@property (nonatomic, strong) NSMutableArray *btnArr;
@property (nonatomic, strong) NSMutableArray *pointBtnArr;
@property (nonatomic, strong) UIView *currentPoint;
@property (nonatomic, strong) UILabel *popLabel;

@property (nonatomic, strong) UIView *clickBg;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, assign) CGPoint xStartPoint;
@property (nonatomic, assign) CGPoint xendPoint;
@property (nonatomic, assign) BOOL needGradient;



@end

@implementation HHSingleLineChartView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _popImgs = @[@"nav-kuang",@"nav-up"];
        
    }
    return self;
}

#pragma mark - 计算
- (void)doWithCalculate{
    if (!self.xValues || !self.xValues.count || !self.yValues || !self.yValues.count) {
        return;
    }
    // 移除多余的值，计算点个数
    if (self.xValues.count > self.yValues.count) {
        NSMutableArray * xArr = [self.xValues mutableCopy];
        for (int i = 0; i < self.xValues.count - self.yValues.count; i++){
            [xArr removeLastObject];
        }
        self.xValues = [xArr mutableCopy];
    }else if (self.xValues.count < self.yValues.count){
        NSMutableArray * yArr = [self.yValues mutableCopy];
        for (int i = 0; i < self.yValues.count - self.xValues.count; i++){
            [yArr removeLastObject];
        }
        self.yValues = [yArr mutableCopy];
    }
    
    allH = HHViewSelfHeight - HHTopMargin-HHBottomMargin;
    allW = HHViewSelfWidth - HHLeftMargin-HHRightMargin;
    
    count = (int)self.xValues.count;
    
    everyX = (CGFloat)(HHViewSelfWidth - HHLeftMargin-HHRightMargin-HHPointleftRightMargin*2) / (count-1);
    
    // y轴最多分5部分
    yCount = count <= 5 ? count : 5;
    
    everyY =  (HHViewSelfHeight - HHTopMargin-HHBottomMargin) / yCount;
    
    maxY = 0;
    self.needGradient = NO;
    for (int i = 0; i < count; i ++) {
        
        if ([self.yValues[i] floatValue] > maxY) {
            
            maxY = ceilf([self.yValues[i] floatValue]);
            _maxIndex = i;
            self.needGradient = YES;
        }
    }
    
    maxY = (maxY >= 100 )?maxY:100;
}

#pragma mark 绘制视图
- (void)setMyView{
    self.backgroundColor = [UIColor whiteColor];
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    _xLableArr = [NSMutableArray arrayWithCapacity:0];
    _btnArr = [NSMutableArray arrayWithCapacity:0];
    
    UIView *clickBg = [[UIView alloc]initWithFrame:CGRectMake(HHLeftMargin, HHTopMargin, allW, allH)];
    clickBg.backgroundColor = [UIColor clearColor];
    [self addSubview:clickBg];
    _clickBg = clickBg;
    
    //x轴 和btn
    for (NSInteger i = 0; i < 7; i++) {
        UILabel *xLabel = [[UILabel alloc]initWithFrame:CGRectMake(HHLeftMargin+HHPointleftRightMargin+everyX*i-everyX/2, HHViewSelfHeight-HHBottomMargin, everyX, HHBottomMargin)];
        xLabel.backgroundColor = [UIColor clearColor];
        xLabel.textColor = self.xyLabelColor;
        xLabel.font = kFont(10);
        xLabel.text = [NSString stringWithFormat:@"%@",_xValues[i]];
        xLabel.textAlignment = NSTextAlignmentCenter;
        xLabel.userInteractionEnabled = YES;
//        xLabel.transform = CGAffineTransformRotate(xLabel.transform, -M_PI/4);
        [self addSubview:xLabel];
        [_xLableArr addObject:xLabel];
        
    
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat singleBtnW = allW/count;
        btn.frame = CGRectMake(singleBtnW*i, 0, singleBtnW, allH);
        btn.backgroundColor = [UIColor clearColor];
        btn.tag = HHLineChartBtnTag+i;
        [btn addTarget:self action:@selector(showValue:) forControlEvents:UIControlEventTouchUpInside];
        [_clickBg addSubview:btn];
    }
    
    long long everageY = maxY/yCount;
    NSInteger number =  [self nsinterLength:everageY];
    NSInteger division;
    
    if (number >= 3) {
       division = 5*powf(10, number-2);
        
//        if (everageY%division > 0) {
////            everageY = division;
//        }
        
    }else{
        division = 10;
    }
    
    if (everageY%division > 0) {
        everageY += (division-everageY%division);
    }
     maxY = everageY*yCount;
    
    for (int i = 0; i <= yCount; i++) {
         UILabel *yLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, HHLeftMargin-2, everyY)];
        yLabel.center = CGPointMake(HHLeftMargin/2-1, HHViewSelfHeight-HHBottomMargin-everyY*i);
        yLabel.font = kFont(10);
        yLabel.textColor = self.xyLabelColor;
        yLabel.userInteractionEnabled = YES;
        yLabel.textAlignment = NSTextAlignmentRight;
        if (i == 0) {
            yLabel.text = @"0";
        }
        
        
        if (number >= 5) {
            long long textBase = everageY/1000;
            yLabel.text = [NSString stringWithFormat:@"%lldk",textBase*i];
        }else{
            yLabel.text = [NSString stringWithFormat:@"%lld",everageY*i];
        }
        
        [self addSubview:yLabel];
    }
    
    
    UILabel *popLabel = [[UILabel alloc]init];
    popLabel.backgroundColor = _popBgColor;
    popLabel.textColor = _popTextColor;
    popLabel.font = kFont(18);
    popLabel.layer.cornerRadius = 5;
    popLabel.layer.masksToBounds = YES;
    popLabel.userInteractionEnabled = YES;
    popLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:popLabel];
    _popLabel = popLabel;
}

- (NSInteger)nsinterLength:(long long)x {
    NSInteger sum=0,j=1;
    while( x >= 1 ) {
        
        x=x/10;
        sum++;
        j=j*10;
    }
    return sum;
}


#pragma mark 事件
- (void)showValue:(UIButton *)sender{
    NSInteger index = sender.tag-HHLineChartBtnTag;
    
    if (_currentPoint) {
        _currentPoint.hidden = YES;
    }
    UIView *pointV = _pointBtnArr[index];
    pointV.hidden = NO;
    _currentPoint = pointV;
    
    [self bringSubviewToFront:_popLabel];
    CGPoint point = [_pointArr[index] CGPointValue];
   NSString *valueStr= [NSString stringWithFormat:@"%.2f",[self.yValues[index] floatValue]];
    _popLabel.text = valueStr;
    CGSize labelSize = [_popLabel sizeThatFits:CGSizeMake(kRelativeWidth(200), kRelativeHeight(25))];
    
    _popLabel.hidden = NO;
    _popLabel.frame = CGRectMake(0, 0, labelSize.width+kRelativeWidth(10), labelSize.height + kRelativeWidth(10));

    CGFloat maxPointMinY = point.y-labelSize.height-kRelativeHeight(5);
    if (maxPointMinY < HHTopMargin) {
        maxPointMinY = point.y + kRelativeHeight(5)+labelSize.height;
    }
    if (index == 0 ) {
        _popLabel.center = CGPointMake(point.x+labelSize.width/2, maxPointMinY);
    }else if (index == count-1 ){
        _popLabel.center = CGPointMake(point.x-labelSize.width/2, maxPointMinY);
    }else{
        _popLabel.center = CGPointMake(point.x, maxPointMinY);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    if (![touch.view isEqual:_clickBg]) {
        _popLabel.hidden = YES;
        _currentPoint.hidden = YES;
    }
}

//TODO: 画网格线
- (void)drawLines{
    UIBezierPath *path = [UIBezierPath bezierPath];
    //竖线 两条
    for (int i = 0; i < 2; i++) {
        [path moveToPoint:CGPointMake(HHLeftMargin+allW*i, HHTopMargin)];
        [path addLineToPoint:CGPointMake(HHLeftMargin+allW*i, HHTopMargin+allH)];
    }
    
    //横线 包括x轴
    for (int i = 0; i <= yCount; i++) {
        [path moveToPoint:CGPointMake(HHLeftMargin, HHViewSelfHeight-HHBottomMargin-everyY*i)];
        [path addLineToPoint:CGPointMake(HHViewSelfWidth-HHRightMargin, HHViewSelfHeight-HHBottomMargin-everyY*i)];
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = self.gridLineColor.CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineWidth = 1;
    [self.layer addSublayer:shapeLayer];
}

//TODO: 计算点的坐标并画点
- (void)drawPoint{
    _pointBtnArr = [NSMutableArray array];
    _pointArr = [NSMutableArray arrayWithCapacity:0];
    //计算7个点的坐标
    for (int i = 0; i < count; i++) {
        CGFloat pointY = HHViewSelfHeight-HHBottomMargin- [_yValues[i] floatValue]/maxY*allH;
        CGFloat pointX = HHLeftMargin+ HHPointleftRightMargin + everyX*i;
        CGPoint point = CGPointMake(pointX, pointY);
        [_pointArr addObject:[NSValue valueWithCGPoint:point]];
    }
    
    self.xStartPoint =CGPointMake(HHLeftMargin+HHPointleftRightMargin, HHViewSelfHeight-HHBottomMargin);
    self.xendPoint = CGPointMake(HHViewSelfWidth-HHPointleftRightMargin-HHRightMargin, HHViewSelfHeight-HHBottomMargin);
    
}

//TODO: 画曲线和渐变填充
- (void)drawCurvePath{
//    [self gradientLayer];
    
    _path = [UIBezierPath bezierPath];
    [_path moveToPoint:[_pointArr[0] CGPointValue]];
    
    for (int i = 1; i < _pointArr.count; i++) {
        CGPoint prePoint = [_pointArr[i-1] CGPointValue];
        CGPoint nowpoint = [_pointArr[i] CGPointValue];
        
        //控制点 x均为两个点的中点
        CGPoint controlPoint1 = CGPointMake((prePoint.x+nowpoint.x)/2, prePoint.y);
        CGPoint controlPoint2 = CGPointMake((prePoint.x+nowpoint.x)/2, nowpoint.y);
        [_path addCurveToPoint:nowpoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    }
    
}

- (void)drawCurveLine{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = _path.CGPath;
    shapeLayer.strokeColor = self.curveColor.CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineWidth = 1;
    [self.layer addSublayer:shapeLayer];
}

- (void)drawGradientLayer{
    UIBezierPath *gradientPath = [UIBezierPath bezierPathWithCGPath:_path.CGPath];

    gradientPath.lineWidth = 0.01;
    [gradientPath addLineToPoint:_xendPoint];
    [gradientPath addLineToPoint:_xStartPoint];
    [gradientPath addLineToPoint:[_pointArr[0] CGPointValue]];
    [gradientPath closePath];
    
    
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.bounds;
    NSArray *colors = @[(__bridge id)self.gradientStartColor.CGColor,(__bridge id)self.gradientEndColor.CGColor];
    gradientLayer.colors = colors;
    gradientLayer.locations = @[@0,@1];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    [self.layer addSublayer:gradientLayer];
    _gradientLayer = gradientLayer;
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.strokeColor = [UIColor clearColor].CGColor;
    maskLayer.path = gradientPath.CGPath;
    maskLayer.lineWidth = 0.01;
    //    maskLayer.fillColor = [UIColor whiteColor].CGColor;
    self.gradientLayer.mask = maskLayer;
    
}

- (void)drawPointCircle{
    for (int i = 0; i < _pointArr.count; i++) {
        CGPoint point = [_pointArr[i] CGPointValue];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        view.center = point;
        view.backgroundColor = self.pointColor;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = [UIColor whiteColor].CGColor;
        view.layer.borderWidth = 2;
        view.layer.cornerRadius = 5;
        view.hidden = YES;
        [self addSubview:view];
        [_pointBtnArr addObject:view];
    }

}


- (void)drawChart{
    
    self.gridLineColor = self.gridLineColor?self.gridLineColor:HHColor(244, 244, 244);
    self.xyLabelColor = self.xyLabelColor?self.xyLabelColor:HHColor(153, 153, 153);
    self.curveColor = self.curveColor?self.curveColor:HHColor(247, 26, 48);
    self.gradientStartColor = self.gradientStartColor?self.gradientStartColor:HHColor(250, 218, 216);
    self.gradientEndColor = self.gradientEndColor?self.gradientEndColor:HHColor(255, 245, 244);
    self.pointColor = self.pointColor?self.pointColor:HHColor(255, 252, 131);
    self.popBgColor = self.popBgColor?self.popBgColor:HHColor(247, 26, 48);
    self.popTextColor = self.popTextColor?self.popTextColor:[UIColor whiteColor];
    
    self.yValues = self.yValues?self.yValues:@[@"100",@"348",@"200",@"60",@"1000",@"500",@"100"];
    self.xValues = self.xValues?self.xValues:@[@1,@2,@3,@4,@5,@6,@7];
    
    [self doWithCalculate];
    [self setMyView];
    [self drawLines];
    [self drawPoint];
    [self drawCurvePath];
    
    if (self.needGradient) {
        [self drawGradientLayer];
    }
    [self drawCurveLine];
    [self drawPointCircle];
}



@end
