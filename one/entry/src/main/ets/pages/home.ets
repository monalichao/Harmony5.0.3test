import { router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
// 【注意】请确认路径是否正确
import { BleRobotController } from '../utils/BlueController';
import { GlobalContext } from '../utils/GlobalContext';
import { BleDevice } from '@ohos/fastble';

// 1. 蓝牙扫描弹窗组件 (保持不变)
@CustomDialog
struct ScanDialog {
  controller: CustomDialogController;
  @Link scannedDevices: BleDevice[];
  action: (device: BleDevice) => void = (device: BleDevice) => {};

  build() {
    Column() {
      Text('附近的蓝牙设备')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      List() {
        ForEach(this.scannedDevices, (item: BleDevice) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.getName() || '未知设备')
                  .fontSize(16)
                  .fontColor(Color.Black)
                Text(item.getMac())
                  .fontSize(12)
                  .fontColor(Color.Gray)
              }.alignItems(HorizontalAlign.Start)

              Button('连接')
                .fontSize(12)
                .height(28)
                .onClick(() => {
                  this.action(item);
                  this.controller.close();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 10, right: 10, top: 10, bottom: 10 })
          }
        }, (item: BleDevice) => item.getMac())
      }
      .width('100%')
      .height(200)
      .divider({ strokeWidth: 0.5, color: '#eee' })

      Button('取消')
        .fontColor(Color.Red)
        .backgroundColor(Color.Transparent)
        .margin({ bottom: 10, top: 10 })
        .onClick(() => {
          BleRobotController.getInstance().stopScan();
          this.controller.close();
        })
    }
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('80%')
  }
}

@Component
export struct Home {
  @State isConnected: boolean = false;
  @State deviceList: BleDevice[] = [];

  scanDialogController: CustomDialogController = new CustomDialogController({
    builder: ScanDialog({
      scannedDevices: $deviceList,
      action: (device: BleDevice) => this.connectToDevice(device)
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center
  });

  aboutToAppear() {
    let context = getContext(this) as common.UIAbilityContext;
    GlobalContext.getContext().setValue('context', context);
    // 初始化蓝牙，但不在这里断开，防止重入页面时断连
    BleRobotController.getInstance().init();
  }

  // 【核心修复】移除这里的 disconnect()
  // 因为跳转页面时 Home 会销毁/隐藏，导致 aboutToDisappear 被触发
  // 我们希望蓝牙在 APP 整个生命周期内保持连接
  aboutToDisappear() {
    // BleRobotController.getInstance().disconnect(); // <--- 注释掉这一行
  }

  startScanLogic(): void {
    if (this.isConnected) {
      AlertDialog.show({
        title: '提示',
        message: '确定要断开当前机器人连接吗？',
        primaryButton: {
          value: '取消',
          action: () => {}
        },
        secondaryButton: {
          value: '断开',
          fontColor: Color.Red,
          action: () => {
            BleRobotController.getInstance().disconnect();
            this.isConnected = false;
          }
        }
      });
      return;
    }

    BleRobotController.getInstance().checkPermissions(() => {
      this.deviceList = [];
      this.scanDialogController.open();
      BleRobotController.getInstance().startScan((device: BleDevice) => {
        let exists = this.deviceList.some(d => d.getMac() === device.getMac());
        if (!exists) {
          this.deviceList.push(device);
        }
      });
    });
  }

  connectToDevice(device: BleDevice): void {
    BleRobotController.getInstance().connect(device, (connected: boolean) => {
      this.isConnected = connected;
      if (connected) {
        AlertDialog.show({
          title: '连接成功',
          message: `已连接到 ${device.getName() || device.getMac()}，是否进入控制台？`,
          primaryButton: {
            value: '稍后',
            action: () => {}
          },
          secondaryButton: {
            value: '立刻进入',
            fontColor: '#0A59F7',
            action: () => {
              // 【核心修复】修改路径 + 增加错误处理
              try {
                router.pushUrl({ url: 'pages/control' }) // 确保文件名大小写一致
                  .catch((err: Error) => {
                    console.error('路由跳转失败:', JSON.stringify(err));
                  });
              } catch (err) {
                console.error('路由异常:', JSON.stringify(err));
              }
            }
          }
        });
      }
    });
  }

  build() {
    Column() {
      // 水下机器人状态文字
      Text('水下机器人状态')
        .fontSize(32)
        .fontColor(Color.Black)
        .margin({ top: 20,bottom: 5,left: 30 })
        .alignSelf(ItemAlign.Start)

      // 添加圆角正方形框，填充#EDEEF0颜色，占据屏幕上部分3/8的大小
      Column() {
        // 使用相对布局放置图标
        RelativeContainer() {
          // 左侧0%到60%上侧0%到60%区域 - cameraback背景图标
          Image($r('app.media.camaraback'))
            .width('55%')
            .height('67%')
            .id("cameraback")
            .alignRules({
              top: { anchor: "__container__", align: VerticalAlign.Top },
              left: { anchor: "__container__", align: HorizontalAlign.Start }
            })
            .borderRadius(10)
            .margin({ 
              top: '2.5%',
              left: '4%'
            })

          // 在cameraback图标上显示摄像头状态图标（根据连接状态切换）
          Image(this.isConnected ? $r('app.media.camara_open') : $r('app.media.camara_close'))
            .width('40%')
            .height('40%')
            .id("cameraStatus")
            .alignRules({
              top: { anchor: "cameraback", align: VerticalAlign.Top },
              left: { anchor: "cameraback", align: HorizontalAlign.Start }
            })
            .margin({ 
              top: '7%',
              left: '8%'
            })
            .objectFit(ImageFit.Contain)

          // 在cameraback图标内部下侧显示摄像头连接状态文字
          Text(this.isConnected ? '摄像头已连接' : '摄像头未连接')
            .fontSize(16)
            .fontColor(Color.Black)
            .id("cameraText")
            .alignRules({
              bottom: { anchor: "cameraback", align: VerticalAlign.Bottom },
              left: { anchor: "cameraback", align: HorizontalAlign.Start }
            })
            .align(Alignment.Center)
            .margin({ 
              bottom: '5%',
              left: '16%'
            })

          // 右侧0%到40%上侧0%到35%区域 - lanyaback背景图标
          Image($r('app.media.lanyaback'))
            .width('35%')
            .height('35%')
            .id("lanyaback")
            .alignRules({
              top: { anchor: "__container__", align: VerticalAlign.Top },
              right: { anchor: "__container__", align: HorizontalAlign.End }
            })
            .borderRadius(10)
            .margin({ 
              top: '2.5%',
              right: '2.5%'
            })

          // 在lanyaback图标上显示蓝牙状态图标（根据连接状态切换）
          Image(this.isConnected ? $r('app.media.lanya_open') : $r('app.media.lanya_close'))
            .width('22%')
            .height('20%')
            .id("bluetoothStatus")
            .alignRules({
              top: { anchor: "lanyaback", align: VerticalAlign.Top },
              right: { anchor: "lanyaback", align: HorizontalAlign.End }
            })
            .margin({ 
              top: '5%',
              right: '7%'
            })
            .objectFit(ImageFit.Contain)

          // 在lanyaback图标内部下侧显示蓝牙连接状态文字
          Text(this.isConnected ? '蓝牙已连接' : '蓝牙未连接')
            .fontSize(16)
            .fontColor(Color.White)
            .id("bluetoothText")
            .alignRules({
              bottom: { anchor: "lanyaback", align: VerticalAlign.Bottom },
              left: { anchor: "lanyaback", align: HorizontalAlign.Start }
            })
            .align(Alignment.Center)
            .margin({ 
              bottom: '1%',
              left: '8%'
            })

          // 右侧0%到40%上侧35%到60%区域 - battery背景图标
          Image($r('app.media.battery'))
            .width('35%')
            .height('28%')
            .id("battery")
            .alignRules({
              top: { anchor: "lanyaback", align: VerticalAlign.Bottom },
              right: { anchor: "__container__", align: HorizontalAlign.End }
            })
            .borderRadius(10)
            .margin({ 
              top: '4%',
              right: '3.5%'
            })

          // 在battery图标上显示电池状态图标
          Image($r('app.media.battery2'))
            .width('30%')
            .height('20%')
            .id("batteryStatus")
            .alignRules({
              top: { anchor: "battery", align: VerticalAlign.Top },
              right: { anchor: "battery", align: HorizontalAlign.End }
            })
            .margin({ 
              top: '5%',
              right: '3%'
            })
            .objectFit(ImageFit.Contain)

          // 在battery图标内部显示电量信息
          Text('剩余电量')
            .fontSize(16)
            .fontColor(Color.Black)
            .alignSelf(ItemAlign.Start)
            .alignRules({
              top: { anchor: "battery", align: VerticalAlign.Top },
              left: { anchor: "battery", align: HorizontalAlign.Start },
            })
            .margin({
              top: '1.5%',
              left: '11%'
            })

          Text(this.isConnected ? '50%' : '未连接')
            .fontSize(16)
            .fontColor(Color.Black)
            .alignSelf(ItemAlign.Start)
            .alignRules({
              bottom: { anchor: "battery", align: VerticalAlign.Bottom },
              left: { anchor: "battery", align: HorizontalAlign.Start }
            })
            .margin({
              bottom: '7%',
              left: '11%'
            })

          // 右侧0%到40%上侧60%到100%区域 - settings_icon图标
          Image($r('app.media.settings_icon'))
            .width('35%')
            .height('20%')
            .id("settings_icon")
            .alignRules({
              top: { anchor: "battery", align: VerticalAlign.Bottom },
              right: { anchor: "__container__", align: HorizontalAlign.End }
            })
            .borderRadius(10)
            .margin({ 
              top: '4%',
              right: '3%',
              bottom: '2.5%'
            })

          // 左侧0%到60%上侧60%到100%区域 - usetime_back图标
          Image($r('app.media.usetime_back'))
            .width('55%')
            .height('20%')
            .id("usetime_back")
            .alignRules({
              top: { anchor: "cameraback", align: VerticalAlign.Bottom },
              left: { anchor: "__container__", align: HorizontalAlign.Start }
            })
            .borderRadius(10)
            .margin({ 
              top: '4.5%',
              left: '3%',
              bottom: '2.5%'
            })
        }
        .width('100%')
        .height('100%')
      }
      .width('90%')
      .height('50%')
      .backgroundColor('#EDEEF0')
      .borderRadius(20)
      .margin({ 
        top: 5, 
        bottom: 20, 
        left: 20, 
        right: 20 
      })
      .alignSelf(ItemAlign.Center)

      Column() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {

          // --- 1. 遥控机器人卡片 ---
          Column() {
            Image($r('app.media.control_select'))
              .width(40).height(40).margin({ bottom: 10 })
              .fillColor(this.isConnected ? Color.Green : undefined)

            Text(this.isConnected ? '进入控制' : '扫描连接')
              .fontSize(14)
          }
          .width('30%').height(80)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .border(this.isConnected ? { width: 2, color: Color.Green } : { width: 0 })
          .onClick(() => {
            if (this.isConnected) {
              // 【核心修复】这里也要加 try-catch
              try {
                router.pushUrl({ url: 'pages/ControlPage' })
                  .catch((err: Error) => {
                    console.error('跳转失败:', JSON.stringify(err));
                  });
              } catch (err) {
                console.error('跳转异常:', JSON.stringify(err));
              }
            } else {
              this.startScanLogic();
            }
          })

          // --- 2. 图像智能处理卡片 ---
          Column() {
            Image($r('app.media.deal_select'))
              .width(40).height(40).margin({ bottom: 10 })
            Text('图像智能处理')
              .fontSize(14)
          }
          .width('30%').height(80)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/MindSpore' });
            } catch (error) {
              console.error('跳转失败: ', JSON.stringify(error));
            }
          })

          // --- 3. 实时视频流卡片 ---
          Column() {
            Image($r('app.media.trans_select'))
              .width(40).height(40).margin({ bottom: 10 })
            Text('实时视频流')
              .fontSize(14)
          }
          .width('30%').height(80)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            // 未来实现
          })
        }
        .width('90%').height(100).margin({ bottom: 30 })

        // --- 设备状态概览 ---
        Column() {
          Text('设备状态概览')
            .fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 10 })

          Row() {
            Text('已连接机器人:')
              .fontSize(14).fontColor($r('app.color.text_primary'))
            Text(this.isConnected ? '是 (已连接)' : '否 (未连接)')
              .fontSize(14)
              .fontColor(this.isConnected ? $r('app.color.primary_blue') : Color.Gray)
              .fontWeight(this.isConnected ? FontWeight.Bold : FontWeight.Normal)
              .margin({ left: 10 })
          }
          .width('100%').justifyContent(FlexAlign.SpaceBetween)
        }
        .width('90%').padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
      }
      .layoutWeight(1).width('100%').alignItems(HorizontalAlign.Center)
    }
    .height('100%').width('100%')
  }
}