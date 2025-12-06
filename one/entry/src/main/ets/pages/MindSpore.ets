import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { AiController, DetectObject } from '../utils/MindSporeController';
import { PhotoHelper } from '../utils/PhotoHelper';

@Entry
@Component
struct AiPage {
  // 状态变量
  @State modelInfo: string = 'Loading...';
  // resultImage 现在既可以是 rawfile(Resource) 也可以是相册图(PixelMap)
  @State resultImage: Resource | PixelMap | undefined = undefined;
  @State detectedObjects: DetectObject[] = [];
  @State isAnalyzing: boolean = false;
  @State inferenceTime: number = 0;

  // 布局参数
  private displaySize: number = 320;
  private modelInputSize: number = 640;

  // 颜色常量
  private readonly THEME_COLOR = '#0A59F7';
  private readonly BOX_COLOR = '#00FFCC';
  private readonly BG_COLOR = '#F5F7FA';

  aboutToAppear() {
    this.initModel();
  }

  async initModel() {
    let context = getContext(this) as common.UIAbilityContext;
    let success = await AiController.getInstance().loadModel(context, 'yolov5s_oh5.ms');
    if (success) {
      this.modelInfo = 'YOLOv5s (OH5.0)';
    } else {
      this.modelInfo = 'Simulation Mode';
    }
  }

  /**
   * 方式一：从 rawfile 加载示例图片 (旧逻辑)
   */
  async loadExampleImage() {
    if (this.isAnalyzing) return;
    this.isAnalyzing = true;
    this.detectedObjects = [];

    // 模拟加载延迟
    await new Promise<void>(r => setTimeout(r, 300));

    this.resultImage = $rawfile('test_fish.jpg');
    let context = getContext(this) as common.UIAbilityContext;

    let startTime = new Date().getTime();
    // 调用旧接口
    let results = await AiController.getInstance().detect(context, 'test_fish.jpg');
    let endTime = new Date().getTime();

    this.inferenceTime = endTime - startTime;
    this.detectedObjects = results;
    this.isAnalyzing = false;
  }

  /**
   * 方式二：从相册选择图片 (新逻辑)
   */
  async selectImageFromAlbum() {
    if (this.isAnalyzing) return;

    try {
      // 1. 使用 PhotoHelper 拉起相册
      // 使用 selectEasy 直接获取 uris 数组
      const uris = await PhotoHelper.selectEasy();

      if (!uris || uris.length === 0) {
        return; // 用户取消了选择
      }

      this.isAnalyzing = true;
      this.detectedObjects = [];
      const uri = uris[0];

      // 2. 读取文件到 ArrayBuffer
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const fileLen = fileIo.statSync(file.fd).size;
      const buffer = new ArrayBuffer(fileLen);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      // 3. 生成 PixelMap 用于界面显示
      // 注意：必须创建 PixelMap，Image组件才能显示来自 buffer 的图
      const imageSource = image.createImageSource(buffer);
      const pixelMap = await imageSource.createPixelMap();
      this.resultImage = pixelMap;

      // 4. 调用 AI 推理 (传入 Buffer)
      let context = getContext(this) as common.UIAbilityContext;
      let startTime = new Date().getTime();

      // 调用我们在 AiController 新增的 buffer 推理方法
      let results = await AiController.getInstance().detectImageBuffer(context, buffer);

      let endTime = new Date().getTime();
      this.inferenceTime = endTime - startTime;
      this.detectedObjects = results;

    } catch (err) {
      console.error('相册选择或推理失败:', JSON.stringify(err));
      // 可以弹个 Toast 提示用户失败
    } finally {
      this.isAnalyzing = false;
    }
  }

  build() {
    Column() {
      // 1. 顶部导航栏
      this.buildHeader()

      // 2. 主内容区
      Scroll() {
        Column({ space: 20 }) {
          this.buildDashboard()
          this.buildVisionWindow()
          this.buildResultList()
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 100 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 3. 底部操作栏 (双按钮)
      this.buildBottomBar()
    }
    .height('100%')
    .backgroundColor(this.BG_COLOR)
  }

  // --- 组件构建 ---

  @Builder
  buildHeader() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.trans_unselect')) // 确保有这个图标
          .width(24).height(24)
          .fillColor(Color.Black)
      }
      .width(40).height(40)
      .backgroundColor(Color.White)
      .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
      .onClick(() => router.back())

      Text('智能目标检测')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 16 })

      Blank()

      Text('AI VISION')
        .fontSize(12)
        .fontColor(this.THEME_COLOR)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#E6F0FF')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(12)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
  }

  @Builder
  buildDashboard() {
    Row() {
      Row() {
        Circle({ width: 8, height: 8 }).fill(Color.Green).margin({ right: 6 })
        Text(this.modelInfo).fontSize(14).fontColor('#666')
      }
      .padding(10).backgroundColor(Color.White).borderRadius(20)

      Blank()

      if (this.inferenceTime > 0) {
        Text(`${this.inferenceTime} ms`)
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.THEME_COLOR)
          .padding(10).backgroundColor(Color.White).borderRadius(20)
      }
    }
    .width('100%')
  }

  @Builder
  buildVisionWindow() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 底层图片：支持 Resource 或 PixelMap
        if (this.resultImage) {
          Image(this.resultImage)
            .width(this.displaySize)
            .height(this.displaySize)
            .objectFit(ImageFit.Fill) // 强制拉伸以匹配坐标
            .borderRadius(16)
        } else {
          Column() {
            // 这里可以放个默认图标
            Text('请选择图片进行检测')
              .fontSize(14).fontColor('#999')
          }
          .width(this.displaySize).height(this.displaySize)
          .backgroundColor('#EEF1F5')
          .justifyContent(FlexAlign.Center)
          .borderRadius(16)
        }

        // 加载遮罩
        if (this.isAnalyzing) {
          Column() {
            LoadingProgress().color(Color.White).width(50).height(50)
            Text('正在分析像素...').fontColor(Color.White).fontSize(14).margin({ top: 10 })
          }
          .width(this.displaySize).height(this.displaySize)
          .backgroundColor('#88000000')
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .zIndex(10)
        }

        // 识别框
        if (!this.isAnalyzing && this.detectedObjects.length > 0) {
          ForEach(this.detectedObjects, (obj: DetectObject) => {
            Rect()
              .width((obj.w / this.modelInputSize) * this.displaySize)
              .height((obj.h / this.modelInputSize) * this.displaySize)
              .position({
                x: (obj.x / this.modelInputSize) * this.displaySize,
                y: (obj.y / this.modelInputSize) * this.displaySize
              })
              .fillOpacity(0.1).fill(this.BOX_COLOR)
              .stroke(this.BOX_COLOR).strokeWidth(2)
              .zIndex(1)

            Row() {
              Text(AiController.getInstance().getLabelName(obj.label).toUpperCase())
                .fontSize(10).fontWeight(FontWeight.Bold).fontColor('#000')
              Text(` | ${(obj.score * 100).toFixed(0)}%`)
                .fontSize(10).fontColor('#000')
            }
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.BOX_COLOR)
            .borderRadius({ topLeft: 0, bottomRight: 4, topRight: 4, bottomLeft: 0 })
            .position({
              x: (obj.x / this.modelInputSize) * this.displaySize,
              y: ((obj.y / this.modelInputSize) * this.displaySize) - 18
            })
            .zIndex(2)
          })
        }
      }
      .shadow({ radius: 20, color: '#20000000', offsetY: 10 })
      .borderRadius(16)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildResultList() {
    Column() {
      Row() {
        Text('检测结果').fontSize(16).fontWeight(FontWeight.Bold)
        if(this.detectedObjects.length > 0) {
          Badge({
            count: this.detectedObjects.length,
            style: { color: Color.White, fontSize: 10, badgeSize: 16, badgeColor: this.THEME_COLOR }
          }).margin({ left: 8 })
        }
      }.width('100%').margin({ bottom: 10, top: 10 })

      if (this.detectedObjects.length > 0) {
        List({ space: 10 }) {
          ForEach(this.detectedObjects, (obj: DetectObject, index: number) => {
            ListItem() {
              Row() {
                Text(`${index + 1}`).fontSize(14).fontColor('#999').width(20)
                Column() {
                  Text(AiController.getInstance().getLabelName(obj.label))
                    .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                  Text(`Confidence: ${(obj.score * 100).toFixed(2)}%`)
                    .fontSize(12).fontColor('#999').margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                Stack() {
                  Progress({ value: obj.score * 100, total: 100, type: ProgressType.Ring })
                    .width(40).color(this.THEME_COLOR).style({ strokeWidth: 4 })
                  Text(`${(obj.score * 100).toFixed(0)}`).fontSize(10).fontColor('#999')
                }
              }
              .width('100%').padding(16).backgroundColor(Color.White)
              .borderRadius(12).shadow({ radius: 10, color: '#0D000000', offsetY: 2 })
            }
          })
        }.width('100%').height(200)
      } else {
        Column() {
          Text(this.isAnalyzing ? '正在分析图像内容...' : '暂无检测数据\n请上传图片开始分析')
            .fontSize(14).fontColor('#BBB').textAlign(TextAlign.Center)
            .margin({ top: 30 })
        }.width('100%').height(100)
      }
    }
    .width('100%')
  }

  @Builder
  buildBottomBar() {
    Row({ space: 12 }) {
      // 左侧按钮：示例图片
      Button("加载示例")
        .height(56)
        .width('35%')
        .type(ButtonType.Capsule)
        .backgroundColor('#E6F0FF') // 浅蓝
        .fontColor(this.THEME_COLOR)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.loadExampleImage();
        })

      // 右侧按钮：相册选择 (主按钮)
      Button() {
        Row() {
          if (this.isAnalyzing) {
            LoadingProgress().width(20).height(20).color(Color.White).margin({ right: 8 })
            Text('分析中...')
          } else {
            Text('从相册选择')
          }
        }
        .justifyContent(FlexAlign.Center)
      }
      .height(56)
      .layoutWeight(1) // 占据剩余空间
      .type(ButtonType.Capsule)
      .backgroundColor(this.THEME_COLOR)
      .fontColor(Color.White)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .shadow({ radius: 20, color: '#4D0A59F7', offsetY: 8 })
      .enabled(!this.isAnalyzing)
      .onClick(() => {
        this.selectImageFromAlbum();
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 24, top: 10 })
    .backgroundColor(this.BG_COLOR)
  }
}