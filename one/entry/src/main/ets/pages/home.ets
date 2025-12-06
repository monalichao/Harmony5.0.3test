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
      Text('OpenArk 灵枢')
        .fontSize(20)
        .fontColor($r('app.color.primary_blue'))
        .margin({ top: 20, bottom: 30 })

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