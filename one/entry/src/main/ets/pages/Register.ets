import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import http from '@ohos.net.http'

// 定义注册请求参数类型 - 更新为新的API格式
interface RegisterRequest {
  username: string
  password: string
  email: string
  phone?: string
  avatar?: string
  signature?: string
  extra1?: string | null
  extra2?: string | null
  extra3?: string | null
  extra4?: string | null
}

// 定义API响应类型
interface ApiResponse {
  code: number
  message?: string
  data?: string
}

@Entry
@Component
struct RegisterPage {
  @State username: string = ''
  @State email: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State verificationCode: string = ''
  @State isPasswordVisible: boolean = false
  @State isConfirmPasswordVisible: boolean = false
  @State isLoading: boolean = false
  @State isSendingCode: boolean = false
  @State countdown: number = 60
  @State countdownTimer: number = -1

  // 验证消息
  @State passwordMsg: string = ''
  @State confirmPasswordMsg: string = ''
  @State verificationCodeMsg: string = ''

  // 更新API基础URL
  private baseUrl: string = 'http://118.31.106.55:8080'

  // 创建HTTP请求对象
  private createHttpRequest(): http.HttpRequest {
    return http.createHttp()
  }

  // 组件销毁时清理定时器
  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Background image
      Image($r('app.media.background'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 可滚动内容
      Scroll() {
        Column() {
          // 顶部导航栏
          Row() {
            Image($r('app.media.back'))
              .width(24)
              .height(24)
              .fillColor('#FFFFFF')
              .onClick(() => {
                router.back()
              })

            Text('用户注册')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ left: 16 })
              .textAlign(TextAlign.Center)
              .layoutWeight(1)

            // 占位符保持对称
            Row()
              .width(24)
              .height(24)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 40, bottom: 16 })

          // Logo
          Image($r('app.media.background'))
            .width(80)
            .height(80)
            .objectFit(ImageFit.Contain)
            .margin({ top: 20, bottom: 20 })

          // Welcome text
          Text('创建新账户')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ bottom: 30 })

          // Username input
          Column() {
            TextInput({ placeholder: '请输入用户名（5-10位字母数字）' })
              .height(50)
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(25)
              .padding({ left: 20, right: 20 })
              .fontSize(16)
              .onChange((value: string) => {
                this.username = value
              })
          }
          .width('90%')
          .margin({ bottom: 15 })

          // Email input
          Column() {
            TextInput({ placeholder: '请输入邮箱地址' })
              .height(50)
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(25)
              .padding({ left: 20, right: 20 })
              .fontSize(16)
              .type(InputType.Email)
              .onChange((value: string) => {
                this.email = value
              })
          }
          .width('90%')
          .margin({ bottom: 15 })

          // Password input - 修复眼睛图标
          Column() {
            Row() {
              TextInput({ placeholder: '请输入密码（6-12位字母数字）' })
                .height(50)
                .width('85%')
                .backgroundColor('#FFFFFF')
                .borderRadius(25)
                .padding({ left: 20 })
                .fontSize(16)
                .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
                .onChange((value: string) => {
                  this.password = value
                })
                .onBlur(() => {
                  this.checkPassword()
                })

              Image(this.isPasswordVisible ? $r('app.media.eye_open') : $r('app.media.eye_open'))
                .width(24)
                .height(24)
                .margin({ right: 20 })
                .fillColor('#999999')
                .onClick(() => {
                  this.isPasswordVisible = !this.isPasswordVisible
                })
            }
            .width('100%')
            .height(50)
            .backgroundColor('#FFFFFF')
            .borderRadius(25)

            Text(this.passwordMsg)
              .fontSize(12)
              .fontColor(this.passwordMsg === 'OK' ? '#00FF00' : '#FF0000')
              .margin({ top: 5, left: 20 })
              .alignSelf(ItemAlign.Start)
              .visibility(this.passwordMsg ? Visibility.Visible : Visibility.Hidden)
          }
          .width('90%')
          .margin({ bottom: 15 })

          // Confirm Password input - 修复眼睛图标
          Column() {
            Row() {
              TextInput({ placeholder: '确认密码' })
                .height(50)
                .width('85%')
                .backgroundColor('#FFFFFF')
                .borderRadius(25)
                .padding({ left: 20 })
                .fontSize(16)
                .type(this.isConfirmPasswordVisible ? InputType.Normal : InputType.Password)
                .onChange((value: string) => {
                  this.confirmPassword = value
                })
                .onBlur(() => {
                  this.checkConfirmPassword()
                })

              Image(this.isConfirmPasswordVisible ? $r('app.media.eye_open') : $r('app.media.eye_open'))
                .width(24)
                .height(24)
                .margin({ right: 20 })
                .fillColor('#999999')
                .onClick(() => {
                  this.isConfirmPasswordVisible = !this.isConfirmPasswordVisible
                })
            }
            .width('100%')
            .height(50)
            .backgroundColor('#FFFFFF')
            .borderRadius(25)

            Text(this.confirmPasswordMsg)
              .fontSize(12)
              .fontColor(this.confirmPasswordMsg === 'OK' ? '#00FF00' : '#FF0000')
              .margin({ top: 5, left: 20 })
              .alignSelf(ItemAlign.Start)
              .visibility(this.confirmPasswordMsg ? Visibility.Visible : Visibility.Hidden)
          }
          .width('90%')
          .margin({ bottom: 15 })

          // Verification code input
          Column() {
            Row() {
              TextInput({ placeholder: '输入验证码' })
                .height(50)
                .width('60%')
                .backgroundColor('#FFFFFF')
                .borderRadius(25)
                .padding({ left: 20, right: 10 })
                .fontSize(16)
                .onChange((value: string) => {
                  this.verificationCode = value
                })

              Button(this.isSendingCode ? `${this.countdown}s` : '发送验证码')
                .width('35%')
                .height(50)
                .fontSize(14)
                .backgroundColor(this.isSendingCode ? '#CCCCCC' : '#5DADE2')
                .fontColor('#FFFFFF')
                .borderRadius(25)
                .enabled(!this.isSendingCode && this.email.length > 0)
                .onClick(() => {
                  this.sendVerificationCode()
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            Text(this.verificationCodeMsg)
              .fontSize(12)
              .fontColor('#FF0000')
              .margin({ top: 5, left: 20 })
              .alignSelf(ItemAlign.Start)
              .visibility(this.verificationCodeMsg ? Visibility.Visible : Visibility.Hidden)
          }
          .width('90%')
          .margin({ bottom: 30 })

          // Register button
          Button({ type: ButtonType.Normal }) {
            Row() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#FFFFFF')
                  .margin({ right: 10 })
              }
              Text('注册')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .width('100%')
            .height('100%')
          }
          .width('90%')
          .height(50)
          .backgroundColor('#5DADE2')
          .borderRadius(25)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.register()
          })

          // Login link - 修复导航到Login页面
          Text() {
            Span('已有账号? ')
              .fontSize(14)
              .fontColor('#FFFFFF')
            Span('立即登录')
              .fontSize(14)
              .fontColor('#FFD700')
          }
          .margin({ top: 20, bottom: 40 })
          .onClick(() => {
            // 修复：直接跳转到Login页面而不是返回
            router.replaceUrl({ url: 'pages/Login' })
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  // 基本验证邮箱格式
  private validateEmail(email: string): boolean {
    const emailReg = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailReg.test(email)
  }

  // 基本验证用户名格式
  private validateUsername(username: string): boolean {
    const usernameReg = /^[a-zA-Z0-9]{5,10}$/
    return usernameReg.test(username)
  }

  // 检查密码
  checkPassword(): boolean {
    const passwordReg = /^[0-9a-zA-Z.]{6,12}$/
    if (!passwordReg.test(this.password)) {
      this.passwordMsg = '不合法'
      return false
    }
    this.passwordMsg = 'OK'
    return true
  }

  // 检查确认密码
  checkConfirmPassword(): boolean {
    if (this.password !== this.confirmPassword) {
      this.confirmPasswordMsg = '不一致'
      return false
    }
    this.confirmPasswordMsg = 'OK'
    return true
  }

  // 发送验证码 - 修复UI上下文问题
  sendVerificationCode(): void {
    console.info('开始发送验证码，邮箱:', this.email)

    // 基本邮箱格式验证
    if (!this.validateEmail(this.email)) {
      promptAction.showToast({ message: '请输入有效的邮箱地址' })
      return
    }

    // 立即更新UI状态
    this.isSendingCode = true

    // 使用Promise处理异步操作
    this.performSendVerificationCode()
      .then((success: boolean) => {
        if (success) {
          this.startCountdown()
          promptAction.showToast({ message: '验证码已发送' })
        } else {
          this.isSendingCode = false
          promptAction.showToast({ message: '发送验证码失败' })
        }
      })
      .catch((error: Error) => {
        console.error('发送验证码失败:', error.message)
        this.isSendingCode = false
        promptAction.showToast({ message: '网络错误，请检查网络连接' })
      })
  }

  // 执行发送验证码的异步操作
  private async performSendVerificationCode(): Promise<boolean> {
    const httpRequest = this.createHttpRequest()

    try {
      const url = `${this.baseUrl}/email/sendEmail?email=${encodeURIComponent(this.email)}`
      console.info('请求URL:', url)

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: 15000,
        readTimeout: 15000
      })

      console.info('响应状态码:', response.responseCode)
      console.info('响应结果:', response.result)

      if (response.responseCode === 200) {
        const resultStr = response.result as string
        const result = JSON.parse(resultStr) as ApiResponse
        console.info('解析后的结果:', JSON.stringify(result))

        return result.code === 200
      } else {
        console.error('HTTP请求失败，状态码:', response.responseCode)
        return false
      }
    } catch (error) {
      console.error('网络请求异常:', JSON.stringify(error))
      throw new Error('网络连接失败')
    } finally {
      httpRequest.destroy()
    }
  }

  // 开始倒计时
  startCountdown(): void {
    this.countdown = 60
    this.countdownTimer = setInterval(() => {
      this.countdown--
      if (this.countdown <= 0) {
        clearInterval(this.countdownTimer)
        this.isSendingCode = false
        this.countdownTimer = -1
      }
    }, 1000)
  }

  // 验证验证码
  verifyVerificationCode(inputCode: string): Promise<boolean> {
    console.info('开始验证验证码:', inputCode)

    return new Promise((resolve, reject) => {
      const httpRequest = this.createHttpRequest()

      const url = `${this.baseUrl}/email/verifyVerificationCode?verificationCode=${encodeURIComponent(inputCode)}&email=${encodeURIComponent(this.email)}`
      console.info('验证码验证URL:', url)

      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: 15000,
        readTimeout: 15000
      }).then((response) => {
        console.info('验证码响应状态码:', response.responseCode)
        console.info('验证码响应结果:', response.result)

        if (response.responseCode === 200) {
          try {
            const resultStr = response.result as string
            const result = JSON.parse(resultStr) as ApiResponse
            console.info('验证码解析后的结果:', JSON.stringify(result))

            if (result.code === 200) {
              resolve(true)
            } else {
              resolve(false)
            }
          } catch (parseError) {
            console.error('验证码响应解析失败:', parseError)
            resolve(false)
          }
        } else {
          console.error('验证码HTTP请求失败，状态码:', response.responseCode)
          resolve(false)
        }
      }).catch((error: Error) => {
        console.error('验证验证码网络错误:', error.message)
        reject(error)
      }).finally(() => {
        httpRequest.destroy()
      })
    })
  }

  // 注册
  register(): void {
    // 基本输入验证
    if (!this.username || this.username.length === 0) {
      promptAction.showToast({ message: '请输入用户名' })
      return
    }

    if (!this.validateUsername(this.username)) {
      promptAction.showToast({ message: '用户名格式不正确（5-10位字母数字）' })
      return
    }

    if (!this.email || this.email.length === 0) {
      promptAction.showToast({ message: '请输入邮箱' })
      return
    }

    if (!this.validateEmail(this.email)) {
      promptAction.showToast({ message: '请输入有效的邮箱地址' })
      return
    }

    if (!this.checkPassword()) {
      promptAction.showToast({ message: '密码格式不正确' })
      return
    }

    if (!this.checkConfirmPassword()) {
      promptAction.showToast({ message: '两次输入的密码不一致' })
      return
    }

    if (!this.verificationCode || this.verificationCode.length === 0) {
      promptAction.showToast({ message: '请输入验证码' })
      return
    }

    // 立即更新UI状态
    this.isLoading = true

    // 先验证验证码，再注册
    this.verifyVerificationCode(this.verificationCode)
      .then((isValid: boolean) => {
        if (isValid) {
          promptAction.showToast({ message: '验证码验证成功' })
          return this.performRegister()
        } else {
          promptAction.showToast({ message: '验证码错误，请重试' })
          this.isLoading = false
          return Promise.resolve(false)
        }
      })
      .then((success: boolean) => {
        if (success) {
          promptAction.showToast({ message: '注册成功快去登录吧' })
          // 修复：注册成功后跳转到Login页面
          router.replaceUrl({ url: 'pages/Login' })
        } else if (success !== undefined) {
          promptAction.showToast({ message: '注册失败' })
        }
        this.isLoading = false
      })
      .catch((error: Error) => {
        console.error('注册过程出错:', error.message)
        promptAction.showToast({ message: '注册失败，请稍后重试' })
        this.isLoading = false
      })
  }

  // 执行注册的异步操作 - 更新为新的API格式
  private async performRegister(): Promise<boolean> {
    const httpRequest = this.createHttpRequest()

    try {
      // 更新注册数据格式以匹配新的API
      const registerData: RegisterRequest = {
        username: this.username,
        password: this.password,
        email: this.email,
        phone: '', // 可选字段，暂时为空
        avatar: 'https://example.com/avatar.jpg', // 默认头像
        signature: '热爱生活，享受编程！', // 默认签名
        extra1: null,
        extra2: null,
        extra3: null,
        extra4: null
      }

      console.info('注册数据:', JSON.stringify(registerData))

      // 更新API端点为 /users/registry
      const response = await httpRequest.request(`${this.baseUrl}/users/registry`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(registerData),
        connectTimeout: 15000,
        readTimeout: 15000
      })

      console.info('注册响应状态码:', response.responseCode)
      console.info('注册响应结果:', response.result)

      if (response.responseCode === 200) {
        const resultStr = response.result as string
        const result = JSON.parse(resultStr) as ApiResponse
        console.info('注册解析后的结果:', JSON.stringify(result))

        return result.code === 200
      } else {
        console.error('注册HTTP请求失败，状态码:', response.responseCode)
        return false
      }
    } catch (error) {
      console.error('注册网络错误:', JSON.stringify(error))
      throw new Error('注册网络连接失败')
    } finally {
      httpRequest.destroy()
    }
  }
}