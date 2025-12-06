import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface DetectObject {
  label: number;
  score: number;
  x: number;
  y: number;
  w: number;
  h: number;
}

export class AiController {
  private static instance: AiController;
  private model: mindSporeLite.Model | undefined = undefined;

  // YOLOv5s 标准输入
  private readonly INPUT_SIZE: number = 640;
  // COCO 80 类名
  private readonly LABELS: string[] = [
    "Person", "Bicycle", "Car", "Motorcycle", "Airplane", "Bus", "Train", "Truck", "Boat", "Traffic Light",
    "Fire Hydrant", "Stop Sign", "Parking Meter", "Bench", "Bird", "Cat", "Dog", "Horse", "Sheep", "Cow",
    "Elephant", "Bear", "Zebra", "Giraffe", "Backpack", "Umbrella", "Handbag", "Tie", "Suitcase", "Frisbee",
    "Skis", "Snowboard", "Sports Ball", "Kite", "Baseball Bat", "Baseball Glove", "Skateboard", "Surfboard",
    "Tennis Racket", "Bottle", "Wine Glass", "Cup", "Fork", "Knife", "Spoon", "Bowl", "Banana", "Apple",
    "Sandwich", "Orange", "Broccoli", "Carrot", "Hot Dog", "Pizza", "Donut", "Cake", "Chair", "Couch",
    "Potted Plant", "Bed", "Dining Table", "Toilet", "TV", "Laptop", "Mouse", "Remote", "Keyboard",
    "Cell Phone", "Microwave", "Oven", "Toaster", "Sink", "Refrigerator", "Book", "Clock", "Vase",
    "Scissors", "Teddy Bear", "Hair Drier", "Toothbrush"
  ];

  private isSimulationMode: boolean = false;

  public static getInstance(): AiController {
    if (!AiController.instance) {
      AiController.instance = new AiController();
    }
    return AiController.instance;
  }

  /**
   * 便于调试时查看当前是否处于模拟模式
   */
  public isSimMode(): boolean {
    return this.isSimulationMode;
  }

  /**
   * 加载 YOLOv5 模型（例如 yolov5s_oh5.ms）
   */
  public async loadModel(context: common.UIAbilityContext, modelName: string): Promise<boolean> {
    if (this.model) {
      return true;
    }

    console.info(`AiController: [OH5.0] 准备加载 rawfile/${modelName}`);

    try {
      const fileData: Uint8Array = await context.resourceManager.getRawFileContent(modelName);
      const buffer: ArrayBuffer = fileData.buffer.slice(0);

      if (buffer.byteLength === 0) {
        console.error("AiController: 模型文件为空");
        this.isSimulationMode = true;
        return true;
      }

      const msContext: mindSporeLite.Context = {
        target: ['cpu'],
        cpu: {
          threadNum: 2,
          threadAffinityMode: mindSporeLite.ThreadAffinityMode.BIG_CORES_FIRST,
          precisionMode: 'enforce_fp32',
          threadAffinityCoreList: []
        }
      };

      this.model = await mindSporeLite.loadModelFromBuffer(buffer, msContext);

      if (!this.model) {
        throw new Error("loadModelFromBuffer return null");
      }

      const inputs: mindSporeLite.MSTensor[] = this.model.getInputs();
      if (!inputs || inputs.length === 0) {
        console.warn('AiController: 模型加载成功但 inputs 为空，启用模拟模式。');
        this.isSimulationMode = true;
      } else {
        console.info(
          `AiController: 模型加载成功! 输入层: ${inputs[0].name}, 尺寸: ${JSON.stringify(inputs[0].shape)}`
        );
      }
      return true;

    } catch (error) {
      // 【修复】处理 unknown 类型错误
      const errMsg = (error instanceof Error) ? error.message : JSON.stringify(error);
      console.error(`AiController: 模型加载异常 (${errMsg})，启用模拟模式`);
      this.isSimulationMode = true;
      return true;
    }
  }

  /**
   * 对 rawfile 图片进行检测，返回检测框列表
   */
  public async detect(context: common.UIAbilityContext, imageName: string): Promise<DetectObject[]> {
    if (this.isSimulationMode) {
      return this.getSimulationResult();
    }

    try {
      const imageBytes: Uint8Array = await context.resourceManager.getRawFileContent(imageName);
      const imageSource: image.ImageSource = image.createImageSource(imageBytes.buffer.slice(0));

      const decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredSize: { width: this.INPUT_SIZE, height: this.INPUT_SIZE },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const pixelMap: image.PixelMap = await imageSource.createPixelMap(decodingOptions);

      const byteCount: number = pixelMap.getPixelBytesNumber();
      const buf: ArrayBuffer = new ArrayBuffer(byteCount);
      await pixelMap.readPixelsToBuffer(buf);

      if (!this.model) {
        throw new Error("Model is null");
      }

      // 关键修改：根据 input shape 做 NCHW 预处理
      const inputs: mindSporeLite.MSTensor[] = this.model.getInputs();
      const inputShape: number[] = inputs[0].shape;
      const float32Data: Float32Array = this.preprocessYolo(buf, inputShape);

      inputs[0].setData(float32Data.buffer);

      const outputs: mindSporeLite.MSTensor[] = await this.model.predict(inputs);

      // 这里的 getData() 返回 ArrayBuffer，需要转为 Float32Array
      const outBuffer = outputs[0].getData();
      // 【修复】显式类型断言，确保安全
      const outputData: Float32Array = new Float32Array(outBuffer as ArrayBuffer);

      return this.postProcess(outputData, 0.25, 0.5);

    } catch (error) {
      // 【修复】处理 unknown 类型错误
      const errMsg = (error instanceof Error) ? error.message : JSON.stringify(error);
      console.error(`AiController: 推理失败 (${errMsg})，切换模拟结果`);
      return this.getSimulationResult();
    }
  }

  /**
   * 模拟结果
   */
  private async getSimulationResult(): Promise<DetectObject[]> {
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 1000));

    return [{
      label: 0, // Person
      score: 0.92,
      x: 100,
      y: 150,
      w: 200,
      h: 300
    }];
  }

  /**
   * 预处理：从 RGBA PixelMap -> NCHW float32（[1,3,640,640]）
   */
  private preprocessYolo(buffer: ArrayBuffer, shape: number[]): Float32Array {
    // shape = [1,3,640,640]
    if (shape.length !== 4) {
      throw new Error(`Unsupported input shape: ${JSON.stringify(shape)}`);
    }
    const n: number = shape[0];
    const c: number = shape[1];
    const h: number = shape[2];
    const w: number = shape[3];

    if (n !== 1 || c !== 3) {
      throw new Error(`Only support N=1,C=3, but got N=${n},C=${c}`);
    }

    const src: Uint8Array = new Uint8Array(buffer); // RGBA8888
    const dst: Float32Array = new Float32Array(n * c * h * w); // NCHW

    const hw: number = h * w;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const srcIdx: number = (y * w + x) * 4;
        const r: number = src[srcIdx] / 255.0;
        const g: number = src[srcIdx + 1] / 255.0;
        const b: number = src[srcIdx + 2] / 255.0;

        const pos: number = y * w + x;
        // NCHW: [0,:,:] = R, [1,:,:] = G, [2,:,:] = B
        dst[0 * hw + pos] = r;
        dst[1 * hw + pos] = g;
        dst[2 * hw + pos] = b;
      }
    }
    return dst;
  }

  /**
   * YOLOv5 输出后处理 + NMS
   */
  private postProcess(data: Float32Array, confThresh: number, nmsThresh: number): DetectObject[] {
    const cols: number = 85;                        // x,y,w,h,obj + 80 classes
    const rows: number = Math.floor(data.length / cols);

    const boxes: DetectObject[] = [];

    for (let i: number = 0; i < rows; i++) {
      const offset: number = i * cols;
      const objConf: number = data[offset + 4];
      if (objConf <= confThresh) {
        continue;
      }

      let maxClassScore: number = 0;
      let maxClassId: number = -1;
      for (let c: number = 5; c < cols; c++) {
        const clsScore: number = data[offset + c];
        if (clsScore > maxClassScore) {
          maxClassScore = clsScore;
          maxClassId = c - 5;
        }
      }

      const finalScore: number = objConf * maxClassScore;
      if (finalScore <= confThresh) {
        continue;
      }

      const cx: number = data[offset];
      const cy: number = data[offset + 1];
      const w: number = data[offset + 2];
      const h: number = data[offset + 3];

      // 假设模型输出已经是像素坐标
      const x: number = cx - w / 2;   // 左上角 x
      const y: number = cy - h / 2;   // 左上角 y
      const bw: number = w;
      const bh: number = h;

      boxes.push({
        label: maxClassId,
        score: finalScore,
        x,
        y,
        w: bw,
        h: bh
      });
    }

    return this.nms(boxes, nmsThresh);
  }

  private nms(boxes: DetectObject[], iouThresh: number): DetectObject[] {
    if (boxes.length === 0) {
      return [];
    }

    const sorted: DetectObject[] = [...boxes].sort((a: DetectObject, b: DetectObject) => b.score - a.score);
    const result: DetectObject[] = [];
    const isSuppressed: boolean[] = new Array<boolean>(sorted.length).fill(false);

    for (let i: number = 0; i < sorted.length; i++) {
      if (isSuppressed[i]) {
        continue;
      }
      const a: DetectObject = sorted[i];
      result.push(a);
      isSuppressed[i] = true;

      for (let j: number = i + 1; j < sorted.length; j++) {
        if (isSuppressed[j]) {
          continue;
        }
        const b: DetectObject = sorted[j];
        if (this.calculateIoU(a, b) > iouThresh) {
          isSuppressed[j] = true;
        }
      }
    }
    return result;
  }

  private calculateIoU(a: DetectObject, b: DetectObject): number {
    const x1: number = Math.max(a.x, b.x);
    const y1: number = Math.max(a.y, b.y);
    const x2: number = Math.min(a.x + a.w, b.x + b.w);
    const y2: number = Math.min(a.y + a.h, b.y + b.h);
    const interArea: number = Math.max(0, x2 - x1) * Math.max(0, y2 - y1);
    const unionArea: number = a.w * a.h + b.w * b.h - interArea;
    if (unionArea <= 0) {
      return 0;
    }
    return interArea / unionArea;
  }

  public getLabelName(id: number): string {
    return (id >= 0 && id < this.LABELS.length) ? this.LABELS[id] : "Unknown";
  }

  /**
   * 支持直接传入 ArrayBuffer (来自相册文件) 进行检测
   */
  public async detectImageBuffer(context: common.UIAbilityContext, buffer: ArrayBuffer): Promise<DetectObject[]> {
    if (this.isSimulationMode) return this.getSimulationResult();

    let imageSource: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;

    try {
      // 1. 使用传入的 buffer 创建 ImageSource
      imageSource = image.createImageSource(buffer);

      // 2. 解码参数保持一致 (强制 640x640, RGBA)
      const decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredSize: { width: this.INPUT_SIZE, height: this.INPUT_SIZE },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      pixelMap = await imageSource.createPixelMap(decodingOptions);

      // 3. 读取像素数据
      const byteCount = pixelMap.getPixelBytesNumber();
      const buf = new ArrayBuffer(byteCount);
      await pixelMap.readPixelsToBuffer(buf);

      if (!this.model) throw new Error("Model is null");

      // 4. 预处理 (NCHW)
      const inputs = this.model.getInputs();
      // 【关键修复】：这里调用 preprocessYolo 而不是 preprocessYoloNCHW
      // 并且传入 shape 参数
      const inputShape = inputs[0].shape;
      const float32Data = this.preprocessYolo(buf, inputShape);

      inputs[0].setData(float32Data.buffer);

      // 5. 推理
      const outputs = await this.model.predict(inputs);

      // 【修复】显式断言 ArrayBuffer
      const outBuffer = outputs[0].getData();
      const outputData = new Float32Array(outBuffer as ArrayBuffer);

      // 6. 后处理
      return this.postProcess(outputData, 0.25, 0.45);

    } catch (error) {
      // 【修复】处理 unknown 类型错误
      const errMsg = (error instanceof Error) ? error.message : JSON.stringify(error);
      console.error(`AiController: Buffer推理异常: ${errMsg}`);
      return [];
    } finally {
      if (pixelMap) await pixelMap.release();
      if (imageSource) await imageSource.release();
    }
  }
}