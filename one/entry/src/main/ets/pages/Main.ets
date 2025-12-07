import { BottomTabBar } from '../components/BottomTabBar';
import { Control } from './control_2';
// import { Control } from './control'; // 【删除】因为 ControlPage 已经是独立页面，不能作为组件导入
import { Deal } from './deal';
import { History } from './history';
import { Home } from './home';
import { Mine } from './mine';

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
        if (this.currentIndex === 1) {
          History()
        }
        // 【说明】真正的控制台现在是通过 Home 页面的"遥控机器人"卡片点击跳转的
        if (this.currentIndex === 2) {
        //   Column() {
        //     Text("请前往[首页]连接蓝牙\n进入遥控中心")
        //       .fontSize(16)
        //       .textAlign(TextAlign.Center)
        //       .fontColor(Color.Gray)
        //       .margin({ top: 100 })
        //   }
        //   .width('100%')
        //   .height('100%')
          Control()
        }

        // 处理页面 (Index 2)
        if (this.currentIndex === 3) {
          // RelativeContainer 建议确保 Deal 组件内部支持该布局，否则普通 Column 即可
          Column() {
            Deal()
          }
          .width('100%')
          .height('100%')
        }

        // 我的
        if (this.currentIndex === 4) {
          Mine()
        }
      }
      .layoutWeight(1)

      // 底部标签栏
      BottomTabBar({ currentIndex: $currentIndex })
    }
    .height('100%')
    .width('100%')
    // 修改对齐方式为起始对齐，使内容区域从顶部开始填充
    .justifyContent(FlexAlign.Start)
    .backgroundImage($r('app.media.OIP_C'))
    .backgroundImageSize(ImageSize.Cover)
  }
}