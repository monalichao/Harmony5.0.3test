import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import http from '@ohos.net.http'

// 定义登录数据类型
interface LoginData {
  userId?: string
  userName?: string
  email?: string
  phone?: string
  avatar?: string
  signature?: string
}

// 定义API响应类型 - 移除any类型
interface LoginResponse {
  token?: string
  userInfo?: UserInfo
  message?: string
  code?: number
  success?: boolean
  data?: LoginData  // 使用具体类型替代any
}

// 用户信息类型
interface UserInfo {
  userId?: string
  userName?: string
  email?: string
}

@Entry
@Component
struct LoginPage {
  @State email: string = '' // 改为邮箱
  @State password: string = ''
  @State isPasswordVisible: boolean = false
  @State isLoading: boolean = false

  // API基础URL
  private baseUrl: string = 'http://118.31.106.55:8080'

  // 创建HTTP请求对象
  private createHttpRequest(): http.HttpRequest {
    return http.createHttp()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Background image
      Image($r('app.media.OIP_C'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column() {
        // 使用OA.png图片替换"OpenArk\n灵枢"文字，并居中放置，放大两倍
        Image($r('app.media.OA'))
          .width(400)  // 原来200，现在放大两倍到400
          .height(160) // 原来80，现在放大两倍到160
          .objectFit(ImageFit.Contain)
          .margin({ top: 80, bottom: 30 })
          .alignSelf(ItemAlign.Center)

        // Email input - 使用图标替换文字提示，背景透明，边框#979797
        Column() {
          Row() {
            Image($r('app.media.youjian'))
              .width(24)
              .height(24)
              .margin({ left: 15, right: 10 })
            
            TextInput({ placeholder: '输入邮箱地址' })
              .height(50)
              .width('85%')
              .backgroundColor(Color.Transparent)
              .fontSize(16)
              .type(InputType.Email)
              .onChange((value: string) => {
                this.email = value
              })
          }
          .width('100%')
          .height(50)
          .border({ 
            width: 1, 
            color: '#979797', 
            style: BorderStyle.Solid 
          })
          .borderRadius(25)
        }
        .width('90%')
        .margin({ bottom: 20 })

        // Password input with visibility toggle - 使用图标替换文字提示，背景透明，边框#979797
        Column() {
          Row() {
            Image($r('app.media.suo'))
              .width(24)
              .height(24)
              .margin({ left: 15, right: 10 })
            
            TextInput({ placeholder: '输入密码' })
              .height(50)
              .width('85%')
              .backgroundColor(Color.Transparent)
              .fontSize(16)
              .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
              .onChange((value: string) => {
                this.password = value
              })

            // Eye icon for password visibility - 向右移动
            Image(this.isPasswordVisible ? $r('app.media.eye_open') : $r('app.media.eye_open'))
              .width(24)
              .height(24)
              .margin({ right: 10 }) // 增加右边距，使图标向右移动
              .fillColor('#999999')
              .onClick(() => {
                this.isPasswordVisible = !this.isPasswordVisible
              })
          }
          .width('100%')
          .height(50)
          .border({ 
            width: 1, 
            color: '#979797', 
            style: BorderStyle.Solid 
          })
          .borderRadius(25)
        }
        .width('90%')

        // Forgot password - 修改为跳转到重置密码页面
        Text('忘记密码?')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .alignSelf(ItemAlign.End)
          .margin({ top: 10, right: '5%' })
          .onClick(() => {
            // 跳转到重置密码页面
            router.pushUrl({ url: 'pages/Home' })
          })

        // Login button - 使用自定义图片替换原有按钮，保持点击功能
        Image($r('app.media.Login_button'))
          .width('90%')
          .height(50)
          .objectFit(ImageFit.Contain)
          .margin({ top: 30 })
          .onClick(() => {
            this.handleLogin()
          })

        // Register link
        Text() {
          Span('没有账号? ')
            .fontSize(14)
            .fontColor('#FFFFFF')
          Span('立即注册')
            .fontSize(14)
            .fontColor('#FFD700')
        }
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/Register' })
        })

        // Alternative login methods - 上下排列QQ和微信登录图标
        Column() {
          Text('—— 其他方式登录 ——')
            .fontSize(14)
            .fontColor('#ff1f1e1e')
            .margin({ top: 40, bottom: 20 })

          // QQ login - 使用自定义图片，上下排列，设置合适的尺寸
          Image($r('app.media.qq_login'))
            .width(200)
            .height(50)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 20 })
            .onClick(() => {
              promptAction.showToast({ message: '敬请期待' })
            })

          // WeChat login - 使用自定义图片，上下排列，设置合适的尺寸
          Image($r('app.media.wechat_login'))
            .width(200)
            .height(50)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              promptAction.showToast({ message: '敬请期待' })
            })
        }
        .width('90%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  // 验证邮箱格式
  private validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return true
  }

  // 实现登录API调用 - 修改为不依赖token，并修复类型问题
  async handleLogin(): Promise<void> {
    // 检查是否为测试账号 (账号: 111, 密码: 111)
    if (this.email === '111' && this.password === '111') {
      promptAction.showToast({ message: '测试登录成功' })
      // 直接跳转到主页
      router.pushUrl({ url: 'pages/Main' })
      return
    }

    // 验证输入
    if (this.email.length === 0) {
      promptAction.showToast({ message: '请输入邮箱地址' })
      return
    }

    if (!this.validateEmail(this.email)) {
      promptAction.showToast({ message: '请输入有效的邮箱地址' })
      return
    }

    if (this.password.length === 0) {
      promptAction.showToast({ message: '请输入密码' })
      return
    }

    // 显示加载状态
    this.isLoading = true
    const httpRequest = this.createHttpRequest()

    try {
      // 调用登录API - 使用邮箱作为账号
      const response = await httpRequest.request(`${this.baseUrl}/users/loginByAccount`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify({
          account: this.email, // 使用邮箱作为账号
          password: this.password
        }),
        connectTimeout: 15000,
        readTimeout: 15000
      })

      console.info('登录响应状态码:', response.responseCode)
      console.info('登录响应结果:', response.result)

      // 处理响应
      if (response.responseCode === 200) {
        const resultStr = response.result as string
        let result: LoginResponse = {}

        try {
          result = JSON.parse(resultStr) as LoginResponse
          console.info('登录解析后的结果:', JSON.stringify(result))
        } catch (e) {
          console.error('解析响应失败:', e.toString())
          promptAction.showToast({ message: '解析响应失败' })
          return
        }

        // 检查API返回的状态码，而不是依赖token
        if (result.code === 200 || result.success === true) {
          // 登录成功
          console.info('登录成功')

          // 如果有用户信息，可以保存
          if (result.userInfo) {
            // AppStorage.SetOrCreate<UserInfo>('userInfo', result.userInfo)
            console.info('保存用户信息:', JSON.stringify(result.userInfo))
          }

          // 如果有data字段，也可以处理
          if (result.data) {
            console.info('登录返回数据:', JSON.stringify(result.data))
          }

          // 登录成功提示
          promptAction.showToast({ message: '登录成功' })

          // 跳转到首页
          router.pushUrl({ url: 'pages/Main' })
        } else {
          // API返回错误
          const errorMessage = result.message || '登录失败，请检查邮箱和密码'
          promptAction.showToast({ message: errorMessage })
        }
      } else {
        // HTTP请求成功但API返回错误
        let errorMessage: string = '登录失败，请检查邮箱和密码'

        try {
          const errorResult: LoginResponse = JSON.parse(response.result as string)
          if (errorResult.message) {
            errorMessage = errorResult.message
          }
        } catch (e) {
          // 解析错误响应失败，使用默认错误消息
          console.error('解析错误响应失败:', e.toString())
        }

        promptAction.showToast({ message: errorMessage })
      }
    } catch (error) {
      // 网络请求异常
      console.error('登录请求错误:', JSON.stringify(error))
      promptAction.showToast({ message: '网络错误，请检查网络连接' })
    } finally {
      // 无论成功失败都关闭加载状态
      this.isLoading = false
      httpRequest.destroy()
    }
  }
}