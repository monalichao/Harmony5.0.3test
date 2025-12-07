import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';

@Component
struct ChatBubble {
  @Prop message: ChatMessage = { id: 0, content: '', isUser: false, timestamp: new Date() };
  @Prop isUser: boolean = false;

  build() {
    Row() {
      if (this.isUser) {
        // 用户消息靠右
        Blank()
        Row() {
          Column() {
            Text(this.message.content)
              .fontSize(16)
              .fontColor(Color.White)
              .padding(15)
              .backgroundColor('#007AFF')
              .borderRadius(20)
          }
          
          // 用户头像（不使用圆角裁剪，向右移动）
          Image($r('app.media.home_unselect'))
            .width(30)
            .height(30)
            .margin({ top: 15, left: 20 }) // 增加左边距使头像更靠右
        }
        .width('80%')
        .justifyContent(FlexAlign.End)
      } else {
        // AI消息靠左
        Row() {
          // 机器人头像（不使用圆角裁剪）
          Image($r('app.media.Agent'))
            .width(30)
            .height(30)
            .margin({ right: 10, top: 15, left: -20 }) // 左移头像位置
          
          Column() {
            Text(this.message.content)
              .fontSize(16)
              .fontColor(Color.Black)
              .padding(15)
              .backgroundColor('#F0F0F0')
              .borderRadius(20)
          }
        }
        .width('80%')
        .justifyContent(FlexAlign.Start)
      }
    }
    .margin({ top: 20, bottom: 20 }) // 扩大上下间距
  }
}

interface ChatMessage {
  id: number;
  content: string;
  isUser: boolean;
  timestamp: Date;
}

@Entry
@Component
struct AIChat {
  // 聊天消息列表
  @State messages: ChatMessage[] = [
    {
      id: 1,
      content: '您好！我是AI助手，有什么我可以帮您的吗？',
      isUser: false,
      timestamp: new Date()
    },
    {
      id: 2,
      content: '你好，我想了解一下这个水下机器人。',
      isUser: true,
      timestamp: new Date()
    },
    {
      id: 3,
      content: '这个水下机器人具备高清摄像、深度探测和远程操控功能。它可以在水下执行检查、拍摄和数据收集任务。',
      isUser: false,
      timestamp: new Date()
    }
  ];

  // 输入框内容
  @State inputMessage: string = '';
  // 添加加载状态
  @State isLoading: boolean = false;

  // 发送消息
  sendMessage() {
    if (this.inputMessage.trim() !== '') {
      // 添加用户消息
      const userMessage: ChatMessage = {
        id: this.messages.length + 1,
        content: this.inputMessage,
        isUser: true,
        timestamp: new Date()
      };
      this.messages.push(userMessage);

      // 设置加载状态
      this.isLoading = true;

      // 调用AI API获取回复
      this.callAIChatAPI(this.inputMessage)
        .then((response: string) => {
          const aiResponse: ChatMessage = {
            id: this.messages.length + 1,
            content: response,
            isUser: false,
            timestamp: new Date()
          };
          this.messages.push(aiResponse);
          this.isLoading = false;
        })
        .catch((error: Error) => {
          const errorMessage: ChatMessage = {
            id: this.messages.length + 1,
            content: '抱歉，我暂时无法回答您的问题，请稍后再试。',
            isUser: false,
            timestamp: new Date()
          };
          this.messages.push(errorMessage);
          this.isLoading = false;
        });

      // 清空输入框
      this.inputMessage = '';
    }
  }

  // 调用AI聊天API
  async callAIChatAPI(userInput: string): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        // 创建http请求
        let httpRequest = http.createHttp();
        
        // 定义消息类型
        interface Message {
          role: string;
          content: string;
        }
        
        // 定义请求体结构
        interface RequestBody {
          model: string;
          messages: Message[];
          stream: boolean;
        }
        
        // 定义HTTP请求选项
        interface RequestOptions {
          method: http.RequestMethod;
          header: object;
          extraData: string | object;
        }
        
        // 定义请求头类型
        interface RequestHeader {
          'Content-Type': string;
          'Authorization': string;
        }
        
        // 构造消息数组
        const messages: Message[] = [
          { role: "system", content: "你是一个 helpful 的 AI 助手，用中文回答。" },
          { role: "user", content: userInput }
        ];
        
        // 构造请求体
        const requestBody: RequestBody = {
          model: "deepseek-chat",
          messages: messages,
          stream: false
        };

        // 配置请求参数
        const header: RequestHeader = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sk-fb272744735343f3bb4cdafb3deb9b58'
        };
        
        const options: RequestOptions = {
          method: http.RequestMethod.POST,
          header: header,
          extraData: JSON.stringify(requestBody)
        };

        // 发起网络请求
        httpRequest.request(
          "https://api.deepseek.com/v1/chat/completions",
          options,
          (err, data) => {
            if (err) {
              console.error('网络请求失败:', err);
              reject(new Error('网络请求失败'));
              return;
            }
            
            try {
              // 确保data.result是字符串类型后再解析
              let resultStr: string;
              if (typeof data.result === 'string') {
                resultStr = data.result;
              } else {
                resultStr = JSON.stringify(data.result);
              }
              
              // 定义响应结构类型
              interface Message {
                role: string;
                content: string;
              }
              
              interface Choice {
                index: number;
                message: Message;
                finish_reason: string;
              }
              
              interface APIResponse {
                choices: Choice[];
              }
              
              // 明确指定解析结果的类型
              let response: APIResponse = JSON.parse(resultStr);
              let reply: string = response.choices[0].message.content;
              resolve(reply);
            } catch (parseError) {
              console.error('解析响应失败:', parseError);
              reject(new Error('解析响应失败'));
            }
            
            // 销毁请求对象
            httpRequest.destroy();
          }
        );
      } catch (error) {
        console.error('调用AI API时出错:', error);
        reject(error);
      }
    });
  }

  // 生成AI回复（静态内容）
  generateAIResponse(userMessage: string): string {
    const responses = 'AIchat功能待开发';

    return responses;
  }

  build() {
    Column() {
      // 顶部标题栏 (透明背景)
      Row() {
        Image($r('app.media.trans_unselect'))
          .width(24)
          .height(24)
          .margin({ right: 10 })
          .onClick(() => {
            router.back()
          })

        Text('AI 助手')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()
        
        // 右上角图标排列 (从右到左)
        Row() {
          Image($r('app.media.svg2'))
            .width(32)
            .height(32)
            .onClick(() => {
              // 显示提示框
              promptAction.showToast({
                message: '功能待开发',
                duration: 2000
              })
            })
          
          Image($r('app.media.svg1'))
            .width(32)
            .height(32)
            .margin({ left: 16 })
            .onClick(() => {
              // 显示提示框
              promptAction.showToast({
                message: '功能待开发',
                duration: 2000
              })
            })
          
          Image($r('app.media.svg'))
            .width(32)
            .height(32)
            .margin({ left: 16 })
            .onClick(() => {
              // 显示提示框
              promptAction.showToast({
                message: '功能待开发',
                duration: 2000
              })
            })
        }
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })
      .backgroundColor('#00000000') // 透明背景

      // 分隔线
      Rect()
        .width('100%')
        .height(1)
        .fill('#B7B8C5')
        .margin({ top: -8, bottom: 8 })

      // 聊天记录区域
      Scroll() {
        Column() {
          ForEach(this.messages, (message: ChatMessage, index: number) => {
            ChatBubble({ message: message, isUser: message.isUser })
          }, (message: ChatMessage) => message.id.toString())
          
          // 添加加载指示器
          if (this.isLoading) {
            Row() {
              Image($r('app.media.Agent'))
                .width(30)
                .height(30)
                .margin({ right: 10, top: 15, left: -20 })
              
              Column() {
                Text('正在输入...')
                  .fontSize(16)
                  .fontColor(Color.Black)
                  .padding(15)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(20)
              }
            }
            .width('80%')
            .justifyContent(FlexAlign.Start)
            .margin({ top: 20, bottom: 20 })
          }
        }
        .padding({ left: 10, right: 10, top: 0 })
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
      
      // 输入区域
      Row() {
        TextInput({ placeholder: '请输入消息...', text: this.inputMessage })
          .onChange((value: string) => {
            this.inputMessage = value;
          })
          .layoutWeight(1)
          .height(40)
          .fontSize(16)
          .padding({ left: 15, right: 15 })
          .backgroundColor('#F5F5F5')
          .borderRadius(20)

        Button('发送')
          .fontSize(16)
          .fontColor('#007AFF')
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            this.sendMessage();
          })
          .margin({ left: 10 })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#E5E5E5' }) // 修复边框设置

      // 功能图标区域
      Row() {
        // 照片图标
        Image($r('app.media.photo'))
          .width(90)
          .height(100)
          .margin({ left: 15, right: 15, top: 15 })
          .onClick(() => {
            promptAction.showToast({
              message: '照片功能待开发',
              duration: 2000
            })
          })

        // 拍照图标
        Image($r('app.media.camera'))
          .width(90)
          .height(100)
          .margin({ left: 15, right: 15, top: 15 })
          .onClick(() => {
            promptAction.showToast({
              message: '拍照功能待开发',
              duration: 2000
            })
          })

        // 文件图标
        Image($r('app.media.file'))
          .width(90)
          .height(100)
          .margin({ left: 15, right: 15, top: 15 })
          .onClick(() => {
            promptAction.showToast({
              message: '文件功能待开发',
              duration: 2000
            })
          })

        // 语音图标
        Image($r('app.media.voice'))
          .width(90)
          .height(100)
          .margin({ left: 15, right: 15, top: 15 })
          .onClick(() => {
            promptAction.showToast({
              message: '语音功能待开发',
              duration: 2000
            })
          })
      }
      .width('100%')
      .padding({ left: 5, right: 10, bottom: 10 })
      .backgroundColor('#B7B9BD')
    }
    .width('100%')
    .height('100%')
    .backgroundImage($r('app.media.OIP_C'))
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition({ x: 0, y: 0 })
  }
}