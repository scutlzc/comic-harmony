/**
 * 应用入口 Ability
 * Stage 模型 - UIAbility
 */
import UIAbility from '@ohos.app.ability.UIAbility'
import Window from '@ohos.window'
import { initStorage } from '../utils/Utils'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'ComicHarmony', 'Ability onCreate')
  }

  onDestroy(): void {
    hilog.info(0x0000, 'ComicHarmony', 'Ability onDestroy')
  }

  async onWindowStageCreate(windowStage: Window.WindowStage): Promise<void> {
    // 初始化本地存储
    await initStorage(this.context)

    // 加载主页
    windowStage.loadContent('ets/pages/Index.ets', (err) => {
      if (err) {
        hilog.error(0x0000, 'ComicHarmony', `loadContent failed: ${err.code}`)
        return
      }
    })
  }

  onWindowStageDestroy(windowStage: Window.WindowStage): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }
}
