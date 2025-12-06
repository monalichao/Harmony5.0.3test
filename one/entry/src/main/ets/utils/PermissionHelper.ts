import { GlobalContext } from './GlobalContext';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

export class PermissionHelper {
  public static requestPermissions(permissions: Permissions[], callback: (results: number[]) => void) {
    let context = GlobalContext.getContext().getValue('context') as common.UIAbilityContext;
    if (!context) {
      console.error("PermissionHelper: Context not found in GlobalContext");
      return;
    }
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, permissions, (err: BusinessError, results: PermissionRequestResult) => {
      callback(results.authResults);
    });
  }
}