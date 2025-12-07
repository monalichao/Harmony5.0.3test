@Component
export struct History {
  @State isObjectDetectionOn: boolean = false;  // 目标检测开关状态
  @State isCrackDetectionOn: boolean = false;   // 裂缝检测开关状态
  
  build() {
    Column() {
      // 第一个板块
      Column() {
        // 一行内：检测模式（左侧）和检测开关列（右侧）
        Row() {
          // 左侧：检测模式
          Text('检测模式')
            .fontSize(25)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 15, bottom: 45})
          
          // 右侧：检测开关列
          Column() {
            // 目标检测 + 滑动按钮
            Row() {
              Text('目标检测')
                .fontSize(25)
              Toggle({ type: ToggleType.Switch, isOn: this.isObjectDetectionOn })
                .onChange((isOn: boolean) => {
                  this.isObjectDetectionOn = isOn;
                })
                .selectedColor('#97F7FA')
                .switchPointColor('#97F7FA')
                .margin({ left: 15 })
            }
            .width('100%')
            .margin({ bottom: 5 })
            
            // 裂缝检测 + 滑动按钮
            Row() {
              Text('裂缝检测')
                .fontSize(25)
              Toggle({ type: ToggleType.Switch, isOn: this.isCrackDetectionOn })
                .onChange((isOn: boolean) => {
                  this.isCrackDetectionOn = isOn;
                })
                .selectedColor('#97F7FA')
                .switchPointColor('#97F7FA')
                .margin({ left: 15 })  // 进一步减小左右间距
            }
            .width('100%')
          }
          .width('60%')  // 设置列宽度
          .margin({ left: 100})
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 22, left: 10, right: 10 })
      }
      .width('90%')
      .height('20%')
      .backgroundColor('#FFFFFF')
      .borderRadius(15)
      .margin({ top: 15, bottom: 8 })
      
      // 第二个板块
      Column() {
        Row() {
          Text('检测历史')
            .fontSize(20)
            .margin({ left: 15, top: 5})
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 10 })

      }
      .width('90%')
      .height('32%')
      .backgroundColor('#FFFFFF')
      .borderRadius(15)
      .margin({ top: 16, bottom: 8 })
      
      // 第三个板块
      Column() {
        Text('分析结果')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 15, bottom: 45})

      }
      .width('90%')
      .height('32%')
      .backgroundColor('#FFFFFF')
      .borderRadius(15)
      .margin({ top: 16, bottom: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}