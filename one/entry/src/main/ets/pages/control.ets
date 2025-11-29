interface QuickFunctionItem {
  name: string;
  color: Resource;
}

@Component
export struct Control {
  build() {
    Column() {
      Text('控制中心')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, top: 16, bottom: 16 })
        .textAlign(TextAlign.Start)
      
      Column() {
        // 虚拟摇杆区域
        Column() {
          Text('虚拟摇杆')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 20 })
          
          // 圆形摇杆（简化实现）
          Circle()
            .width(120)
            .height(120)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(60)
            .margin({ bottom: 30 })
        }
        .width('100%')
        .height(200)
        .margin({ bottom: 20 })
        
        // 快捷功能区
        Column() {
          Text('快捷功能')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 })
            .width('100%')
            .textAlign(TextAlign.Start)
          
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach([
              { name: '悬停', color: $r('app.color.primary_blue') },
              { name: '上升', color: $r('app.color.primary_blue') },
              { name: '下降', color: $r('app.color.primary_blue') },
              { name: '灯光控制', color: $r('app.color.primary_blue') }
            ], (item: QuickFunctionItem, index: number) => {
              Column() {
                Image($r('app.media.deal_select'))
                  .width(24)
                  .height(24)
                  .margin({ bottom: 5 })
                Text(item.name)
                  .fontSize(12)
              }
              .width('22%')
              .height(60)
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            })
          }
          .width('100%')
          .height(80)
        }
        .width('90%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
        .margin({ bottom: 20 })
        
        // 状态显示栏
        Column() {
          Text('状态显示')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 })
          
          Flex({ justifyContent: FlexAlign.SpaceBetween }) {
            Text('深度: 10m')
              .fontSize(14)
            Text('电量: 85%')
              .fontSize(14)
            Text('信号: 良好')
              .fontSize(14)
          }
        }
        .width('90%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
    .width('100%')
  }
}