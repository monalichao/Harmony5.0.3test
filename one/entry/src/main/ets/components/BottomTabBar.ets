interface TabItem {
  name: string;
  iconSelected?: Resource;
  iconUnselected?: Resource;
}

@Component
export struct BottomTabBar {
  @Link currentIndex: number;

  private tabs: TabItem[] = [
    {
      name: "设备控制",
      iconSelected: $r('app.media.control_select'),
      iconUnselected: $r('app.media.control_unselect')
    },
    {
      name: "历史记录",
      iconSelected: $r('app.media.history_select'),
      iconUnselected: $r('app.media.history_unselect')
    },
    {
      name: "遥控",
      iconSelected: $r('app.media.device_select'),
      iconUnselected: $r('app.media.device_unselect')
    },
    {
      name: "智能处理",
      iconSelected: $r('app.media.deal_select'),
      iconUnselected: $r('app.media.deal_unselect')
    },
    {
      name: "我的",
      iconSelected: $r('app.media.home_select'),
      iconUnselected: $r('app.media.home_unselect')
    }
  ];

  build() {
    // 外层Column：宽度100%，内容靠底部对齐，高度自适应
    Column() {
      // 导航栏核心Row
      Row() {
        ForEach(this.tabs, (item: TabItem, index: number) => {
          Column() {
            // 图标
            Image(this.currentIndex === index ? item.iconSelected : item.iconUnselected)
              .width(24)
              .height(24)
              .scale({ x: this.currentIndex === index ? 1.2 : 1.0, y: this.currentIndex === index ? 1.2 : 1.0 })
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
              .margin({ bottom: 8 })

            // 文字标签
            Text(item.name)
              .fontColor(this.currentIndex === index ? $r('app.color.nav_icon_selected') : $r('app.color.nav_icon_unselected'))
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
          }
          .onClick(() => {
            this.currentIndex = index;
          })
          .layoutWeight(1) // 平均分配宽度
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .height('100%') // 让点击区域占满Row高度
        }, (item: TabItem) => item.name)
      }
      .width('100%')
      .backgroundColor('#CCCCCC')
      .opacity(0.7)
      .borderRadius(16)
      .padding({ top: 10, bottom: 10, left: 20, right: 20 })
      .margin({ bottom: 20 }) // 与屏幕底部保持20px间距
      .height(60) // 固定导航栏高度，提升体验
    }
    .width('100%')
    .justifyContent(FlexAlign.End) // 关键：内容靠底部对齐
    .padding({ left: 16, right: 16 }) // 左右边距，避免贴边
  }
}