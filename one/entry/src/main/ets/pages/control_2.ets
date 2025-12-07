import { router } from '@kit.ArkUI';
import { BleRobotController } from '../utils/BlueController';

interface QuickFunctionItem {
  name: string;
  color: Resource;
  command: string;
  icon: Resource;
}


@Component
export struct Control {
  private centerX: number = 100;
  private centerY: number = 100;
  private maxRadius: number = 60;

  @State stickX: number = 100;
  @State stickY: number = 100;

  private lastCommand: string = '';

  private quickFunctions: QuickFunctionItem[] = [
    { name: '悬停/停止', color: $r('app.color.primary_blue'), command: 'C', icon: $r('app.media.deal_select') }, // 停止用 C
    { name: '上升/抬头', color: $r('app.color.primary_blue'), command: 'U', icon: $r('app.media.deal_select') },
    { name: '下降/低头', color: $r('app.color.primary_blue'), command: 'D', icon: $r('app.media.deal_select') },
    { name: '灯光开关', color: $r('app.color.primary_blue'), command: 'L', icon: $r('app.media.deal_select') }
  ];

  aboutToAppear() {
    this.stickX = this.centerX;
    this.stickY = this.centerY;

    // 自动发送 AA 解锁 APP 控制模式（前提：底盘上电已超过10秒）
    console.info('ControlPage: 开始激活序列...');
    setTimeout(() => {
      BleRobotController.getInstance().sendByteCommand('A');
      setTimeout(() => {
        BleRobotController.getInstance().sendByteCommand('A');
        // 解锁后发一个 C 确保停止
        setTimeout((): void => BleRobotController.getInstance().sendByteCommand('C'), 100);
      }, 150);
    }, 500);
  }

  private sendCommand(cmdChar: string): void {
    if (!cmdChar) {
      return;
    }
    console.info(`ControlPage: 发送指令 -> ${cmdChar}`);
    BleRobotController.getInstance().sendByteCommand(cmdChar);
    this.lastCommand = cmdChar;
  }

  private handleJoystick(event: TouchEvent): void {
    if (event.type === TouchType.Up) {
      animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
        this.stickX = this.centerX;
        this.stickY = this.centerY;
      });
      // 松手停止：发 Z
      this.sendCommand('Z');
      return;
    }

    const x = event.touches[0].x;
    const y = event.touches[0].y;

    let dx = x - this.centerX;
    let dy = y - this.centerY;
    let distance = Math.sqrt(dx * dx + dy * dy);

    if (distance > this.maxRadius) {
      const ratio = this.maxRadius / distance;
      dx *= ratio;
      dy *= ratio;
    }

    this.stickX = this.centerX + dx;
    this.stickY = this.centerY + dy;

    const threshold = 20;
    if (Math.abs(dy) > Math.abs(dx)) {
      if (dy < -threshold) {
        this.sendCommand('A'); // 前进
      } else if (dy > threshold) {
        this.sendCommand('E'); // 后退
      }
    } else {
      if (dx < -threshold) {
        this.sendCommand('G'); // 左移
      } else if (dx > threshold) {
        this.sendCommand('C'); // 右移（这里你也可以换成 B/D 看实际效果）
      }
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.trans_unselect'))
          .width(24).height(24)
          .margin({ right: 10 })
          .onClick(() => router.back())

        Text('控制中心')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })

      // 添加圆角正方形方框，占据屏幕上侧60%，填充颜色为C4C4C4
      Column() {
        // 这里可以放置方框内的内容
      }
      .width('90%')
      .height('50%')
      .backgroundColor('#C4C4C4')
      .borderRadius(20)
      .margin({ 
        top: 10, 
        bottom: 10, 
        left: '5%', 
        right: '5%' 
      })

      Column() {
        // 虚拟摇杆
        Column() {
          Text('虚拟摇杆')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 20 })

          Stack() {
            // 使用自定义遥杆背景图片
            Image($r('app.media.yaogan_bian'))
              .width(200).height(200)
            
            // 使用自定义遥杆图片
            Image($r('app.media.yaogan'))
              .width(80).height(80)
              .position({ x: this.stickX - 40, y: this.stickY - 40 })
          }
          .width(200).height(200).margin({ bottom: 10 })
          .onTouch((e: TouchEvent) => this.handleJoystick(e))
        }
        .width('100%').height(260).margin({ bottom: 20 })


      }
      .layoutWeight(1).width('100%').alignItems(HorizontalAlign.Center)
    }
    .height('100%').width('100%')
  }
}