import { router } from '@kit.ArkUI';

@Component
export struct Home {
  build() {
    Column() {
      Text('OpenArk 灵枢')
        .fontSize(20)
        .fontColor($r('app.color.primary_blue'))
        .margin({ top: 20, bottom: 30 })
      
      Column() {
        // 快捷卡片区域
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          // 遥控机器人卡片
          Column() {
            Image($r('app.media.control_select'))
              .width(40)
              .height(40)
              .margin({ bottom: 10 })
            Text('遥控机器人')
              .fontSize(14)
          }
          .width('30%')
          .height(80)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            // 跳转到控制页面
          })
          
          // 图像智能处理卡片
          Column() {
            Image($r('app.media.deal_select'))
              .width(40)
              .height(40)
              .margin({ bottom: 10 })
            Text('图像智能处理')
              .fontSize(14)
          }
          .width('30%')
          .height(80)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            // 跳转到处理页面
          })
          
          // 实时视频流卡片
          Column() {
            Image($r('app.media.trans_select'))
              .width(40)
              .height(40)
              .margin({ bottom: 10 })
            Text('实时视频流')
              .fontSize(14)
          }
          .width('30%')
          .height(80)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            // 跳转到传输页面
          })
        }
        .width('90%')
        .height(100)
        .margin({ bottom: 30 })
        
        // 设备状态概览
        Column() {
          Text('设备状态概览')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 })
          
          Row() {
            Text('已连接机器人:')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Text('是')
              .fontSize(14)
              .fontColor($r('app.color.primary_blue'))
              .margin({ left: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
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