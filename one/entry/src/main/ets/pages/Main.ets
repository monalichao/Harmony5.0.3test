import { BottomTabBar } from '../components/BottomTabBar';
// import { Control } from './control'; // 【删除】因为 ControlPage 已经是独立页面，不能作为组件导入
import { Deal } from './deal';
import { Home } from './home';
import { Trans } from './trans';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  build() {
    Column() {
      // 页面内容区域
      Stack() {
        // 首页内容 (Index 0)
        if (this.currentIndex === 0) {
          Home()
        }

        // 控制页面占位 (Index 1)
        // 【说明】真正的控制台现在是通过 Home 页面的“遥控机器人”卡片点击跳转的
        if (this.currentIndex === 1) {
          Column() {
            Text("请前往[首页]连接蓝牙\n进入遥控中心")
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .fontColor(Color.Gray)
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        }

        // 处理页面 (Index 2)
        if (this.currentIndex === 2) {
          // RelativeContainer 建议确保 Deal 组件内部支持该布局，否则普通 Column 即可
          Column() {
            Deal()
          }
          .width('100%')
          .height('100%')
        }

        // 传输页面 (Index 3)
        if (this.currentIndex === 3) {
          Trans()
        }
      }
      .layoutWeight(1)

      // 底部标签栏
      BottomTabBar({ currentIndex: $currentIndex })
    }
    .height('100%')
    .width('100%')
  }
}