import {
  BleManager,
  BleDevice,
  BleGattCallback,
  BleScanCallback,
  BleWriteCallback,
  BleException,
  HexUtil,
  BleScanRuleConfig
} from '@ohos/fastble';
import ble from '@ohos.bluetooth.ble';
import { Permissions } from '@ohos.abilityAccessCtrl';
import { PermissionHelper } from './PermissionHelper';

// 定义特征值信息结构
class WriteCharacteristicInfo {
  serviceUuid: string = '';
  charUuid: string = '';
}

type ScanResultCallback = (device: BleDevice) => void;
type ConnectionStateCallback = (isConnected: boolean) => void;

export class BleRobotController {
  private static instance: BleRobotController;
  private currentDevice: BleDevice | null = null;
  private writeCharacteristic: WriteCharacteristicInfo | null = null;

  public static getInstance(): BleRobotController {
    if (!BleRobotController.instance) {
      BleRobotController.instance = new BleRobotController();
    }
    return BleRobotController.instance;
  }

  public isConnected(): boolean {
    return this.currentDevice !== null && this.writeCharacteristic !== null;
  }

  init() {
    BleManager.getInstance().init();
    BleManager.getInstance()
      .enableLog(true)
      .setReConnectCount(1, 5000)
      .setConnectOverTime(10000)
      .setOperateTimeout(5000);
  }

  checkPermissions(onGranted: () => void) {
    let permissions: Permissions[] = [
      'ohos.permission.USE_BLUETOOTH',
      'ohos.permission.DISCOVER_BLUETOOTH',
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION',
      'ohos.permission.ACCESS_BLUETOOTH'
    ];
    PermissionHelper.requestPermissions(permissions, (results) => {
      onGranted();
    });
  }

  startScan(onDeviceFound: ScanResultCallback) {
    let scanRuleConfig = BleScanRuleConfig.Builder.setScanTimeOut(10000).build();
    BleManager.getInstance().initScanRule(scanRuleConfig);

    class MyScanCallback extends BleScanCallback {
      onScanStarted(success: boolean): void {}
      onScanning(bleDevice: BleDevice): void {
        if (bleDevice.getName()) {
          onDeviceFound(bleDevice);
        }
      }
      onLeScan(bleDevice: BleDevice): void {}
      onScanFinished(scanResultList: Array<BleDevice>): void {}
    }

    BleManager.getInstance().scan(new MyScanCallback());
  }

  stopScan() {
    BleManager.getInstance().cancelScan();
  }

  connect(device: BleDevice, onStateChange: ConnectionStateCallback) {
    this.stopScan();
    let that = this;

    class MyGattCallback extends BleGattCallback {
      onStartConnect(): void {
        console.info(`BleRobotController: 开始连接 ${device.getName()}`);
      }
      onConnectFail(bleDevice: BleDevice, exception: BleException): void {
        console.error('BleRobotController: 连接失败: ' + JSON.stringify(exception));
        onStateChange(false);
      }
      onConnectSuccess(bleDevice: BleDevice, gatt: ble.GattClientDevice, status: number): void {
        console.info(`BleRobotController: 连接成功`);
        that.currentDevice = bleDevice;
        onStateChange(true);
        setTimeout(() => { that.discoverServices(bleDevice); }, 500);
      }
      onDisConnected(isActive: boolean, device: BleDevice, gatt: ble.GattClientDevice, status: number): void {
        console.warn('BleRobotController: 连接断开');
        that.currentDevice = null;
        that.writeCharacteristic = null;
        onStateChange(false);
      }
    }

    BleManager.getInstance().connect(device, new MyGattCallback());
  }

  private discoverServices(device: BleDevice) {
    BleManager.getInstance().getBluetoothGattServices(device, (err, services: ble.GattService[]) => {
      if (err) {
        console.error('BleRobotController: 获取服务失败: ' + JSON.stringify(err));
        return;
      }

      console.info('BleRobotController: 发现服务数量: ' + services.length);

      let targetService: ble.GattService | null = null;
      let targetChar: ble.BLECharacteristic | null = null;

      // 1. 优先找 FFE0 服务里的 FFE2 特征（之前成功过）
      for (let s of services) {
        if (s.serviceUuid.toUpperCase().includes('FFE0')) {
          for (let c of s.characteristics) {
            if (c.characteristicUuid.toUpperCase().includes('FFE2') &&
              (c.properties?.write || c.properties?.writeNoResponse)) {
              targetService = s;
              targetChar = c;
              break;
            }
          }
        }
        if (targetChar) break;
      }

      // 2. 如果还没找到，退而求其次：找第一个具备 write/writeNoResponse 的特征
      if (!targetChar) {
        for (let s of services) {
          for (let c of s.characteristics) {
            if (c.properties?.write || c.properties?.writeNoResponse) {
              targetService = s;
              targetChar = c;
              break;
            }
          }
          if (targetChar) break;
        }
      }

      if (targetService && targetChar) {
        let info = new WriteCharacteristicInfo();
        info.serviceUuid = targetService.serviceUuid;
        info.charUuid = targetChar.characteristicUuid;
        this.writeCharacteristic = info;
        console.info(`>>> 锁定写入特征值: Service=${info.serviceUuid}, Char=${info.charUuid}`);
      } else {
        console.error('>>> 警告: 未找到任何可写入的特征值！无法控制设备！');
      }
    });
  }

  /**
   * 核心修复：发送单字节字符
   */
  sendByteCommand(cmdChar: string) {
    if (!this.currentDevice || !this.writeCharacteristic) {
      console.error('发送失败: 未连接或未锁定写特征');
      return;
    }
    if (!cmdChar || cmdChar.length === 0) {
      console.warn('发送失败: 空命令');
      return;
    }

    const buffer = new ArrayBuffer(1);
    const data = new Uint8Array(buffer);
    data[0] = cmdChar.charCodeAt(0);

    console.info(`BleRobotController.sendByteCommand: cmd="${cmdChar}", bytes=[${Array.from(data)}]`);

    class MyWriteCallback extends BleWriteCallback {
      onWriteSuccess(current: number, total: number, val: Uint8Array): void {
        console.info(`BleRobotController: 写入成功 cmd="${cmdChar}", data=[${Array.from(val)}]`);
      }
      onWriteFailure(exception: BleException): void {
        console.error(`BleRobotController: 写入失败 cmd="${cmdChar}", err=${JSON.stringify(exception)}`);
      }
    }

    // 这里使用 split=true, needResponse=false -> WRITE_NO_RESPONSE （你之前成功时的模式）
    BleManager.getInstance().write(
      this.currentDevice,
      this.writeCharacteristic.serviceUuid,
      this.writeCharacteristic.charUuid,
      data,
      true,   // split
      false,  // needResponse -> false => WRITE_NO_RESPONSE
      0,
      new MyWriteCallback()
    );
  }

  disconnect() {
    this.currentDevice = null;
    this.writeCharacteristic = null;
    BleManager.getInstance().disconnectAllDevice();
  }
}