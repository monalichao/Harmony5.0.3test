import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import http from '@ohos.net.http';
import { AppStorageV2 } from '@kit.ArkUI';

const AI_RESULT_STORAGE_KEY: string = 'deal_ai_result';

@Component
export struct Trans {
  @State videoSrc: string = '';
  @State isPlaying: boolean = false;
  @State errorMessage: string = '';
  @State playerState: string = 'idle';
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State streamUrl: string = 'https://gossv-vcg.cfp.cn/videos/mts_videos/medium/temp/VCG42N1147239881.mp4';
  @State downloadStatus: string = '未请求数据流';
  @State captureStatus: string = '未抓取帧';
  @State aiResult: string = '尚未同步';
  avPlayer: media.AVPlayer | null = null;

  aboutToAppear(): void {
    this.initAVPlayer();
    this.pullAIResult();
  }

  aboutToDisappear(): void {
    this.releasePlayer();
  }

  private pullAIResult(): void {
    // 使用AppStorage获取存储的AI结果
    const stored: String | undefined = AppStorageV2.connect(String, AI_RESULT_STORAGE_KEY, () => new String('尚未同步'));
    if (stored !== undefined) {
      const stringValue: string = stored.toString();
      if (stringValue && stringValue !== this.aiResult) {
        this.aiResult = stringValue;
      }
    }
  }

  async initAVPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();

      this.avPlayer.on('stateChange', (state: string) => {
        this.playerState = state;

        switch (state) {
          case 'prepared':
            this.duration = this.avPlayer?.duration || 0;
            break;
          case 'playing':
            this.isPlaying = true;
            break;
          case 'paused':
          case 'stopped':
            this.isPlaying = false;
            break;
          case 'completed':
            this.isPlaying = false;
            this.currentTime = 0;
            break;
        }
      });

      this.avPlayer.on('timeUpdate', (time: number) => {
        this.currentTime = time;
      });

      this.avPlayer.on('endOfStream', () => {
        this.isPlaying = false;
        this.currentTime = 0;
        this.playerState = 'completed';
      });

      this.avPlayer.on('error', (err: BusinessError) => {
        this.errorMessage = `播放错误: ${err.message}`;
        this.isPlaying = false;
      });
    } catch (err) {
      const error = err as BusinessError;
      this.errorMessage = `初始化播放器失败: ${error.message}`;
    }
  }

  async loadMedia(url: string): Promise<void> {
    if (!this.avPlayer) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    try {
      this.videoSrc = url;
      this.avPlayer.url = url;
    } catch (err) {
      const error = err as BusinessError;
      this.errorMessage = `加载媒体失败: ${error.message}`;
    }
  }

  async startStreamPlayback(): Promise<void> {
    await this.loadMedia(this.streamUrl);
    if (!this.isPlaying) {
      await this.playOrPause();
    }
  }

  async playOrPause(): Promise<void> {
    if (!this.avPlayer) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    try {
      if (this.isPlaying) {
        await this.avPlayer.pause();
      } else {
        if (!this.videoSrc) {
          await this.loadMedia(this.streamUrl);
        }
        await this.avPlayer.play();
      }
    } catch (err) {
      const error = err as BusinessError;
      this.errorMessage = `播放/暂停失败: ${error.message}`;
    }
  }

  async stopVideoStream(): Promise<void> {
    if (this.avPlayer && this.isPlaying) {
      try {
        await this.avPlayer.stop();
        this.isPlaying = false;
      } catch (err) {
        const error = err as BusinessError;
        this.errorMessage = `停止播放失败: ${error.message}`;
      }
    }
  }

  async seekTo(time: number): Promise<void> {
    if (!this.avPlayer) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    try {
      if (this.playerState === 'prepared' || this.playerState === 'playing' ||
        this.playerState === 'paused' || this.playerState === 'completed') {
        await this.avPlayer.seek(time);
      } else {
        this.errorMessage = `当前状态不支持跳转: ${this.playerState}`;
      }
    } catch (err) {
      const error = err as BusinessError;
      this.errorMessage = `跳转失败: ${error.message}`;
    }
  }

  releasePlayer(): void {
    if (this.avPlayer) {
      this.avPlayer.release();
      this.avPlayer = null;
    }
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  async fetchStreamSample(): Promise<void> {
    const url = this.streamUrl.trim();
    if (!url) {
      this.downloadStatus = '请先输入数据流地址';
      return;
    }

    const httpClient = http.createHttp();
    try {
      const response = await httpClient.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 8000
      });

      const size = this.getPayloadLength(response.result);
      this.downloadStatus = `已请求数据流，接收 ${size} 字节`;
    } catch (error) {
      const bizError = error as BusinessError;
      this.downloadStatus = `请求失败: ${bizError.message}`;
    } finally {
      httpClient.destroy();
    }
  }

  private getPayloadLength(payload: string | ArrayBuffer | object | undefined): number {
    if (typeof payload === 'string') {
      return payload.length;
    }
    if (payload instanceof ArrayBuffer) {
      return payload.byteLength;
    }
    return 0;
  }

  captureFrameInfo(): void {
    if (!this.avPlayer) {
      this.captureStatus = '无法抓取：播放器尚未就绪';
      return;
    }
    if (!this.isPlaying) {
      this.captureStatus = '请先启动播放再尝试抓帧';
      return;
    }
    this.captureStatus = `关键帧信息已缓存 (时间戳 ${this.formatTime(this.currentTime)})`;
  }

  build() {
    Column() {
      // 顶部标题区域
      Column() {
        Text('DATA・STREAM 控制台')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Text('接入实时数据流，回放 AI 推理结果')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })
      
      Scroll() {
        Column() {
          // 数据流配置区
          Column() {
            Text('数据流配置')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .width('100%')
              .textAlign(TextAlign.Start)

            Column() {
              TextInput({ placeholder: '请输入流媒体地址', text: this.streamUrl })
                .onChange((value: string) => {
                  this.streamUrl = value;
                })
                .width('100%')
                .height(40)
                .borderRadius(4)
                .margin({ bottom: 12 })
              
              Row() {
                Button('拉流并播放')
                  .backgroundColor($r('app.color.primary_blue'))
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .onClick(() => {
                    this.startStreamPlayback();
                  })
                  .layoutWeight(1)

                Button('仅加载')
                  .margin({ left: 10 })
                  .backgroundColor($r('app.color.card_background'))
                  .fontColor($r('app.color.text_primary'))
                  .borderRadius(8)
                  .onClick(() => {
                    this.loadMedia(this.streamUrl);
                  })
                  .layoutWeight(1)
              }
              .width('100%')
              .height(40)
            }
          }
          .width('90%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .margin({ bottom: 18 })

          // 视频播放区域
          Column() {
            Text('视频播放')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .width('100%')
              .textAlign(TextAlign.Start)
            
            // 使用Video组件播放视频
            Video({
              src: this.streamUrl,
              previewUri: '',
            })
            .width('100%')
            .height(150)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 10 })
            .onStart(() => {
              console.log('视频开始播放');
              this.isPlaying = true;
            })
            .onPause(() => {
              console.log('视频暂停');
              this.isPlaying = false;
            })
            .onFinish(() => {
              console.log('视频播放完成');
              this.isPlaying = false;
            })
            .onError(() => {
              console.log('视频播放出错');
              this.errorMessage = '视频播放出错';
            })
            
            Column() {
              Text(`播放器状态: ${this.isPlaying ? '播放中' : '已暂停'}`)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .textAlign(TextAlign.Start)

              if (this.errorMessage) {
                Text(this.errorMessage)
                  .fontSize(12)
                  .fontColor('#ff4d4f')
                  .margin({ top: 6 })
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }

              Row() {
                Button(this.isPlaying ? '暂停' : '播放')
                  .backgroundColor($r('app.color.primary_blue'))
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .onClick(() => {
                    // 视频控制通过Video组件自身处理
                  })
                  .layoutWeight(1)
                  .margin({ right: 10 })

                Button('停止')
                  .backgroundColor($r('app.color.card_background'))
                  .fontColor($r('app.color.text_primary'))
                  .borderRadius(8)
                  .onClick(() => {
                    // 视频控制通过Video组件自身处理
                  })
                  .layoutWeight(1)
                  .margin({ right: 10 })

                Button('刷新AI结果')
                  .backgroundColor($r('app.color.card_background'))
                  .fontColor($r('app.color.text_primary'))
                  .borderRadius(8)
                  .onClick(() => {
                    this.pullAIResult();
                  })
                  .layoutWeight(1)
              }
              .width('100%')
              .height(40)
              .margin({ top: 18 })
            }
          }
          .width('90%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .margin({ bottom: 18 })

          // 帧操作区
          Column() {
            Text('帧操作')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .width('100%')
              .textAlign(TextAlign.Start)

            Row() {
              Button('抓取关键帧')
                .backgroundColor($r('app.color.primary_purple'))
                .fontColor(Color.White)
                .borderRadius(8)
                .onClick(() => {
                  this.captureFrameInfo();
                })
                .layoutWeight(1)

              Button('请求数据流')
                .margin({ left: 10 })
                .backgroundColor($r('app.color.primary_cyan'))
                .fontColor(Color.White)
                .borderRadius(8)
                .onClick(() => {
                  this.fetchStreamSample();
                })
                .layoutWeight(1)
            }
            .width('100%')
            .height(40)
            .margin({ bottom: 10 })

            Column() {
              Text(this.captureStatus)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 4 })

              Text(this.downloadStatus)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Start)
            }
          }
          .width('90%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .margin({ bottom: 18 })

          // 结果展示区
          Column() {
            Text('AI 分析结果')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 10 })
              .width('100%')
              .textAlign(TextAlign.Start)

            Scroll() {
              Text(this.aiResult)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .textAlign(TextAlign.Start)
                .width('100%')
            }
            .width('100%')
            .height(200)
            .border({ width: 1, color: '#dddddd', style: BorderStyle.Solid })
            .borderRadius(8)
            .padding(12)
          }
          .width('90%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .margin({ bottom: 20 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}