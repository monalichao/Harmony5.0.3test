import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

// 定义菜单项接口
interface MenuItem {
  icon: Resource;
  title: string;
  onClick: () => void;
}

// 定义导航项接口
interface NavItem {
  icon: Resource;
  activeIcon: Resource;
  label: string;
  url: string;
}


@Component
export struct Mine {
  @State nickname: string = '昵称'
  @State phoneNumber: string = '12345678912(账号)'
  @State avatarUrl: Resource = $r('app.media.home_unselect')
  @State isEditingNickname: boolean = false
  @State newNickname: string = ''
  @State showLogoutDialog: boolean = false



  // 菜单项列表 - 添加AI助手
  private menuItems: MenuItem[] = [
    {
      icon: $r('app.media.home_unselect'),
      title: 'AI助手',
      onClick: () => {
        // 跳转到AI助手页面
        router.pushUrl({
          url: 'pages/AIchat'
        }).catch((error: Error) => {
          promptAction.showToast({
            message: '页面跳转失败',
            duration: 2000
          })
        })
      }
    },
    {
      icon: $r('app.media.user_info'),
      title: '个人信息',
      onClick: () => {
        promptAction.showToast({
          message: '个人信息功能开发中',
          duration: 2000
        })
      }
    },
    {
      icon: $r('app.media.help'),
      title: '帮助中心',
      onClick: () => {
        promptAction.showToast({
          message: '帮助中心功能开发中',
          duration: 2000
        })
      }
    },
    {
      icon: $r('app.media.settings'),
      title: '设置',
      onClick: () => {
        promptAction.showToast({
          message: '设置功能开发中',
          duration: 2000
        })
      }
    }
  ]

  // 编辑昵称
  startEditNickname(): void {
    this.newNickname = this.nickname
    this.isEditingNickname = true
  }

  // 保存昵称
  saveNickname(): void {
    if (this.newNickname.trim() !== '') {
      this.nickname = this.newNickname
    }
    this.isEditingNickname = false
  }

  // 切换账号
  switchAccount(): void {
    promptAction.showToast({
      message: '切换账号功能锐意开发中，敬请期待',
      duration: 2000
    })
  }

  // 退出登录
  logout(): void {
    this.showLogoutDialog = true
  }

  // 确认退出
  confirmLogout(): void {
    this.showLogoutDialog = false
    // 跳转到登录页面
    router.pushUrl({
      url: 'pages/Login'
    }).catch((error: Error) => {
      promptAction.showToast({
        message: '页面跳转失败',
        duration: 2000
      })
    })
  }

  @Builder
  MenuItemBuilder(item: MenuItem) {
    Row() {
      Image(item.icon)
        .width(24)
        .height(24)
        .fillColor(item.title === 'AI助手' ? '#4A90E2' : '#666666')
        .margin({ right: 16 })

      Text(item.title)
        .fontSize(16)
        .fontColor(item.title === 'AI助手' ? '#4A90E2' : '#333333')
        .fontWeight(item.title === 'AI助手' ? FontWeight.Medium : FontWeight.Normal)

      Blank()

      Image($r('app.media.arrow_right'))
        .width(20)
        .height(20)
        .fillColor(item.title === 'AI助手' ? '#4A90E2' : '#999999')
    }
    .width('100%')
    .height(120)
    .backgroundColor(item.title === 'AI助手' ? '#E6F2FF' : '#E6F7F2')
    .borderRadius(16)
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 12 })
    .onClick(() => {
      item.onClick()
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }



  build() {
    Stack() {
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.back'))
            .width(24)
            .height(24)
            .onClick(() => {
              router.back()
            })

          Text('个人中心')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 16 })

          Blank()

          // 将"修改密码"改为"主页"，并在右侧添加右箭头图标
          Row() {
            Text('主页')
              .fontSize(14)
              .fontColor('#666666')
            
            Image($r('app.media.arrow_right'))
              .width(16)
              .height(16)
              .margin({ left: 4 })
          }
          .onClick(() => {
            // 点击主页显示提示信息
            promptAction.showToast({
              message: '主页功能开发中',
              duration: 2000
            })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        // 头像和昵称区域 - 修改为水平排列
        Row() {
          // 头像 - 不再使用圆形边框，缩小尺寸到70x70
          Image(this.avatarUrl)
            .width(70)
            .height(70)
            .margin({ left: 16, right: 16 })

          Column() {
            // 昵称和编辑按钮
            if (this.isEditingNickname) {
              // 编辑状态
              Row() {
                TextInput({ text: this.newNickname })
                  .width(150)
                  .height(60)
                  .fontSize(36)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor('#F0F5FF')
                  .borderRadius(8)
                  .onChange((value: string) => {
                    this.newNickname = value
                  })

                Button('保存')
                  .width(60)
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#4A90E2')
                  .borderRadius(18)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.saveNickname()
                  })
              }
            } else {
              // 显示状态
              Row() {
                Text(this.nickname)
                  .fontSize(30)
                  .fontWeight(FontWeight.Medium)

                Image($r('app.media.edit'))
                  .width(20)
                  .height(20)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.startEditNickname()
                  })
              }
            }
            
            // 移除账号显示
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)

        // 灯泡图标
        Row() {
          Image($r("app.media.moon"))
            .width(40)
            .height(40)
            .fillColor('#4A90E2')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        // 菜单项列表 - 修改为2x2网格布局，增加宽度
        Grid() {
          ForEach(this.menuItems, (item: MenuItem, index: number) => {
            GridItem() {
              this.MenuItemBuilder(item)
            }
            .width('95%')
            .height(120)
          }, (item: MenuItem, index: number) => `${item.title}_${index}`)
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(20)
        .columnsGap(20)
        .width('95%')
        .layoutWeight(1)
        .margin({ top: 16 })



        // 底部按钮
        Row() {
          Button('切换账号')
            .width('48%')
            .height(50)
            .backgroundColor('#FFFFFF')
            .borderRadius(25)
            .fontColor('#333333')
            .border({ width: 1, color: '#DDDDDD', style: BorderStyle.Solid })
            .onClick(() => {
              this.switchAccount()
            })

          Button('退出登录')
            .width('48%')
            .height(50)
            .backgroundColor('#7DDEF5')
            .borderRadius(25)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.logout()
            })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 24 })


      }
      .width('100%')
      .height('100%')
      // 将背景颜色设置为透明，使其与tabs背景保持一致
      .backgroundColor(Color.Transparent)
      .alignItems(HorizontalAlign.Center)

      // 退出登录确认对话框
      if (this.showLogoutDialog) {
        Column() {
          Text('确认退出登录')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 24 })

          Text('您确定要退出当前账号吗？')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 24 })

          Row() {
            Button('取消')
              .width('48%')
              .height(45)
              .backgroundColor('#F0F0F0')
              .borderRadius(22.5)
              .fontColor('#333333')
              .onClick(() => {
                this.showLogoutDialog = false
              })

            Button('确认')
              .width('48%')
              .height(45)
              .backgroundColor('#4A90E2')
              .borderRadius(22.5)
              .fontColor('#FFFFFF')
              .onClick(() => {
                this.confirmLogout()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('80%')
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        // 修复后的正确代码
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.2)', offsetX: 0, offsetY: 4 })

      }
    }
    .width('100%')
    .height('100%')
  }
}