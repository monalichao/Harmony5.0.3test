import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { media } from '@kit.MediaKit';

type DetectionMode = 'crack' | 'target';
type ResponsePayload = string | number | boolean | null | object | Array<object>;

interface DetectionRequestOptions {
  remark?: string;
}

interface DetectionRequestPayload {
  type: DetectionMode;
  imageUrl: string;
  apiKey?: string;
  options?: DetectionRequestOptions;
}

interface DetectionApiResponse {
  code?: number;
  success?: boolean;
  message?: string;
  data?: ResponsePayload;
  result?: ResponsePayload;
}

interface DetectionEndpoints {
  crack: string;
  target: string;
}

interface ModeOption {
  value: DetectionMode;
  label: string;
  hint: string;
}

const DETECTION_ENDPOINTS: DetectionEndpoints = {
  crack: '/multi/face',
  target: '/v1/target-recognition'
};

const MODE_OPTIONS: ModeOption[] = [
  { value: 'crack', label: '裂缝检测', hint: '物体表面裂缝检测' },
  { value: 'target', label: '目标识别', hint: '识别关键设备 / 目标物' }
];

const MODEL_NAME: string = 'DATA · DETECT';
const MODEL_DESC: string = '实时融合裂缝与目标识别能力';
const API_BASE_URL: string = 'https://lxyichang.market.alicloudapi.com';
const API_KEY: string = '840e1628a99f4f8ca4c35e872111066b'; // TODO: 在此填入你的真实密钥
const AI_RESULT_STORAGE_KEY: string = 'deal_ai_result';

@Component
export struct Deal {
  @State detectionMode: DetectionMode = 'crack';
  @State imageUrl: string = 'https://gossv-vcg.cfp.cn/videos/mts_videos/medium/temp/VCG42N1147239881.mp4';//'https://img95.699pic.com/photo/50618/9137.jpg_wh860.jpg';
  @State remark: string = '';
  @State resultText: string = '等待检测...';
  @State lastLatency: number = 0;
  @State isLoading: boolean = false;
  @State avPlayer: media.AVPlayer | null = null; // 添加视频播放器
  @State isPlaying: boolean = false; // 添加播放状态
  @State playerErrorMessage: string = ''; // 添加播放错误信息
  private controller: VideoController = new VideoController()

  aboutToAppear(): void {
    this.syncAIResult(this.resultText);
    this.initAVPlayer(); // 初始化播放器
  }
  
  aboutToDisappear(): void {
    this.releasePlayer(); // 释放播放器资源
  }
  
  // 初始化AVPlayer
  async initAVPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      
      // 监听播放器状态变化
      this.avPlayer.on('stateChange', (state: string) => {
        console.log('播放器状态变化:', state);
        switch (state) {
          case 'initialized':
            // initialized状态后需要调用prepare方法
            this.preparePlayer();
            break;
          case 'prepared':
            // 准备好后自动开始播放
            this.tryPlayWhenPrepared();
            break;
          case 'playing':
            this.isPlaying = true;
            this.playerErrorMessage = '';
            break;
          case 'paused':
          case 'stopped':
            this.isPlaying = false;
            break;
          case 'completed':
            this.isPlaying = false;
            break;
          case 'error':
            this.playerErrorMessage = '视频播放出错';
            this.isPlaying = false;
            break;
        }
      });
      
      // 监听播放错误
      this.avPlayer.on('error', (err: BusinessError) => {
        this.playerErrorMessage = `播放错误: ${err.message}`;
        this.isPlaying = false;
        console.error('播放器错误:', err);
      });
    } catch (err) {
      const error = err as BusinessError;
      this.playerErrorMessage = `初始化播放器失败: ${error.message}`;
      console.error('初始化播放器失败:', error);
    }
  }
  
  // 准备播放器
  private async preparePlayer(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.prepare();
      } catch (err) {
        const error = err as BusinessError;
        this.playerErrorMessage = `准备播放失败: ${error.message}`;
        console.error('准备播放失败:', error);
      }
    }
  }
  
  // 在prepared状态时尝试播放
  private async tryPlayWhenPrepared(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.play();
      } catch (err) {
        const error = err as BusinessError;
        this.playerErrorMessage = `播放失败: ${error.message}`;
        console.error('播放失败:', error);
      }
    }
  }
  
  // 设置播放URL（支持HTTP/HTTPS和HLS流媒体）
  private async setupMediaUrl(url: string): Promise<void> {
    if (!this.avPlayer) {
      this.playerErrorMessage = '播放器未初始化';
      return;
    }
    
    try {
      // 对于HTTP/HTTPS媒体资源和HLS媒体资源，直接设置URL
      this.avPlayer.url = url;
    } catch (err) {
      const error = err as BusinessError;
      this.playerErrorMessage = `设置播放URL失败: ${error.message}`;
      console.error('设置播放URL失败:', error);
    }
  }
  
  // 设置带请求头的播放URL（适用于需要校验HTTP请求头信息的情况）
  private async setupMediaUrlWithHeaders(url: string, headers: Record<string, string>): Promise<void> {
    if (!this.avPlayer) {
      this.playerErrorMessage = '播放器未初始化';
      return;
    }
    
    try {
      // 创建MediaSource实例对象，设置媒体来源，定制HTTP请求
      const mediaSource = media.createMediaSourceWithUrl(url, headers);
      
      // 设置播放策略，设置缓冲区数据量为3秒
      const playbackStrategy: media.PlaybackStrategy = {
        preferredWidth: 1, 
        preferredHeight: 2, 
        preferredBufferDuration: 3, 
        preferredHdr: false
      };
      
      // 为avPlayer设置媒体来源和播放策略
      this.avPlayer.setMediaSource(mediaSource, playbackStrategy);
    } catch (err) {
      const error = err as BusinessError;
      this.playerErrorMessage = `设置带请求头的播放URL失败: ${error.message}`;
      console.error('设置带请求头的播放URL失败:', error);
    }
  }
  
  // 释放播放器资源
  releasePlayer(): void {
    if (this.avPlayer) {
      this.avPlayer.release();
      this.avPlayer = null;
    }
  }
  
  // 播放或暂停视频
  async togglePlay(): Promise<void> {
    if (!this.avPlayer) {
      this.playerErrorMessage = '播放器未初始化';
      return;
    }
    
    try {
      if (this.isPlaying) {
        await this.avPlayer.pause();
      } else {
        // 如果还没有设置URL或者URL改变了，需要重新设置
        if (!this.avPlayer.url || this.avPlayer.url !== this.imageUrl) {
          // 判断是否需要设置请求头（可根据实际需求扩展）
          if (this.imageUrl.includes('.m3u8')) {
            // 对于HLS流媒体，可以设置特定的请求头
            const headers: Record<string, string> = {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            };
            await this.setupMediaUrlWithHeaders(this.imageUrl, headers);
          } else {
            // 对于普通HTTP/HTTPS媒体资源
            await this.setupMediaUrl(this.imageUrl);
          }
        } else {
          // 确保在合适的状态下调用play方法
          await this.avPlayer.play();
        }
      }
    } catch (err) {
      const error = err as BusinessError;
      this.playerErrorMessage = `播放/暂停失败: ${error.message}`;
      console.error('播放/暂停失败:', error);
    }
  }
  
  // 停止播放
  async stopVideo(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.stop();
        this.isPlaying = false;
      } catch (err) {
        const error = err as BusinessError;
        this.playerErrorMessage = `停止播放失败: ${error.message}`;
        console.error('停止播放失败:', error);
      }
    }
  }
  
  // 判断是否为视频URL
  private isVideoUrl(url: string): boolean {
    const videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv'];
    const lowerUrl = url.toLowerCase();
    return videoExtensions.some(ext => lowerUrl.includes(ext));
  }

  private resolveEndpoint(mode: DetectionMode): string {
    const trimmedBase = API_BASE_URL.trim().replace(/\/$/, '');
    const path = mode === 'target' ? DETECTION_ENDPOINTS.target : DETECTION_ENDPOINTS.crack;
    return `${trimmedBase}${path}`;
  }

  private stringifyJson(value?: ResponsePayload): string {
    if (value === undefined) {
      return '';
    }

    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      return value.toString();
    }

    if (value === null) {
      return 'null';
    }

    try {
      return JSON.stringify(value, null, 2);
    } catch (_) {
      return '[Unsupported JSON Structure]';
    }
  }

  private formatResponse(response?: DetectionApiResponse, fallback?: string): string {
    if (!response) {
      return fallback ?? 'AI 服务未返回结果';
    }

    const segments: Array<string> = [
      `检测类型: ${this.detectionMode === 'crack' ? '裂缝检测' : '目标识别'}`
    ];

    if (response.code !== undefined) {
      segments.push(`业务码: ${response.code}`);
    }

    if (this.lastLatency > 0) {
      segments.push(`耗时: ${this.lastLatency} ms`);
    }

    if (response.message) {
      segments.push(`消息: ${response.message}`);
    }

    const payloadText = this.stringifyJson(response.data ?? response.result);
    if (payloadText) {
      segments.push('结果:');
      segments.push(payloadText);
    }

    return segments.join('\n');
  }

  private ensureReady(): boolean {
    if (!this.imageUrl.trim()) {
      this.resultText = '请填写需要检测的图片 URL';
      this.syncAIResult(this.resultText);
      return false;
    }

    return true;
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let result = '';
    bytes.forEach((value: number) => {
      result += String.fromCharCode(value);
    });
    return result;
  }

  private extractResponseText(result: ResponsePayload | string | ArrayBuffer | undefined): string {
    if (typeof result === 'string') {
      return result;
    }

    if (result instanceof ArrayBuffer) {
      return this.arrayBufferToString(result);
    }

    if (result) {
      try {
        return JSON.stringify(result, null, 2);
      } catch (_) {
        return '[无法解析的响应内容]';
      }
    }

    return '';
  }

  private clearResult(): void {
    if (this.isLoading) {
      return;
    }
    this.resultText = '等待检测...';
    this.lastLatency = 0;
    this.syncAIResult(this.resultText);
  }

  private getModeHint(): string {
    const option = MODE_OPTIONS.find((item: ModeOption) => item.value === this.detectionMode);
    return option ? option.hint : '';
  }

  async triggerDetection(): Promise<void> {
    if (!this.ensureReady() || this.isLoading) {
      return;
    }

    this.isLoading = true;
    this.resultText = '正在调用 AI 服务...';

    try {
      // 下载图片并转换为Base64编码
      const base64String = await this.downloadImageAsBase64(this.imageUrl.trim());
      
      // 检查Base64字符串长度
      console.log(`Base64字符串长度: ${base64String.length}`);
      this.resultText = `图片已转换，Base64长度: ${base64String.length}`;
      this.syncAIResult(this.resultText);
      
      // 如果Base64字符串过长，截取一部分用于测试
      let truncatedBase64 = base64String;
      if (base64String.length > 500000) { // 如果超过500KB字符数，进行截取
        truncatedBase64 = base64String.substring(0, 500000);
        this.resultText += '\n注意：图片数据已截取以减少大小';
        this.syncAIResult(this.resultText);
      }
      
      // 构建表单数据 - 使用Base64编码的图片数据
      let formData = '';
      formData += 'fileBase64String=' + encodeURIComponent(base64String);
      // 添加question参数，根据Java示例
      formData += '&question=' + encodeURIComponent('question');
      
      const headers: Record<string, string> = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Authorization': `APPCODE 840e1628a99f4f8ca4c35e872111066b`
      };

      // 打印请求信息用于调试
      console.log('发送API请求:');
      console.log('URL:', this.resolveEndpoint(this.detectionMode));
      console.log('Headers:', JSON.stringify(headers));
      console.log('FormData长度:', formData.length);

      const httpClient = http.createHttp();
      const startedAt = Date.now();

      const response = await httpClient.request(this.resolveEndpoint(this.detectionMode), {
        method: http.RequestMethod.POST,
        extraData: formData,
        header: headers,
        expectDataType: http.HttpDataType.OBJECT,
        connectTimeout: 8000,
        readTimeout: 15000
      });

      this.lastLatency = Date.now() - startedAt;
      console.log(`API响应状态码: ${response.responseCode}`);
      
      // 根据响应状态码提供具体提示
      if (response.responseCode === 403) {
        this.resultText = 'API认证失败或权限不足，请检查AppCode是否正确且有足够权限';
        this.syncAIResult(this.resultText);
        return;
      }
      
      if (response.responseCode === 413) {
        this.resultText = '请求数据过大，请尝试使用较小的图片';
        this.syncAIResult(this.resultText);
        return;
      }
      
      const raw = this.extractResponseText(response.result);
      let parsed: DetectionApiResponse | undefined;

      if (raw) {
        try {
          parsed = JSON.parse(raw) as DetectionApiResponse;
        } catch (_) {
          parsed = undefined;
        }
      }

      this.resultText = this.formatResponse(parsed, raw || 'AI 服务未返回文本结果');
      this.syncAIResult(this.resultText);
    } catch (error) {
      const bizError = error as BusinessError;
      let errorMsg = `调用失败: ${bizError.message}`;
      
      // 简化错误处理逻辑（符合用户偏好）
      if (bizError.code === 400) {
        errorMsg = '请求参数错误，请检查API配置和输入参数';
      } else if (bizError.code === 401) {
        errorMsg = 'API认证失败，请检查AppCode是否正确';
      } else if (bizError.code === 404) {
        errorMsg = 'API端点不存在，请检查URL配置';
      } else if (bizError.code === 413) {
        errorMsg = '请求实体过大，图片可能太大';
      }
      
      console.error('API调用错误:', errorMsg);
      this.resultText = errorMsg;
      this.syncAIResult(this.resultText);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 通过HTTP请求下载图片并转换为Base64编码
   * @param url 图片URL
   * @returns Base64编码字符串
   */
  private async downloadImageAsBase64(url: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const httpClient = http.createHttp();
      
      // 设置期望的数据类型为ARRAY_BUFFER
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        header: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        connectTimeout: 8000,
        readTimeout: 15000
      };

      httpClient.request(url, options, (err: BusinessError, data: http.HttpResponse) => {
        try {
          if (err) {
            reject(new Error(`图片下载失败: ${err.message}`));
            return;
          }

          if (data.responseCode !== http.ResponseCode.OK) {
            reject(new Error(`图片下载失败，HTTP状态码: ${data.responseCode}`));
            return;
          }

          // 获取图片数据
          const arrayBuffer = data.result as ArrayBuffer;
          
          // 将ArrayBuffer转换为Uint8Array
          const uint8Array = new Uint8Array(arrayBuffer);
          
          // 使用Base64Helper进行编码
          const base64Helper = new util.Base64Helper();
          const base64String = base64Helper.encodeToStringSync(uint8Array);
          
          resolve(base64String);
        } catch (e) {
          reject(new Error(`图片转换为Base64失败: ${e.message}`));
        } finally {
          httpClient.destroy();
        }
      });
    });
  }

  private syncAIResult(result: string): void {
    // 使用AppStorageV2存储AI结果
    AppStorageV2.connect(String, AI_RESULT_STORAGE_KEY, () => new String(result));
  }

  build() {
    Column() {
      // 顶部标题区域
      Column() {
        Text(MODEL_NAME)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Text(MODEL_DESC)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })
      
      Scroll() {
        Column() {
          // 模式切换区
          Column() {
            Text('检测模式')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .width('100%')
              .textAlign(TextAlign.Start)
            
            Row() {
              ForEach(MODE_OPTIONS, (option: ModeOption) => {
                Button(option.label)
                  .backgroundColor(option.value === this.detectionMode ? $r('app.color.primary_blue') : $r('app.color.card_background'))
                  .fontColor(option.value === this.detectionMode ? '#FFFFFF' : $r('app.color.text_primary'))
                  .borderRadius(4)
                  .onClick(() => {
                    if (this.isLoading) {
                      return;
                    }
                    this.detectionMode = option.value;
                  })
                  .layoutWeight(1)
                  .margin({ right: option.value === 'target' ? 0 : 10 });
              }, (item: ModeOption, index: number) => `${item.value}-${index}`);
            }
            .width('100%')
            .height(40)
            
            Text(this.getModeHint())
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 10 })
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .width('90%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .margin({ bottom: 18 })

          // 数据流配置区
          Column() {
            Text('数据流配置')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .width('100%')
              .textAlign(TextAlign.Start)

            Column() {
              TextInput({ placeholder: '输入需要数据流的URL', text: this.imageUrl })
                .onChange((value: string) => {
                  this.imageUrl = value;
                })
                .width('100%')
                .height(40)
                .borderRadius(4)
                .margin({ bottom: 10 })

              TextInput({ placeholder: '可选：补充环境或备注', text: this.remark })
                .onChange((value: string) => {
                  this.remark = value;
                })
                .width('100%')
                .height(40)
                .borderRadius(4)
            }
            .width('100%')
          }
          .width('90%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(8)
          .margin({ bottom: 18 })

          // 操作按钮区
          Row() {
            Button(this.isLoading ? '推理中...' : '启动')
              .backgroundColor($r('app.color.primary_blue'))
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                this.triggerDetection();
              })
              .layoutWeight(1)

            Button('清空面板')
              .margin({ left: 10 })
              .backgroundColor($r('app.color.card_background'))
              .fontColor($r('app.color.text_primary'))
              .borderRadius(8)
              .onClick(() => {
                this.clearResult();
              })
              .layoutWeight(1)
          }
          .width('90%')
          .height(40)
          .margin({ bottom: 18 })

          // 结果展示区
          Column() {
            Text('AI 分析结果')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 10 })
              .width('100%')
              .textAlign(TextAlign.Start)

            // 显示当前图片或视频
            if (this.isVideoUrl(this.imageUrl)) {
              // 视频播放区域
              Column() {
                // 实际的视频显示组件
                Video({
                  src: this.imageUrl,
                  previewUri: ''
                })
                .width('100%')
                .height(150)
                .margin({ bottom: 10 })
                .onStart(() => {
                  console.log('视频开始播放');
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
                  this.playerErrorMessage = '视频播放出错';
                })

                
                // 错误信息显示
                if (this.playerErrorMessage) {
                  Text(this.playerErrorMessage)
                    .fontSize(12)
                    .fontColor('#ff4d4f')
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .margin({ top: 5 })
                }
                
                Text(`播放器状态: ${this.isPlaying ? '播放中' : '已暂停'}`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .textAlign(TextAlign.Start)
                  .margin({ top: 5 })
              }
              .width('100%')
              .margin({ bottom: 10 })
            } else {
              // 图片显示区域
              Image(this.imageUrl)
                .width('100%')
                .height(150)
                .objectFit(ImageFit.Contain)
                .margin({ bottom: 10 })
                .onComplete(() => {
                  console.log('Image loaded successfully');
                })
                .onError(() => {
                  console.log('Failed to load image');
                })
            }

            Scroll() {
              Text(this.resultText)
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